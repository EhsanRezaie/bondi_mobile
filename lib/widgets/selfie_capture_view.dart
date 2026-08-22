// lib/widgets/selfie_capture_view.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  CameraDescription? _camera;
  FaceDetector? _detector;
  bool _ready = false;
  bool _initializing = true;
  bool _capturing = false;
  String? _permissionError;
  String? _status;
  bool _faceOk = false;

  final _lastDetect = <String, int>{};
  static const int _detectIntervalMs = 250;

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
      _camera = camera;

      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        // nv21 (Android) / bgra8888 (iOS) produce a single packed plane that
        // google_mlkit can consume directly — no manual YUV conversion needed.
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.android
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await controller.initialize();
      _detector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.fast,
          enableTracking: false,
          minFaceSize: 0.05,
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

  // Canonical ML Kit rotation: iOS uses sensor orientation directly; Android
  // compensates sensor orientation with the current device orientation.
  InputImageRotation get _rotation {
    final camera = _camera;
    final controller = _controller;
    if (camera == null) return InputImageRotation.rotation0deg;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _rotationFromDegrees(camera.sensorOrientation);
    }
    if (controller == null) return InputImageRotation.rotation0deg;

    const orientations = {
      DeviceOrientation.portraitUp: 0,
      DeviceOrientation.landscapeLeft: 90,
      DeviceOrientation.portraitDown: 180,
      DeviceOrientation.landscapeRight: 270,
    };
    var compensation = orientations[controller.value.deviceOrientation] ?? 0;
    if (camera.lensDirection == CameraLensDirection.front) {
      compensation = (camera.sensorOrientation + compensation) % 360;
    } else {
      compensation =
          (camera.sensorOrientation - compensation + 360) % 360;
    }
    return _rotationFromDegrees(compensation);
  }

  InputImageRotation _rotationFromDegrees(int degrees) {
    switch (degrees % 360) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  // ML Kit works in the upright (displayed) image space after applying
  // rotation, so for 90/270 rotations the width and height swap.
  ({double width, double height}) _uprightImageSize(
    double imageWidth,
    double imageHeight,
  ) {
    final rotation = _rotation;
    if (rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg) {
      return (width: imageHeight, height: imageWidth);
    }
    return (width: imageWidth, height: imageHeight);
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

    try {
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
        _setStatus(false, 'Move your face into the oval');
        return;
      }

      // ML Kit returns bounding boxes in the upright (portrait) coordinate
      // space after applying rotation, so the ellipse must use upright dims.
      final upright = _uprightImageSize(
        image.width.toDouble(),
        image.height.toDouble(),
      );
      final result = checkFaceInEllipse(
        face: face,
        imageWidth: upright.width,
        imageHeight: upright.height,
      );
      _setStatus(
        result.ok,
        result.ok ? 'Face detected — capture!' : 'Fill the oval',
      );
    } catch (e) {
      // Never let a bad frame take down the capture screen.
      debugPrint('❌ Camera frame error: $e');
    }
  }

  List<Face>? _facesCache;
  Future<List<Face>?> _safeDetect(InputImage input) async {    final detector = _detector;
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

      // The captured JPEG may be stored with EXIF orientation that differs
      // from the raw decoded dims — accept if the face fills the ellipse in
      // either orientation.
      final ok = checkFaceInEllipse(
            face: face,
            imageWidth: w,
            imageHeight: h,
          ).ok ||
          checkFaceInEllipse(
            face: face,
            imageWidth: h,
            imageHeight: w,
          ).ok;
      return ok;
    } catch (e) {
      debugPrint('❌ Validate captured error: $e');
      return false;
    }
  }

  // Build a contiguous, de-padded NV21 buffer for ML Kit regardless of the
  // plane layout the camera actually reports (nv21 single/two-plane, or
  // YUV_420_888 three-plane). Handles row padding so rows are never misread.
  Uint8List _toNv21(CameraImage image) {
    final w = image.width;
    final h = image.height;
    final ySize = w * h;
    final uvSize = ySize ~/ 2;
    final planes = image.planes;
    if (planes.isEmpty) return Uint8List(0);

    if (planes.length == 1) {
      final y = planes[0];
      if (y.bytes.length >= ySize + uvSize && y.bytesPerRow == w) {
        return y.bytes;
      }
      final data = Uint8List(ySize + uvSize);
      final uvCount = uvSize < data.length - ySize ? uvSize : 0;
      for (var i = 0; i < h; i++) {
        final src = i * y.bytesPerRow;
        final dst = i * w;
        if (src + w <= y.bytes.length) data.setRange(dst, dst + w, y.bytes, src);
      }
      for (var i = 0; i < uvCount; i++) {
        final src = ySize + i * y.bytesPerRow;
        final dst = ySize + i * w;
        if (src + w <= y.bytes.length) data.setRange(dst, dst + w, y.bytes, src);
      }
      return data;
    }

    if (planes.length == 2) {
      // NV21: Y plane + interleaved VU plane.
      final y = planes[0];
      final uv = planes[1];
      final data = Uint8List(ySize + uvSize);
      for (var i = 0; i < h; i++) {
        final src = i * y.bytesPerRow;
        final dst = i * w;
        if (src + w <= y.bytes.length) data.setRange(dst, dst + w, y.bytes, src);
      }
      final uvRows = h ~/ 2;
      for (var i = 0; i < uvRows; i++) {
        final src = i * uv.bytesPerRow;
        final dst = ySize + i * w;
        if (src + w <= uv.bytes.length) data.setRange(dst, dst + w, uv.bytes, src);
      }
      return data;
    }

    // YUV_420_888: separate Y, U, V planes -> interleave V,U as NV21.
    final y = planes[0];
    final u = planes[1];
    final v = planes[2];
    final data = Uint8List(ySize + uvSize);
    for (var i = 0; i < h; i++) {
      final src = i * y.bytesPerRow;
      final dst = i * w;
      if (src + w <= y.bytes.length) data.setRange(dst, dst + w, y.bytes, src);
    }
    final uStride = u.bytesPerRow;
    final vStride = v.bytesPerRow;
    final uPS = u.bytesPerPixel ?? 2;
    final vPS = v.bytesPerPixel ?? 2;
    final rows = (h + 1) ~/ 2;
    final samples = (w + 1) ~/ 2;
    var k = ySize;
    for (var i = 0; i < rows; i++) {
      for (var sample = 0; sample < samples; sample++) {
        final uIdx = i * uStride + sample * uPS;
        final vIdx = i * vStride + sample * vPS;
        if (uIdx >= u.bytes.length || vIdx >= v.bytes.length) break;
        if (k + 1 > data.length) break;
        data[k++] = v.bytes[vIdx];
        data[k++] = u.bytes[uIdx];
      }
    }
    return data;
  }

  // Canonical google_mlkit approach: convert the camera frame to a single
  // contiguous NV21 (Android) buffer, or pass the bgra8888 plane straight
  // through (iOS). No fragile YUV math in the hot path beyond _toNv21.
  InputImage? _inputImageFromCameraImage(
    CameraImage image,
    CameraController controller,
  ) {
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;

    Uint8List bytes;
    int bytesPerRow;
    if (isAndroid) {
      bytes = _toNv21(image);
      if (bytes.isEmpty) return null;
      bytesPerRow = image.width;
    } else {
      if (image.planes.isEmpty) return null;
      bytes = image.planes.first.bytes;
      bytesPerRow = image.planes.first.bytesPerRow;
    }

    final format =
        isAndroid ? InputImageFormat.nv21 : InputImageFormat.bgra8888;

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: _rotation,
        format: format,
        bytesPerRow: bytesPerRow,
      ),
    );
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
              final s = math.min(size.width, size.height);
              final w = kFaceEllipseWidthFraction * s;
              final h = kFaceEllipseHeightFraction * s;
              return CustomPaint(
                painter: _OvalGuidePainter(
                  ellipseWidth: w,
                  ellipseHeight: h,
                  ok: _faceOk,
                ),
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

class _OvalGuidePainter extends CustomPainter {
  final double ellipseWidth;
  final double ellipseHeight;
  final bool ok;

  _OvalGuidePainter({
    required this.ellipseWidth,
    required this.ellipseHeight,
    required this.ok,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final ovalRect = Rect.fromCenter(
      center: center,
      width: ellipseWidth,
      height: ellipseHeight,
    );

    // Dim everything outside the oval WITHOUT touching the camera pixels
    // below (BlendMode.clear would erase them, showing a black circle). Draw
    // a single scrim path that has an oval hole instead.
    final scrim = Paint()..color = Colors.black.withValues(alpha: 0.5);
    final full = Path()..addRect(Offset.zero & size);
    final hole = Path()..addOval(ovalRect);
    final scrimPath = Path.combine(PathOperation.difference, full, hole);
    canvas.drawPath(scrimPath, scrim);

    // Guide outline: red until a face fills the oval, green when ready.
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = ok ? Colors.greenAccent : Colors.redAccent;
    canvas.drawOval(ovalRect, outline);
  }

  @override
  bool shouldRepaint(_OvalGuidePainter oldDelegate) =>
      oldDelegate.ellipseWidth != ellipseWidth ||
      oldDelegate.ellipseHeight != ellipseHeight ||
      oldDelegate.ok != ok;
}
