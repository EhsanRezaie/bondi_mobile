import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

void main() {
  group('Google OAuth', () {
    patrolTest('Google OAuth login with mocked provider', (patrolTester) async {
      await patrolTester.app.start();

      await patrolTester.tap(find.text('Google Sign-In'));

      await patrolTester.pumpWidgetAndSettle();

      expect(find.text('Discover'), findsOneWidget);
    });
  });
}