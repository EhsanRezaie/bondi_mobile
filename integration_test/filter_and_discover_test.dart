import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

void main() {
  group('Filter and Discover', () {
    patrolTest('Apply filters → Discover feed updates', ($) async {
      await $.pumpAndSettle();

      await $(find.byIcon(Icons.wc)).tap();
      await $.pumpAndSettle();

      await $(find.text('Male')).tap();
      await $.pumpAndSettle();

      expect(find.text('Male'), findsOneWidget);
    });
  });
}