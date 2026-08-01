import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:dating_app/config/app_theme.dart';

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
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

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
      _player!.durationStream.listen((d) {
        if (mounted) setState(() => _duration = d ?? Duration.zero);
      });
      _player!.positionStream.listen((p) {
        if (mounted) setState(() => _position = p);
      });
      _player!.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
          });
          if (state.processingState == ProcessingState.completed) {
            setState(() {
              _isPlaying = false;
              _position = Duration.zero;
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
    final mutedColor =
        isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;

    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    return SizedBox(
      width: 200,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _togglePlay,
                child: Icon(
                  _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                  size: 32,
                  color: widget.isMine ? Colors.white : primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 5),
                    activeTrackColor:
                        widget.isMine ? Colors.white.withOpacity(0.8) : primaryColor,
                    inactiveTrackColor:
                        widget.isMine ? Colors.white.withOpacity(0.3) : mutedColor.withOpacity(0.3),
                    thumbColor: widget.isMine ? Colors.white : primaryColor,
                  ),
                  child: Slider(
                    value: progress.clamp(0.0, 1.0),
                    onChanged: (v) {
                      if (_player != null) {
                        final position = Duration(
                          milliseconds: (v * _duration.inMilliseconds).toInt(),
                        );
                        _player!.seek(position);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            _formatDuration(_position),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: widget.isMine
                  ? Colors.white.withOpacity(0.7)
                  : mutedColor,
            ),
          ),
        ],
      ),
    );
  }
}
