import 'package:flutter_test/flutter_test.dart';
import 'package:dating_app/utils/formatters.dart';
import '../../helpers/fixtures.dart';

void main() {
  group('formatDistanceKm', () {
    test('null → 500+ km', () {
      expect(formatDistanceKm(null), '500+ km');
    });

    test('>= 500 → 500+ km', () {
      expect(formatDistanceKm(500), '500+ km');
      expect(formatDistanceKm(750.2), '500+ km');
    });

    test('rounds to whole km below 500', () {
      expect(formatDistanceKm(12.4), '12 km');
      expect(formatDistanceKm(0.5), '1 km');
      expect(formatDistanceKm(499.0), '499 km');
    });
  });

  group('formatLastSeen', () {
    final now = kNow;

    test('under 1 minute → Just now', () {
      expect(formatLastSeen(now.subtract(const Duration(seconds: 30)), now: now), 'Just now');
      expect(formatLastSeen(now.subtract(const Duration(seconds: 59)), now: now), 'Just now');
    });

    test('under 60 minutes → Xm ago', () {
      expect(formatLastSeen(now.subtract(const Duration(minutes: 5)), now: now), '5m ago');
      expect(formatLastSeen(now.subtract(const Duration(minutes: 59)), now: now), '59m ago');
    });

    test('under 24 hours → Xh ago', () {
      expect(formatLastSeen(now.subtract(const Duration(hours: 2)), now: now), '2h ago');
      expect(formatLastSeen(now.subtract(const Duration(hours: 23)), now: now), '23h ago');
    });

    test('under 7 days → Xd ago', () {
      expect(formatLastSeen(now.subtract(const Duration(days: 3)), now: now), '3d ago');
      expect(formatLastSeen(now.subtract(const Duration(days: 6)), now: now), '6d ago');
    });

    test('7+ days → short date', () {
      final old = DateTime(2026, 7, 1, 12);
      expect(formatLastSeen(old, now: now), 'Jul 1');
    });
  });
}