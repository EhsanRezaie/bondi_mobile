// test/unit/utils/face_geometry_test.dart
import 'dart:ui';

import 'package:dating_app/utils/face_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const w = 1000.0;
  const h = 750.0;

  // Ellipse semi-axes = 0.50 * 750 = 375 (x), 0.80 * 750 = 600 (y).
  // Smaller diameter = 750; fills needs faceSize >= 0.28 * 750 = 210.
  Rect faceBox({required double size, required Offset center}) {
    return Rect.fromCenter(center: center, width: size, height: size);
  }

  test('centered face that fills the ellipse passes', () {
    final face = faceBox(size: 400, center: const Offset(500, 375));
    final r = checkFaceInEllipse(face: face, imageWidth: w, imageHeight: h);
    expect(r.ok, isTrue);
    expect(r.centered, isTrue);
    expect(r.fills, isTrue);
  });

  test('too-small face fails fill', () {
    final face = faceBox(size: 100, center: const Offset(500, 375));
    final r = checkFaceInEllipse(face: face, imageWidth: w, imageHeight: h);
    expect(r.centered, isTrue);
    expect(r.fills, isFalse);
    expect(r.ok, isFalse);
  });

  test('off-center face fails centering', () {
    final face = faceBox(size: 400, center: const Offset(800, 100));
    final r = checkFaceInEllipse(face: face, imageWidth: w, imageHeight: h);
    expect(r.centered, isFalse);
    expect(r.ok, isFalse);
  });

  test('face near center but slightly low passes', () {
    // dy = (455 - 375) / 600 ≈ 0.13 — within tolerance 0.5.
    final face = faceBox(size: 400, center: const Offset(500, 455));
    final r = checkFaceInEllipse(face: face, imageWidth: w, imageHeight: h);
    expect(r.centered, isTrue);
    expect(r.ok, isTrue);
  });

  test('face wide-offset horizontally still within tolerance passes', () {
    // dx = (580 - 500) / 375 ≈ 0.21 — within tolerance 0.5.
    final face = faceBox(size: 400, center: const Offset(580, 375));
    final r = checkFaceInEllipse(face: face, imageWidth: w, imageHeight: h);
    expect(r.centered, isTrue);
    expect(r.ok, isTrue);
  });
}
