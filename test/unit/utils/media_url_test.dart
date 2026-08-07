import 'package:flutter_test/flutter_test.dart';
import 'package:dating_app/utils/media_url.dart';

void main() {
  group('mediaUrlForDisplay', () {
    test('returns empty string for null/empty', () {
      expect(mediaUrlForDisplay(null), isEmpty);
      expect(mediaUrlForDisplay(''), isEmpty);
    });

    test('leaves non-Android URLs untouched', () {
      final url = 'https://cdn.example.com/img.jpg';
      expect(mediaUrlForDisplay(url, isAndroidOverride: true), url);
    });

    test('rewrites localhost host to 10.0.2.2 on Android', () {
      expect(
        mediaUrlForDisplay(
          'localhost:8000/media/1.jpg',
          isAndroidOverride: true,
        ),
        '10.0.2.2:8000/media/1.jpg',
      );
    });

    test('rewrites 127.0.0.1 host to 10.0.2.2 on Android', () {
      expect(
        mediaUrlForDisplay(
          '127.0.0.1:8000/media/1.jpg',
          isAndroidOverride: true,
        ),
        '10.0.2.2:8000/media/1.jpg',
      );
    });

    test('does not rewrite host on non-Android when override is false', () {
      final url = 'localhost:8000/media/1.jpg';
      expect(mediaUrlForDisplay(url, isAndroidOverride: false), url);
    });
  });
}