import 'package:flutter/material.dart';
import 'package:dating_app/models/ticket.dart';
import 'package:dating_app/services/ticket_service.dart';

class TicketProvider extends ChangeNotifier {
  bool _disposed = false;

  static const _pageSize = 20;

  // ── List state ───────────────────────────────────────────────────
  List<Ticket> _tickets = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _nextOffset = 0;
  bool _hasMore = true;

  // ── Detail / create / reply state ────────────────────────────────
  Ticket? _currentTicket;
  bool _isDetailLoading = false;
  bool _isCreating = false;
  bool _isReplying = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  // ── Getters ──────────────────────────────────────────────────────
  List<Ticket> get tickets => List.unmodifiable(_tickets);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;
  Ticket? get currentTicket => _currentTicket;
  bool get isDetailLoading => _isDetailLoading;
  bool get isCreating => _isCreating;
  bool get isReplying => _isReplying;

  // ── List ─────────────────────────────────────────────────────────
  Future<bool> loadTickets() async {
    _isLoading = true;
    _errorMessage = null;
    _nextOffset = 0;
    _hasMore = true;
    _safeNotify();

    try {
      final response = await TicketService.getMyTickets(
        limit: _pageSize,
        offset: 0,
      );
      if (response.statusCode == 200) {
        final page = TicketPage.fromJson(response.data);
        _tickets = page.tickets;
        _nextOffset = page.nextOffset ?? 0;
        _hasMore = page.nextOffset != null;
        _isLoading = false;
        _safeNotify();
        return true;
      } else {
        _errorMessage =
            response.data?['detail'] ?? 'Failed to load tickets';
        _isLoading = false;
        _safeNotify();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      _safeNotify();
      return false;
    }
  }

  Future<void> loadMoreTickets() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    _safeNotify();

    try {
      final response = await TicketService.getMyTickets(
        limit: _pageSize,
        offset: _nextOffset,
      );
      if (response.statusCode == 200) {
        final page = TicketPage.fromJson(response.data);
        final seen = _tickets.map((t) => t.id).toSet();
        _tickets.addAll(page.tickets.where((t) => seen.add(t.id)));
        _nextOffset = page.nextOffset ?? 0;
        _hasMore = page.nextOffset != null;
      }
    } catch (e) {
      // silent
    }

    _isLoadingMore = false;
    _safeNotify();
  }

  // ── Create ───────────────────────────────────────────────────────
  Future<bool> createTicket(String subject, String message) async {
    _isCreating = true;
    _errorMessage = null;
    _safeNotify();

    try {
      final response = await TicketService.createTicket(subject, message);
      if (response.statusCode == 201 || response.statusCode == 200) {
        final ticket = Ticket.fromJson(response.data);
        _tickets.insert(0, ticket);
        _isCreating = false;
        _safeNotify();
        return true;
      } else {
        _errorMessage =
            response.data?['detail'] ?? 'Failed to create ticket';
        _isCreating = false;
        _safeNotify();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isCreating = false;
      _safeNotify();
      return false;
    }
  }

  // ── Detail ───────────────────────────────────────────────────────
  Future<bool> loadTicket(String id) async {
    _isDetailLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      final response = await TicketService.getTicket(id);
      if (response.statusCode == 200) {
        _currentTicket = Ticket.fromJson(response.data);
        _isDetailLoading = false;
        _safeNotify();
        return true;
      } else {
        _errorMessage = response.data?['detail'] ?? 'Failed to load ticket';
        _isDetailLoading = false;
        _safeNotify();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isDetailLoading = false;
      _safeNotify();
      return false;
    }
  }

  // ── Reply ────────────────────────────────────────────────────────
  Future<bool> replyToTicket(String id, String content) async {
    _isReplying = true;
    _errorMessage = null;
    _safeNotify();

    try {
      final response = await TicketService.replyToTicket(id, content);
      if (response.statusCode == 201 || response.statusCode == 200) {
        final ticket = Ticket.fromJson(response.data);
        _currentTicket = ticket;
        final index = _tickets.indexWhere((t) => t.id == id);
        if (index != -1) {
          _tickets[index] = ticket;
        }
        _isReplying = false;
        _safeNotify();
        return true;
      } else {
        _errorMessage = response.data?['detail'] ?? 'Failed to send reply';
        _isReplying = false;
        _safeNotify();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isReplying = false;
      _safeNotify();
      return false;
    }
  }

  void clearCurrent() {
    _currentTicket = null;
    _errorMessage = null;
    _safeNotify();
  }

  void clearError() {
    _errorMessage = null;
    _safeNotify();
  }
}