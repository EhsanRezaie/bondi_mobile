class TicketMessage {
  final String id;
  final String senderType; // 'user' | 'admin'
  final String? adminName;
  final String content;
  final DateTime createdAt;

  const TicketMessage({
    required this.id,
    required this.senderType,
    this.adminName,
    required this.content,
    required this.createdAt,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      id: json['id'] ?? '',
      senderType: json['sender_type'] ?? 'user',
      adminName: json['admin_name'],
      content: json['content'] ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  bool get isFromAdmin => senderType == 'admin';
}

class Ticket {
  final String id;
  final String userId;
  final String subject;
  final String message;
  final String status; // open | in_progress | closed
  final String? adminResponse;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<TicketMessage> messages;

  const Ticket({
    required this.id,
    required this.userId,
    required this.subject,
    required this.message,
    required this.status,
    this.adminResponse,
    required this.createdAt,
    this.updatedAt,
    this.messages = const [],
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'];
    return Ticket(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      subject: json['subject'] ?? '',
      message: json['message'] ?? '',
      status: json['status'] ?? 'open',
      adminResponse: json['admin_response'],
      createdAt:
          DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      messages: rawMessages is List
          ? rawMessages
              .map((m) => TicketMessage.fromJson(m))
              .toList()
          : const [],
    );
  }

  bool get isClosed => status == 'closed';

  Ticket copyWith({
    String? status,
    String? adminResponse,
    DateTime? updatedAt,
    List<TicketMessage>? messages,
  }) {
    return Ticket(
      id: id,
      userId: userId,
      subject: subject,
      message: message,
      status: status ?? this.status,
      adminResponse: adminResponse ?? this.adminResponse,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
    );
  }
}

class TicketPage {
  final List<Ticket> tickets;
  final int total;
  final int? nextOffset;

  const TicketPage({
    required this.tickets,
    required this.total,
    this.nextOffset,
  });

  factory TicketPage.fromJson(Map<String, dynamic> json) {
    final list = (json['tickets'] ?? []) as List;
    return TicketPage(
      tickets: list.map((j) => Ticket.fromJson(j)).toList(),
      total: json['total'] ?? 0,
      nextOffset: json['next_offset'],
    );
  }
}