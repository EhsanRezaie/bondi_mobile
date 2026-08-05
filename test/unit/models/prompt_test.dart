import 'package:flutter_test/flutter_test.dart';
import 'package:dating_app/models/prompt.dart';
import '../../helpers/fixtures.dart';

void main() {
  test('Prompt.fromJson parses all fields', () {
    final p = prompt();
    expect(p.id, 'p1');
    expect(p.question, 'My simple pleasures');
    expect(p.category, isNull);
    expect(p.isActive, isTrue);
  });

  test('Prompt defaults isActive to true', () {
    final p = Prompt.fromJson({'id': 'x', 'question': 'Q'});
    expect(p.isActive, isTrue);
  });

  test('Prompt parses is_active false', () {
    final p = Prompt.fromJson({'id': 'x', 'question': 'Q', 'is_active': false});
    expect(p.isActive, isFalse);
  });

  test('Prompt.toJson round-trips', () {
    final original = prompt();
    final round = Prompt.fromJson(original.toJson());
    expect(round.id, original.id);
    expect(round.question, original.question);
    expect(round.isActive, original.isActive);
  });
}