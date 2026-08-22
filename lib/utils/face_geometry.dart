// lib/utils/face_geometry.dart
import 'dart:math' as math;
import 'dart:ui';

/// Face guide ellipse proportions (fractions of min(image width, image height)).
///
/// The guide is a face-shaped oval: taller than it is wide. These constants are
/// shared between the capture-screen painter and the validation logic so the
/// on-screen guide always matches what is actually accepted.
const double kFaceEllipseWidthFraction = 0.50;
const double kFaceEllipseHeightFraction = 0.80;

/// Result of checking whether a detected face fills a centered ellipse.
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
/// coordinates) is centered on, and fills, the capture ellipse.
///
/// The ellipse is centered in the image; its semi-axes are
/// [ellipseWidthFraction] / [ellipseHeightFraction] * min([imageWidth],
/// [imageHeight]).
///
/// - [centerTolerance]: max normalized distance (in units of the ellipse
///   semi-axes) the face center may be from the ellipse center.
/// - [minFillRatio]: the face's smaller dimension must be at least this
///   fraction of the ellipse's smaller diameter (2 * min(rx, ry)) to "fill"
///   it. Using the smaller axis keeps the check achievable even when the
///   guide is a tall face oval; the lenient default means the user doesn't
///   have to literally fill the whole oval. Default 0.28 still comfortably
///   exceeds the backend's MIN_FACE_RATIO (0.15 of the image dimension) so
///   accepted selfies pass the server check too.
FaceCheckResult checkFaceInEllipse({
  required Rect face,
  required double imageWidth,
  required double imageHeight,
  double ellipseWidthFraction = kFaceEllipseWidthFraction,
  double ellipseHeightFraction = kFaceEllipseHeightFraction,
  double centerTolerance = 0.5,
  double minFillRatio = 0.28,
}) {
  final s = math.min(imageWidth, imageHeight);
  final rx = ellipseWidthFraction * s;
  final ry = ellipseHeightFraction * s;
  final referenceD = 2 * math.min(rx, ry);

  final faceCx = face.left + face.width / 2;
  final faceCy = face.top + face.height / 2;
  final cx = imageWidth / 2;
  final cy = imageHeight / 2;

  final dx = (faceCx - cx) / rx;
  final dy = (faceCy - cy) / ry;
  final dist = math.sqrt(dx * dx + dy * dy);

  final faceSize = math.min(face.width, face.height);
  final fillRatio =
      referenceD <= 0 ? 0.0 : (faceSize / referenceD).clamp(0.0, 1.0);

  final centered = dist <= centerTolerance;
  final fills = faceSize >= minFillRatio * referenceD;

  return FaceCheckResult(
    centered: centered,
    fills: fills,
    fillRatio: fillRatio,
  );
}
