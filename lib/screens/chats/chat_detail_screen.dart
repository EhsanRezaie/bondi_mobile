import 'package:flutter/material.dart';
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
import 'package:dating_app/generated/app_localizations.dart';

class ChatDetailScreen extends StatefulWidget {
  final String identifier;
  final String userName;
  final String? avatarUrl;
  final bool isOnline;
  final String? lastSeenAt;
  final String? initialStatus;
  final String? initialInitiatorId;

  const ChatDetailScreen({
    super.key,
    required this.identifier,
    required this.userName,
    this.avatarUrl,
    this.isOnline = false,
    this.lastSeenAt,
    this.initialStatus,
    this.initialInitiatorId,
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
    final primaryColor =
        isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final surfaceColor =
        isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final errorColor = isDark ? AppTheme.darkError : AppTheme.lightError;

    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (message.isSent) ...[
              ListTile(
                leading: Icon(Icons.edit, color: primaryColor),
                title: Text(
                  'Edit',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: textColor,
                  ),
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
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: textColor,
                  ),
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
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: textColor,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _replyToId = message.id;
                  _replyToContent = message.content;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(Message message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final errorColor = isDark ? AppTheme.darkError : AppTheme.lightError;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        title: Text(
          'Delete Message',
          style: TextStyle(
            fontFamily: 'Inter',
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Choose how to delete this message.',
          style: TextStyle(
            fontFamily: 'Inter',
            color: textColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Inter', color: textColor),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<ChatProvider>()
                  .deleteMessage(message.id, deleteForAll: false);
            },
            child: Text(
              'Delete for me',
              style: TextStyle(fontFamily: 'Inter', color: errorColor),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<ChatProvider>()
                  .deleteMessage(message.id, deleteForAll: true);
            },
            child: Text(
              'Delete for everyone',
              style: TextStyle(fontFamily: 'Inter', color: errorColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final mutedColor =
        isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: ChatAppBar(
        userName: widget.userName,
        avatarUrl: widget.avatarUrl,
        isOnline: context.watch<ChatProvider>().isOtherUserOnline,
        lastSeenAt: context
                .watch<ChatProvider>()
                .otherUserLastSeenAt
                ?.toIso8601String() ??
            widget.lastSeenAt,
      ),
      body: Column(
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

                return _buildMessageList(provider, isDark, textColor, mutedColor);
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
    );
  }

  Widget _buildAcceptCard(
    BuildContext context,
    ChatProvider provider,
    bool isDark,
  ) {
    final t = AppLocalizations.of(context)!;
    final bgColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final borderColor =
        isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(color: borderColor, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t.chat_accept_title(widget.userName),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
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
                : ElevatedButton(
                    onPressed: () async {
                      await provider.acceptChat(widget.identifier);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      t.chat_accept,
                      style: const TextStyle(
                        fontFamily: 'Inter',
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
    final borderColor =
        isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(color: borderColor, width: 0.5),
        ),
      ),
      child: Text(
        t.chat_waiting_accept(widget.userName),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Inter',
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

    return NotificationListener<ScrollNotification>(
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

          if (message.isDeleted) {
            return Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'This message was deleted',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: mutedColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            );
          }

          return ChatMessageBubble(
            message: message,
            isMine: message.senderId == userId,
            onLongPress: () => _showMessageOptions(message),
          );
        },
      ),
    );
  }
}
