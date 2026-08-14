import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/providers/chat_provider.dart';
import 'package:dating_app/models/message.dart';
import 'package:dating_app/services/storage_service.dart';
import 'package:dating_app/widgets/chat_app_bar.dart';
import 'package:dating_app/widgets/chat_message_bubble.dart';
import 'package:dating_app/widgets/chat_input_bar.dart';
import 'package:dating_app/widgets/typing_indicator.dart';
import 'package:dating_app/utils/media_url.dart';
import 'package:dating_app/screens/shared/profile_detail_loader.dart';
import 'package:dating_app/screens/search/search_profile_detail.dart';
import 'package:dating_app/generated/app_localizations.dart';
import 'package:dating_app/widgets/action_toast.dart';
import 'package:intl/intl.dart';

class ChatDetailScreen extends StatefulWidget {
  final String identifier;
  final String userName;
  final String? avatarUrl;
  final bool isOnline;
  final String? lastSeenAt;
  final String? initialStatus;
  final String? initialInitiatorId;
  final String? peerId;

  const ChatDetailScreen({
    super.key,
    required this.identifier,
    required this.userName,
    this.avatarUrl,
    this.isOnline = false,
    this.lastSeenAt,
    this.initialStatus,
    this.initialInitiatorId,
    this.peerId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _scrollController = ScrollController();
  final _storageService = StorageService();
  String? _replyToId;
  String? _replyToContent;
  String? _currentUserId;
  ChatProvider? _chatProvider;
  bool _showScrollToBottom = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chatProvider = Provider.of<ChatProvider>(context, listen: false);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _currentUserId = await _storageService.getUserId();
      if (!mounted) return;
      _chatProvider?.loadMessages(
        widget.identifier,
        initialStatus: widget.initialStatus,
        initialInitiatorId: widget.initialInitiatorId,
      );
      _chatProvider?.subscribeChat(widget.identifier);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _chatProvider?.clearActiveChat();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels <= 0) {
      context.read<ChatProvider>().loadMoreMessages();
    }
    final atBottom =
        _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200;
    if (atBottom != _showScrollToBottom) {
      setState(() => _showScrollToBottom = !atBottom);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _attachPhoto() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;
      final provider = context.read<ChatProvider>();
      final success = await provider.sendPhoto(widget.identifier, file.path);
      if (success) _scrollToBottom();
    } catch (e) {
      // silent
    }
  }

  void _showMessageOptions(Message message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final errorColor = isDark ? AppTheme.darkError : AppTheme.lightError;

    final isMine = message.senderId == _currentUserId;

    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkBorder : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (message.messageType == MessageType.text &&
                message.content != null) ...[
              ListTile(
                leading: Icon(Icons.copy, color: primaryColor),
                title: Text(
                  'Copy',
                  style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')), color: textColor),
                ),
                onTap: () async {
                  await Clipboard.setData(
                    ClipboardData(text: message.content!),
                  );
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
            if (message.isSent && isMine) ...[
              ListTile(
                leading: Icon(Icons.edit, color: primaryColor),
                title: Text(
                  'Edit',
                  style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')), color: textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.read<ChatProvider>().startEditing(message.id);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: errorColor),
                title: Text(
                  'Delete',
                  style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')), color: textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteDialog(message);
                },
              ),
            ],
            ListTile(
              leading: Icon(Icons.reply, color: primaryColor),
              title: Text(
                'Reply',
                style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')), color: textColor),
              ),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _replyToId = message.id;
                  _replyToContent = message.content;
                });
              },
            ),
            ListTile(
              leading: Icon(Icons.flag, color: errorColor),
              title: Text(
                'Report',
                style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')), color: textColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _showReportDialog(message);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _setReplyFromSwipeRight(Message message) {
    setState(() {
      _replyToId = message.id;
      _replyToContent = message.content;
    });
  }

  void _showReportDialog(Message message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: surfaceColor,
        title: Text(
          'Report Message',
          style: TextStyle(
            fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          maxLength: 2000,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Tell us what went wrong...',
            border: const OutlineInputBorder(),
            hintStyle: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')), color: textColor),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')), color: textColor),
            ),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().length < 5) return;
              Navigator.pop(dialogContext, controller.text.trim());
            },
            child: Text(
              'Send',
              style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')), color: textColor),
            ),
          ),
        ],
      ),
    ).then((reason) async {
      if (reason is String && reason.isNotEmpty && mounted) {
        await context.read<ChatProvider>().reportMessage(
          message.id,
          reason: reason,
        );
        if (mounted) {
          final t = AppLocalizations.of(context)!;
          showActionToast(context, t.chat_message_reported);
        }
      }
    });
  }

  void _showDeleteDialog(Message message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final errorColor = isDark ? AppTheme.darkError : AppTheme.lightError;
    bool deleteForAll = false;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: surfaceColor,
        child: StatefulBuilder(
          builder: (dialogContext, setDialogState) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delete Message',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  value: deleteForAll,
                  onChanged: (value) {
                    setDialogState(() => deleteForAll = value ?? false);
                  },
                  title: Text(
                    'Delete for ${widget.userName} too',
                    style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')), color: textColor),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(
                        'Cancel',
                        style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')), color: textColor),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        context.read<ChatProvider>().deleteMessage(
                          message.id,
                          deleteForAll: deleteForAll,
                        );
                      },
                      child: Text(
                        'Delete',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                          color: errorColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openPeerProfile() {
    final provider = context.read<ChatProvider>();
    final peerId = widget.peerId ?? provider.peerId;
    if (peerId == null || peerId.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileDetailLoader(
          userId: peerId,
          builder: (profile) =>
              SearchProfileDetail(profile: profile, viewOnly: true),
        ),
      ),
    );
  }

  void _openChatMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;

    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(
                'View Profile',
                style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')), color: textColor),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _openPeerProfile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(
                'Delete Chat',
                style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')), color: textColor),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _confirmDeleteChat();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteChat() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: surfaceColor,
        title: Text('Delete Chat', style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')))),
        content: Text(
          'This deletes the chat on your side.',
          style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en'))),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel', style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Delete', style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')))),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<ChatProvider>().deleteChat(widget.identifier);
    if (mounted) Navigator.pop(context);
  }

  Widget _buildConversationOverBanner(
    BuildContext context,
    bool isDark,
    Color mutedColor,
  ) {
    final t = AppLocalizations.of(context)!;
    final bgColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: Text(
        t.chat_conversation_over(widget.userName),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
          fontSize: 13,
          color: mutedColor,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final mutedColor = isDark
        ? AppTheme.darkTextMuted
        : AppTheme.lightTextMuted;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: ChatAppBar(
        userName: widget.userName,
        avatarUrl: mediaUrlForDisplay(widget.avatarUrl),
        isOnline: context.watch<ChatProvider>().isOtherUserOnline,
        lastSeenAt:
            context
                .watch<ChatProvider>()
                .otherUserLastSeenAt
                ?.toIso8601String() ??
            widget.lastSeenAt,
        onAvatarTap: _openPeerProfile,
        onMenuPressed: _openChatMenu,
      ),
      body: Container(
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
              child: Consumer<ChatProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.messages.isEmpty) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: isDark
                            ? AppTheme.darkPrimary
                            : AppTheme.lightPrimary,
                      ),
                    );
                  }

                  return _buildMessageList(
                    provider,
                    isDark,
                    textColor,
                    mutedColor,
                  );
                },
              ),
            ),
            Consumer<ChatProvider>(
              builder: (context, provider, _) {
                if (provider.isRecipientWaiting) {
                  return _buildAcceptCard(context, provider, isDark);
                }
                if (provider.isInitiatorWaiting) {
                  return _buildWaitingBanner(context, isDark, mutedColor);
                }
                if (provider.conversationIsOver) {
                  return _buildConversationOverBanner(
                    context,
                    isDark,
                    mutedColor,
                  );
                }
                return ChatInputBar(
                  canSend: provider.canSendMessage,
                  replyToId: _replyToId,
                  replyToContent: _replyToContent,
                  onCancelReply: () {
                    setState(() {
                      _replyToId = null;
                      _replyToContent = null;
                    });
                  },
                  isEditing: provider.editingMessageId != null,
                  editingContent: provider.editingMessageId != null
                      ? provider.messages
                            .where((m) => m.id == provider.editingMessageId)
                            .map((m) => m.content)
                            .firstOrNull
                      : null,
                  onCancelEdit: () => provider.cancelEditing(),
                  onEditSave: (content) {
                    provider.editMessage(provider.editingMessageId!, content);
                  },
                  onTyping: () => provider.setTyping(),
                  onTypingStopped: () => provider.stopTyping(),
                  onSendText: (text, {replyToId}) async {
                    final success = await provider.sendText(
                      widget.identifier,
                      text,
                      replyToId: replyToId,
                    );
                    if (success) _scrollToBottom();
                    setState(() {
                      _replyToId = null;
                      _replyToContent = null;
                    });
                  },
                  onSendVoice: (path, duration) async {
                    final success = await provider.sendVoice(
                      widget.identifier,
                      path,
                      duration,
                    );
                    if (success) _scrollToBottom();
                  },
                  onAttachPhoto: _attachPhoto,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcceptCard(
    BuildContext context,
    ChatProvider provider,
    bool isDark,
  ) {
    final t = AppLocalizations.of(context)!;
    final bgColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t.chat_accept_title(widget.userName),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
              fontSize: 13,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: provider.isAccepting
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primaryColor,
                      ),
                    ),
                  )
                : AppTheme.gradientButton(
                    onPressed: () async {
                      await provider.acceptChat(widget.identifier);
                    },
                    child: Text(
                      t.chat_accept,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingBanner(
    BuildContext context,
    bool isDark,
    Color mutedColor,
  ) {
    final t = AppLocalizations.of(context)!;
    final bgColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: Text(
        t.chat_waiting_accept(widget.userName),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
          fontSize: 13,
          color: mutedColor,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildMessageList(
    ChatProvider provider,
    bool isDark,
    Color textColor,
    Color mutedColor,
  ) {
    final userId = _currentUserId ?? '';

    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollEndNotification &&
                notification.metrics.pixels <= 0) {
              provider.loadMoreMessages();
            }
            return false;
          },
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: provider.messages.length + (provider.isTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == provider.messages.length) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: TypingIndicator(),
                  ),
                );
              }

              final message = provider.messages[index];

              final bool showDatePill =
                  index == 0 ||
                  !_isSameDay(
                    provider.messages[index - 1].sentAt,
                    message.sentAt,
                  );

              if (message.isDeleted) {
                return Column(
                  children: [
                    if (showDatePill) _buildDatePill(message.sentAt),
                    Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'This message was deleted',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                            fontSize: 12,
                            color: mutedColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  if (showDatePill) _buildDatePill(message.sentAt),
                  ChatMessageBubble(
                    message: message,
                    isMine: message.senderId == userId,
                    onLongPress: () => _showMessageOptions(message),
                    onTap: () => _showMessageOptions(message),
                    onReplyTap: () => _setReplyFromSwipeRight(message),
                  ),
                ],
              );
            },
          ),
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _showScrollToBottom ? 1 : 0,
            child: IgnorePointer(
              ignoring: !_showScrollToBottom,
              child: Material(
                color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                shape: const CircleBorder(),
                elevation: 4,
                child: IconButton(
                  onPressed: _scrollToBottom,
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: isDark ? AppTheme.darkText : AppTheme.lightText,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildDatePill(DateTime date) {
    final isDark = context.isDarkMode;
    final mutedColor =
        isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;
    final now = DateTime.now();
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');

    final String label;
    if (_isSameDay(date, now)) {
      label = 'Today';
    } else if (_isSameDay(
      date,
      now.subtract(const Duration(days: 1)),
    )) {
      label = 'Yesterday';
    } else {
      label = DateFormat('MMM d, yyyy').format(date);
    }

    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.darkSurface.withValues(alpha: 0.9)
              : AppTheme.lightSurface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontFor(isPersian),
            fontSize: 12,
            color: mutedColor,
          ),
        ),
      ),
    );
  }
}
