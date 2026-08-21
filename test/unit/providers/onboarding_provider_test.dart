import 'package:flutter_test/flutter_test.dart';
import 'package:dating_app/providers/onboarding_provider.dart';

void main() {
  group('OnboardingProvider', () {
    late OnboardingProvider provider;

    setUp(() {
      provider = OnboardingProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    group('setPhone', () {
      test('sets phone and hasPhone is true', () {
        provider.setPhone('+989121112233');

        expect(provider.phone, '+989121112233');
        expect(provider.hasPhone, isTrue);
      });

      test('hasPhone is false when phone is empty', () {
        provider.setPhone('');

        expect(provider.hasPhone, isFalse);
      });
    });

    group('setPersonalInfo', () {
      test('sets all personal info fields', () {
        provider.setPersonalInfo(
          name: 'Test User',
          birthDate: '1990-01-01',
          gender: 'male',
          sexualOrientation: 'straight',
          bio: 'Hello world',
        );

        expect(provider.name, 'Test User');
        expect(provider.birthDate, '1990-01-01');
        expect(provider.gender, 'male');
        expect(provider.sexualOrientation, 'straight');
        expect(provider.bio, 'Hello world');
      });

      test('sets optional fields to null', () {
        provider.setPersonalInfo(
          name: 'Test',
          birthDate: '1990-01-01',
          gender: 'male',
        );

        expect(provider.sexualOrientation, isNull);
        expect(provider.bio, isNull);
      });
    });

    group('setPhysicalAndLifestyle', () {
      test('sets all physical and lifestyle fields', () {
        provider.setPhysicalAndLifestyle(
          height: 175,
          weight: 70,
          bodyType: 'Athletic',
          relationshipStatus: 'single',
          livingSituation: 'alone',
          childrenStatus: 'no',
          smoking: 'no',
          drinking: 'sometimes',
          education: "Bachelor's",
          workplace: 'Tech Corp',
          religion: 'None',
          ethnicity: 'Asian',
          politicalOrientation: 'Moderate',
          languages: ['English', 'Persian'],
        );

        expect(provider.height, 175);
        expect(provider.weight, 70);
        expect(provider.bodyType, 'Athletic');
        expect(provider.relationshipStatus, 'single');
        expect(provider.livingSituation, 'alone');
        expect(provider.childrenStatus, 'no');
        expect(provider.smoking, 'no');
        expect(provider.drinking, 'sometimes');
        expect(provider.education, "Bachelor's");
        expect(provider.workplace, 'Tech Corp');
        expect(provider.religion, 'None');
        expect(provider.ethnicity, 'Asian');
        expect(provider.politicalOrientation, 'Moderate');
        expect(provider.languages, ['English', 'Persian']);
      });

      test('sets all fields to null when not provided', () {
        provider.setPhysicalAndLifestyle();

        expect(provider.height, isNull);
        expect(provider.weight, isNull);
        expect(provider.bodyType, isNull);
        expect(provider.languages, isNull);
      });
    });

    group('setLocation', () {
      test('sets location fields', () {
        provider.setLocation(
          lat: 35.6895,
          lng: 51.3890,
          country: 'Iran',
          province: 'Tehran',
          city: 'Tehran',
        );

        expect(provider.lat, 35.6895);
        expect(provider.lng, 51.3890);
        expect(provider.country, 'Iran');
        expect(provider.province, 'Tehran');
        expect(provider.city, 'Tehran');
      });
    });

    group('Interests', () {
      test('setInterests replaces existing interests', () {
        provider.setInterests(['Hiking', 'Coffee']);
        expect(provider.interests, ['Hiking', 'Coffee']);

        provider.setInterests(['Gaming']);
        expect(provider.interests, ['Gaming']);
      });

      test('addInterest adds a new interest', () {
        provider.setInterests(['Hiking']);
        provider.addInterest('Coffee');

        expect(provider.interests, ['Hiking', 'Coffee']);
      });

      test('addInterest does not add duplicate', () {
        provider.setInterests(['Hiking']);
        provider.addInterest('Hiking');

        expect(provider.interests, ['Hiking']);
      });

      test('removeInterest removes an interest', () {
        provider.setInterests(['Hiking', 'Coffee']);
        provider.removeInterest('Coffee');

        expect(provider.interests, ['Hiking']);
      });

      test('removeInterest does nothing if interest not present', () {
        provider.setInterests(['Hiking']);
        provider.removeInterest('Coffee');

        expect(provider.interests, ['Hiking']);
      });
    });

    group('Prompts', () {
      test('setPrompts replaces existing prompts', () {
        final prompts = [{'question': 'Q1', 'answer': 'A1'}];
        provider.setPrompts(prompts);
        expect(provider.prompts, prompts);
      });
    });

    group('Photos', () {
      test('setPhotos replaces existing photos', () {
        provider.setPhotos(['photo1.jpg', 'photo2.jpg']);
        expect(provider.photos, ['photo1.jpg', 'photo2.jpg']);

        provider.setPhotos(['photo3.jpg']);
        expect(provider.photos, ['photo3.jpg']);
      });

      test('addPhoto adds a new photo', () {
        provider.setPhotos(['photo1.jpg']);
        provider.addPhoto('photo2.jpg');

        expect(provider.photos, ['photo1.jpg', 'photo2.jpg']);
      });

      test('removePhoto removes a photo', () {
        provider.setPhotos(['photo1.jpg', 'photo2.jpg']);
        provider.removePhoto('photo1.jpg');

        expect(provider.photos, ['photo2.jpg']);
      });
    });

    group('isComplete', () {
      test('returns false when no phone set', () {
        expect(provider.isComplete, isFalse);
      });

      test('returns false when phone set but no name', () {
        provider.setPhone('+989121112233');
        expect(provider.isComplete, isFalse);
      });
    });

    group('clear', () {
      test('resets all fields', () {
        provider.setPhone('+989121112233');
        provider.setPersonalInfo(
          name: 'Test',
          birthDate: '1990-01-01',
          gender: 'male',
        );
        provider.setInterests(['Hiking']);

        provider.clear();

        expect(provider.phone, isNull);
        expect(provider.name, isNull);
        expect(provider.interests, isNull);
      });
    });
  });
}