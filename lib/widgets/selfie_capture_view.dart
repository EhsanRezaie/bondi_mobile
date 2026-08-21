// lib/widgets/selfie_capture_view.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/face_geometry.dart';

/// Full-screen front-camera selfie capture with a face-fill circle guide.
///
/// Returns the captured selfie [File] via `Navigator.pop(context, file)`, or
/// `null` if the user backs out.
class SelfieCaptureView extends StatefulWidget {
  const SelfieCaptureView({super.key});

  @override
  State<SelfieCaptureView> createState() => _SelfieCaptureViewState();
}

class _SelfieCaptureViewState extends State<SelfieCaptureView> {
  CameraController? _controller;
  FaceDetector? _detector;
  bool _ready = false;
  bool _initializing = true;
  bool _capturing = false;
  String? _permissionError;
  String? _status;
  bool _faceOk = false;

  final _lastDetect = <String, int>{};
  static const int _detectIntervalMs = 250;
  static const double _circleRadiusFraction = 0.35;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _stopImageStream();
    _controller?.dispose();
    _detector?.close();
    super.dispose();
  }

  void _stopImageStream() {
    if (_controller != null && _controller!.value.isStreamingImages) {
      try {
        _controller!.stopImageStream();
      } catch (_) {}
    }
  }

  Future<void> _init() async {
    if (!mounted) return;

    final permission = await Permission.camera.request();
    if (!permission.isGranted) {
      setState(() {
        _initializing = false;
        _permissionError =
            'Camera permission is required to verify your identity.';
      });
      return;
    }

    try {
      final cameras = await availableCameras();
      CameraDescription? front;
      for (final c in cameras) {
        if (c.lensDirection == CameraLensDirection.front) {
          front = c;
          break;
        }
      }
      final camera = front ?? (cameras.isNotEmpty ? cameras.first : null);
      if (camera == null) {
        setState(() {
          _initializing = false;
          _permissionError = 'No camera found on this device.';
        });
        return;
      }

      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      _detector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.fast,
          enableTracking: false,
          minFaceSize: 0.1,
        ),
      );

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _ready = true;
        _initializing = false;
      });

      _startImageStream();
    } catch (e) {
      debugPrint('❌ Camera init error: $e');
      if (mounted) {
        setState(() {
          _initializing = false;
          _permissionError = 'Could not start the camera. Please try again.';
        });
      }
    }
  }

  InputImageRotation get _rotation {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return InputImageRotation.rotation90deg;
    }
    return InputImageRotation.rotation0deg;
  }

  void _startImageStream() {
    final controller = _controller;
    if (controller == null) return;
    try {
      controller.startImageStream(_onCameraImage);
    } catch (e) {
      // Image stream unsupported — the authoritative check still runs on capture.
      debugPrint('❌ startImageStream failed: $e');
    }
  }

  Future<void> _onCameraImage(CameraImage image) async {
    final controller = _controller;
    if (controller == null || !mounted) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final last = _lastDetect['f'] ?? 0;
    if (now - last < _detectIntervalMs) return;
    _lastDetect['f'] = now;

    final input = _inputImageFromCameraImage(image, controller);
    if (input == null) return;

    final faces = await _safeDetect(input);
    if (!mounted || faces == null) return;

    final face = _pickFace(faces);
    if (face == null) {
      _setStatus(false, 'Move your face into the circle');
      return;
    }

    final result = checkFaceInCircle(
      face: face,
      imageWidth: image.width.toDouble(),
      imageHeight: image.height.toDouble(),
      circleRadiusFraction: _circleRadiusFraction,
    );
    _setStatus(
      result.ok,
      result.ok ? 'Face detected — capture!' : 'Fill the circle',
    );
  }

  List<Face>? _facesCache;
  Future<List<Face>?> _safeDetect(InputImage input) async {
    final detector = _detector;
    if (detector == null) return null;
    try {
      final faces = await detector.processImage(input);
      _facesCache = faces;
      return faces;
    } catch (e) {
      debugPrint('❌ Face detect error: $e');
      return _facesCache;
    }
  }

  Rect? _pickFace(List<Face> faces) {
    if (faces.isEmpty) return null;
    Face? largest;
    for (final f in faces) {
      if (largest == null ||
          (f.boundingBox.width * f.boundingBox.height) >
              (largest.boundingBox.width * largest.boundingBox.height)) {
        largest = f;
      }
    }
    final box = largest!.boundingBox;
    return Rect.fromLTRB(box.left, box.top, box.right, box.bottom);
  }

  void _setStatus(bool ok, String message) {
    if (!mounted) return;
    if (_faceOk != ok || _status != message) {
      setState(() {
        _faceOk = ok;
        _status = message;
      });
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _capturing) return;

    setState(() {
      _capturing = true;
      _status = 'Checking…';
    });

    try {
      final file = await controller.takePicture();
      final ok = await _validateCaptured(file);
      if (!mounted) return;
      if (ok) {
        _stopImageStream();
        Navigator.pop(context, File(file.path));
        return;
      }
      setState(() {
        _capturing = false;
        _status = 'Face didn\'t fill the circle — retake';
        _faceOk = false;
      });
    } catch (e) {
      debugPrint('❌ Capture error: $e');
      if (mounted) {
        setState(() {
          _capturing = false;
          _status = 'Capture failed — try again';
        });
      }
    }
  }

  Future<bool> _validateCaptured(XFile file) async {
    final detector = _detector;
    if (detector == null) return false;
    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final w = frame.image.width.toDouble();
      final h = frame.image.height.toDouble();

      final faces = await detector.processImage(
        InputImage.fromFilePath(file.path),
      );
      final face = _pickFace(faces);
      if (face == null) return false;

      return checkFaceInCircle(
        face: face,
        imageWidth: w,
        imageHeight: h,
        circleRadiusFraction: _circleRadiusFraction,
      ).ok;
    } catch (e) {
      debugPrint('❌ Validate captured error: $e');
      return false;
    }
  }

  InputImage? _inputImageFromCameraImage(
    CameraImage image,
    CameraController controller,
  ) {
    final bytes = _concatenatePlanes(image.planes, image.width, image.height);
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: _rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  // Standard NV21 conversion for camera YUV420 frames (used by ML Kit samples).
  Uint8List _concatenatePlanes(List<Plane> planes, int width, int height) {
    final yRowStride = planes[0].bytesPerRow;
    final yRowSize = width;
    final ySize = yRowSize * height;
    final uvRowStride = planes[1].bytesPerRow;
    final uvPixelStride = planes[1].bytesPerPixel ?? 2;
    final uvRowSize = (uvRowStride / uvPixelStride).round();
    final uvSize = uvRowSize * ((height + 1) / 2).round();

    final data = Uint8List(ySize + uvSize * 2);

    for (var i = 0; i < height; i++) {
      data.setRange(
        i * yRowSize,
        i * yRowSize + yRowSize,
        planes[0].bytes,
        i * yRowStride,
      );
    }

    for (var i = 0; i < ((height + 1) / 2).ceil(); i++) {
      final dstOffset = ySize + i * uvRowSize * 2;
      for (var j = 0; j < uvRowSize; j++) {
        final srcOffset = i * uvRowStride + j * uvPixelStride;
        data[dstOffset + j * 2] = planes[2].bytes[srcOffset]; // V
        data[dstOffset + j * 2 + 1] = planes[1].bytes[srcOffset]; // U
      }
    }

    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_initializing) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_permissionError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography, color: Colors.white, size: 48),
              const SizedBox(height: 16),
              Text(
                _permissionError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _controller;
    if (!_ready || controller == null || !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(child: CameraPreview(controller)),
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              final r =
                  math.min(size.width, size.height) * _circleRadiusFraction;
              return CustomPaint(
                painter: _CircleGuidePainter(circleRadius: r, ok: _faceOk),
                child: const SizedBox.expand(),
              );
            },
          ),
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _status ?? 'Center your face in the circle',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _faceOk ? Colors.greenAccent : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Positioned(
          top: 16,
          left: 8,
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
          ),
        ),
        Positioned(
          bottom: 40,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _capturing || !_faceOk ? null : _capture,
                iconSize: 76,
                color: _faceOk ? Colors.white : Colors.white38,
                icon: const Icon(Icons.circle),
                disabledColor: Colors.white38,
              ),
              const SizedBox(height: 8),
              Text(
                _capturing ? 'Checking…' : 'Capture',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CircleGuidePainter extends CustomPainter {
  final double circleRadius;
  final bool ok;

  _CircleGuidePainter({required this.circleRadius, required this.ok});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Dim everything outside the circle.
    final scrim = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..blendMode = BlendMode.srcOver;
    canvas.drawRect(Offset.zero & size, scrim);

    // Clear the circle so the preview shows through.
    final clear = Paint()..blendMode = BlendMode.clear;
    canvas.drawCircle(center, circleRadius, clear);

    // Guide outline.
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = ok ? Colors.greenAccent : Colors.white;
    canvas.drawCircle(center, circleRadius, outline);
  }

  @override
  bool shouldRepaint(_CircleGuidePainter oldDelegate) =>
      oldDelegate.circleRadius != circleRadius || oldDelegate.ok != ok;
}
