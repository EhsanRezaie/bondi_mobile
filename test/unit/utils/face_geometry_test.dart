// test/unit/utils/face_geometry_test.dart
import 'dart:ui';

import 'package:dating_app/utils/face_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const w = 1000.0;
  const h = 750.0;

  // circle radius = 0.35 * min(1000,750) = 262.5
  Rect faceBox({required double size, required Offset center}) {
    return Rect.fromCenter(center: center, width: size, height: size);
  }

  test('centered face that fills the circle passes', () {
    final face = faceBox(size: 360, center: const Offset(500, 375));
    final r = checkFaceInCircle(face: face, imageWidth: w, imageHeight: h);
    expect(r.ok, isTrue);
    expect(r.centered, isTrue);
    expect(r.fills, isTrue);
  });

  test('too-small face fails fill', () {
    final face = faceBox(size: 120, center: const Offset(500, 375));
    final r = checkFaceInCircle(face: face, imageWidth: w, imageHeight: h);
    expect(r.centered, isTrue);
    expect(r.fills, isFalse);
    expect(r.ok, isFalse);
  });

  test('off-center face fails centering', () {
    final face = faceBox(size: 360, center: const Offset(800, 100));
    final r = checkFaceInCircle(face: face, imageWidth: w, imageHeight: h);
    expect(r.centered, isFalse);
    expect(r.ok, isFalse);
  });

  test('face at bottom of circle but still near center passes', () {
    // center offset ~ (0, 80) — within tolerance (0.35 * 262.5 ≈ 91.9)
    final face = faceBox(size: 360, center: const Offset(500, 455));
    final r = checkFaceInCircle(face: face, imageWidth: w, imageHeight: h);
    expect(r.centered, isTrue);
    expect(r.ok, isTrue);
  });
}
