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
        child: _SwipeToReply(
          onReply: onReplyTap,
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
                _buildReplyPreview(context, isDark, mutedColor),
              Container(
                padding: const EdgeInsets.only(
                  left: 14,
                  right: 14,
                  top: 10,
                  bottom: 6,
                ),
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
                child: Column(
                  crossAxisAlignment:
                      isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    _buildContent(context, isDark, textColor, mutedColor),
                    const SizedBox(height: 2),
                    _buildTimestampAndStatus(
                      context,
                      isDark,
                      mutedColor,
                      successColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildReplyPreview(BuildContext context, bool isDark, Color mutedColor) {
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
              fontFamily: AppTheme.fontFor(
                !Localizations.localeOf(
                  context,
                ).languageCode.contains('en'),
              ),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
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
        return _buildTextContent(context, textColor);
      case MessageType.photo:
        return _buildPhotoContent(context);
      case MessageType.voice:
        return _buildVoiceContent(textColor, mutedColor);
    }
  }

  Widget _buildTextContent(BuildContext context, Color textColor) {
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
                fontFamily: AppTheme.fontFor(isPersian),
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
    final fullUrl = mediaUrlForDisplay(message.mediaUrl);
    final thumbUrl = mediaUrlForDisplay(message.mediaThumbUrl);
    final displayUrl = thumbUrl.isNotEmpty ? thumbUrl : fullUrl;
    // Scale photo to the bubble's max width; never exceeds 220 on phones.
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

    return displayUrl.isNotEmpty
        ? CachedImage.widget(
            displayUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            borderRadius: borderRadius,
            placeholder: photoPlaceholder,
            errorWidget: photoError,
            fallbackUrl: fullUrl,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _PhotoLightbox(imageUrl: fullUrl),
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

  Widget _buildVoiceContent(Color textColor, Color mutedColor) {
    return VoiceMessagePlayer(
      audioUrl: mediaUrlForDisplay(message.mediaUrl),
      isMine: isMine,
    );
  }

  Widget _buildTimestampAndStatus(
      BuildContext context, bool isDark, Color mutedColor, Color successColor) {
    final timeStr = DateFormat('HH:mm').format(message.sentAt);
    final inlineColor = isMine
        ? Colors.white.withValues(alpha: 0.75)
        : mutedColor;
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
                ? Colors.white
                : Colors.white.withValues(alpha: 0.6),
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

/// Telegram-style swipe-to-reply: dragging the bubble right reveals a reply
/// chip behind it and, past a threshold, triggers the reply. Works for both
/// own and received messages. The bubble visually follows your finger (no
/// more "static message" feeling) and snaps back when the gesture is cancelled.
class _SwipeToReply extends StatefulWidget {
  final Widget child;
  final VoidCallback? onReply;

  static const double maxDrag = 110;
  static const double threshold = 70;

  const _SwipeToReply({required this.child, this.onReply});

  @override
  State<_SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<_SwipeToReply>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );
  bool _dragging = false;
  double _startX = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onStart(DragStartDetails details) {
    _startX = details.globalPosition.dx;
    _dragging = false;
  }

  void _onUpdate(DragUpdateDetails details) {
    final raw = details.globalPosition.dx - _startX;
    if (!_dragging && raw > 8) _dragging = true;
    if (!_dragging) return;
    _controller.value =
        (raw.clamp(0.0, _SwipeToReply.maxDrag)) / _SwipeToReply.maxDrag;
  }

  void _onEnd(DragEndDetails details) {
    final travelled = _controller.value * _SwipeToReply.maxDrag;
    final committed =
        travelled >= _SwipeToReply.threshold ||
        (details.primaryVelocity ?? 0) > 300;
    final callback = widget.onReply;
    _controller.animateBack(0).then((_) {
      if (committed && callback != null && mounted) {
        callback();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: _onStart,
      onHorizontalDragUpdate: _onUpdate,
      onHorizontalDragEnd: _onEnd,
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) {
          final dx = _controller.value * _SwipeToReply.maxDrag;
          final revealed = _controller.value.clamp(0.0, 1.0);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Reply chip revealed behind the bubble as it slides right.
              Positioned(
                left: dx > 4 ? 4 : -32,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Opacity(
                    opacity: revealed,
                    child: Icon(
                      Icons.reply,
                      size: 22,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              Transform.translate(offset: Offset(dx, 0), child: child),
            ],
          );
        },
      ),
    );
  }
}
