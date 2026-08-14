import 'package:flutter/material.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/models/message.dart';
import 'package:dating_app/utils/media_url.dart';
import 'package:dating_app/utils/responsive.dart';
import 'package:dating_app/utils/cached_image.dart';
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

  /// Background fill of my (sent) bubble.
  /// Background fill of my (sent) bubble — the warm orange brand color.
  /// Light mode: full `lightPrimary`; dark mode: `darkPrimary @ 85%`.
  Color _sentFill(BuildContext context) =>
      context.isDarkMode
          ? AppTheme.darkPrimary.withValues(alpha: 0.85)
          : AppTheme.lightPrimary;

  /// Foreground color on my (sent) bubble — white text reads on the orange.
  Color _sentForeground(BuildContext context) => Colors.white;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final mutedColor =
        isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final sentFill = _sentFill(context);
    final sentFg = _sentForeground(context);

    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMine ? 18 : 4),
      bottomRight: Radius.circular(isMine ? 4 : 18),
    );

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
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          margin: const EdgeInsets.symmetric(vertical: 3),
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (message.replyTo != null)
                _buildReplyPreview(
                  context,
                  isDark,
                  mutedColor,
                  sentFill,
                  sentFg,
                ),
              Container(
                padding: const EdgeInsets.only(
                  left: 14,
                  right: 14,
                  top: 10,
                  bottom: 6,
                ),
                decoration: BoxDecoration(
                  color: isMine ? sentFill : surfaceColor,
                  borderRadius: borderRadius,
                  border: isMine
                      ? null
                      : Border.all(color: borderColor, width: 1),
                  boxShadow: isMine
                      ? [
                          BoxShadow(
                            color: sentFill.withValues(alpha: 0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  crossAxisAlignment:
                      isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    _buildContent(
                      context,
                      isDark,
                      textColor,
                      mutedColor,
                      sentFill,
                      sentFg,
                    ),
                    const SizedBox(height: 2),
                    _buildTimestampAndStatus(
                      context,
                      isDark,
                      mutedColor,
                      sentFg,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyPreview(
    BuildContext context,
    bool isDark,
    Color mutedColor,
    Color sentFill,
    Color sentFg,
  ) {
    final isReplyMine = message.replyTo!.senderId == message.senderId;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isMine
            ? sentFg.withValues(alpha: 0.12)
            : isDark
                ? AppTheme.darkSecondary
                : AppTheme.lightSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMine ? sentFg.withValues(alpha: 0.22) : borderColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 28,
            decoration: BoxDecoration(
              color: isMine
                  ? sentFg
                  : (isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isReplyMine ? 'You' : '',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFor(
                      !Localizations.localeOf(
                        context,
                      ).languageCode.contains('en'),
                    ),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isMine ? sentFg : mutedColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message.replyTo!.content ?? '',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFor(
                      !Localizations.localeOf(
                        context,
                      ).languageCode.contains('en'),
                    ),
                    fontSize: 12,
                    color: isMine ? sentFg.withValues(alpha: 0.85) : mutedColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color mutedColor,
    Color sentFill,
    Color sentFg,
  ) {
    switch (message.messageType) {
      case MessageType.text:
        return _buildTextContent(context, textColor, sentFg);
      case MessageType.photo:
        return _buildPhotoContent(context);
      case MessageType.voice:
        return _buildVoiceContent(sentFill, sentFg);
    }
  }

  Widget _buildTextContent(BuildContext context, Color textColor, Color sentFg) {
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message.content ?? '',
          style: TextStyle(
            fontFamily: AppTheme.fontFor(isPersian),
            fontSize: 15,
            color: isMine ? sentFg : textColor,
            height: 1.3,
          ),
        ),
        if (message.isEdited)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'edited',
              style: TextStyle(
                fontFamily: AppTheme.fontFor(isPersian),
                fontSize: 10,
                color: isMine
                    ? sentFg.withValues(alpha: 0.7)
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
    final maxW = MediaQuery.of(context).size.width * 0.78 - 28;
    final size = AppLayout.s(context, 220).clamp(0.0, maxW);
    final borderRadius = BorderRadius.circular(12);
    final photoPlaceholder = Container(
      width: size,
      height: size,
      color: Colors.grey.shade300,
      child: const Center(child: CircularProgressIndicator()),
    );
    final photoError = Container(
      width: size,
      height: size,
      color: Colors.grey.shade300,
      child: const Icon(Icons.broken_image, size: 40),
    );

    return url.isNotEmpty
        ? CachedImage.widget(
            url,
            width: size,
            height: size,
            fit: BoxFit.cover,
            borderRadius: borderRadius,
            placeholder: photoPlaceholder,
            errorWidget: photoError,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _PhotoLightbox(imageUrl: url),
                ),
              );
            },
          )
        : Container(
            width: size,
            height: size,
            color: Colors.grey.shade300,
            child: const Icon(Icons.image, size: 40),
          );
  }

  Widget _buildVoiceContent(Color sentFill, Color sentFg) {
    return VoiceMessagePlayer(
      audioUrl: mediaUrlForDisplay(message.mediaUrl),
      isMine: isMine,
      mineFill: sentFill,
      mineForeground: sentFg,
    );
  }

  Widget _buildTimestampAndStatus(
    BuildContext context,
    bool isDark,
    Color mutedColor,
    Color sentFg,
  ) {
    final timeStr = DateFormat('HH:mm').format(message.sentAt);
    final inlineColor = isMine ? sentFg.withValues(alpha: 0.8) : mutedColor;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          timeStr,
          style: TextStyle(
            fontFamily: AppTheme.fontFor(
              !Localizations.localeOf(
                context,
              ).languageCode.contains('en'),
            ),
            fontSize: 11,
            color: inlineColor,
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
                ? sentFg.withValues(alpha: 0.95)
                : sentFg.withValues(alpha: 0.6),
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
              ? CachedImage.widget(
                  imageUrl,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  fit: BoxFit.contain,
                  placeholder: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: const Icon(
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