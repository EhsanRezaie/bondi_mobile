import 'package:flutter_test/flutter_test.dart';
import 'package:dating_app/models/user.dart';
import '../../helpers/fixtures.dart';

void main() {
  group('User.fromJson', () {
    test('parses a basic user', () {
      final u = User.fromJson(jsonUser());
      expect(u.id, 'user-a');
      expect(u.email, 'a@example.com');
      expect(u.name, 'Ali');
      expect(u.age, 30);
      expect(u.createdAt, kNow);
    });

    test('parses nested settings', () {
      final u = User.fromJson(jsonUser(settings: {
        'hide_last_seen': true,
        'hide_online_status': true,
        'push_enabled': false,
        'dark_mode': true,
      }));
      expect(u.settings, isNotNull);
      expect(u.settings!.hideLastSeen, isTrue);
      expect(u.settings!.pushEnabled, isFalse);
      expect(u.settings!.darkMode, isTrue);
      // Top-level hides fall back to parsed settings
      expect(u.hideLastSeen, isTrue);
    });

    test('defaults settings to UserSettings defaults', () {
      final u = User.fromJson(jsonUser());
      expect(u.settings, isNull);
      expect(u.hideLastSeen, isFalse);
      expect(u.hideOnlineStatus, isFalse);
    });
  });

  group('UserSettings.fromJson', () {
    test('applies defaults', () {
      const s = UserSettings();
      expect(s.pushEnabled, isTrue);
      expect(s.language, 'fa');
      expect(s.darkMode, isFalse);
    });
  });

  group('getAgeFromBirthDate', () {
    test('returns null-age fallback when no birthDate', () {
      final u = User.fromJson(jsonUser(age: null));
      expect(u.age, isNull);
      expect(u.getAgeFromBirthDate(), isNull);
    });

    test('computes age from birthDate', () {
      final now = DateTime.now();
      final birth = DateTime(now.year - 30, now.month, now.day, 0)
          .toIso8601String();
      final u = User.fromJson(jsonUser()..['birth_date'] = birth);
      expect(u.getAgeFromBirthDate(), 30);
    });
  });

  group('User.toJson round-trip', () {
    test('preserves core fields', () {
      final original = User.fromJson(jsonUser());
      final round = User.fromJson(original.toJson());
      expect(round.id, original.id);
      expect(round.email, original.email);
      expect(round.createdAt, original.createdAt);
    });
  });
}