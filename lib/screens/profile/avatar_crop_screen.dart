// lib/screens/profile/avatar_crop_screen.dart
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:dating_app/models/photo.dart';
import 'package:dating_app/services/photo_service.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/generated/app_localizations.dart';
import 'package:dating_app/utils/responsive.dart';
import 'package:dating_app/widgets/action_toast.dart';

class AvatarCropScreen extends StatefulWidget {
  final PhotoResponse photo;
  final Function(PhotoResponse) onCropSaved;

  const AvatarCropScreen({
    super.key,
    required this.photo,
    required this.onCropSaved,
  });

  @override
  State<AvatarCropScreen> createState() => _AvatarCropScreenState();
}

class _AvatarCropScreenState extends State<AvatarCropScreen> {
  Offset _offset = Offset.zero;
  bool _isLoading = true;
  File? _imageFile;
  bool _isSaving = false;
  bool _isError = false;
  double _circleSize = 280.0;

  // Design baseline for the crop circle.
  static const double _designCircleSize = 280.0;

  @override
  void initState() {
    super.initState();
    _loadImage();

    if (widget.photo.crop != null) {
      _offset = Offset(
        widget.photo.crop!.x * _circleSize,
        widget.photo.crop!.y * _circleSize,
      );
    }
  }

  Future<void> _loadImage() async {
    try {
      final response = await http.get(Uri.parse(widget.photo.displayUrl));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/avatar_crop_temp.jpg');
        await file.writeAsBytes(response.bodyBytes);
        setState(() {
          _imageFile = file;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _isError = true;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isError = true;
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _offset += details.delta;
      // Pan bounds are proportional to the crop circle.
      final span = _circleSize / 2;
      _offset = Offset(
        _offset.dx.clamp(-span, span),
        _offset.dy.clamp(-span, span),
      );
    });
  }

  Future<void> _saveCrop() async {
    final t = AppLocalizations.of(context)!;
    if (_imageFile == null || _isSaving) return;

    setState(() => _isSaving = true);

    final cropData = CropData(
      x: _offset.dx / _circleSize,
      y: _offset.dy / _circleSize,
      size: 120.0,
    );

    try {
      final updatedPhoto = await PhotoService.updateCrop(
        photoId: widget.photo.id,
        crop: cropData,
      );

      if (updatedPhoto != null && mounted) {
        widget.onCropSaved(updatedPhoto);
        if (mounted) {
          Navigator.pop(context);
          showActionToast(context, t.photo_cropped_success);
        }
      } else if (mounted) {
        showActionToast(context, t.photo_crop_failed, isError: true);
      }
    } catch (e) {
      if (mounted) {
        showActionToast(
          context,
          t.photo_crop_error(e.toString()),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _resetCrop() {
    setState(() {
      _offset = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Adjust Profile Picture',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: onSurfaceColor,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: onSurfaceColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveCrop,
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.darkPrimary
                          : AppTheme.lightPrimary,
                    ),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
              ),
            )
          : _isError
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load image',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : GestureDetector(
              onPanUpdate: _onPanUpdate,
              behavior: HitTestBehavior.opaque,
              child: Container(
                color: bgColor,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Scale the crop circle with the available space so it
                    // is neither tiny on tablets nor overflowing phones.
                    final maxDim = math.min(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                    _circleSize = math.min(_designCircleSize, maxDim * 0.9);
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(child: Container(color: bgColor)),
                        // Subtle background pattern/dots
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: BackgroundPatternPainter(isDark: isDark),
                            ),
                          ),
                        ),
                        // Enforce central positioning across all aspect ratios
                        Center(
                          child: SizedBox(
                            width: _circleSize,
                            height: _circleSize,
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                Transform.translate(
                                  offset: _offset,
                                  child: Image.file(
                                    _imageFile!,
                                    fit: BoxFit.cover,
                                    width: _circleSize,
                                    height: _circleSize,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: CircleCropPainter(
                                circleSize: _circleSize,
                                isDark: isDark,
                              ),
                            ),
                          ),
                        ),
                        IgnorePointer(
                          child: Container(
                            width: _circleSize,
                            height: _circleSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: AppLayout.s(context, 40),
                          child: IgnorePointer(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppLayout.s(context, 20),
                                vertical: AppLayout.s(context, 10),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Drag anywhere to adjust',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: AppLayout.s(context, 14),
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: AppLayout.s(context, 20),
                          right: AppLayout.s(context, 20),
                          child: GestureDetector(
                            onTap: _resetCrop,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppLayout.s(context, 16),
                                vertical: AppLayout.s(context, 8),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Reset',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: Colors.white,
                                  fontSize: AppLayout.s(context, 13),
                                  fontWeight: FontWeight.w500,
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
}

class CircleCropPainter extends CustomPainter {
  final double circleSize;
  final bool isDark;

  CircleCropPainter({required this.circleSize, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? Colors.black.withValues(alpha: 0.7)
          : Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: center, radius: circleSize / 2))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class BackgroundPatternPainter extends CustomPainter {
  final bool isDark;

  BackgroundPatternPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.02)
          : Colors.black.withValues(alpha: 0.02)
      ..style = PaintingStyle.fill;

    const spacing = 30.0;
    const dotSize = 2.0;

    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotSize, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
