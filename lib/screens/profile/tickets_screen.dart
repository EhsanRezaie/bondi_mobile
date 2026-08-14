import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/generated/app_localizations.dart';
import 'package:dating_app/models/ticket.dart';
import 'package:dating_app/providers/ticket_provider.dart';
import 'package:dating_app/screens/profile/create_ticket_screen.dart';
import 'package:dating_app/screens/profile/ticket_detail_screen.dart';
import 'package:dating_app/utils/responsive.dart';
import 'package:dating_app/utils/relative_time.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TicketProvider>(context, listen: false).loadTickets();
    });
  }

  Future<void> _refresh() async {
    final provider = Provider.of<TicketProvider>(context, listen: false);
    await provider.loadTickets();
  }

  Future<void> _openCreate() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateTicketScreen()),
    );
    if (created == true && mounted) {
      Provider.of<TicketProvider>(context, listen: false).loadTickets();
    }
  }

  void _openDetail(Ticket ticket) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TicketDetailScreen(ticketId: ticket.id),
      ),
    );
  }

  Color _statusColor(String status, bool isDark) {
    switch (status) {
      case 'in_progress':
        return isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
      case 'closed':
        return isDark ? AppTheme.darkSuccess : AppTheme.lightSuccess;
      default:
        return isDark ? AppTheme.darkWarning : AppTheme.lightWarning;
    }
  }

  String _statusLabel(String status, AppLocalizations t) {
    switch (status) {
      case 'in_progress':
        return t.ticket_status_in_progress;
      case 'closed':
        return t.ticket_status_closed;
      default:
        return t.ticket_status_open;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.my_tickets,
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
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: _buildBody(context, provider, isDark, onSurfaceColor),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  8,
                  24,
                  AppLayout.floatingNavClearance,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _openCreate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.new_ticket,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFor(
                          !Localizations.localeOf(
                            context,
                          ).languageCode.contains('en'),
                        ),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    TicketProvider provider,
    bool isDark,
    Color onSurfaceColor,
  ) {
    final t = AppLocalizations.of(context)!;

    if (provider.isLoading && provider.tickets.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && provider.tickets.isEmpty) {
      return _buildError(t, isDark, onSurfaceColor);
    }

    if (provider.tickets.isEmpty) {
      return _buildEmpty(t, isDark, onSurfaceColor);
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      itemCount: provider.tickets.length + (provider.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= provider.tickets.length) {
          if (provider.isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            );
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Provider.of<TicketProvider>(context, listen: false)
                .loadMoreTickets();
          });
          return const SizedBox.shrink();
        }
        final ticket = provider.tickets[index];
        return _buildTicketTile(context, ticket, isDark, onSurfaceColor);
      },
    );
  }

  Widget _buildTicketTile(
    BuildContext context,
    Ticket ticket,
    bool isDark,
    Color onSurfaceColor,
  ) {
    final t = AppLocalizations.of(context)!;
    final textMutedColor =
        isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;
    final statusColor = _statusColor(ticket.status, isDark);

    return InkWell(
      onTap: () => _openDetail(ticket),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    ticket.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFor(
                        !Localizations.localeOf(
                          context,
                        ).languageCode.contains('en'),
                      ),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: onSurfaceColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _statusLabel(ticket.status, t),
                    style: TextStyle(
                      fontFamily: AppTheme.fontFor(
                        !Localizations.localeOf(
                          context,
                        ).languageCode.contains('en'),
                      ),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              ticket.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTheme.fontFor(
                  !Localizations.localeOf(
                    context,
                  ).languageCode.contains('en'),
                ),
                fontSize: 13,
                color: textMutedColor,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 13,
                  color: textMutedColor.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  relativeTime(ticket.updatedAt ?? ticket.createdAt, t),
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
                const Spacer(),
                if (ticket.messages.isNotEmpty)
                  Text(
                    '${ticket.messages.length}',
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
                const SizedBox(width: 2),
                Icon(
                  Icons.chat_bubble_outline,
                  size: 14,
                  color: textMutedColor.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: textMutedColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(
    AppLocalizations t,
    bool isDark,
    Color onSurfaceColor,
  ) {
    final textMutedColor =
        isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 16),
      children: [
        const SizedBox(height: 40),
        Icon(
          Icons.headset_mic_outlined,
          size: 72,
          color: textMutedColor.withValues(alpha: 0.6),
        ),
        const SizedBox(height: 20),
        Text(
          t.ticket_empty_title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTheme.fontFor(
              !Localizations.localeOf(context).languageCode.contains('en'),
            ),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: onSurfaceColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          t.ticket_empty_body,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTheme.fontFor(
              !Localizations.localeOf(context).languageCode.contains('en'),
            ),
            fontSize: 14,
            color: textMutedColor,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildError(
    AppLocalizations t,
    bool isDark,
    Color onSurfaceColor,
  ) {
    final textMutedColor =
        isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 40),
        Icon(
          Icons.error_outline,
          size: 56,
          color: isDark ? AppTheme.darkError : AppTheme.lightError,
        ),
        const SizedBox(height: 16),
        Text(
          t.ticket_load_error,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTheme.fontFor(
              !Localizations.localeOf(context).languageCode.contains('en'),
            ),
            fontSize: 14,
            color: textMutedColor,
          ),
        ),
      ],
    );
  }
}