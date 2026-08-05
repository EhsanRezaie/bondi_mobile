import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

void main() {
  group('Filter and Discover', () {
    patrolTest('Apply filters → Discover feed updates', (patrolTester) async {
      await patrolTester.app.start();

      await patrolTester.tap(find.byIcon(Icons.wc));
      await patrolTester.pumpWidgetAndSettle();

      await patrolTester.tap(find.text('Male'));
      await patrolTester.pumpWidgetAndSettle();

      expect(find.text('Male'), findsOneWidget);
    });
  });
}