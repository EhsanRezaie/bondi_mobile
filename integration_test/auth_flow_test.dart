import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

void main() {
  group('Auth Flow', () {
    patrolTest('Signup → OTP verify → land on Discover', (patrolTester) async {
      await patrolTester.app.start();

      await patrolTester.tap(find.text('Sign Up'));
      await patrolTester.enterText(
        find.byType(TextField).first,
        'test@example.com',
      );
      await patrolTester.tap(find.text('Send Code'));

      await patrolTester.enterText(
        find.byType(TextField).first,
        '123456',
      );
      await patrolTester.tap(find.text('Verify'));

      await patrolTester.enterText(
        find.byType(TextField).first,
        'TestUser',
      );
      await patrolTester.tap(find.text('Continue'));

      await patrolTester.pumpWidgetAndSettle();

      expect(find.text('Discover'), findsOneWidget);
    });
  });
}