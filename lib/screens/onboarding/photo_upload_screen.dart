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
import '../../widgets/action_toast.dart';
import '../../widgets/selfie_capture_view.dart';
import '../main_screen.dart';
import '../profile/create_ticket_screen.dart';

/// Single all-in-one photo flow: add/replace/delete/reorder photos (each
/// upload is checked immediately), take a selfie (auto-verified), and either
/// Finish once every photo is verified or fix things right here and re-verify.
class PhotoUploadScreen extends StatefulWidget {
  const PhotoUploadScreen({super.key});

  @override
  State<PhotoUploadScreen> createState() => _PhotoUploadScreenState();
}

class _PhotoUploadScreenState extends State<PhotoUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  List<PhotoUpload> _photos = [];
  bool _isWorking = false;
  String? _errorMessage;

  File? _selfieFile;
  List<String> _mismatchedPhotoIds = [];
  String? _lastVerifyMessage;
  bool _allVerified = false;

  static const int minPhotos = 3;
  static const int maxPhotos = 9;

  @override
  void initState() {
    super.initState();
    _loadSavedPhotos();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final onboarding = Provider.of<OnboardingProvider>(
        context,
        listen: false,
      );
      onboarding.setStepIndex(4);
      if (onboarding.selfieStage) {
        _syncRestoredServerIds();
      }
    });
  }

  void _syncPhotosToProvider() {
    Provider.of<OnboardingProvider>(
      context,
      listen: false,
    ).setPhotos(_photos.map((p) => p.file.path).toList());
  }

  void _loadSavedPhotos() {
    final onboarding = Provider.of<OnboardingProvider>(context, listen: false);
    if (onboarding.photos != null && onboarding.photos!.isNotEmpty) {
      final restored = <PhotoUpload>[];
      for (final path in onboarding.photos!) {
        final file = File(path);
        if (file.existsSync()) {
          restored.add(
            PhotoUpload(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              file: file,
              isMain: false,
              isUploaded: false,
            ),
          );
        }
      }
      _photos = restored;
      if (_photos.isNotEmpty) {
        _photos[0].isMain = true;
      }
      setState(() {});
    }
  }

  // On a resumed session the photos were uploaded before the app was killed,
  // but only their local paths are saved. Map the server photos back onto the
  // local list (by order) so verification state is correct without duplicates.
  Future<void> _syncRestoredServerIds() async {
    final server = await PhotoService.getMyPhotos();
    if (!mounted || server.isEmpty || _photos.isEmpty) return;
    server.sort((a, b) => a.order.compareTo(b.order));
    setState(() {
      for (var i = 0; i < _photos.length && i < server.length; i++) {
        final p = _photos[i];
        p.url = server[i].url;
        p.serverId = server[i].id;
        p.isUploaded = true;
        p.isMain = i == 0;
      }
    });
  }

  // ------------------------------------------------------------------
  // Photo management (each add/replace uploads immediately)
  // ------------------------------------------------------------------
  Future<void> _pickAndUpload({
    int? replaceIndex,
    ImageSource source = ImageSource.gallery,
  }) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    final file = File(picked.path);
    final validationError = PhotoService.validateImage(file);
    if (validationError != null) {
      setState(() => _errorMessage = validationError);
      return;
    }
    final finalFile = await PhotoService.convertToJpeg(file);
    if (!mounted) return;

    setState(() => _isWorking = true);
    final (result, uploadError) = await PhotoService.uploadPhoto(finalFile);
    if (!mounted) return;
    setState(() => _isWorking = false);

    if (result != null) {
      setState(() {
        if (replaceIndex != null && replaceIndex < _photos.length) {
          final old = _photos[replaceIndex];
          if (old.serverId != null) {
            PhotoService.deletePhoto(old.serverId!);
            _mismatchedPhotoIds.remove(old.serverId);
          }
          _photos[replaceIndex] = PhotoUpload(
            id: result.id,
            file: finalFile,
            isMain: old.isMain,
            isUploaded: true,
            url: result.url,
            serverId: result.id,
          );
        } else {
          _photos.add(
            PhotoUpload(
              id: result.id,
              file: finalFile,
              isMain: _photos.isEmpty,
              isUploaded: true,
              url: result.url,
              serverId: result.id,
            ),
          );
        }
        _allVerified = false;
        _lastVerifyMessage = null;
        _errorMessage = null;
      });
      _syncPhotosToProvider();
      showActionToast(context, 'Photo uploaded');
    } else {
      setState(() {
        if (replaceIndex != null && replaceIndex < _photos.length) {
          final old = _photos[replaceIndex];
          if (old.serverId != null) {
            PhotoService.deletePhoto(old.serverId!);
            _mismatchedPhotoIds.remove(old.serverId);
          }
          _photos[replaceIndex] = PhotoUpload(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            file: finalFile,
            isMain: old.isMain,
            rejectReason: uploadError,
          );
        } else {
          _photos.add(
            PhotoUpload(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              file: finalFile,
              isMain: _photos.isEmpty,
              rejectReason: uploadError,
            ),
          );
        }
        _allVerified = false;
        _lastVerifyMessage = null;
      });
      _syncPhotosToProvider();
      showActionToast(
        context,
        uploadError ?? 'Upload failed',
        isError: true,
      );
    }
  }

  Future<void> _removePhoto(int index) async {
    final photo = _photos[index];
    if (photo.serverId != null) {
      PhotoService.deletePhoto(photo.serverId!);
      _mismatchedPhotoIds.remove(photo.serverId);
    }
    setState(() {
      final wasMain = photo.isMain;
      _photos.removeAt(index);
      if (wasMain && _photos.isNotEmpty) {
        _photos[0].isMain = true;
      }
      _allVerified = false;
      _lastVerifyMessage = null;
    });
    _syncPhotosToProvider();
  }

  void _reorderPhotos(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    setState(() {
      final item = _photos.removeAt(oldIndex);
      _photos.insert(newIndex, item);
      for (final p in _photos) {
        p.isMain = false;
      }
      _photos[0].isMain = true;
    });
    _syncPhotosToProvider();
  }

  Future<void> _persistOrderAndMain() async {
    final serverItems = _photos.where((p) => p.serverId != null).toList();
    if (serverItems.length > 1) {
      final orders = <String, int>{};
      for (var i = 0; i < serverItems.length; i++) {
        orders[serverItems[i].serverId!] = i;
      }
      await PhotoService.reorderPhotos(orders);
    }
    final first = _photos.isNotEmpty ? _photos.first : null;
    if (first != null && first.serverId != null) {
      await PhotoService.setMainPhoto(first.serverId!);
    }
  }

  // ------------------------------------------------------------------
  // Selfie verification
  // ------------------------------------------------------------------
  int get _acceptedCount => _photos.where((p) => p.serverId != null).length;

  bool get _canTakeSelfie =>
      _acceptedCount >= minPhotos && !_photos.any((p) => p.isRejected);

  Future<void> _takeSelfie() async {
    if (!_canTakeSelfie) {
      showActionToast(
        context,
        'Upload at least $minPhotos photos first',
        isError: true,
      );
      return;
    }
    final file = await Navigator.push<File>(
      context,
      MaterialPageRoute(builder: (_) => const SelfieCaptureView()),
    );
    if (file == null || !mounted) return;

    final validationError = PhotoService.validateImage(file);
    if (validationError != null) {
      showActionToast(context, validationError, isError: true);
      return;
    }
    setState(() => _selfieFile = file);
    await _verifySelfie(file);
  }

  Future<void> _verifySelfie(File file) async {
    setState(() {
      _isWorking = true;
      _errorMessage = null;
    });

    final result = await PhotoService.verifyWithSelfie(file);
    if (!mounted) return;

    if (result.verified) {
      setState(() {
        _isWorking = false;
        _allVerified = true;
        _mismatchedPhotoIds = [];
        _lastVerifyMessage = null;
      });
      showActionToast(context, result.message);
      return;
    }

    setState(() {
      _isWorking = false;
      _allVerified = false;
      _mismatchedPhotoIds = result.mismatchedPhotoIds;
      _lastVerifyMessage = result.message;
    });
    showActionToast(context, result.message, isError: true);
  }

  Future<void> _finish() async {
    setState(() => _isWorking = true);
    await _persistOrderAndMain();
    if (!mounted) return;
    Provider.of<OnboardingProvider>(context, listen: false).markFlowComplete();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  void _openManualReview() {
    final badIds = _photos
        .where((p) => p.serverId != null && _mismatchedPhotoIds.contains(p.serverId))
        .map((p) => p.serverId ?? p.id)
        .toList();
    final ids = badIds.isNotEmpty
        ? badIds
        : _photos.map((p) => p.serverId ?? p.id).toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateTicketScreen(
          initialSubject: 'Photo verification',
          initialMessage:
              'My photos could not be verified with my selfie. Please review them manually.\nPhoto IDs: ${ids.join(', ')}',
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // UI
  // ------------------------------------------------------------------
  String get _ctaLabel {
    if (_allVerified) return 'Finish';
    if (!_canTakeSelfie) {
      if (_photos.any((p) => p.isRejected)) return 'Fix rejected photos';
      return 'Add ${minPhotos - _acceptedCount} more';
    }
    return _selfieFile != null ? 'Retake selfie' : 'Take selfie';
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
                  fontFamily: AppTheme.fontFor(
                    !Localizations.localeOf(
                      context,
                    ).languageCode.contains('en'),
                  ),
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
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add 3–9 photos so people can recognize you.',
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
                                    fontFamily: AppTheme.fontFor(
                                      !Localizations.localeOf(
                                        context,
                                      ).languageCode.contains('en'),
                                    ),
                                    fontSize: 12,
                                    color: errorColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_errorMessage != null) const SizedBox(height: 10),

                      _buildPhotoGrid(primaryColor, borderColor),

                      // Tips
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.drag_handle,
                                  size: 14,
                                  color: textMutedColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Tap a photo to change it',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFor(
                                      !Localizations.localeOf(
                                        context,
                                      ).languageCode.contains('en'),
                                    ),
                                    fontSize: 11,
                                    color: textMutedColor,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Drag to reorder',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFor(
                                  !Localizations.localeOf(
                                    context,
                                  ).languageCode.contains('en'),
                                ),
                                fontSize: 11,
                                color: textMutedColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      const SizedBox(height: 16),

                      _buildSelfieSection(
                        primaryColor: primaryColor,
                        borderColor: borderColor,
                        errorColor: errorColor,
                        onSurfaceColor: onSurfaceColor,
                        textMutedColor: textMutedColor,
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom CTA
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
                    enabled: _allVerified
                        ? !_isWorking
                        : _canTakeSelfie && !_isWorking,
                    onPressed: _isWorking
                        ? null
                        : (_allVerified ? _finish : _takeSelfie),
                    child: _isWorking
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _ctaLabel,
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

  Widget _buildSelfieSection({
    required Color primaryColor,
    required Color borderColor,
    required Color errorColor,
    required Color onSurfaceColor,
    required Color textMutedColor,
  }) {
    final hasMismatch = _mismatchedPhotoIds.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Verify it\'s you',
          style: AppTheme.headlineSmall.copyWith(
            color: onSurfaceColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Take a selfie so we can confirm your photos are really you.',
          style: AppTheme.bodyMedium.copyWith(color: textMutedColor),
        ),
        const SizedBox(height: 12),

        if (_allVerified)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  'All photos verified — you\'re all set.',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        else if (_lastVerifyMessage != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: errorColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: errorColor.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _lastVerifyMessage!,
                  style: TextStyle(color: errorColor, fontSize: 13),
                ),
                if (hasMismatch) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Tap the photos that didn\'t match to replace them, then retake your selfie.',
                    style: TextStyle(color: errorColor, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isWorking ? null : _openManualReview,
                    child: const Text('Manual review'),
                  ),
                ),
              ],
            ),
          )
        else if (_selfieFile != null) ...[
          Center(
            child: GestureDetector(
              onTap: _isWorking ? null : _takeSelfie,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  _selfieFile!,
                  width: 130,
                  height: 170,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Tap the photo to retake',
              style: TextStyle(
                color: textMutedColor,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPhotoGrid(Color primaryColor, Color borderColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double gap = 10.0;
        final double slotW = (width - gap * 2) / 3;
        final double slotH = slotW * 1.1;

        return SizedBox(
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
                            hasPhoto: (row * 3 + col) < _photos.length,
                            photo: (row * 3 + col) < _photos.length
                                ? _photos[row * 3 + col]
                                : null,
                            isMain:
                                (row * 3 + col) == 0 &&
                                _photos.isNotEmpty &&
                                _photos[0].isMain,
                            primaryColor: primaryColor,
                            borderColor: borderColor,
                            totalCount: _photos.length,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
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
    required int totalCount,
  }) {
    if (!hasPhoto) {
      if (_photos.length >= maxPhotos) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
        );
      }
      return GestureDetector(
        onTap: () => _showImagePicker(),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: const Center(
            child: Icon(Icons.add, size: 28, color: Colors.grey),
          ),
        ),
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
          onDragStarted: () => setState(() {}),
          onDragEnd: (_) => setState(() {}),
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
            ),
          ),
          child: _buildPhotoSlot(
            index: index,
            hasPhoto: hasPhoto,
            photo: photo,
            isMain: isMain,
            primaryColor: primaryColor,
            borderColor: borderColor,
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
  }) {
    final Widget? statusBadge = _buildStatusBadge(photo);

    return GestureDetector(
      onTap: hasPhoto ? () => _showImagePicker(replaceIndex: index) : null,
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
              if (hasPhoto && photo != null)
                Image.file(
                  photo.file,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.broken_image),
                  ),
                )
              else
                Center(
                  child: Icon(
                    Icons.add,
                    size: 28,
                    color: Colors.grey.shade400,
                  ),
                ),

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
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.white, size: 12),
                        SizedBox(width: 3),
                        Text(
                          'Main',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (hasPhoto && statusBadge != null)
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: statusBadge,
                ),

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
                    child: const Icon(
                      Icons.drag_handle,
                      color: Colors.white70,
                      size: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildStatusBadge(PhotoUpload? photo) {
    if (photo == null) return null;
    final Color bg;
    final IconData icon;
    final String label;

    if (photo.isRejected) {
      bg = AppTheme.lightError;
      icon = Icons.block;
      label = 'Rejected';
    } else if (_allVerified) {
      bg = Colors.green.shade700;
      icon = Icons.check_circle;
      label = 'Verified';
    } else if (photo.serverId != null &&
        _mismatchedPhotoIds.contains(photo.serverId)) {
      bg = Colors.orange.shade700;
      icon = Icons.error_outline;
      label = 'Didn\'t match';
    } else {
      return null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImagePicker({int? replaceIndex}) {
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
                  _pickAndUpload(
                    replaceIndex: replaceIndex,
                    source: ImageSource.gallery,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUpload(
                    replaceIndex: replaceIndex,
                    source: ImageSource.camera,
                  );
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
