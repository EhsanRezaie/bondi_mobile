enum MessageType { text, photo, voice }

class Message {
  final String id;
  final String matchId;
  final String senderId;
  final String receiverId;
  final MessageType messageType;
  final String? content;
  final String? mediaUrl;
  final int? mediaDuration;
  final Message? replyTo;
  final bool isSent;
  final bool isDelivered;
  final bool isRead;
  final bool isAccepted;
  final DateTime sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final bool isEdited;
  final DateTime? editedAt;
  final bool isDeleted;

  Message({
    required this.id,
    required this.matchId,
    required this.senderId,
    required this.receiverId,
    required this.messageType,
    this.content,
    this.mediaUrl,
    this.mediaDuration,
    this.replyTo,
    required this.isSent,
    this.isDelivered = false,
    this.isRead = false,
    this.isAccepted = false,
    required this.sentAt,
    this.deliveredAt,
    this.readAt,
    this.isEdited = false,
    this.editedAt,
    this.isDeleted = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? '',
      matchId: json['match_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      receiverId: json['receiver_id'] ?? '',
      messageType: _parseMessageType(json['message_type']),
      content: json['content'],
      mediaUrl: json['media_url'],
      mediaDuration: json['media_duration'],
      replyTo: json['reply_to'] != null
          ? Message.fromJson(json['reply_to'])
          : null,
      isSent: json['is_sent'] ?? false,
      isDelivered: json['is_delivered'] ?? false,
      isRead: json['is_read'] ?? false,
      isAccepted: json['is_accepted'] ?? false,
      sentAt: DateTime.tryParse(json['sent_at'] ?? '') ?? DateTime.now(),
      deliveredAt: json['delivered_at'] != null
          ? DateTime.tryParse(json['delivered_at'])
          : null,
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'])
          : null,
      isEdited: json['is_edited'] ?? false,
      editedAt: json['edited_at'] != null
          ? DateTime.tryParse(json['edited_at'])
          : null,
      isDeleted: json['is_deleted'] ?? false,
    );
  }

  factory Message.fromSocketData(Map<String, dynamic> data) {
    return Message(
      id: data['id'] ?? '',
      matchId: data['match_id'] ?? '',
      senderId: data['sender_id'] ?? '',
      receiverId: data['receiver_id'] ?? '',
      messageType: _parseMessageType(data['message_type']),
      content: data['content'],
      mediaUrl: data['media_url'],
      mediaDuration: data['media_duration'],
      replyTo: data['reply_to'] != null
          ? Message.fromJson(data['reply_to'])
          : null,
      isSent: data['is_sent'] ?? false,
      isDelivered: data['is_delivered'] ?? false,
      isRead: data['is_read'] ?? false,
      isAccepted: data['is_accepted'] ?? false,
      sentAt: DateTime.tryParse(data['sent_at'] ?? '') ?? DateTime.now(),
      isEdited: data['is_edited'] ?? false,
      editedAt: data['edited_at'] != null
          ? DateTime.tryParse(data['edited_at'])
          : null,
      isDeleted: data['is_deleted'] ?? false,
    );
  }

  factory Message.local(
    String id,
    String matchId,
    String senderId,
    String receiverId,
    String content, {
    bool isSent = true,
    MessageType messageType = MessageType.text,
  }) {
    return Message(
      id: id,
      matchId: matchId,
      senderId: senderId,
      receiverId: receiverId,
      messageType: messageType,
      content: content,
      isSent: isSent,
      sentAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'match_id': matchId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message_type': messageType.name,
      'content': content,
      'media_url': mediaUrl,
      'media_duration': mediaDuration,
      'reply_to': replyTo?.toJson(),
      'is_sent': isSent,
      'is_delivered': isDelivered,
      'is_read': isRead,
      'is_accepted': isAccepted,
      'sent_at': sentAt.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'is_edited': isEdited,
      'edited_at': editedAt?.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  static MessageType _parseMessageType(String? type) {
    switch (type) {
      case 'photo':
        return MessageType.photo;
      case 'voice':
        return MessageType.voice;
      default:
        return MessageType.text;
    }
  }

  Message copyWith({
    String? content,
    bool? isEdited,
    bool? isDeleted,
    bool? isDelivered,
    bool? isRead,
  }) {
    return Message(
      id: id,
      matchId: matchId,
      senderId: senderId,
      receiverId: receiverId,
      messageType: messageType,
      content: content ?? this.content,
      mediaUrl: mediaUrl,
      mediaDuration: mediaDuration,
      replyTo: replyTo,
      isSent: isSent,
      isDelivered: isDelivered ?? this.isDelivered,
      isRead: isRead ?? this.isRead,
      isAccepted: isAccepted,
      sentAt: sentAt,
      deliveredAt: deliveredAt,
      readAt: readAt,
      isEdited: isEdited ?? this.isEdited,
      editedAt: (isEdited ?? false) ? DateTime.now() : editedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
