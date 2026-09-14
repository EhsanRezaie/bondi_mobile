import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/screens/auth/phone_entry_screen.dart';
import 'package:dating_app/providers/auth_provider.dart';
import 'package:dating_app/providers/language_provider.dart';
import 'package:dating_app/providers/settings_provider.dart';
import '../../../helpers/test_helpers.dart';

/// Captures the phone handed to [AuthProvider.requestCode].
class RecordingAuthProvider extends AuthProvider {
  String? lastPhone;

  @override
  Future<bool> requestCode(String phone, BuildContext context) async {
    lastPhone = phone;
    return false;
  }
}

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  Widget buildScreen(AuthProvider auth) => buildTestable(
    const PhoneEntryScreen(
      title: 'Welcome',
      subtitle: 'Find your match',
      submitLabel: 'Send Code',
    ),
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ChangeNotifierProvider(create: (_) => SettingsProvider()),
    ],
  );

  group('PhoneEntryScreen', () {
    testWidgets('strips a leading zero as the user types', (tester) async {
      await tester.pumpWidget(buildScreen(AuthProvider()));

      await tester.enterText(find.byType(TextField), '09123456789');
      await tester.pump();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, '9123456789');
    });

    testWidgets('shows the no-zero example as the hint', (tester) async {
      await tester.pumpWidget(buildScreen(AuthProvider()));

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.decoration?.hintText, '912 345 6789');
    });

    testWidgets('sends clean E.164 without a trunk zero', (tester) async {
      final auth = RecordingAuthProvider();
      await tester.pumpWidget(buildScreen(auth));

      await tester.enterText(find.byType(TextField), '09123456789');
      await tester.pump();

      await tester.tap(find.text('Send Code'));
      await tester.pump();

      expect(auth.lastPhone, '+989123456789');

      // Flush the action toast's 2s timer so the test ends without a pending
      // timer assertion.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    });

    testWidgets('shows an error for an invalid national number', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen(AuthProvider()));

      await tester.enterText(find.byType(TextField), '12345');
      await tester.pump();

      await tester.tap(find.text('Send Code'));
      await tester.pump();

      expect(find.text('Please enter a valid phone number'), findsOneWidget);
    });
  });
}
