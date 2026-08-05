import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

void main() {
  group('Premium Upgrade', () {
    patrolTest('Free → premium upgrade → unlocked feature visible', (patrolTester) async {
      await patrolTester.app.start();

      await patrolTester.tap(find.text('Profile'));
      await patrolTester.pumpWidgetAndSettle();

      await patrolTester.tap(find.text('Upgrade'));
      await patrolTester.pumpWidgetAndSettle();

      expect(find.text('Premium'), findsOneWidget);
    });
  });
}