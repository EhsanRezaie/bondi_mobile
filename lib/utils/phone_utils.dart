// lib/utils/phone_utils.dart
import 'package:flutter/services.dart';

/// Per-country rules for the national part of a phone number (the digits typed
/// after the dial code). The dial code already carries the country prefix, so a
/// national trunk `0` must never be part of the value.
class PhoneRule {
  final int minLength;
  final int maxLength;
  final String? requiredPrefix;

  const PhoneRule({
    required this.minLength,
    required this.maxLength,
    this.requiredPrefix,
  });

  bool isValid(String national) {
    if (national.length < minLength || national.length > maxLength) return false;
    if (requiredPrefix != null && !national.startsWith(requiredPrefix!)) {
      return false;
    }
    return true;
  }
}

class PhoneUtils {
  PhoneUtils._();

  // Iran: 10 digits after +98, mobile numbers start with 9 (e.g. 9123456789).
  static const Map<String, PhoneRule> _rules = {
    'IR': PhoneRule(minLength: 10, maxLength: 10, requiredPrefix: '9'),
  };

  static const PhoneRule _fallback =
      PhoneRule(minLength: 6, maxLength: 15);

  static PhoneRule ruleFor(String isoCode) =>
      _rules[isoCode.toUpperCase()] ?? _fallback;

  /// Digits only, with any leading zeros removed. Safe to run on every
  /// keystroke and on pasted text.
  static String sanitize(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.replaceFirst(RegExp(r'^0+'), '');
  }

  /// Builds the E.164 value sent to the backend (dial code + clean national).
  static String toE164({required String dialCode, required String national}) {
    return '$dialCode${sanitize(national)}';
  }

  /// Formats a national number for display, e.g. 9123456789 -> 912 345 6789.
  static String displayExample(String isoCode) {
    switch (isoCode.toUpperCase()) {
      case 'IR':
        return '912 345 6789';
      default:
        return '123 456 7890';
    }
  }
}

/// Strips non-digits and any leading zeros as the user types or pastes.
class PhoneNumberInputFormatter extends TextInputFormatter {
  const PhoneNumberInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = PhoneUtils.sanitize(newValue.text);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
