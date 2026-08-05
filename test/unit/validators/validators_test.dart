import 'package:flutter_test/flutter_test.dart';
import 'package:dating_app/utils/validators.dart';

void main() {
  group('validateEmail', () {
    test('accepts well-formed emails', () {
      expect(Validators.validateEmail('a@b.co'), isNull);
      expect(Validators.validateEmail('name@domain.com'), isNull);
      expect(Validators.validateEmail('x@y.io'), isNull);
      expect(Validators.validateEmail('first.last@sub.domain.org'), isNull);
    });

    test('rejects empty', () {
      expect(Validators.validateEmail(null), isNotNull);
      expect(Validators.validateEmail(''), isNotNull);
    });

    test('rejects malformed emails', () {
      expect(Validators.validateEmail('a@'), isNotNull);
      expect(Validators.validateEmail('a@b'), isNotNull);
      expect(Validators.validateEmail('no-at-sign'), isNotNull);
      expect(Validators.validateEmail('has space@x.com'), isNotNull);
    });
  });

  group('validatePassword', () {
    test('rejects empty', () {
      expect(Validators.validatePassword(null), isNotNull);
      expect(Validators.validatePassword(''), isNotNull);
    });

    test('rejects passwords shorter than 8', () {
      expect(Validators.validatePassword('1234567'), isNotNull);
    });

    test('accepts 8 or more characters at the boundary', () {
      expect(Validators.validatePassword('12345678'), isNull);
      expect(Validators.validatePassword('1234567890abcdef'), isNull);
    });
  });

  group('validateName', () {
    test('rejects empty', () {
      expect(Validators.validateName(null), isNotNull);
      expect(Validators.validateName(''), isNotNull);
    });

    test('rejects a single character', () {
      expect(Validators.validateName('A'), isNotNull);
    });

    test('accepts 2 or more characters at the boundary', () {
      expect(Validators.validateName('Al'), isNull);
      expect(Validators.validateName('Ali'), isNull);
    });
  });

  group('validateAge', () {
    test('rejects empty', () {
      expect(Validators.validateAge(null), isNotNull);
      expect(Validators.validateAge(''), isNotNull);
    });

    test('rejects non-numeric input', () {
      expect(Validators.validateAge('abc'), isNotNull);
    });

    test('rejects out-of-range bounds', () {
      expect(Validators.validateAge('17'), isNotNull);
      expect(Validators.validateAge('101'), isNotNull);
    });

    test('accepts inclusive bounds', () {
      expect(Validators.validateAge('18'), isNull);
      expect(Validators.validateAge('100'), isNull);
      expect(Validators.validateAge('30'), isNull);
    });
  });
}