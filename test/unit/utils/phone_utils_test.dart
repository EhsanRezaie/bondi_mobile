import 'package:flutter_test/flutter_test.dart';
import 'package:dating_app/utils/phone_utils.dart';

void main() {
  group('PhoneUtils.sanitize', () {
    test('strips a single leading zero', () {
      expect(PhoneUtils.sanitize('09123456789'), '9123456789');
    });

    test('strips multiple leading zeros', () {
      expect(PhoneUtils.sanitize('0009123456789'), '9123456789');
    });

    test('removes non-digit characters (spaces, dashes, plus)', () {
      expect(PhoneUtils.sanitize('+98 912-345-6789'), '989123456789');
    });

    test('keeps a number without a leading zero unchanged', () {
      expect(PhoneUtils.sanitize('9123456789'), '9123456789');
    });

    test('returns empty for non-numeric input', () {
      expect(PhoneUtils.sanitize('abc'), '');
    });
  });

  group('PhoneUtils.toE164', () {
    test('drops the national trunk zero before the dial code', () {
      expect(
        PhoneUtils.toE164(dialCode: '+98', national: '09123456789'),
        '+989123456789',
      );
    });

    test('keeps a clean national number', () {
      expect(
        PhoneUtils.toE164(dialCode: '+98', national: '9123456789'),
        '+989123456789',
      );
    });
  });

  group('PhoneUtils.ruleFor', () {
    test('Iran requires 10 digits starting with 9', () {
      final rule = PhoneUtils.ruleFor('IR');
      expect(rule.isValid('9123456789'), isTrue);
      expect(rule.isValid('912345678'), isFalse); // too short
      expect(rule.isValid('8123456789'), isFalse); // wrong prefix
    });

    test('unknown country falls back to a generic 6-15 digit rule', () {
      final rule = PhoneUtils.ruleFor('ZZ');
      expect(rule.isValid('123456'), isTrue);
      expect(rule.isValid('12345'), isFalse);
      expect(rule.isValid('1234567890123456'), isFalse);
    });
  });

  group('PhoneNumberInputFormatter', () {
    test('strips a leading zero typed at the start', () {
      const formatter = PhoneNumberInputFormatter();
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '0'),
      );
      expect(result.text, '');
    });

    test('strips pasted leading zero and separators', () {
      const formatter = PhoneNumberInputFormatter();
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '0912 345 6789'),
      );
      expect(result.text, '9123456789');
      expect(result.selection.baseOffset, '9123456789'.length);
    });
  });

  group('PhoneUtils.displayExample', () {
    test('Iran example has no leading zero', () {
      final example = PhoneUtils.displayExample('IR');
      expect(example.startsWith('0'), isFalse);
      expect(example.replaceAll(' ', ''), '9123456789');
    });
  });
}
