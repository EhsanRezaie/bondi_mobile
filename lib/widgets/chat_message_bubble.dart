import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/models/message.dart';
import 'package:dating_app/utils/media_url.dart';
import 'package:dating_app/widgets/voice_message_player.dart';
import 'package:intl/intl.dart';

class ChatMessageBubble extends StatelessWidget {
  final Message message;
  final bool isMine;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  final VoidCallback? onReplyTap;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.onLongPress,
    this.onTap,
    this.onReplyTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final mutedColor =
        isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;
    final successColor =
        isDark ? AppTheme.darkSuccess : AppTheme.lightSuccess;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: isMine ? onLongPress : null,
        onTap: onTap,
        onHorizontalDragEnd: (details) {
          if (onReplyTap != null &&
              details.primaryVelocity != null &&
              details.primaryVelocity! > 250) {
            onReplyTap!();
          }
        },
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          margin: const EdgeInsets.symmetric(vertical: 3),
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (message.replyTo != null) _buildReplyPreview(isDark, mutedColor),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMine
                      ? (isDark
                          ? AppTheme.darkPrimary.withValues(alpha: 0.85)
                          : AppTheme.lightPrimary)
                      : surfaceColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMine ? 18 : 4),
                    bottomRight: Radius.circular(isMine ? 4 : 18),
                  ),
                  border: isMine
                      ? null
                      : Border.all(
                          color: isDark
                              ? AppTheme.darkBorder
                              : AppTheme.lightBorder,
                          width: 1,
                        ),
                ),
                child: _buildContent(context, isDark, textColor, mutedColor),
              ),
              const SizedBox(height: 2),
              _buildTimestampAndStatus(isDark, mutedColor, successColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyPreview(bool isDark, Color mutedColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkSurface.withValues(alpha: 0.6)
            : AppTheme.lightBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.replyTo!.senderId == message.senderId ? 'You' : '',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            message.replyTo!.content ?? '',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: mutedColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark, Color textColor, Color mutedColor) {
    switch (message.messageType) {
      case MessageType.text:
        return _buildTextContent(textColor);
      case MessageType.photo:
        return _buildPhotoContent(context);
      case MessageType.voice:
        return _buildVoiceContent(textColor, mutedColor);
    }
  }

  Widget _buildTextContent(Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message.content ?? '',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            color: isMine ? Colors.white : textColor,
            height: 1.3,
          ),
        ),
        if (message.isEdited)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'edited',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                color: isMine
                    ? Colors.white.withValues(alpha: 0.6)
                    : textColor.withValues(alpha: 0.5),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPhotoContent(BuildContext context) {
    final url = mediaUrlForDisplay(message.mediaUrl);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _PhotoLightbox(imageUrl: url),
            ),
          );
        },
        child: url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url,
                width: 220,
                height: 220,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 220,
                  height: 220,
                  color: Colors.grey.shade300,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 220,
                  height: 220,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.broken_image, size: 40),
                ),
              )
            : Container(
                width: 220,
                height: 220,
                color: Colors.grey.shade300,
                child: const Icon(Icons.image, size: 40),
              ),
      ),
    );
  }

  Widget _buildVoiceContent(Color textColor, Color mutedColor) {
    return VoiceMessagePlayer(
      audioUrl: mediaUrlForDisplay(message.mediaUrl),
      isMine: isMine,
    );
  }

  Widget _buildTimestampAndStatus(
      bool isDark, Color mutedColor, Color successColor) {
    final timeStr = DateFormat('HH:mm').format(message.sentAt);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          timeStr,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            color: mutedColor,
          ),
        ),
        if (isMine) ...[
          const SizedBox(width: 4),
          Icon(
            message.isRead
                ? Icons.done_all
                : message.isDelivered
                    ? Icons.done_all
                    : Icons.done,
            size: 14,
            color: message.isRead
                ? (isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary)
                : successColor,
          ),
        ],
      ],
    );
  }
}

/// Full-screen, zoomable photo viewer opened when tapping a photo message.
class _PhotoLightbox extends StatelessWidget {
  final String imageUrl;

  const _PhotoLightbox({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: InteractiveViewer(
        maxScale: 5,
        child: Center(
          child: imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.broken_image,
                    size: 64,
                    color: Colors.white54,
                  ),
                )
              : const Icon(Icons.image, size: 64, color: Colors.white54),
        ),
      ),
    );
  }
}
