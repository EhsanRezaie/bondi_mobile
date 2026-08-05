import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:dating_app/models/photo.dart';
import '../../helpers/fixtures.dart';

void main() {
  group('PhotoResponse.fromJson', () {
    test('parses a response', () {
      final p = photoResponse();
      expect(p.id, 'ph1');
      expect(p.userId, 'user-a');
      expect(p.url, 'https://example.com/1.jpg');
      expect(p.order, 1);
      expect(p.isMain, isTrue);
      expect(p.status, 'approved');
      expect(p.faceVerified, isTrue);
      expect(p.crop, isNull);
    });

    test('parses crop data', () {
      final p = PhotoResponse.fromJson({
        'id': 'ph1',
        'user_id': 'user-a',
        'url': 'https://example.com/1.jpg',
        'order': 1,
        'is_main': true,
        'status': 'approved',
        'face_verified': false,
        'crop': {'x': 10.0, 'y': 20.0, 'size': 150.0},
      });
      expect(p.crop, isNotNull);
      expect(p.crop!.x, 10.0);
      expect(p.cropOffsetX, 10.0);
      expect(p.cropSize, 150.0);
    });

    test('defaults crop getters when crop null', () {
      expect(photoResponse().cropOffsetX, 0.0);
      expect(photoResponse().cropOffsetY, 0.0);
      expect(photoResponse().cropSize, 120.0);
    });
  });

  group('PhotoUpload', () {
    test('copyWith updates only provided fields', () {
      final f = PhotoUpload(id: 'a', file: File('x'));
      final updated = f.copyWith(isMain: true, isUploaded: true, url: 'u');
      expect(updated.isMain, isTrue);
      expect(updated.isUploaded, isTrue);
      expect(updated.url, 'u');
      expect(updated.id, 'a');
      expect(updated.serverId, isNull);
    });
  });

  group('PhotoUploadResponse.fromJson', () {
    test('parses and defaults message', () {
      final r = PhotoUploadResponse.fromJson({'id': 'x', 'url': 'u', 'status': 'pending'});
      expect(r.id, 'x');
      expect(r.url, 'u');
      expect(r.status, 'pending');
      expect(r.message, isNotEmpty);
    });
  });
}