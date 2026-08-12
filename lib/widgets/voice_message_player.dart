import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/utils/responsive.dart';

class VoiceMessagePlayer extends StatefulWidget {
  final String? audioUrl;
  final bool isMine;

  const VoiceMessagePlayer({
    super.key,
    this.audioUrl,
    required this.isMine,
  });

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  AudioPlayer? _player;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && widget.audioUrl != null) {
      _initPlayer();
    }
  }

  Future<void> _initPlayer() async {
    _player = AudioPlayer();
    try {
      await _player!.setUrl(widget.audioUrl!);
      _player!.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
          });
          if (state.processingState == ProcessingState.completed) {
            setState(() {
              _isPlaying = false;
            });
          }
        }
      });
    } catch (e) {
      // silent
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_player == null) return;
    if (_isPlaying) {
      await _player!.pause();
    } else {
      await _player!.play();
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();

    final isDark = context.isDarkMode;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;

    final maxW = MediaQuery.of(context).size.width * 0.78 - 28;
    final width = AppLayout.s(context, 200).clamp(0.0, maxW);

    return SizedBox(
      width: width,
      child: _VoiceControls(
        player: _player,
        isPlaying: _isPlaying,
        isDark: isDark,
        primaryColor: primaryColor,
        isMine: widget.isMine,
        width: width,
        onTogglePlay: _togglePlay,
        formatDuration: _formatDuration,
      ),
    );
  }
}

class _VoiceControls extends StatelessWidget {
  const _VoiceControls({
    required this.player,
    required this.isPlaying,
    required this.isDark,
    required this.primaryColor,
    required this.isMine,
    required this.width,
    required this.onTogglePlay,
    required this.formatDuration,
  });

  final AudioPlayer? player;
  final bool isPlaying;
  final bool isDark;
  final Color primaryColor;
  final bool isMine;
  final double width;
  final Future<void> Function() onTogglePlay;
  final String Function(Duration) formatDuration;

  @override
  Widget build(BuildContext context) {
    if (player == null) {
      return const SizedBox.shrink();
    }

    final mutedColor =
        isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;

    return StreamBuilder<Duration>(
      stream: player!.positionStream,
      builder: (context, positionSnapshot) {
        final position =
            positionSnapshot.data ?? Duration.zero;
        return StreamBuilder<Duration?>(
          stream: player!.durationStream,
          builder: (context, durationSnapshot) {
            final duration = durationSnapshot.data ?? Duration.zero;
            final progress = duration.inMilliseconds > 0
                ? position.inMilliseconds / duration.inMilliseconds
                : 0.0;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: onTogglePlay,
                      child: Icon(
                        isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_fill,
                        size: AppLayout.s(context, 32),
                        color: isMine ? Colors.white : primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 5),
                          activeTrackColor: isMine
                              ? Colors.white.withValues(alpha: 0.8)
                              : primaryColor,
                          inactiveTrackColor: isMine
                              ? Colors.white.withValues(alpha: 0.3)
                              : mutedColor.withValues(alpha: 0.3),
                          thumbColor:
                              isMine ? Colors.white : primaryColor,
                        ),
                        child: Slider(
                          value: progress.clamp(0.0, 1.0),
                          onChanged: (v) {
                            final seekPosition = Duration(
                              milliseconds:
                                  (v * duration.inMilliseconds).toInt(),
                            );
                            player!.seek(seekPosition);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  formatDuration(position),
                  style: TextStyle(
                    fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                    fontSize: 10,
                    color: isMine
                        ? Colors.white.withValues(alpha: 0.7)
                        : mutedColor,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
