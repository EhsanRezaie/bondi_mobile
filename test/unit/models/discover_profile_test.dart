import 'package:flutter_test/flutter_test.dart';
import 'package:dating_app/models/discover_profile.dart';
import '../../helpers/fixtures.dart';

void main() {
  group('DiscoverProfile.fromJson', () {
    test('parses full profile', () {
      final p = DiscoverProfile.fromJson(jsonDiscoverProfile());
      expect(p.id, 'prof-1');
      expect(p.name, 'Sara');
      expect(p.age, 26);
      expect(p.gender, 'female');
      expect(p.bio, 'Coffee and mountains');
      expect(p.distanceKm, 12.4);
      expect(p.photos, ['https://example.com/1.jpg']);
      expect(p.interests, ['Hiking', 'Coffee']);
      expect(p.prompts.length, 1);
      expect(p.city, 'Tehran');
      expect(p.isOnline, isTrue);
    });

    test('parses missing distance as null', () {
      final p = DiscoverProfile.fromJson(jsonDiscoverProfile(distanceKm: null));
      expect(p.distanceKm, isNull);
    });

    test('defaults lists and flags when absent', () {
      final p = DiscoverProfile.fromJson({'id': 'x', 'name': 'N', 'age': 1, 'gender': 'm'});
      expect(p.photos, isEmpty);
      expect(p.interests, isEmpty);
      expect(p.prompts, isEmpty);
      expect(p.isPremium, isFalse);
      expect(p.isVerified, isFalse);
      expect(p.isOnline, isFalse);
    });
  });

  group('display getters', () {
    test('displayPhotoUrl falls back to empty', () {
      expect(DiscoverProfile.fromJson({'id': 'x', 'name': 'N', 'age': 1, 'gender': 'm'}).displayPhotoUrl, '');
    });

    test('locationDisplay combines city and province', () {
      expect(discoverProfile().locationDisplay, 'Tehran, Tehran');
    });

    test('locationDisplay returns city alone when no province', () {
      final p = DiscoverProfile.fromJson(jsonDiscoverProfile(province: null));
      expect(p.locationDisplay, 'Tehran');
    });
  });
}