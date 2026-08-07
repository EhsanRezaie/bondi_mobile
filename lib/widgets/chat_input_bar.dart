import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dating_app/config/app_theme.dart';

class ChatInputBar extends StatefulWidget {
  final Function(String text, {String? replyToId}) onSendText;
  final Function(String path, int duration) onSendVoice;
  final Function() onAttachPhoto;
  final bool canSend;
  final String? replyToId;
  final String? replyToContent;
  final VoidCallback? onCancelReply;
  final String? editingContent;
  final bool isEditing;
  final VoidCallback? onCancelEdit;
  final Function(String)? onEditSave;
  final VoidCallback? onTyping;
  final VoidCallback? onTypingStopped;

  const ChatInputBar({
    super.key,
    required this.onSendText,
    required this.onSendVoice,
    required this.onAttachPhoto,
    this.canSend = true,
    this.replyToId,
    this.replyToContent,
    this.onCancelReply,
    this.editingContent,
    this.isEditing = false,
    this.onCancelEdit,
    this.onEditSave,
    this.onTyping,
    this.onTypingStopped,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isRecording = false;
  int _recordSeconds = 0;
  AudioRecorder? _recorder;
  bool _disposed = false;
  DateTime? _lastTypingSent;
  static const _typingThrottle = Duration(milliseconds: 800);

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.editingContent != null) {
      _controller.text = widget.editingContent!;
    }
  }

  @override
  void didUpdateWidget(covariant ChatInputBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_disposed) return;
    if (widget.isEditing && widget.editingContent != null) {
      _controller.text = widget.editingContent!;
    } else if (!widget.isEditing && oldWidget.isEditing) {
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _controller.dispose();
    _focusNode.dispose();
    _recorder?.dispose();
    super.dispose();
  }

  void _sendText() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (widget.isEditing) {
      widget.onEditSave?.call(text);
      setState(() => _controller.clear());
    } else {
      widget.onSendText(text, replyToId: widget.replyToId);
      setState(() => _controller.clear());
    }
    widget.onTypingStopped?.call();
    _lastTypingSent = null;
  }

  void _sendTypingThrottled() {
    final now = DateTime.now();
    if (_lastTypingSent == null ||
        now.difference(_lastTypingSent!) >= _typingThrottle) {
      _lastTypingSent = now;
      widget.onTyping?.call();
    }
  }

  Future<void> _startRecording() async {
    if (kIsWeb) return;

    try {
      _recorder = AudioRecorder();
      if (await _recorder!.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path =
            '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.aac';
        await _recorder!.start(
          RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: path,
        );
        setState(() {
          _isRecording = true;
          _recordSeconds = 0;
        });
        _startRecordTimer();
      }
    } catch (e) {
      // silent
    }
  }

  void _startRecordTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_isRecording && mounted) {
        setState(() => _recordSeconds++);
        if (_recordSeconds >= 120) {
          _stopRecording();
        } else {
          _startRecordTimer();
        }
      }
    });
  }

  Future<void> _stopRecording() async {
    if (_recorder == null) return;
    final path = await _recorder!.stop();
    setState(() => _isRecording = false);
    if (path != null && _recordSeconds >= 1) {
      widget.onSendVoice(path, _recordSeconds);
    } else if (_recordSeconds < 1) {
      HapticFeedback.mediumImpact();
    }
    _recordSeconds = 0;
  }

  Future<void> _cancelRecording() async {
    if (_recorder == null) return;
    await _recorder!.stop();
    setState(() => _isRecording = false);
    _recordSeconds = 0;
  }

  String _formatRecordTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final bgColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final borderColor =
        isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final mutedColor =
        isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;

    if (!widget.canSend && !widget.isEditing) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            top: BorderSide(color: borderColor, width: 0.5),
          ),
        ),
        child: Text(
          'Waiting for a reply to continue chatting...',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: mutedColor,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(color: borderColor, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.replyToId != null && widget.replyToContent != null)
              _buildReplyBanner(isDark, primaryColor, mutedColor),
            if (widget.isEditing)
              _buildEditBanner(isDark, primaryColor, mutedColor),
            if (_isRecording)
              _buildRecordingBanner(isDark, primaryColor, mutedColor)
            else
              _buildInputRow(isDark, bgColor, borderColor, primaryColor,
                  textColor, mutedColor),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyBanner(
      bool isDark, Color primaryColor, Color mutedColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.reply, size: 16, color: primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.replyToContent!,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: mutedColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: widget.onCancelReply,
            child: Icon(Icons.close, size: 16, color: mutedColor),
          ),
        ],
      ),
    );
  }

  Widget _buildEditBanner(
      bool isDark, Color primaryColor, Color mutedColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.edit, size: 16, color: primaryColor),
          const SizedBox(width: 8),
          Text(
            'Editing message',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: widget.onCancelEdit,
            child: Icon(Icons.close, size: 16, color: mutedColor),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingBanner(
      bool isDark, Color primaryColor, Color mutedColor) {
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppTheme.lightError,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatRecordTime(_recordSeconds),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _cancelRecording,
            icon: Icon(Icons.delete_outline, color: AppTheme.lightError),
          ),
          IconButton(
            onPressed: _stopRecording,
            icon: Icon(Icons.send, color: primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow(
    bool isDark,
    Color bgColor,
    Color borderColor,
    Color primaryColor,
    Color textColor,
    Color mutedColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!widget.isEditing)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 1),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: _showAttachSheet,
              icon: Icon(Icons.add, color: primaryColor),
            ),
          ),
        const SizedBox(width: 6),
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
              controller: _controller,
              focusNode: _focusNode,
              maxLines: 3,
              minLines: 1,
              maxLength: 5000,
              textInputAction: TextInputAction.newline,
              onChanged: (value) {
                setState(() {});
                if (value.trim().isNotEmpty) {
                  _sendTypingThrottled();
                } else {
                  widget.onTypingStopped?.call();
                }
              },
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                color: textColor,
              ),
              decoration: InputDecoration(
                counterText: '',
                border: InputBorder.none,
                isDense: true,
                hintText:
                    widget.isEditing ? 'Edit message...' : 'Type a message...',
                hintStyle: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  color: mutedColor,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        if (!_isRecording && _controller.text.trim().isNotEmpty)
          _roundAction(Icons.send, () => _sendText(), primaryColor)
        else if (!_isRecording)
          _roundAction(
            Icons.mic,
            widget.canSend ? _startRecording : null,
            primaryColor,
          ),
        if (_isRecording)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _cancelRecording,
                child: Icon(Icons.close, color: AppTheme.lightError),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _stopRecording,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppTheme.lightError,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _roundAction(
    IconData icon,
    VoidCallback? onPressed,
    Color color,
  ) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: onPressed == null ? Colors.grey.shade300 : color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  void _showAttachSheet() {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery', style: TextStyle(fontFamily: 'Inter')),
              onTap: () {
                Navigator.pop(sheetContext);
                widget.onAttachPhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Camera', style: TextStyle(fontFamily: 'Inter')),
              onTap: () {
                Navigator.pop(sheetContext);
                widget.onAttachPhoto();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
