import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/generated/app_localizations.dart';
import 'package:dating_app/models/ticket.dart';
import 'package:dating_app/providers/ticket_provider.dart';
import 'package:dating_app/utils/relative_time.dart';
import 'package:dating_app/widgets/action_toast.dart';
import 'package:intl/intl.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TicketProvider>(context, listen: false)
          .loadTicket(widget.ticketId);
    });
  }

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final provider = Provider.of<TicketProvider>(context, listen: false);
    final content = _replyController.text.trim();
    if (content.isEmpty) return;

    final ok = await provider.replyToTicket(widget.ticketId, content);
    if (!mounted) return;

    if (ok) {
      _replyController.clear();
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } else {
      showActionToast(
        context,
        provider.errorMessage ??
            AppLocalizations.of(context)!.ticket_load_error,
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          t.support,
          style: TextStyle(
            fontFamily: AppTheme.fontFor(
              !Localizations.localeOf(
                context,
              ).languageCode.contains('en'),
            ),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: onSurfaceColor,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<TicketProvider>(
        builder: (context, provider, _) {
          final ticket = provider.currentTicket;

          if (provider.isDetailLoading && ticket == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (ticket == null) {
            return _buildError(t, isDark, onSurfaceColor);
          }

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryGradientStart.withValues(alpha: 0.04),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    children: [
                      _buildStatusBanner(ticket, t, isDark),
                      if (ticket.isClosed) ...[
                        const SizedBox(height: 8),
                        _buildClosedNote(t, isDark),
                      ],
                      const SizedBox(height: 16),
                      _buildHeader(ticket, t, isDark, onSurfaceColor),
                      const SizedBox(height: 16),
                      if (ticket.messages.isEmpty)
                        _buildNoMessages(t, isDark)
                      else
                        ...ticket.messages.map(
                          (m) => _buildBubble(context, m, t, isDark),
                        ),
                    ],
                  ),
                ),
                _buildComposer(context, provider, t, isDark),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBanner(Ticket ticket, AppLocalizations t, bool isDark) {
    final (color, label) = _statusInfo(ticket.status, t, isDark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFor(
                !Localizations.localeOf(
                  context,
                ).languageCode.contains('en'),
              ),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  (Color, String) _statusInfo(String status, AppLocalizations t, bool isDark) {
    switch (status) {
      case 'in_progress':
        return (
          isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
          t.ticket_status_in_progress,
        );
      case 'closed':
        return (
          isDark ? AppTheme.darkSuccess : AppTheme.lightSuccess,
          t.ticket_status_closed,
        );
      default:
        return (
          isDark ? AppTheme.darkWarning : AppTheme.lightWarning,
          t.ticket_status_open,
        );
    }
  }

  Widget _buildClosedNote(AppLocalizations t, bool isDark) {
    final textMutedColor =
        isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline,
            size: 16,
            color: textMutedColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              t.ticket_closed_note,
              style: TextStyle(
                fontFamily: AppTheme.fontFor(
                  !Localizations.localeOf(
                    context,
                  ).languageCode.contains('en'),
                ),
                fontSize: 12,
                color: textMutedColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    Ticket ticket,
    AppLocalizations t,
    bool isDark,
    Color onSurfaceColor,
  ) {
    final textMutedColor =
        isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ticket.subject,
            style: TextStyle(
              fontFamily: AppTheme.fontFor(
                !Localizations.localeOf(
                  context,
                ).languageCode.contains('en'),
              ),
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: onSurfaceColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            relativeTime(ticket.createdAt, t),
            style: TextStyle(
              fontFamily: AppTheme.fontFor(
                !Localizations.localeOf(
                  context,
                ).languageCode.contains('en'),
              ),
              fontSize: 12,
              color: textMutedColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoMessages(AppLocalizations t, bool isDark) {
    final textMutedColor =
        isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        t.ticket_reply_hint,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppTheme.fontFor(
            !Localizations.localeOf(context).languageCode.contains('en'),
          ),
          fontSize: 13,
          fontStyle: FontStyle.italic,
          color: textMutedColor,
        ),
      ),
    );
  }

  Widget _buildBubble(
    BuildContext context,
    TicketMessage message,
    AppLocalizations t,
    bool isDark,
  ) {
    final isAdmin = message.isFromAdmin;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final surfaceColor =
        isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final mutedColor =
        isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');

    return Align(
      alignment: isAdmin ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.only(
          left: 14,
          right: 14,
          top: 8,
          bottom: 6,
        ),
        decoration: BoxDecoration(
          color: isAdmin
              ? surfaceColor
              : (isDark
                  ? AppTheme.darkPrimary.withValues(alpha: 0.85)
                  : primaryColor),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isAdmin ? 4 : 18),
            bottomRight: Radius.circular(isAdmin ? 18 : 4),
          ),
          border: isAdmin
              ? Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: isAdmin
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          children: [
            if (isAdmin) ...[
              Text(
                message.adminName != null && message.adminName!.isNotEmpty
                    ? message.adminName!
                    : t.ticket_support_team,
                style: TextStyle(
                  fontFamily: AppTheme.fontFor(isPersian),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 2),
            ],
            Text(
              message.content,
              style: TextStyle(
                fontFamily: AppTheme.fontFor(isPersian),
                fontSize: 15,
                color: isAdmin ? textColor : Colors.white,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('HH:mm').format(message.createdAt),
              style: TextStyle(
                fontFamily: AppTheme.fontFor(isPersian),
                fontSize: 10,
                color: isAdmin
                    ? mutedColor
                    : Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer(
    BuildContext context,
    TicketProvider provider,
    AppLocalizations t,
    bool isDark,
  ) {
    final surfaceColor =
        isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final borderColor =
        isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final mutedColor =
        isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;

    final canSend = _replyController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(
          top: BorderSide(color: borderColor, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkBackground
                      : AppTheme.lightBackground,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: TextField(
                  controller: _replyController,
                  maxLines: 4,
                  minLines: 1,
                  maxLength: 2000,
                  textInputAction: TextInputAction.newline,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                    fontFamily: AppTheme.fontFor(
                      !Localizations.localeOf(
                        context,
                      ).languageCode.contains('en'),
                    ),
                    fontSize: 15,
                    color: textColor,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    isDense: true,
                    hintText: t.ticket_reply_hint,
                    hintStyle: TextStyle(
                      fontFamily: AppTheme.fontFor(
                        !Localizations.localeOf(
                          context,
                        ).languageCode.contains('en'),
                      ),
                      fontSize: 15,
                      color: mutedColor,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: (canSend && !provider.isReplying) ? _sendReply : null,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: canSend && !provider.isReplying
                      ? primaryColor
                      : Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: provider.isReplying
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(Icons.send, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(
    AppLocalizations t,
    bool isDark,
    Color onSurfaceColor,
  ) {
    final textMutedColor =
        isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: isDark ? AppTheme.darkError : AppTheme.lightError,
            ),
            const SizedBox(height: 12),
            Text(
              t.ticket_load_error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFor(
                  !Localizations.localeOf(
                    context,
                  ).languageCode.contains('en'),
                ),
                fontSize: 14,
                color: textMutedColor,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Provider.of<TicketProvider>(
                context,
                listen: false,
              ).loadTicket(widget.ticketId),
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: TextStyle(
                  fontFamily: AppTheme.fontFor(
                    !Localizations.localeOf(
                      context,
                    ).languageCode.contains('en'),
                  ),
                  color: onSurfaceColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}