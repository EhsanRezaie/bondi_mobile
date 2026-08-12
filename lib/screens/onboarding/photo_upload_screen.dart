// lib/screens/onboarding/photo_upload_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_theme.dart';
import '../../providers/onboarding_provider.dart';
import '../../services/photo_service.dart';
import '../../models/photo.dart';
import '../../utils/responsive.dart';
import '../main_screen.dart';

class PhotoUploadScreen extends StatefulWidget {
  const PhotoUploadScreen({super.key});

  @override
  State<PhotoUploadScreen> createState() => _PhotoUploadScreenState();
}

class _PhotoUploadScreenState extends State<PhotoUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  List<PhotoUpload> _photos = [];
  bool _isUploading = false;
  String? _errorMessage;

  static const int minPhotos = 3;
  static const int maxPhotos = 9;

  @override
  void initState() {
    super.initState();
    _loadSavedPhotos();
  }

  void _loadSavedPhotos() {
    final onboarding = Provider.of<OnboardingProvider>(context, listen: false);
    if (onboarding.photos != null && onboarding.photos!.isNotEmpty) {
      _photos = onboarding.photos!
          .map(
            (path) => PhotoUpload(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              file: File(path),
              isMain: false,
              isUploaded: false,
            ),
          )
          .toList();
      if (_photos.isNotEmpty) {
        _photos[0].isMain = true;
      }
      setState(() {});
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_photos.length >= maxPhotos) {
      setState(() {
        _errorMessage = 'Maximum $maxPhotos photos allowed';
      });
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

        // Validate image
        final validationError = PhotoService.validateImage(file);
        if (validationError != null) {
          setState(() {
            _errorMessage = validationError;
          });
          return;
        }

        // Convert to JPEG for better compatibility
        final finalFile = await PhotoService.convertToJpeg(file);

        setState(() {
          final newPhoto = PhotoUpload(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            file: finalFile,
            isMain: _photos.isEmpty,
            isUploaded: false,
          );
          _photos.add(newPhoto);
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image';
      });
    }
  }

  void _removePhoto(int index) {
    setState(() {
      final wasMain = _photos[index].isMain;
      _photos.removeAt(index);

      if (wasMain && _photos.isNotEmpty) {
        _photos[0].isMain = true;
      }
      _errorMessage = null;
    });
  }

  void _reorderPhotos(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;

    setState(() {
      final item = _photos.removeAt(oldIndex);
      _photos.insert(newIndex, item);

      for (var photo in _photos) {
        photo.isMain = false;
      }
      _photos[0].isMain = true;
    });
  }

  bool get _canProceed {
    return _photos.length >= minPhotos;
  }

  String? get _validationMessage {
    if (_photos.isEmpty) return 'Please add at least $minPhotos photos';
    if (_photos.length < minPhotos) {
      return 'Add ${minPhotos - _photos.length} more photo${minPhotos - _photos.length > 1 ? 's' : ''}';
    }
    return null;
  }

  Future<void> _handleComplete() async {
    if (!_canProceed) {
      setState(() {
        _errorMessage = _validationMessage;
      });
      return;
    }

    setState(() => _isUploading = true);

    final onboarding = Provider.of<OnboardingProvider>(context, listen: false);

    try {
      // Upload all photos
      final List<String> uploadedUrls = [];

      for (var i = 0; i < _photos.length; i++) {
        final photo = _photos[i];

        final result = await PhotoService.uploadPhoto(photo.file);
        if (result != null) {
          photo.url = result.url;
          photo.serverId = result.id;
          photo.isUploaded = true;
          uploadedUrls.add(result.url);

          if (photo.isMain) {
            await PhotoService.setMainPhoto(result.id);
          }
        } else {
          setState(() {
            _errorMessage = 'Failed to upload photo ${i + 1}';
            _isUploading = false;
          });
          return;
        }
      }

      // Save photo URLs to provider
      onboarding.setPhotos(uploadedUrls);

      // Profile is already complete - just go to MainScreen!
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to upload photos. Please try again.';
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = context.isDarkMode;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textMutedColor = isDark
        ? AppTheme.darkTextMuted
        : AppTheme.lightTextMuted;
    final onSurfaceColor = colors.onSurface;
    final errorColor = AppTheme.lightError;

    final int selectedCount = _photos.length;
    final bool canProceed = selectedCount >= minPhotos;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 80,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2.0),
                      decoration: BoxDecoration(
                        color: index <= 4
                            ? primaryColor
                            : (isDark ? Colors.white12 : Colors.black12),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 14),
              Text(
                'Photos',
                style: TextStyle(
                  fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: onSurfaceColor,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: AppLayout.box(
          context: context,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add at least 3 photos to showcase your best self. You can add up to 9.',
                      style: AppTheme.bodyLarge.copyWith(
                        color: textMutedColor,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: errorColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: errorColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: errorColor,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                                  fontSize: 12,
                                  color: errorColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_errorMessage != null) const SizedBox(height: 6),
                  ],
                ),
              ),

              // Photo Grid with Drag & Drop
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: _buildPhotoGrid(primaryColor, borderColor),
                ),
              ),

              // Tips with drag hint
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 4.0,
                ),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.drag_handle, size: 14, color: textMutedColor),
                        const SizedBox(width: 6),
                        Text(
                          'Drag to reorder photos',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                            fontSize: 11,
                            color: textMutedColor,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Tips: Clear, high-quality photos work best.',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: textMutedColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Button
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: bgColor,
                  border: Border(
                    top: BorderSide(color: borderColor, width: 0.5),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: AppTheme.gradientButton(
                    enabled: canProceed && !_isUploading,
                    onPressed: _isUploading ? null : _handleComplete,
                    child: _isUploading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            canProceed
                                ? 'Complete'
                                : 'Add ${minPhotos - selectedCount} more',
                            style: AppTheme.button.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoGrid(Color primaryColor, Color borderColor) {
    final int count = _photos.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double gap = 10.0;
        final double slotW = (width - gap * 2) / 3;
        final double slotH = slotW * 1.1;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: SizedBox(
            width: width,
            child: Column(
              children: [
                for (int row = 0; row < 3; row++)
                  Padding(
                    padding: EdgeInsets.only(bottom: row < 2 ? gap : 0),
                    child: Row(
                      children: [
                        for (int col = 0; col < 3; col++) ...[
                          if (col > 0) SizedBox(width: gap),
                          SizedBox(
                            width: slotW,
                            height: slotH,
                            child: _buildDraggablePhotoSlot(
                              index: row * 3 + col,
                              hasPhoto: count > (row * 3 + col),
                              photo: count > (row * 3 + col)
                                  ? _photos[row * 3 + col]
                                  : null,
                              isMain: (row * 3 + col) == 0 &&
                                  count > 0 &&
                                  _photos[0].isMain,
                              primaryColor: primaryColor,
                              borderColor: borderColor,
                              isBig: false,
                              totalCount: count,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDraggablePhotoSlot({
    required int index,
    required bool hasPhoto,
    required PhotoUpload? photo,
    required bool isMain,
    required Color primaryColor,
    required Color borderColor,
    required bool isBig,
    required int totalCount,
  }) {
    if (!hasPhoto) {
      // Empty slot - not draggable
      return _buildPhotoSlot(
        index: index,
        hasPhoto: false,
        photo: null,
        isMain: false,
        primaryColor: primaryColor,
        borderColor: borderColor,
        isBig: isBig,
      );
    }

    return DragTarget<int>(
      onWillAcceptWithDetails: (oldIndex) {
        return oldIndex.data != index && oldIndex.data < totalCount;
      },
      onAcceptWithDetails: (oldIndex) {
        _reorderPhotos(oldIndex.data, index);
      },
      builder: (context, candidateData, rejectedData) {
        return LongPressDraggable<int>(
          data: index,
          onDragStarted: () {
            setState(() {});
          },
          onDragEnd: (details) {
            setState(() {});
          },
          feedback: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primaryColor, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: photo != null
                    ? Image.file(photo.file, fit: BoxFit.cover)
                    : Container(),
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: _buildPhotoSlot(
              index: index,
              hasPhoto: hasPhoto,
              photo: photo,
              isMain: isMain,
              primaryColor: primaryColor,
              borderColor: borderColor,
              isBig: isBig,
            ),
          ),
          child: _buildPhotoSlot(
            index: index,
            hasPhoto: hasPhoto,
            photo: photo,
            isMain: isMain,
            primaryColor: primaryColor,
            borderColor: borderColor,
            isBig: isBig,
          ),
        );
      },
    );
  }

  Widget _buildPhotoSlot({
    required int index,
    required bool hasPhoto,
    required PhotoUpload? photo,
    required bool isMain,
    required Color primaryColor,
    required Color borderColor,
    required bool isBig,
  }) {
    return GestureDetector(
      onTap: hasPhoto ? null : () => _showImagePicker(context),
      child: Container(
        decoration: BoxDecoration(
          color: hasPhoto ? Colors.transparent : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasPhoto
                ? (isMain ? primaryColor : Colors.grey.shade300)
                : Colors.grey.shade300,
            width: hasPhoto ? (isMain ? 2.5 : 1) : 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              if (hasPhoto && photo != null)
                Image.file(
                  photo.file,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade300,
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.grey.shade600,
                        size: 28,
                      ),
                    );
                  },
                )
              else
                Center(
                  child: Icon(
                    Icons.add,
                    size: isBig ? 40 : 28,
                    color: Colors.grey.shade400,
                  ),
                ),

              // Main badge
              if (isMain && hasPhoto)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
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
                            fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Remove button - shows on ALL photos including main
              if (hasPhoto)
                Positioned(
                  top: 5,
                  left: 5,
                  child: GestureDetector(
                    onTap: () => _removePhoto(index),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ),

              // Drag handle
              if (hasPhoto)
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.drag_handle,
                      color: Colors.white70,
                      size: 14,
                    ),
                  ),
                ),

              // Tap to add overlay (empty slots)
              if (!hasPhoto)
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

  void _showImagePicker(BuildContext context) {
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
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
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
