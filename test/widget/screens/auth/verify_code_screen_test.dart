import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/screens/auth/verify_code_screen.dart';
import 'package:dating_app/providers/auth_provider.dart';
import "package:dating_app/providers/language_provider.dart";
import '../../../helpers/test_helpers.dart';

class FakeOnboardingProvider extends ChangeNotifier {
  String _phone = '';
  String get phone => _phone;
  void setPhone(String phone) {
    _phone = phone;
    notifyListeners();
  }
}

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('VerifyCodeScreen', () {
    testWidgets('auto-advances focus to next field on digit entry', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestable(
          const VerifyCodeScreen(phone: '+989121112233'),
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => FakeOnboardingProvider()),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ],
        ),
      );

      final firstField = find.byType(TextFormField).first;
      expect(FocusScope.of(tester.element(firstField)).hasFocus, isTrue);

      await tester.enterText(firstField, '1');
      await tester.pump();

      final secondField = find.byType(TextFormField).at(1);
      expect(FocusScope.of(tester.element(secondField)).hasFocus, isTrue);
    });

    testWidgets('backspace on empty field returns focus to previous', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestable(
          const VerifyCodeScreen(phone: '+989121112233'),
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => FakeOnboardingProvider()),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ],
        ),
      );

      await tester.enterText(find.byType(TextFormField).first, '1');
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).at(1), '');
      await tester.pump();

      final firstField = find.byType(TextFormField).first;
      expect(FocusScope.of(tester.element(firstField)).hasFocus, isTrue);
    });

    testWidgets('entering 6 digits one at a time fills all boxes', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestable(
          const VerifyCodeScreen(phone: '+989121112233'),
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => FakeOnboardingProvider()),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ],
        ),
      );

      for (int i = 0; i < 6; i++) {
        await tester.enterText(find.byType(TextFormField).at(i), '1');
        await tester.pump();
      }

      for (int i = 0; i < 6; i++) {
        final field = find.byType(TextFormField).at(i);
        expect(
          tester.widget<TextFormField>(field).controller?.text,
          isNotEmpty,
        );
      }
    });

    testWidgets('shows error for incomplete 6-digit code', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const VerifyCodeScreen(phone: '+989121112233'),
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => FakeOnboardingProvider()),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ],
        ),
      );

      await tester.enterText(find.byType(TextFormField).first, '123');
      await tester.pump();

      await tester.tap(find.text('Verify'));
      await tester.pump();

      expect(find.text('Please enter the 6-digit code'), findsOneWidget);
    });

    testWidgets('resend button is disabled while timer is running', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestable(
          const VerifyCodeScreen(phone: '+989121112233'),
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => FakeOnboardingProvider()),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ],
        ),
      );

      final resendButton = find.byWidgetPredicate(
        (widget) =>
            widget is OutlinedButton &&
            widget.child is Text &&
            (widget.child as Text).data!.contains('Resend Code'),
      );
      expect(tester.widget<OutlinedButton>(resendButton).onPressed, isNull);
    });
  });
}
