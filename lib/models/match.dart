import 'package:dating_app/models/swipe_user.dart';
import 'package:dating_app/models/message.dart';

class Match {
  final String id;
  final DateTime matchedAt;
  final SwipeUser user;
  final Message? lastMessage;
  final bool isActive;

  Match({
    required this.id,
    required this.matchedAt,
    required this.user,
    this.lastMessage,
    this.isActive = true,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] ?? '',
      matchedAt: DateTime.tryParse(json['matched_at'] ?? '') ?? DateTime.now(),
      user: SwipeUser.fromJson(json['user'] ?? {}),
      lastMessage: json['last_message'] != null
          ? Message.fromJson(json['last_message'])
          : null,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matched_at': matchedAt.toIso8601String(),
      'user': user.toJson(),
      'last_message': lastMessage?.toJson(),
      'is_active': isActive,
    };
  }
}
