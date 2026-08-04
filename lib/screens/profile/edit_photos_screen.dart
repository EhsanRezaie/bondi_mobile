import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/generated/app_localizations.dart';
import 'package:dating_app/models/photo.dart';
import 'package:dating_app/providers/profile_provider.dart';
import 'package:dating_app/services/photo_service.dart';
import 'package:dating_app/widgets/action_toast.dart';
import 'package:dating_app/widgets/shimmer_avatar.dart';

class _EditablePhoto {
  final String key;
  PhotoResponse? serverPhoto;
  File? localFile;
  bool isNew;
  bool isMain;

  _EditablePhoto({
    required this.key,
    this.serverPhoto,
    this.localFile,
    this.isNew = false,
    this.isMain = false,
  });
}

class EditPhotosScreen extends StatefulWidget {
  final ProfileProvider? profileProvider;

  const EditPhotosScreen({super.key, this.profileProvider});

  @override
  State<EditPhotosScreen> createState() => _EditPhotosScreenState();
}

class _EditPhotosScreenState extends State<EditPhotosScreen> {
  final ImagePicker _picker = ImagePicker();
  List<_EditablePhoto> _items = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  static const int minPhotos = 3;
  static const int maxPhotos = 9;

  @override
  void initState() {
    super.initState();
    _loadExistingPhotos();
  }

  Future<void> _loadExistingPhotos() async {
    setState(() => _isLoading = true);

    try {
      final photos = await PhotoService.getMyPhotos();
      photos.sort((a, b) => a.order.compareTo(b.order));

      setState(() {
        _items = photos.map((p) => _EditablePhoto(
          key: 'server_${p.id}',
          serverPhoto: p,
          isMain: p.isMain,
        )).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load photos';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndAddPhoto(ImageSource source) async {
    if (_items.length >= maxPhotos) {
      setState(() => _errorMessage = 'Maximum $maxPhotos photos allowed');
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);

        final validationError = PhotoService.validateImage(file);
        if (validationError != null) {
          setState(() => _errorMessage = validationError);
          return;
        }

        final finalFile = await PhotoService.convertToJpeg(file);

        setState(() {
          _items.add(_EditablePhoto(
            key: 'new_${DateTime.now().millisecondsSinceEpoch}',
            localFile: finalFile,
            isNew: true,
            isMain: _items.isEmpty,
          ));
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to pick image');
    }
  }

  Future<void> _deletePhoto(int index) async {
    final item = _items[index];

    if (item.isNew) {
      setState(() {
        final wasMain = item.isMain;
        _items.removeAt(index);
        if (wasMain && _items.isNotEmpty) {
          _items[0].isMain = true;
        }
        _errorMessage = null;
      });
      return;
    }

    if (item.serverPhoto == null) return;

    final success = await PhotoService.deletePhoto(item.serverPhoto!.id);
    if (success && mounted) {
      setState(() {
        final wasMain = item.isMain;
        _items.removeAt(index);
        if (wasMain && _items.isNotEmpty) {
          _items[0].isMain = true;
        }
        _errorMessage = null;
      });
    } else if (mounted) {
      setState(() => _errorMessage = 'Failed to delete photo');
    }
  }

  void _reorderPhotos(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;

    setState(() {
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);

      for (var i in _items) {
        i.isMain = false;
      }
      _items[0].isMain = true;
      _errorMessage = null;
    });
  }

  bool get _hasChanges {
    if (_items.any((i) => i.isNew)) return true;

    if (_items.any((i) => i.serverPhoto != null && i.isMain)) {
      final mainItem = _items.firstWhere((i) => i.isMain);
      if (mainItem.serverPhoto != null && !mainItem.serverPhoto!.isMain) return true;
    }

    final serverItems = _items.where((i) => i.serverPhoto != null).toList();
    for (int i = 0; i < serverItems.length; i++) {
      if (serverItems[i].serverPhoto!.order != i) return true;
    }

    return false;
  }

  Future<bool> _hasUnsavedChanges() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to go back?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _handleSave() async {
    final t = AppLocalizations.of(context)!;
    if (_isSaving) return;

    if (_items.length < minPhotos) {
      setState(() {
        _errorMessage = 'At least $minPhotos photos are required';
        _isSaving = false;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final List<_EditablePhoto> uploadedItems = [];

      for (var item in _items) {
        if (item.isNew && item.localFile != null) {
          final result = await PhotoService.uploadPhoto(item.localFile!);
          if (result == null) {
            setState(() {
              _errorMessage = 'Failed to upload a photo';
              _isSaving = false;
            });
            return;
          }
          uploadedItems.add(_EditablePhoto(
            key: 'server_${result.id}',
            serverPhoto: PhotoResponse(
              id: result.id,
              userId: '',
              url: result.url,
              order: 999,
              isMain: item.isMain,
              status: result.status,
              faceVerified: false,
            ),
            isMain: item.isMain,
          ));
        } else if (item.serverPhoto != null) {
          uploadedItems.add(item);
        }
      }

      final mainItem = uploadedItems.firstWhere(
        (i) => i.isMain,
        orElse: () => uploadedItems.first,
      );
      if (mainItem.serverPhoto != null) {
        final originalMain = _items.where(
          (i) => i.serverPhoto != null && i.serverPhoto!.isMain,
        ).toList();

        bool needsSetMain = true;
        if (originalMain.isNotEmpty && originalMain.first.serverPhoto!.id == mainItem.serverPhoto!.id) {
          if (!_items.any((i) => i.isNew)) {
            needsSetMain = false;
          }
        }

        if (needsSetMain) {
          final result = await PhotoService.setMainPhoto(mainItem.serverPhoto!.id);
          if (result == null) {
            setState(() {
              _errorMessage = 'Failed to set main photo';
              _isSaving = false;
            });
            return;
          }
        }
      }

      final serverItems = uploadedItems.where((i) => i.serverPhoto != null).toList();
      bool orderChanged = false;
      for (int i = 0; i < serverItems.length; i++) {
        if (serverItems[i].serverPhoto!.order != i) {
          orderChanged = true;
          break;
        }
      }
      if (serverItems.length > 1 && orderChanged) {
        final Map<String, int> orders = {};
        for (int i = 0; i < serverItems.length; i++) {
          orders[serverItems[i].serverPhoto!.id] = i;
        }
        final ok = await PhotoService.reorderPhotos(orders);
        if (!ok) {
          setState(() {
            _errorMessage = 'Failed to reorder photos';
            _isSaving = false;
          });
          return;
        }
      }

      if (mounted) {
        widget.profileProvider?.loadPhotos();
        showActionToast(context, t.photos_updated_success);
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('❌ Save error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred. Please try again.';
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = context.isDarkMode;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textMutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;
    final onSurfaceColor = colors.onSurface;
    final errorColor = AppTheme.lightError;

    final canSave = _items.isNotEmpty && _hasChanges;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _hasUnsavedChanges();
        if (!context.mounted) return;
        if (shouldPop) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: onSurfaceColor, size: 20),
            onPressed: () async {
              final shouldPop = await _hasUnsavedChanges();
              if (!context.mounted) return;
              if (shouldPop) {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            'Edit Photos',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: onSurfaceColor,
              letterSpacing: -0.4,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            )
          : SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 0),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Manage your photos. Add new ones, reorder, or set a main photo.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  color: textMutedColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    '${_items.length} / $maxPhotos photos',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: onSurfaceColor,
                                    ),
                                  ),
                                  if (_items.length < minPhotos) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      '(${minPhotos - _items.length} more required)',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        color: errorColor,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 10),

                              if (_errorMessage != null)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: errorColor.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: errorColor.withValues(alpha: 0.2)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error_outline, color: errorColor, size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 14,
                                            color: errorColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),

                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        sliver: SliverToBoxAdapter(
                          child: _buildPhotoGrid(primaryColor, borderColor, textMutedColor, onSurfaceColor),
                        ),
                      ),

                      // Tips row
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 4.0),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            children: [
                              Icon(Icons.drag_handle, size: 14, color: textMutedColor),
                              const SizedBox(width: 6),
                              Text(
                                'Drag to reorder',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  color: textMutedColor,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Drag to first slot to set as main',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  color: textMutedColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Container(
                          alignment: Alignment.bottomCenter,
                          padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0, top: 16.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: (_isSaving || !canSave) ? null : _handleSave,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: canSave ? primaryColor : primaryColor.withValues(alpha: 0.3),
                                foregroundColor: canSave ? Colors.white : primaryColor.withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                                minimumSize: const Size(double.infinity, 56),
                              ),
                              child: _isSaving
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(
                                    _items.length < minPhotos ? 'Add ${minPhotos - _items.length} more' : (canSave ? 'Save' : 'No changes'),
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: canSave ? Colors.white : primaryColor.withValues(alpha: 0.5),
                                    ),
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
      ),
    );
  }

  Widget _buildPhotoGrid(Color primaryColor, Color borderColor, Color textMutedColor, Color onSurfaceColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double gap = 10.0;
        final double smallItemWidth = (width - gap * 2) / 3;
        final double smallItemHeight = smallItemWidth * 1.1;
        final double mainWidth = smallItemWidth * 2 + gap;
        final double mainHeight = smallItemHeight * 2 + gap;

        final List<_EditablePhoto> displayItems = List.from(_items);

        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: SizedBox(
            width: width,
            child: Column(
              children: [
                // Row 1: Main slot + 2 small
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: mainWidth,
                      height: mainHeight,
                      child: _buildDraggableSlot(
                        index: 0,
                        items: displayItems,
                        primaryColor: primaryColor,
                        borderColor: borderColor,
                        textMutedColor: textMutedColor,
                        onSurfaceColor: onSurfaceColor,
                        isBig: true,
                      ),
                    ),
                    SizedBox(width: gap),
                    Column(
                      children: [
                        SizedBox(
                          width: smallItemWidth,
                          height: smallItemHeight,
                          child: _buildDraggableSlot(
                            index: 1,
                            items: displayItems,
                            primaryColor: primaryColor,
                            borderColor: borderColor,
                            textMutedColor: textMutedColor,
                            onSurfaceColor: onSurfaceColor,
                            isBig: false,
                          ),
                        ),
                        SizedBox(height: gap),
                        SizedBox(
                          width: smallItemWidth,
                          height: smallItemHeight,
                          child: _buildDraggableSlot(
                            index: 2,
                            items: displayItems,
                            primaryColor: primaryColor,
                            borderColor: borderColor,
                            textMutedColor: textMutedColor,
                            onSurfaceColor: onSurfaceColor,
                            isBig: false,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: gap),
                // Row 2: 3 small
                Row(
                  children: [
                    _buildSmallSlot(3, displayItems, primaryColor, borderColor, textMutedColor, onSurfaceColor, gap),
                    _buildSmallSlot(4, displayItems, primaryColor, borderColor, textMutedColor, onSurfaceColor, gap),
                    _buildSmallSlot(5, displayItems, primaryColor, borderColor, textMutedColor, onSurfaceColor, gap),
                  ],
                ),
                SizedBox(height: gap),
                // Row 3: 3 small
                Row(
                  children: [
                    _buildSmallSlot(6, displayItems, primaryColor, borderColor, textMutedColor, onSurfaceColor, gap),
                    _buildSmallSlot(7, displayItems, primaryColor, borderColor, textMutedColor, onSurfaceColor, gap),
                    _buildSmallSlot(8, displayItems, primaryColor, borderColor, textMutedColor, onSurfaceColor, gap),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSmallSlot(int index, List<_EditablePhoto> displayItems, Color primaryColor, Color borderColor, Color textMutedColor, Color onSurfaceColor, double gap) {
    final double totalWidth = MediaQuery.of(context).size.width - 48;
    final double smallItemWidth = (totalWidth - gap * 2) / 3;
    final double smallItemHeight = smallItemWidth * 1.1;

    return SizedBox(
      width: smallItemWidth,
      height: smallItemHeight,
      child: _buildDraggableSlot(
        index: index,
        items: displayItems,
        primaryColor: primaryColor,
        borderColor: borderColor,
        textMutedColor: textMutedColor,
        onSurfaceColor: onSurfaceColor,
        isBig: false,
      ),
    );
  }

  Widget _buildDraggableSlot({
    required int index,
    required List<_EditablePhoto> items,
    required Color primaryColor,
    required Color borderColor,
    required Color textMutedColor,
    required Color onSurfaceColor,
    required bool isBig,
  }) {
    final bool hasItem = index < items.length;
    final item = hasItem ? items[index] : null;

    if (!hasItem) {
      return _buildSlotContent(
        item: null,
        index: index,
        primaryColor: primaryColor,
        borderColor: borderColor,
        textMutedColor: textMutedColor,
        onSurfaceColor: onSurfaceColor,
        isBig: isBig,
      );
    }

    return DragTarget<int>(
      onWillAcceptWithDetails: (oldIndex) {
        return oldIndex.data != index && oldIndex.data < items.length;
      },
      onAcceptWithDetails: (oldIndex) {
        _reorderPhotos(oldIndex.data, index);
      },
      builder: (context, candidateData, rejectedData) {
        return LongPressDraggable<int>(
          data: index,
          onDragStarted: () => setState(() {}),
          onDragEnd: (_) => setState(() {}),
          feedback: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: isBig ? 160 : 80,
              height: isBig ? 160 : 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primaryColor, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: item?.localFile != null
                  ? Image.file(item!.localFile!, fit: BoxFit.cover)
                  : (item?.serverPhoto != null
                      ? CachedNetworkImage(
                          imageUrl: item!.serverPhoto!.displayUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Container(color: Colors.grey.shade200),
                          errorWidget: (_, _, _) => const Icon(Icons.broken_image),
                        )
                      : Container()),
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: _buildSlotContent(
              item: item,
              index: index,
              primaryColor: primaryColor,
              borderColor: borderColor,
              textMutedColor: textMutedColor,
              onSurfaceColor: onSurfaceColor,
              isBig: isBig,
            ),
          ),
          child: _buildSlotContent(
            item: item,
            index: index,
            primaryColor: primaryColor,
            borderColor: borderColor,
            textMutedColor: textMutedColor,
            onSurfaceColor: onSurfaceColor,
            isBig: isBig,
          ),
        );
      },
    );
  }

  Widget _buildSlotContent({
    required _EditablePhoto? item,
    required int index,
    required Color primaryColor,
    required Color borderColor,
    required Color textMutedColor,
    required Color onSurfaceColor,
    required bool isBig,
  }) {
    final bool hasItem = item != null;

    Color border = borderColor;
    double borderWidth = 1.5;

    if (hasItem) {
      if (item.isMain) {
        border = primaryColor;
        borderWidth = 2.5;
      } else {
        border = Colors.grey.shade300;
        borderWidth = 1;
      }
    }

    return GestureDetector(
      onTap: hasItem ? null : () => _showImagePicker(context),
      child: Container(
        decoration: BoxDecoration(
          color: hasItem ? Colors.transparent : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: borderWidth),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasItem && item.localFile != null)
                Image.file(item.localFile!, fit: BoxFit.cover, errorBuilder: (_, _, _) => _imageErrorWidget())
              else if (hasItem && item.serverPhoto != null)
                CachedNetworkImage(
                  imageUrl: item.serverPhoto!.displayUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => const ShimmerAvatar(),
                  errorWidget: (_, _, _) => _imageErrorWidget(),
                )
              else
                Center(
                  child: Icon(Icons.add, size: isBig ? 40 : 28, color: Colors.grey.shade400),
                ),

              if (hasItem && item.isMain)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.white, size: 12),
                        const SizedBox(width: 3),
                        Text(
                          'Main',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (hasItem && item.serverPhoto != null)
                _buildStatusBadge(item, textMutedColor, primaryColor),

              if (hasItem)
                Positioned(
                  top: 5,
                  left: 5,
                  child: GestureDetector(
                    onTap: () => _deletePhoto(index),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 12),
                    ),
                  ),
                ),

              if (hasItem)
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(Icons.drag_handle, color: Colors.white70, size: 14),
                  ),
                ),

              if (!hasItem)
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(13),
                      onTap: () => _showImagePicker(context),
                      child: Container(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(_EditablePhoto item, Color textMutedColor, Color primaryColor) {
    final t = AppLocalizations.of(context)!;
    if (item.serverPhoto == null) return const SizedBox.shrink();

    if (item.serverPhoto!.status != 'rejected') return const SizedBox.shrink();

    return Positioned(
      bottom: 26,
      left: 5,
      child: GestureDetector(
        onTap: item.serverPhoto!.rejectReason != null
            ? () {
                showActionToast(
                  context,
                  t.photo_rejected_reason(item.serverPhoto!.rejectReason!),
                  isError: true,
                );
              }
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.lightError,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.block, color: Colors.white, size: 10),
              const SizedBox(width: 3),
              Text(
                'Rejected',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageErrorWidget() {
    return Container(
      color: Colors.grey.shade300,
      child: Icon(Icons.broken_image, color: Colors.grey.shade600, size: 28),
    );
  }

  void _showImagePicker(BuildContext context) {
    if (_items.length >= maxPhotos) {
      setState(() => _errorMessage = 'Maximum $maxPhotos photos allowed');
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndAddPhoto(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndAddPhoto(ImageSource.camera);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
