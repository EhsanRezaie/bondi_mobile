class ChatUser {
  final String id;
  final String name;
  final int age;
  final String? mainPhotoUrl;
  final String? mainPhotoThumbUrl;
  final bool isOnline;
  final String? lastSeenAt;

  ChatUser({
    required this.id,
    required this.name,
    required this.age,
    this.mainPhotoUrl,
    this.mainPhotoThumbUrl,
    this.isOnline = false,
    this.lastSeenAt,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      mainPhotoUrl: json['main_photo_url'],
      mainPhotoThumbUrl: json['main_photo_thumb_url'],
      isOnline: json['is_online'] ?? false,
      lastSeenAt: json['last_seen_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'main_photo_url': mainPhotoUrl,
      'main_photo_thumb_url': mainPhotoThumbUrl,
      'is_online': isOnline,
      'last_seen_at': lastSeenAt,
    };
  }

  ChatUser copyWith({
    String? name,
    int? age,
    String? mainPhotoUrl,
    String? mainPhotoThumbUrl,
    bool? isOnline,
    String? lastSeenAt,
  }) {
    return ChatUser(
      id: id,
      name: name ?? this.name,
      age: age ?? this.age,
      mainPhotoUrl: mainPhotoUrl ?? this.mainPhotoUrl,
      mainPhotoThumbUrl: mainPhotoThumbUrl ?? this.mainPhotoThumbUrl,
      isOnline: isOnline ?? this.isOnline,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }
}

class ChatLastMessage {
  final String? id;
  final String? content;
  final String messageType;
  final bool isSent;
  final bool isRead;
  final DateTime sentAt;

  ChatLastMessage({
    this.id,
    this.content,
    this.messageType = 'text',
    this.isSent = true,
    this.isRead = false,
    required this.sentAt,
  });

  factory ChatLastMessage.fromJson(Map<String, dynamic> json) {
    return ChatLastMessage(
      id: json['id'],
      content: json['content'],
      messageType: json['message_type'] ?? 'text',
      isSent: json['is_sent'] ?? true,
      isRead: json['is_read'] ?? false,
      sentAt: DateTime.tryParse(json['sent_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'message_type': messageType,
      'is_sent': isSent,
      'is_read': isRead,
      'sent_at': sentAt.toIso8601String(),
    };
  }

  ChatLastMessage copyWith({
    String? id,
    String? content,
    String? messageType,
    bool? isSent,
    bool? isRead,
    DateTime? sentAt,
  }) {
    return ChatLastMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      isSent: isSent ?? this.isSent,
      isRead: isRead ?? this.isRead,
      sentAt: sentAt ?? this.sentAt,
    );
  }
}

class ChatCard {
  final String id;
  final String status;
  final String initiatorId;
  final ChatUser user;
  final ChatLastMessage? lastMessage;
  final int unreadCount;
  final DateTime? updatedAt;
  final bool isBlocked;
  final bool isEnded;

  ChatCard({
    required this.id,
    required this.status,
    required this.initiatorId,
    required this.user,
    this.lastMessage,
    this.unreadCount = 0,
    this.updatedAt,
    this.isBlocked = false,
    this.isEnded = false,
  });

  factory ChatCard.fromJson(Map<String, dynamic> json) {
    return ChatCard(
      id: json['id'] ?? '',
      status: json['status'] ?? 'pending',
      initiatorId: json['initiator_id'] ?? '',
      user: ChatUser.fromJson(json['user'] ?? {}),
      lastMessage: json['last_message'] != null
          ? ChatLastMessage.fromJson(json['last_message'])
          : null,
      unreadCount: json['unread_count'] ?? 0,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      isBlocked: json['is_blocked'] ?? false,
      isEnded: json['is_ended'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'initiator_id': initiatorId,
      'user': user.toJson(),
      'last_message': lastMessage?.toJson(),
      'unread_count': unreadCount,
      'updated_at': updatedAt?.toIso8601String(),
      'is_blocked': isBlocked,
      'is_ended': isEnded,
    };
  }

  ChatCard copyWith({
    String? status,
    ChatUser? user,
    ChatLastMessage? lastMessage,
    int? unreadCount,
    DateTime? updatedAt,
    bool? isBlocked,
    bool? isEnded,
  }) {
    return ChatCard(
      id: id,
      status: status ?? this.status,
      initiatorId: initiatorId,
      user: user ?? this.user,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      updatedAt: updatedAt ?? this.updatedAt,
      isBlocked: isBlocked ?? this.isBlocked,
      isEnded: isEnded ?? this.isEnded,
    );
  }
}
