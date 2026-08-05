import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:dating_app/models/match.dart';
import 'package:dating_app/models/message.dart';
import 'package:dating_app/models/swipe_user.dart';
import 'package:dating_app/services/chat_service.dart';
import 'package:dating_app/services/chat_websocket_service.dart';
import 'package:dating_app/services/storage_service.dart';

class ChatProvider extends ChangeNotifier {
  bool _disposed = false;

  StreamSubscription<bool>? _connectionStateSubscription;
  StreamSubscription<Map<String, dynamic>>? _eventsSubscription;

  @override
  void dispose() {
    _disposed = true;
    _connectionStateSubscription?.cancel();
    _eventsSubscription?.cancel();
    _wsService?.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  static const _uuid = Uuid();
  final _storageService = StorageService();

  // ── State ────────────────────────────────────────────────────────
  List<Match> _matches = [];
  List<Match> _conversations = [];
  List<SwipeUser> _likedUsers = [];
  List<SwipeUser> _likers = [];
  List<Message> _messages = [];
  String? _activeMatchId;
  ChatWebSocketService? _wsService;
  bool _isConnected = false;
  bool _isOtherUserOnline = false;
  bool _isTyping = false;
  int _chatsRemaining = 0;
  bool _isPremium = false;
  int _likesRemaining = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _sentCountInNewChat = 0;
  bool _isChatAccepted = false;
  String? _editingMessageId;
  Timer? _typingTimer;

  int _matchesOffset = 0;
  int _conversationsOffset = 0;
  int _likersOffset = 0;
  int _likedOffset = 0;
  bool _hasMoreMatches = true;
  bool _hasMoreConversations = true;
  bool _hasMoreLikers = true;
  bool _hasMoreLiked = true;
  static const _pageSize = 20;

  // ── Getters ──────────────────────────────────────────────────────
  List<Match> get matches => _matches;
  List<Match> get conversations => _conversations;
  List<SwipeUser> get likedUsers => _likedUsers;
  List<SwipeUser> get likers => _likers;
  List<Message> get messages => _messages;
  String? get activeMatchId => _activeMatchId;
  bool get isConnected => _isConnected;
  bool get isOtherUserOnline => _isOtherUserOnline;
  bool get isTyping => _isTyping;
  int get chatsRemaining => _chatsRemaining;
  bool get isPremium => _isPremium;
  int get likesRemaining => _likesRemaining;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  bool get hasMoreMatches => _hasMoreMatches;
  bool get hasMoreConversations => _hasMoreConversations;
  bool get hasMoreLikers => _hasMoreLikers;
  bool get hasMoreLiked => _hasMoreLiked;
  String? get editingMessageId => _editingMessageId;
  bool get isChatAccepted => _isChatAccepted;

  bool get canSendMessage {
    if (_isPremium) return true;
    if (_isChatAccepted) return true;
    if (_sentCountInNewChat >= 2) return false;
    return true;
  }

  int get sentCountInNewChat => _sentCountInNewChat;

  // ── Matches ──────────────────────────────────────────────────────
  Future<void> loadMatches() async {
    _isLoading = true;
    _errorMessage = null;
    _matchesOffset = 0;
    _hasMoreMatches = true;
    _safeNotify();

    try {
      final response = await ChatService.getMatches(
        limit: _pageSize,
        offset: 0,
      );
      if (response.statusCode == 200) {
        final data = response.data;
        final items = (data['items'] ?? data['matches'] ?? data ?? []) as List;
        _matches = items.map((j) => Match.fromJson(j)).toList();
        _matchesOffset = _matches.length;
        _hasMoreMatches = items.length >= _pageSize;
      } else {
        _errorMessage = 'Failed to load matches';
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    _safeNotify();
  }

  Future<void> loadMoreMatches() async {
    if (_isLoadingMore || !_hasMoreMatches) return;
    _isLoadingMore = true;
    _safeNotify();

    try {
      final response = await ChatService.getMatches(
        limit: _pageSize,
        offset: _matchesOffset,
      );
      if (response.statusCode == 200) {
        final data = response.data;
        final items = (data['items'] ?? data['matches'] ?? data ?? []) as List;
        final newMatches = items.map((j) => Match.fromJson(j)).toList();
        _matches.addAll(newMatches);
        _matchesOffset += newMatches.length;
        _hasMoreMatches = items.length >= _pageSize;
      }
    } catch (e) {
      // silent
    }

    _isLoadingMore = false;
    _safeNotify();
  }

  // ── Conversations ───────────────────────────────────────────────
  Future<void> loadConversations() async {
    _isLoading = true;
    _errorMessage = null;
    _conversationsOffset = 0;
    _hasMoreConversations = true;
    _safeNotify();

    try {
      final response = await ChatService.getConversations(
        limit: _pageSize,
        offset: 0,
      );
      final data = response.data;
      if (response.statusCode == 200) {
        final items =
            (data['items'] ?? data['conversations'] ?? data ?? []) as List;
        _conversations = items.map((j) => Match.fromJson(j)).toList();
        _conversationsOffset = _conversations.length;
        _hasMoreConversations = items.length >= _pageSize;
      } else {
        _errorMessage = data?['detail'] ?? 'Failed to load conversations';
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    _safeNotify();
  }

  Future<void> loadMoreConversations() async {
    if (_isLoadingMore || !_hasMoreConversations) return;
    _isLoadingMore = true;
    _safeNotify();

    try {
      final response = await ChatService.getConversations(
        limit: _pageSize,
        offset: _conversationsOffset,
      );
      if (response.statusCode == 200) {
        final data = response.data;
        final items =
            (data['items'] ?? data['conversations'] ?? data ?? []) as List;
        final newConversations = items.map((j) => Match.fromJson(j)).toList();
        _conversations.addAll(newConversations);
        _conversationsOffset += newConversations.length;
        _hasMoreConversations = items.length >= _pageSize;
      }
    } catch (e) {
      // silent
    }

    _isLoadingMore = false;
    _safeNotify();
  }

  // ── Likers ───────────────────────────────────────────────────────
  Future<void> loadLikers() async {
    _isLoading = true;
    _errorMessage = null;
    _likersOffset = 0;
    _hasMoreLikers = true;
    _safeNotify();

    try {
      final response = await ChatService.getLikers(
        limit: _pageSize,
        offset: 0,
      );
      if (response.statusCode == 200) {
        final data = response.data;
        final items = (data['items'] ?? data['users'] ?? data ?? []) as List;
        _likers = items.map((j) => SwipeUser.fromJson(j)).toList();
        _likersOffset = _likers.length;
        _hasMoreLikers = items.length >= _pageSize;
      } else {
        _errorMessage = 'Failed to load likers';
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    _safeNotify();
  }

  Future<void> loadMoreLikers() async {
    if (_isLoadingMore || !_hasMoreLikers) return;
    _isLoadingMore = true;
    _safeNotify();

    try {
      final response = await ChatService.getLikers(
        limit: _pageSize,
        offset: _likersOffset,
      );
      if (response.statusCode == 200) {
        final data = response.data;
        final items = (data['items'] ?? data['users'] ?? data ?? []) as List;
        final newLikers = items.map((j) => SwipeUser.fromJson(j)).toList();
        _likers.addAll(newLikers);
        _likersOffset += newLikers.length;
        _hasMoreLikers = items.length >= _pageSize;
      }
    } catch (e) {
      // silent
    }

    _isLoadingMore = false;
    _safeNotify();
  }

  // ── Liked Users ──────────────────────────────────────────────────
  Future<void> loadLikedUsers() async {
    _isLoading = true;
    _errorMessage = null;
    _likedOffset = 0;
    _hasMoreLiked = true;
    _safeNotify();

    try {
      final response = await ChatService.getLikedUsers(
        limit: _pageSize,
        offset: 0,
      );
      if (response.statusCode == 200) {
        final data = response.data;
        final items = (data['items'] ?? data['users'] ?? data ?? []) as List;
        _likedUsers = items.map((j) => SwipeUser.fromJson(j)).toList();
        _likedOffset = _likedUsers.length;
        _hasMoreLiked = items.length >= _pageSize;
      } else {
        _errorMessage = 'Failed to load liked users';
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    _safeNotify();
  }

  Future<void> loadMoreLikedUsers() async {
    if (_isLoadingMore || !_hasMoreLiked) return;
    _isLoadingMore = true;
    _safeNotify();

    try {
      final response = await ChatService.getLikedUsers(
        limit: _pageSize,
        offset: _likedOffset,
      );
      if (response.statusCode == 200) {
        final data = response.data;
        final items = (data['items'] ?? data['users'] ?? data ?? []) as List;
        final newLiked = items.map((j) => SwipeUser.fromJson(j)).toList();
        _likedUsers.addAll(newLiked);
        _likedOffset += newLiked.length;
        _hasMoreLiked = items.length >= _pageSize;
      }
    } catch (e) {
      // silent
    }

    _isLoadingMore = false;
    _safeNotify();
  }

  // ── Messages ─────────────────────────────────────────────────────
  Future<void> loadMessages(String identifier) async {
    _isLoading = true;
    _errorMessage = null;
    _messages = [];
    _activeMatchId = identifier;
    _sentCountInNewChat = 0;
    _isChatAccepted = false;
    _safeNotify();

    try {
      final response = await ChatService.getChatHistory(identifier);
      if (response.statusCode == 200) {
        final data = response.data;
        final items =
            (data['items'] ?? data['messages'] ?? data ?? []) as List;
        _messages = items.map((j) => Message.fromJson(j)).toList();

        // Check if chat is accepted (has messages from both sides or isAccepted)
        if (_messages.isNotEmpty) {
          final userId = await _storageService.getUserId();
          final hasReceivedMessages =
              _messages.any((m) => m.senderId != userId);
          final hasAcceptedFlag = _messages.any((m) => m.isAccepted);
          _isChatAccepted = hasReceivedMessages || hasAcceptedFlag;

          // Count sent messages in new chat if not accepted
          if (!_isChatAccepted && userId != null) {
            _sentCountInNewChat =
                _messages.where((m) => m.senderId == userId).length;
          }
        }

        // Mark unread messages as delivered
        final userId = await _storageService.getUserId();
        if (userId != null) {
          final unreadIds = _messages
              .where((m) => m.receiverId == userId && !m.isDelivered)
              .map((m) => m.id)
              .toList();
          if (unreadIds.isNotEmpty) {
            ChatService.markDelivered(unreadIds);
          }
        }
      } else {
        _errorMessage = 'Failed to load messages';
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    _safeNotify();
  }

  Future<void> loadMoreMessages() async {
    if (_isLoadingMore || _activeMatchId == null || _messages.isEmpty) return;
    _isLoadingMore = true;
    _safeNotify();

    try {
      final oldest = _messages.first.sentAt.toIso8601String();
      final response = await ChatService.getChatHistory(
        _activeMatchId!,
        before: oldest,
      );
      if (response.statusCode == 200) {
        final data = response.data;
        final items =
            (data['items'] ?? data['messages'] ?? data ?? []) as List;
        final olderMessages = items.map((j) => Message.fromJson(j)).toList();
        _messages.insertAll(0, olderMessages);
      }
    } catch (e) {
      // silent
    }

    _isLoadingMore = false;
    _safeNotify();
  }

  // ── Send ─────────────────────────────────────────────────────────
  Future<bool> sendText(
    String identifier,
    String content, {
    String? replyToId,
  }) async {
    if (!canSendMessage) return false;

    final userId = await _storageService.getUserId() ?? '';
    final tempId = _uuid.v4();
    final matchId = identifier;

    // Check if identifier is a userId (unmatched) — use it as matchId
    final tempMessage = Message.local(
      tempId,
      matchId,
      userId,
      identifier,
      content,
      isSent: true,
    );
    _messages.add(tempMessage);
    _sentCountInNewChat++;
    _safeNotify();

    try {
      final response = await ChatService.sendText(
        identifier,
        content,
        replyToId: replyToId,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final realMessage = Message.fromJson(data['message'] ?? data);

        // Replace temp message with real one
        final index = _messages.indexWhere((m) => m.id == tempId);
        if (index != -1) {
          _messages[index] = realMessage;
        }

        // Check if accepted after first reply received
        if (realMessage.senderId != userId) {
          _isChatAccepted = true;
        }

        _safeNotify();
        return true;
      } else {
        // Remove failed message
        _messages.removeWhere((m) => m.id == tempId);
        _sentCountInNewChat = (_sentCountInNewChat - 1).clamp(0, 999);
        _errorMessage = response.data['detail'] ?? 'Failed to send message';
        _safeNotify();
        return false;
      }
    } catch (e) {
      _messages.removeWhere((m) => m.id == tempId);
      _sentCountInNewChat = (_sentCountInNewChat - 1).clamp(0, 999);
      _errorMessage = e.toString();
      _safeNotify();
      return false;
    }
  }

  Future<bool> sendPhoto(
    String identifier,
    String imagePath, {
    String? caption,
  }) async {
    if (!canSendMessage) return false;

    final userId = await _storageService.getUserId() ?? '';
    final tempId = _uuid.v4();

    final tempMessage = Message.local(
      tempId,
      identifier,
      userId,
      identifier,
      caption ?? '',
      messageType: MessageType.photo,
    );
    _messages.add(tempMessage);
    _sentCountInNewChat++;
    _safeNotify();

    try {
      final response = await ChatService.sendPhoto(
        identifier,
        imagePath,
        caption: caption,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final realMessage = Message.fromJson(data['message'] ?? data);
        final index = _messages.indexWhere((m) => m.id == tempId);
        if (index != -1) _messages[index] = realMessage;
        _safeNotify();
        return true;
      } else {
        _messages.removeWhere((m) => m.id == tempId);
        _sentCountInNewChat = (_sentCountInNewChat - 1).clamp(0, 999);
        _safeNotify();
        return false;
      }
    } catch (e) {
      _messages.removeWhere((m) => m.id == tempId);
      _sentCountInNewChat = (_sentCountInNewChat - 1).clamp(0, 999);
      _errorMessage = e.toString();
      _safeNotify();
      return false;
    }
  }

  Future<bool> sendVoice(
    String identifier,
    String filePath,
    int duration,
  ) async {
    if (!canSendMessage) return false;

    final userId = await _storageService.getUserId() ?? '';
    final tempId = _uuid.v4();

    final tempMessage = Message.local(
      tempId,
      identifier,
      userId,
      identifier,
      '',
      messageType: MessageType.voice,
    );
    _messages.add(tempMessage);
    _sentCountInNewChat++;
    _safeNotify();

    try {
      final response = await ChatService.sendVoice(
        identifier,
        filePath,
        duration,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final realMessage = Message.fromJson(data['message'] ?? data);
        final index = _messages.indexWhere((m) => m.id == tempId);
        if (index != -1) _messages[index] = realMessage;
        _safeNotify();
        return true;
      } else {
        _messages.removeWhere((m) => m.id == tempId);
        _sentCountInNewChat = (_sentCountInNewChat - 1).clamp(0, 999);
        _safeNotify();
        return false;
      }
    } catch (e) {
      _messages.removeWhere((m) => m.id == tempId);
      _sentCountInNewChat = (_sentCountInNewChat - 1).clamp(0, 999);
      _errorMessage = e.toString();
      _safeNotify();
      return false;
    }
  }

  // ── Edit ─────────────────────────────────────────────────────────
  void startEditing(String messageId) {
    _editingMessageId = messageId;
    _safeNotify();
  }

  void cancelEditing() {
    _editingMessageId = null;
    _safeNotify();
  }

  Future<bool> editMessage(String messageId, String newContent) async {
    try {
      final response = await ChatService.editMessage(messageId, newContent);
      if (response.statusCode == 200) {
        final index = _messages.indexWhere((m) => m.id == messageId);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(
            content: newContent,
            isEdited: true,
          );
        }
        _editingMessageId = null;
        _safeNotify();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _safeNotify();
      return false;
    }
  }

  // ── Delete ───────────────────────────────────────────────────────
  Future<bool> deleteMessage(String messageId, {bool deleteForAll = false}) async {
    try {
      final response = await ChatService.deleteMessage(
        messageId,
        deleteFor: deleteForAll ? 'all' : 'me',
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        if (deleteForAll) {
          final index = _messages.indexWhere((m) => m.id == messageId);
          if (index != -1) {
            _messages[index] = _messages[index].copyWith(isDeleted: true);
          }
        } else {
          _messages.removeWhere((m) => m.id == messageId);
        }
        _safeNotify();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _safeNotify();
      return false;
    }
  }

  // ── Read ─────────────────────────────────────────────────────────
  Future<void> markMessagesRead(List<String> messageIds) async {
    if (messageIds.isEmpty) return;
    try {
      await ChatService.markRead(messageIds);
      for (final id in messageIds) {
        final index = _messages.indexWhere((m) => m.id == id);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(isRead: true);
        }
      }
      _safeNotify();
    } catch (e) {
      // silent
    }
  }

  // ── Accept Chat ──────────────────────────────────────────────────
  Future<void> acceptChat(String matchId) async {
    try {
      final response = await ChatService.acceptChat(matchId);
      if (response.statusCode == 200 || response.statusCode == 201) {
        _isChatAccepted = true;
        _safeNotify();
      }
    } catch (e) {
      _errorMessage = e.toString();
      _safeNotify();
    }
  }

  // ── Limits ───────────────────────────────────────────────────────
  Future<void> refreshLimits() async {
    try {
      final response = await ChatService.getDailyLimits();
      if (response.statusCode == 200) {
        final data = response.data;
        _isPremium = data['is_premium'] ?? false;
        _chatsRemaining = data['chats_remaining_today'] ?? 0;
        _likesRemaining = data['likes_remaining_today'] ?? 0;
        _safeNotify();
      }
    } catch (e) {
      // silent
    }
  }

  // ── WebSocket ────────────────────────────────────────────────────
  Future<void> connectWebSocket(String matchId) async {
    await disconnectWebSocket();

    final token = await _storageService.getAccessToken();
    if (token == null) return;

    _wsService = ChatWebSocketService(
      matchId: matchId,
      jwtToken: token,
    );

    _connectionStateSubscription = _wsService!.connectionState.listen((connected) {
      _isConnected = connected;
      _safeNotify();
    });

    _eventsSubscription = _wsService!.events.listen((event) {
      _handleSocketEvent(event);
    });

    await _wsService!.connect();
  }

  Future<void> disconnectWebSocket() async {
    await _wsService?.dispose();
    _connectionStateSubscription?.cancel();
    _eventsSubscription?.cancel();
    _wsService = null;
    _isConnected = false;
    _isOtherUserOnline = false;
    _isTyping = false;
    _safeNotify();
  }

  void _handleSocketEvent(Map<String, dynamic> event) {
    final type = event['type'] as String?;
    final data = event['data'] as Map<String, dynamic>? ?? {};

    switch (type) {
      case 'new_message':
        _handleNewMessage(data);
        break;
      case 'new_match':
        handleNewMatch(data);
        break;
      case 'user_online':
        _isOtherUserOnline = true;
        _safeNotify();
        break;
      case 'user_offline':
        _isOtherUserOnline = false;
        _safeNotify();
        break;
      case 'typing':
        _isTyping = true;
        _safeNotify();
        _resetTypingTimer();
        break;
      case 'typing_stopped':
        _isTyping = false;
        _safeNotify();
        break;
      case 'messages_read':
        _handleMessagesRead(data);
        break;
    }
  }

  void _handleNewMessage(Map<String, dynamic> data) {
    final message = Message.fromSocketData(data);
    // Don't add duplicate if already in list (optimistic add)
    final exists = _messages.any((m) => m.id == message.id);
    if (!exists) {
      _messages.add(message);

      // If we received a message, the chat is accepted
      final userId = _storageService.getUserId();
      userId.then((id) {
        if (id != null && message.senderId != id) {
          _isChatAccepted = true;
          _safeNotify();
        }
      });
    }
    _safeNotify();
  }

  void _handleMessagesRead(Map<String, dynamic> data) {
    final messageIds = List<String>.from(data['message_ids'] ?? []);
    for (final id in messageIds) {
      final index = _messages.indexWhere((m) => m.id == id);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(isRead: true);
      }
    }
    _safeNotify();
  }

  void handleNewMatch(Map<String, dynamic> data) {
    try {
      final match = Match.fromJson(data);
      _matches.insert(0, match);
      if (!_conversations.any((c) => c.id == match.id)) {
        _conversations.insert(0, match);
      }
      _safeNotify();
    } catch (e) {
      // silent
    }
  }

  void _resetTypingTimer() {
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 5), () {
      _isTyping = false;
      _safeNotify();
    });
  }

  // ── Typing ───────────────────────────────────────────────────────
  void setTyping() {
    _wsService?.sendTyping();
  }

  void stopTyping() {
    _wsService?.sendTypingStopped();
  }

  // ── Clear ────────────────────────────────────────────────────────
  void clearActiveChat() {
    _activeMatchId = null;
    _messages = [];
    _editingMessageId = null;
    _isTyping = false;
    _isOtherUserOnline = false;
    _sentCountInNewChat = 0;
    _isChatAccepted = false;
    disconnectWebSocket();
    _safeNotify();
  }
}
