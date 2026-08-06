import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

void main() {
  group('Match and Chat', () {
    patrolTest('Swipe → match → chat → send message', ($) async {
      await $.pumpAndSettle();

      await $(find.byIcon(Icons.favorite_rounded)).tap();
      await $.pumpAndSettle();

      await $(find.byIcon(Icons.chat_bubble_rounded)).tap();
      await $.pumpAndSettle();

      await $(find.byType(TextField).first).enterText('Hello!');
      await $(find.byIcon(Icons.send)).tap();

      await $.pumpAndSettle();

      expect(find.text('Hello!'), findsOneWidget);
    });
  });
}