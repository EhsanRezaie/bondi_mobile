import 'package:flutter_test/flutter_test.dart';
import 'package:dating_app/models/interest.dart';
import '../../helpers/fixtures.dart';

void main() {
  test('Interest.fromJson parses all fields', () {
    final i = interest();
    expect(i.id, 'i1');
    expect(i.name, 'Hiking');
    expect(i.category, 'Outdoor');
    expect(i.icon, isNull);
  });

  test('Interest defaults category and icon', () {
    final i = Interest.fromJson({'id': 'x', 'name': 'Y'});
    expect(i.category, '');
    expect(i.icon, isNull);
  });

  test('Interest.toJson round-trips', () {
    final original = interest();
    final round = Interest.fromJson(original.toJson());
    expect(round.id, original.id);
    expect(round.name, original.name);
    expect(round.category, original.category);
  });
}