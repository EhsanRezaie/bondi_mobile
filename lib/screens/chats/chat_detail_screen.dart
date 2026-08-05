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

  const ChatDetailScreen({
    super.key,
    required this.identifier,
    required this.userName,
    this.avatarUrl,
    this.isOnline = false,
    this.lastSeenAt,
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _currentUserId = await _storageService.getUserId();
      if (!mounted) return;
      final provider = context.read<ChatProvider>();
      provider.loadMessages(widget.identifier);
      provider.connectWebSocket(widget.identifier);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    context.read<ChatProvider>().clearActiveChat();
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
    final t = AppLocalizations.of(context)!;
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
        lastSeenAt: widget.lastSeenAt,
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

                // Chat initiation limit banner
                if (!provider.canSendMessage) {
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (isDark
                                  ? AppTheme.darkPrimary
                                  : AppTheme.lightPrimary)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: isDark
                                  ? AppTheme.darkPrimary
                                  : AppTheme.lightPrimary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                t.chat_initiation_limit_explanation,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color: isDark
                                      ? AppTheme.darkPrimary
                                      : AppTheme.lightPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _buildMessageList(provider, isDark, textColor, mutedColor),
                      ),
                    ],
                  );
                }

                return _buildMessageList(provider, isDark, textColor, mutedColor);
              },
            ),
          ),
          Consumer<ChatProvider>(
            builder: (context, provider, _) {
              if (provider.isTyping) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TypingIndicator(),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Consumer<ChatProvider>(
            builder: (context, provider, _) {
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
        itemCount: provider.messages.length,
        itemBuilder: (context, index) {
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
