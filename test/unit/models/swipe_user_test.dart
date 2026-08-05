import 'package:flutter_test/flutter_test.dart';
import 'package:dating_app/models/swipe_user.dart';
import '../../helpers/fixtures.dart';

void main() {
  group('SwipeUser.fromJson', () {
    test('parses full user', () {
      final u = SwipeUser.fromJson(jsonSwipeUser());
      expect(u.id, 'user-1');
      expect(u.name, 'Sara');
      expect(u.age, 26);
      expect(u.mainPhotoUrl, 'https://example.com/1.jpg');
      expect(u.isPremium, isFalse);
      expect(u.isVerified, isTrue);
      expect(u.isOnline, isTrue);
      expect(u.distanceKm, 12.4);
    });

    test('parses nullable fields', () {
      final u = SwipeUser.fromJson(jsonSwipeUser(isOnline: null, lastSeenAt: null, distanceKm: null));
      expect(u.isOnline, isNull);
      expect(u.lastSeenAt, isNull);
      expect(u.distanceKm, isNull);
    });

    test('parses swiped_at', () {
      final u = SwipeUser.fromJson(jsonSwipeUser(swipedAt: kNowIso));
      expect(u.swipedAt, kNow);
    });

    test('defaults age and flags', () {
      final u = SwipeUser.fromJson({'id': 'x'});
      expect(u.age, 0);
      expect(u.isPremium, isFalse);
      expect(u.isVerified, isFalse);
    });
  });

  group('SwipeUser.toJson round-trip', () {
    test('preserves fields', () {
      final original = SwipeUser.fromJson(jsonSwipeUser());
      final round = SwipeUser.fromJson(original.toJson());
      expect(round.id, original.id);
      expect(round.name, original.name);
      expect(round.age, original.age);
      expect(round.isOnline, original.isOnline);
      expect(round.distanceKm, original.distanceKm);
    });
  });
}