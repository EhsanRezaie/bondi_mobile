import 'package:flutter_test/flutter_test.dart';
import 'package:dating_app/models/match.dart';
import 'package:dating_app/models/message.dart';
import '../../helpers/fixtures.dart';

void main() {
  group('Match.fromJson', () {
    test('parses the /matches shape', () {
      final m = Match.fromJson(jsonMatch());
      expect(m.id, 'match-1');
      expect(m.kind, 'match');
      expect(m.isAccepted, isTrue);
      expect(m.unreadCount, 0);
      expect(m.updatedAt, isNull);
      expect(m.user.id, 'user-1');
      expect(m.matchedAt, kNow);
    });

    test('parses a /conversations shape with kind=unmatched', () {
      final c = Match.fromJson(jsonConversation(kind: 'unmatched', unreadCount: 3));
      expect(c.kind, 'unmatched');
      expect(c.unreadCount, 3);
      expect(c.updatedAt, kNow);
    });

    test('isAccepted defaults per kind', () {
      expect(Match.fromJson(jsonMatch(isAccepted: false)).isAccepted, isFalse);
      // kind==match without explicit flag → accepted
      expect(Match.fromJson(jsonMatch()).isAccepted, isTrue);
    });

    test('last_message parsed when present', () {
      final m = Match.fromJson(jsonMatch(lastMessage: jsonMessage()));
      expect(m.lastMessage, isNotNull);
      expect(m.lastMessage!.messageType, MessageType.text);
    });

    test('last_message null when absent', () {
      final m = Match.fromJson(jsonMatch(lastMessage: null));
      expect(m.lastMessage, isNull);
    });

    test('defaults kind to match', () {
      final m = Match.fromJson({'id': 'x', 'user': jsonSwipeUser()});
      expect(m.kind, 'match');
    });
  });

  group('Match.toJson round-trip', () {
    test('preserves fields', () {
      final original = Match.fromJson(jsonConversation(kind: 'unmatched', unreadCount: 2));
      final round = Match.fromJson(original.toJson());
      expect(round.id, original.id);
      expect(round.kind, original.kind);
      expect(round.unreadCount, original.unreadCount);
      expect(round.user.name, original.user.name);
    });
  });
}