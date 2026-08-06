import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

void main() {
  group('Google OAuth', () {
    patrolTest('Google OAuth login with mocked provider', ($) async {
      await $.pumpAndSettle();

      await $(find.text('Google Sign-In')).tap();

      await $.pumpAndSettle();

      expect(find.text('Discover'), findsOneWidget);
    });
  });
}