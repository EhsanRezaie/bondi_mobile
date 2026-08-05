import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

void main() {
  group('Match and Chat', () {
    patrolTest('Swipe → match → chat → send message', (patrolTester) async {
      await patrolTester.app.start();

      await patrolTester.tap(find.byIcon(Icons.favorite_rounded));
      await patrolTester.pumpWidgetAndSettle();

      await patrolTester.tap(find.byIcon(Icons.chat_bubble_rounded));
      await patrolTester.pumpWidgetAndSettle();

      await patrolTester.enterText(
        find.byType(TextField).first,
        'Hello!',
      );
      await patrolTester.tap(find.byIcon(Icons.send));

      await patrolTester.pumpWidgetAndSettle();

      expect(find.text('Hello!'), findsOneWidget);
    });
  });
}