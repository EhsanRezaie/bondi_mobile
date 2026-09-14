import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinput/pinput.dart';
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

/// Captures the code handed to [AuthProvider.verifyCode] so we can assert the
/// full pasted/typed code reached verification.
class RecordingAuthProvider extends AuthProvider {
  String? lastCode;

  @override
  Future<bool> verifyCode({
    required String code,
    String? referralCode,
    required BuildContext context,
  }) async {
    lastCode = code;
    return false;
  }
}

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  Widget buildScreen(AuthProvider auth) => buildTestable(
    const VerifyCodeScreen(phone: '+989121112233'),
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ChangeNotifierProvider(create: (_) => FakeOnboardingProvider()),
      ChangeNotifierProvider(create: (_) => LanguageProvider()),
    ],
  );

  group('VerifyCodeScreen', () {
    testWidgets('renders a single 6-digit code field', (tester) async {
      await tester.pumpWidget(buildScreen(AuthProvider()));

      final pinput = tester.widget<Pinput>(find.byType(Pinput));
      expect(pinput.length, 6);
    });

    testWidgets('accepts a pasted 6-digit code and verifies it', (
      tester,
    ) async {
      final auth = RecordingAuthProvider();
      await tester.pumpWidget(buildScreen(auth));

      await tester.enterText(find.byType(EditableText), '123456');
      await tester.pump();

      expect(auth.lastCode, '123456');
    });

    testWidgets('autofills and verifies when the SMS consent API delivers it', (
      tester,
    ) async {
      final auth = RecordingAuthProvider();
      await tester.pumpWidget(buildScreen(auth));
      await tester.pump();

      await TestDefaultBinaryMessengerBinding
          .instance
          .defaultBinaryMessenger
          .handlePlatformMessage(
            'ir.bondi.app/sms_consent',
            const StandardMethodCodec().encodeMethodCall(
              const MethodCall(
                'onSmsReceived',
                'Bondi verification code: 445566',
              ),
            ),
            (_) {},
          );
      await tester.pump();

      expect(auth.lastCode, '445566');
    });

    testWidgets('shows error for incomplete 6-digit code', (tester) async {
      await tester.pumpWidget(buildScreen(AuthProvider()));

      await tester.enterText(find.byType(EditableText), '123');
      await tester.pump();

      await tester.tap(find.text('Verify'));
      await tester.pump();

      expect(find.text('Please enter the 6-digit code'), findsOneWidget);
    });

    testWidgets('resend button is disabled while timer is running', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen(AuthProvider()));

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
