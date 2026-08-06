import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

void main() {
  group('Premium Upgrade', () {
    patrolTest('Free → premium upgrade → unlocked feature visible', ($) async {
      await $.pumpAndSettle();

      await $(find.text('Profile')).tap();
      await $.pumpAndSettle();

      await $(find.text('Upgrade')).tap();
      await $.pumpAndSettle();

      expect(find.text('Premium'), findsOneWidget);
    });
  });
}