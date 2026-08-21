// lib/utils/face_geometry.dart
import 'dart:math' as math;
import 'dart:ui';

/// Result of checking whether a detected face fills a centered circle.
class FaceCheckResult {
  final bool centered;
  final bool fills;
  final double fillRatio;

  const FaceCheckResult({
    required this.centered,
    required this.fills,
    required this.fillRatio,
  });

  bool get ok => centered && fills;
}

/// Checks that a single detected face (its bounding box in image pixel
/// coordinates) is centered on, and fills, the capture circle.
///
/// The circle is centered in the image; its radius is
/// [circleRadiusFraction] * min([imageWidth], [imageHeight]).
///
/// - [centerTolerance]: max distance (as a fraction of the circle radius) the
///   face center may be from the circle center.
/// - [minFillRatio]: the face's smaller dimension must be at least this
///   fraction of the circle diameter (2 * radius) to "fill" it. Default 0.65
///   comfortably exceeds the backend's MIN_FACE_RATIO (0.15 of the image
///   dimension) so accepted selfies pass the server check too.
FaceCheckResult checkFaceInCircle({
  required Rect face,
  required double imageWidth,
  required double imageHeight,
  double circleRadiusFraction = 0.35,
  double centerTolerance = 0.35,
  double minFillRatio = 0.65,
}) {
  final s = math.min(imageWidth, imageHeight);
  final circleR = circleRadiusFraction * s;
  final circleD = circleR * 2;

  final faceCx = face.left + face.width / 2;
  final faceCy = face.top + face.height / 2;
  final cx = imageWidth / 2;
  final cy = imageHeight / 2;

  final dist = math.sqrt(math.pow(faceCx - cx, 2) + math.pow(faceCy - cy, 2));

  final faceSize = math.min(face.width, face.height);
  final fillRatio = circleD <= 0 ? 0.0 : (faceSize / circleD).clamp(0.0, 1.0);

  final centered = dist <= centerTolerance * circleR;
  final fills = faceSize >= minFillRatio * circleD;

  return FaceCheckResult(
    centered: centered,
    fills: fills,
    fillRatio: fillRatio,
  );
}
