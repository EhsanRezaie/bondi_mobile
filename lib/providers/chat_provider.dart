import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:uuid/uuid.dart';
import 'package:dating_app/models/chat_card.dart';
import 'package:dating_app/models/match.dart';
import 'package:dating_app/models/message.dart';
import 'package:dating_app/models/swipe_user.dart';
import 'package:dating_app/services/chat_service.dart';
import 'package:dating_app/services/session_socket_service.dart';
import 'package:dating_app/services/storage_service.dart';

class ChatProvider extends ChangeNotifier {
  bool _disposed = false;

  StreamSubscription<bool>? _connectionStateSubscription;
  StreamSubscription<Map<String, dynamic>>? _eventsSubscription;
  SessionSocketService? _socketService;

  Stream<Map<String, dynamic>> get socketEvents => _socketService?.events ?? const Stream.empty();
  DateTime? _lastListRefetch;
  static const _listRefetchMinInterval = Duration(seconds: 2);

  @override
  void dispose() {
    _disposed = true;
    _connectionStateSubscription?.cancel();
    _eventsSubscription?.cancel();
    _socketService?.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _safeNotify() {
    if (_disposed) return;
    // If the framework is locked in the middle of a build/layout/paint phase,
    // calling notifyListeners() throws "setState() or markNeedsBuild() called
    // when widget tree was locked". Defer to the next frame instead.
    final phase = WidgetsBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.transientCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  static const _uuid = Uuid();
  final _storageService = StorageService();

  // ── State ────────────────────────────────────────────────────────
  List<Match> _matches = [];
  List<ChatCard> _conversations = [];
  List<ChatCard> _pendingChats = [];
  List<ChatCard> _incomingChats = [];
  List<SwipeUser> _likedUsers = [];
  List<SwipeUser> _likers = [];
  List<Message> _messages = [];
  String? _activeMatchId;
  bool _isConnected = false;
  bool _isOtherUserOnline = false;
  DateTime? _otherUserLastSeenAt;
  bool _isTyping = false;
  int _chatsRemaining = 0;
  bool _isPremium = false;
  int _likesRemaining = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _sentCountInNewChat = 0;
  bool _isChatAccepted = false;
  String? _chatStatus;
  bool _amInitiator = false;
  bool _isAccepting = false;
  String? _userId;
  String? _editingMessageId;
  Timer? _typingTimer;
  final Set<String> _sentReadIds = {};
  bool _isBlocked = false;
  bool _isEnded = false;
  String? _peerId;

  int _matchesOffset = 0;
  String? _conversationsNextCursor;
  String? _pendingNextCursor;
  int _likersOffset = 0;
  int _likedOffset = 0;
  final Set<String> _seenConversationIds = {};
  final Set<String> _seenPendingIds = {};
  bool _hasMoreMatches = true;
  bool _hasMoreConversations = true;
  bool _hasMorePending = true;
  bool _hasMoreIncoming = true;
  bool _hasMoreLikers = true;
  bool _hasMoreLiked = true;
  static const _pageSize = 50;

  // ── Getters ──────────────────────────────────────────────────────
  List<Match> get matches => _matches;
  List<ChatCard> get conversations => _conversations;
  List<ChatCard> get pendingChats => _pendingChats;
  List<ChatCard> get incomingChats => _incomingChats;

  int get totalUnread {
    var total = 0;
    for (final card in _conversations) {
      total += card.unreadCount;
    }
    for (final card in _pendingChats) {
      total += card.unreadCount;
    }
    for (final card in _incomingChats) {
      total += card.unreadCount;
    }
    return total;
  }
  List<SwipeUser> get likedUsers => _likedUsers;
  List<SwipeUser> get likers => _likers;
  List<Message> get messages => _messages;
  String? get activeMatchId => _activeMatchId;
  bool get isConnected => _isConnected;
  bool get isOtherUserOnline => _isOtherUserOnline;
  DateTime? get otherUserLastSeenAt => _otherUserLastSeenAt;
  bool get isTyping => _isTyping;
  int get chatsRemaining => _chatsRemaining;
  bool get isPremium => _isPremium;
  int get likesRemaining => _likesRemaining;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  bool get hasMoreMatches => _hasMoreMatches;
  bool get hasMoreConversations => _hasMoreConversations;
  bool get hasMorePending => _hasMorePending;
  bool get hasMoreIncoming => _hasMoreIncoming;
  bool get hasMoreLikers => _hasMoreLikers;
  bool get hasMoreLiked => _hasMoreLiked;
  String? get editingMessageId => _editingMessageId;
  bool get isChatAccepted => _isChatAccepted;
  bool get isAccepting => _isAccepting;
  bool get isBlocked => _isBlocked;
  bool get isEnded => _isEnded;
  String? get peerId => _peerId;

  /// Whether this conversation is over (blocked or ended) — the UI shows a
  /// "This conversation is over" banner and disables the composer.
  bool get conversationIsOver => _isBlocked || _isEnded;
  bool get isInitiator => _amInitiator;
  bool get isPending => _chatStatus == 'pending';
  bool get isRecipientWaiting => isPending && !_amInitiator;
  bool get isInitiatorWaiting => isPending && _amInitiator && isChatBlocked;
  bool get isChatBlocked => !_isChatAccepted && isPending && _amInitiator && _sentCountInNewChat >= 2;

  bool get canSendMessage {
    if (conversationIsOver) return false;
    if (_isPremium) return true;
    if (_isChatAccepted) return true;
    if (_chatStatus == null) {
      // Status not (yet) confirmed — never hard-block. Allow while under the
      // cap, or if the other side has already replied (effectively accepted).
      return _sentCountInNewChat < 2 || _hasReceivedMessage;
    }
    if (isPending && _amInitiator) return _sentCountInNewChat < 2;
    return false;
  }

  bool get _hasReceivedMessage => _messages.any((m) => m.senderId != _userId);

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
    _conversationsNextCursor = null;
    _seenConversationIds.clear();
    _hasMoreConversations = true;
    _safeNotify();

    try {
      final response = await ChatService.getChats(
        limit: _pageSize,
        offset: 0,
        status: 'accepted',
      );
      final data = response.data;
      if (response.statusCode == 200) {
        final items = (data['chats'] ?? data ?? []) as List;
        _conversations = items.map((j) => ChatCard.fromJson(j)).toList();
        _seenConversationIds.addAll(_conversations.map((c) => c.id));
        final next = data['next_cursor'] as String?;
        _conversationsNextCursor =
            (next != null && next.isNotEmpty) ? next : null;
        _hasMoreConversations = _conversationsNextCursor != null ||
            data['next_offset'] != null;
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
      final response = await ChatService.getChats(
        limit: _pageSize,
        status: 'accepted',
        cursor: _conversationsNextCursor,
      );
      if (response.statusCode == 200) {
        final data = response.data;
        final items = (data['chats'] ?? data ?? []) as List;
        final newConversations = items
            .map((j) => ChatCard.fromJson(j))
            .where((c) => _seenConversationIds.add(c.id))
            .toList();
        _conversations.addAll(newConversations);
        final next = data['next_cursor'] as String?;
        _conversationsNextCursor =
            (next != null && next.isNotEmpty) ? next : null;
        _hasMoreConversations = _conversationsNextCursor != null ||
            data['next_offset'] != null;
      }
    } catch (e) {
      // silent
    }

    _isLoadingMore = false;
    _safeNotify();
  }

  // ── Pending & Incoming ──────────────────────────────────────────
  /// Loads all pending chats and splits them by direction:
  /// - Pending = I started the chat (initiator).
  /// - Incoming = they started it (I'm the recipient).
  Future<void> loadPendingIncoming() async {
    _isLoading = true;
    _errorMessage = null;
    _pendingNextCursor = null;
    _seenPendingIds.clear();
    _hasMorePending = true;
    _hasMoreIncoming = true;
    _safeNotify();

    try {
      final myUserId = await _storageService.getUserId();
      final response = await ChatService.getChats(
        limit: _pageSize,
        offset: 0,
        status: 'pending',
      );
      final data = response.data;
      if (response.statusCode == 200) {
        final items = (data['chats'] ?? data ?? []) as List;
        final all = items.map((j) => ChatCard.fromJson(j)).toList();
        _seenPendingIds.addAll(all.map((c) => c.id));
        _pendingChats = all.where((c) => c.initiatorId == myUserId).toList();
        _incomingChats =
            all.where((c) => c.initiatorId != myUserId).toList();
        final next = data['next_cursor'] as String?;
        _pendingNextCursor = (next != null && next.isNotEmpty) ? next : null;
        _hasMorePending = _pendingNextCursor != null ||
            data['next_offset'] != null;
        _hasMoreIncoming = _pendingNextCursor != null ||
            data['next_offset'] != null;
      } else {
        _errorMessage = data?['detail'] ?? 'Failed to load chats';
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    _safeNotify();
  }

  Future<void> loadMorePendingIncoming() async {
    if (_isLoadingMore || (!_hasMorePending && !_hasMoreIncoming)) return;
    _isLoadingMore = true;
    _safeNotify();

    try {
      final myUserId = await _storageService.getUserId();
      final response = await ChatService.getChats(
        limit: _pageSize,
        status: 'pending',
        cursor: _pendingNextCursor,
      );
      if (response.statusCode == 200) {
        final data = response.data;
        final items = (data['chats'] ?? data ?? []) as List;
        final newChats = items
            .map((j) => ChatCard.fromJson(j))
            .where((c) => _seenPendingIds.add(c.id))
            .toList();
        final newPending =
            newChats.where((c) => c.initiatorId == myUserId).toList();
        final newIncoming =
            newChats.where((c) => c.initiatorId != myUserId).toList();
        _pendingChats.addAll(newPending);
        _incomingChats.addAll(newIncoming);
        final next = data['next_cursor'] as String?;
        _pendingNextCursor = (next != null && next.isNotEmpty) ? next : null;
        _hasMorePending = _pendingNextCursor != null ||
            data['next_offset'] != null;
        _hasMoreIncoming = _pendingNextCursor != null ||
            data['next_offset'] != null;
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
  Future<void> loadMessages(
    String identifier, {
    String? initialStatus,
    String? initialInitiatorId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _messages = [];
    _activeMatchId = identifier;
    _sentCountInNewChat = 0;
    _userId = await _storageService.getUserId();
    _isChatAccepted = initialStatus == 'accepted';
    _chatStatus = initialStatus;
    _amInitiator = _userId != null && initialInitiatorId == _userId;
    _safeNotify();

    // Fetch the authoritative chat status (accepted / pending) + direction.
    // On success it overwrites the seeded values; on failure the seed stays.
    await _loadChatDetail(identifier);

    try {
      final response = await ChatService.getChatHistory(identifier);
      if (response.statusCode == 200) {
        final data = response.data;
        final items =
            (data['items'] ?? data['messages'] ?? data ?? []) as List;
        _messages = items.map((j) => Message.fromJson(j)).toList();

        // Count my sent messages when the chat is still pending and I am the
        // initiator (limit ≤ 2 until it is accepted). For accepted chats the
        // count is irrelevant — sending is unlimited.
        if (isPending && _amInitiator) {
          _sentCountInNewChat =
              _messages.where((m) => m.senderId == _userId).length;
        }

        // Mark unread messages as delivered
        if (_userId != null) {
          final unreadIds = _messages
              .where((m) => m.receiverId == _userId && !m.isDelivered)
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

    // Opening the chat means the peer's messages are visible → mark read,
    // push a realtime read receipt, and clear the list unread badge.
    markVisibleMessagesRead();
  }

  /// Loads the authoritative chat status + direction from `GET /chats/{id}`.
  /// Used to decide whether the user can send, must accept, or is waiting.
  Future<void> _loadChatDetail(String chatId) async {
    try {
      final response = await ChatService.getChatDetail(chatId);
      if (response.statusCode == 200) {
        final data = response.data;
        final status = data['status'] as String?;
        if (status != null) {
          _chatStatus = status;
          _isChatAccepted = status == 'accepted';
        }
        final initiatorId = data['initiator_id'] as String?;
        if (initiatorId != null) {
          _amInitiator = _userId != null && initiatorId == _userId;
        }
        final other = data['user'] as Map<String, dynamic>?;
        if (other != null) {
          _peerId = other['id'] as String?;
        }
        _isBlocked = data['is_blocked'] == true;
        _isEnded = data['is_ended'] == true;
      }
      // On failure (or non-200) keep whatever status was seeded so a
      // transient chat-detail error never disables sending.
    } catch (e) {
      // keep seeded status
    }
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

  // ── Block / Report / Delete chat ─────────────────────────────────
  Future<bool> blockUser(String userId) async {
    try {
      final response = await ChatService.blockUser(userId);
      if (response.statusCode == 204 || response.statusCode == 200) {
        _isBlocked = true;
        _safeNotify();
        return true;
      }
      _errorMessage = response.data['detail'] ?? 'Block failed';
      _safeNotify();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _safeNotify();
      return false;
    }
  }

  Future<bool> unblockUser(String userId) async {
    try {
      final response = await ChatService.unblockUser(userId);
      if (response.statusCode == 204 || response.statusCode == 200) {
        _isBlocked = false;
        _safeNotify();
        return true;
      }
      _errorMessage = response.data['detail'] ?? 'Unblock failed';
      _safeNotify();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _safeNotify();
      return false;
    }
  }

  Future<bool> reportMessage(
    String messageId, {
    required String reason,
    String? description,
  }) async {
    try {
      final response = await ChatService.reportMessage(
        messageId,
        reason,
        description: description,
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      }
      _errorMessage = response.data['detail'] ?? 'Report failed';
      _safeNotify();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _safeNotify();
      return false;
    }
  }

  Future<bool> reportUser(String userId, String reason) async {
    try {
      final response = await ChatService.reportUser(userId, reason);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      }
      _errorMessage = response.data['detail'] ?? 'Report failed';
      _safeNotify();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _safeNotify();
      return false;
    }
  }

  /// Deletes a chat for the current user and refreshes the lists so the card
  /// disappears (the other side keeps it, marked ended).
  Future<bool> deleteChat(String chatId) async {
    try {
      final response = await ChatService.deleteChat(chatId);
      if (response.statusCode == 204 || response.statusCode == 200) {
        _conversations.removeWhere((c) => c.id == chatId);
        _pendingChats.removeWhere((c) => c.id == chatId);
        _incomingChats.removeWhere((c) => c.id == chatId);
        _isEnded = true;
        _safeNotify();
        return true;
      }
      _errorMessage = response.data['detail'] ?? 'Delete chat failed';
      _safeNotify();
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

  /// Marks the peer's unread messages in the currently-open chat as read:
  /// persists via HTTP, pushes a realtime `read` frame over WS (so the sender
  /// sees the blue check immediately), updates local state, and clears the
  /// chat's unread badge in the list. Idempotent — each message id is sent
  /// once so bursts don't re-fire on every frame.
  Future<void> markVisibleMessagesRead() async {
    final active = _activeMatchId;
    if (active == null) return;
    final userId = await _storageService.getUserId();
    if (userId == null) return;

    final newlyRead = _messages
        .where((m) =>
            m.receiverId == userId && !m.isRead && !_sentReadIds.contains(m.id))
        .toList();
    if (newlyRead.isEmpty) return;
    final ids = newlyRead.map((m) => m.id).toList();

    for (final m in newlyRead) {
      final index = _messages.indexWhere((e) => e.id == m.id);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(isRead: true);
      }
    }
    _sentReadIds.addAll(ids);
    _safeNotify();

    _socketService?.sendReadReceipt(active, ids);
    _resetChatUnread(active);
    try {
      await ChatService.markRead(ids);
    } catch (e) {
      // silent
    }
  }

  /// Resets a chat card's unread badge to zero (its messages were just read).
  void _resetChatUnread(String chatId) {
    void patch(List<ChatCard> list) {
      final index = list.indexWhere((c) => c.id == chatId);
      if (index != -1) {
        list[index] = list[index].copyWith(unreadCount: 0);
      }
    }

    patch(_conversations);
    patch(_pendingChats);
    patch(_incomingChats);
    _safeNotify();
  }

  /// Keeps conversation-card online state live by forwarding a peer's
  /// user_online/user_offline presence event onto the matching card.
  void _applyUserPresence(
    String userId, {
    required bool isOnline,
    String? lastSeenAt,
  }) {
    void patch(List<ChatCard> list) {
      for (var i = 0; i < list.length; i++) {
        final card = list[i];
        if (card.user.id == userId) {
          list[i] = card.copyWith(
            user: card.user.copyWith(
              isOnline: isOnline,
              lastSeenAt: lastSeenAt,
            ),
          );
          _safeNotify();
        }
      }
    }

    patch(_conversations);
    patch(_pendingChats);
    patch(_incomingChats);
  }
  /// Accepts a pending chat (moves it from Pending/Incoming to
  /// Conversations). Callers can refresh lists or rely on real-time events.
  Future<bool> acceptChat(String chatId) async {
    if (_isAccepting) return false;
    _isAccepting = true;
    _safeNotify();
    try {
      final response = await ChatService.acceptChat(chatId);
      if (response.statusCode == 200 || response.statusCode == 201) {
        _chatStatus = 'accepted';
        _isChatAccepted = true;
        _pendingChats.removeWhere((c) => c.id == chatId);
        _incomingChats.removeWhere((c) => c.id == chatId);
        loadConversations();
        _safeNotify();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _safeNotify();
      return false;
    } finally {
      _isAccepting = false;
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
  /// Opens the single persistent session socket (/ws/stream). Called once at
  /// app start; stays open until logout/app exit. All realtime events arrive
  /// here. Opening/changing/leaving a chat just sends subscribe/unsubscribe
  /// frames on this same connection.
  Future<void> connectSessionSocket() async {
    final token = await _storageService.getAccessToken();
    if (token == null) return;

    await _socketService?.dispose();
    _socketService = SessionSocketService(jwtToken: token);

    _connectionStateSubscription = _socketService!.connectionState.listen((
      connected,
    ) {
      _isConnected = connected;
      _safeNotify();
      if (!connected) return;
      // Re-sync lists + re-subscribe the open chat on (re)connect.
      _refetchChatLists(debounced: false);
      final active = _activeMatchId;
      if (active != null) {
        _socketService!.subscribe(active);
      }
    });

    _eventsSubscription = _socketService!.events.listen((event) {
      _handleSocketEvent(event);
    });

    await _socketService!.connect();
  }

  /// Opens a chat: subscribes the session socket to its topic and records it
  /// as the active chat so realtime events are dispatched to it.
  Future<void> subscribeChat(String chatId) async {
    _activeMatchId = chatId;
    _socketService?.subscribe(chatId);
    _safeNotify();
  }

  void _handleSocketEvent(Map<String, dynamic> event) {
    final type = event['type'] as String?;
    final data = event['data'] as Map<String, dynamic>? ?? {};

    switch (type) {
      case 'new_message':
        if (_isEventForActiveChat(event, data)) {
          _handleNewMessage(data);
        }
        break;

      case 'typing':
        if (_isEventForActiveChat(event, data)) {
          _isTyping = true;
          _safeNotify();
          _resetTypingTimer();
        }
        break;

      case 'typing_stopped':
        if (_isEventForActiveChat(event, data)) {
          _isTyping = false;
          _safeNotify();
        }
        break;

      case 'user_online':
        final onlineUserId = (event['user_id'] ?? data['user_id']) as String?;
        if (onlineUserId != null) {
          _applyUserPresence(onlineUserId, isOnline: true);
        }
        if (_isEventForActiveChat(event, data)) {
          _isOtherUserOnline = true;
          _safeNotify();
        }
        break;

      case 'user_offline':
        final offlineUserId = (event['user_id'] ?? data['user_id']) as String?;
        if (offlineUserId != null) {
          final raw = (event['last_seen_at'] ?? data['last_seen_at']) as String?;
          _applyUserPresence(offlineUserId, isOnline: false, lastSeenAt: raw);
        }
        if (_isEventForActiveChat(event, data)) {
          _isOtherUserOnline = false;
          final raw = (event['last_seen_at'] ?? data['last_seen_at']) as String?;
          if (raw != null && raw.isNotEmpty) {
            _otherUserLastSeenAt = DateTime.tryParse(raw);
          }
          _safeNotify();
        }
        break;

      case 'messages_read':
        if (_isEventForActiveChat(event, data)) {
          _handleMessagesRead({
            'message_ids': List<String>.from(
              event['message_ids'] ?? data['message_ids'] ?? [],
            ),
          });
        }
        break;

      case 'chat_updated':
        _applyChatUpdated(data);
        break;

      case 'new_chat':
      case 'chat_accepted':
        // If the accepted chat is currently open, reflect the new status now.
        if (type == 'chat_accepted' && _isEventForActiveChat(event, data)) {
          _chatStatus = 'accepted';
          _isChatAccepted = true;
        }
        _refetchChatLists(debounced: true);
        break;

      case 'new_match':
        handleNewMatch(data);
        break;

      case 'new_notification':
        _handleNewNotification(data);
        break;

      case 'blocked':
        _handleBlockedEvent(event, data);
        break;

      case 'chat_ended':
        _handleChatEndedEvent(event, data);
        break;

      case 'message_edited':
        _handleMessageEdited(data);
        break;

      default:
        break;
    }
  }

  bool _isEventForActiveChat(Map<String, dynamic> event, Map<String, dynamic> data) {
    final active = _activeMatchId;
    if (active == null) return false;
    final chatId = (event['chat_id'] ?? data['chat_id']) as String?;
    // Chat-channel events always reference their chat; if present it must
    // match the open chat. (No chat id → defensive true.)
    return chatId == null || chatId == active;
  }

  /// Applies a chat_updated event to the list in place (preview, unread,
  /// reorder) so the chat list updates without an HTTP refresh.
  void _applyChatUpdated(Map<String, dynamic> data) {
    final chatId = data['chat_id'] as String?;
    if (chatId == null) return;

    final status = data['status'] as String?;
    final unread = (data['unread_count'] as num?)?.toInt() ?? 0;
    final updatedAt = DateTime.tryParse(data['updated_at'] as String? ?? '');

    ChatLastMessage? lastMessage;
    final lm = data['last_message'] as Map<String, dynamic>?;
    if (lm != null) {
      lastMessage = ChatLastMessage(
        content: lm['content'] as String?,
        messageType: lm['message_type'] as String? ?? 'text',
        isSent: true,
        isRead: false,
        sentAt: DateTime.tryParse(lm['sent_at'] as String? ?? '') ?? DateTime.now(),
      );
    }

    bool found = false;
    void patch(List<ChatCard> list) {
      final index = list.indexWhere((c) => c.id == chatId);
      if (index == -1) return;
      found = true;
      list[index] = list[index].copyWith(
        status: status,
        lastMessage: lastMessage,
        unreadCount: unread,
        updatedAt: updatedAt,
      );
    }

    patch(_conversations);
    patch(_pendingChats);
    patch(_incomingChats);

    int cardTs(ChatCard c) =>
        (c.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .millisecondsSinceEpoch;
    _conversations.sort((a, b) => cardTs(b).compareTo(cardTs(a)));
    _pendingChats.sort((a, b) => cardTs(b).compareTo(cardTs(a)));
    _incomingChats.sort((a, b) => cardTs(b).compareTo(cardTs(a)));

    _safeNotify();

    if (!found) {
      // Conversation not loaded yet — fetch to render it accurately.
      _refetchChatLists(debounced: false);
    }
  }

  void _refetchChatLists({required bool debounced}) {
    if (debounced) {
      final now = DateTime.now();
      if (_lastListRefetch != null &&
          now.difference(_lastListRefetch!) < _listRefetchMinInterval) {
        return;
      }
      _lastListRefetch = now;
    }
    loadConversations();
    loadPendingIncoming();
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

    // The chat is open/visible → immediately mark the peer's message as
    // read and push a realtime read receipt + clear the list unread badge.
    if (message.senderId != _userId) {
      markVisibleMessagesRead();
    }
  }

  void _handleBlockedEvent(
    Map<String, dynamic> event,
    Map<String, dynamic> data,
  ) {
    final userId = (event['user_id'] ?? data['user_id']) as String?;
    if (userId != null && peerId != null && userId == peerId) {
      _isBlocked = true;
    }
    _safeNotify();
    _refetchChatLists(debounced: true);
  }

  void _handleChatEndedEvent(
    Map<String, dynamic> event,
    Map<String, dynamic> data,
  ) {
    final chatId = (event['chat_id'] ?? data['chat_id']) as String?;
    if (chatId != null && chatId == _activeMatchId) {
      _isEnded = true;
    }
    _safeNotify();
    _refetchChatLists(debounced: true);
  }

  void _handleMessageEdited(Map<String, dynamic> data) {
    final messageId = data['id'] as String?;
    if (messageId == null) return;
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;
    _messages[index] = _messages[index].copyWith(
      content: data['content'] as String? ?? _messages[index].content,
      isEdited: (data['is_edited'] as bool?) ?? true,
    );
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

  @visibleForTesting
  void applyBlockedEvent(
    Map<String, dynamic> event,
    Map<String, dynamic> data,
  ) =>
      _handleBlockedEvent(event, data);

  @visibleForTesting
  void applyChatEndedEvent(
    Map<String, dynamic> event,
    Map<String, dynamic> data,
  ) =>
      _handleChatEndedEvent(event, data);

  @visibleForTesting
  void applyMessageEdited(Map<String, dynamic> data) =>
      _handleMessageEdited(data);

  void _handleNewNotification(Map<String, dynamic> data) {
    debugPrint('WS new_notification: $data');
    // NotificationProvider will listen to socketEvents and handle this
    // This method is a no-op in ChatProvider; NotificationsProvider subscribes directly to socketEvents
  }

  void handleNewMatch(Map<String, dynamic> data) {
    try {
      final chat = ChatCard.fromJson(data);
      if (!_conversations.any((c) => c.id == chat.id)) {
        _conversations.insert(0, chat);
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
    final id = _activeMatchId;
    if (id != null) _socketService?.sendTyping(id);
  }

  void stopTyping() {
    final id = _activeMatchId;
    if (id != null) _socketService?.sendTypingStopped(id);
  }

  // ── Clear ────────────────────────────────────────────────────────
  void clearActiveChat() {
    final active = _activeMatchId;
    if (active != null) {
      _socketService?.unsubscribe(active);
    }
    _activeMatchId = null;
    _messages = [];
    _editingMessageId = null;
    _isTyping = false;
    _isOtherUserOnline = false;
    _sentCountInNewChat = 0;
    _isChatAccepted = false;
    _chatStatus = null;
    _amInitiator = false;
    _isAccepting = false;
    _isBlocked = false;
    _isEnded = false;
    _peerId = null;
    _safeNotify();
  }
}
