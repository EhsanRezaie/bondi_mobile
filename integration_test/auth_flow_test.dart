import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

void main() {
  group('Auth Flow', () {
    patrolTest('Signup → OTP verify → land on Discover', ($) async {
      await $.pumpAndSettle();

      await $(find.text('Sign Up')).tap();
      await $(find.byType(TextField).first).enterText('test@example.com');
      await $(find.text('Send Code')).tap();

      await $(find.byType(TextField).first).enterText('123456');
      await $(find.text('Verify')).tap();

      await $(find.byType(TextField).first).enterText('TestUser');
      await $(find.text('Continue')).tap();

      await $.pumpAndSettle();

      expect(find.text('Discover'), findsOneWidget);
    });
  });
}