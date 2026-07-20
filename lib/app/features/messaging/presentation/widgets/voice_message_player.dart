import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:just_audio/just_audio.dart';

import 'package:jobaway/app/core/theme/app_colors.dart';
import 'package:jobaway/app/core/theme/app_text_styles.dart';
import 'package:jobaway/app/core/utils/haptics.dart';

/// Lecteur de message vocal compact intégré à la bulle : play/pause +
/// progression + durée. L'audio n'est chargé qu'à la première lecture (pas de
/// préchargement de toute la conversation) et le player est libéré à la
/// destruction du widget.
class VoiceMessagePlayer extends StatefulWidget {
  const VoiceMessagePlayer(
      {super.key, required this.url, required this.isMine});

  final String url;
  final bool isMine;

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  final _player = AudioPlayer();
  bool _loaded = false;
  bool _loading = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    AppHaptics.tap();
    try {
      if (!_loaded) {
        setState(() => _loading = true);
        await _player.setUrl(widget.url);
        _loaded = true;
        if (mounted) setState(() => _loading = false);
      }
      if (_player.playing) {
        await _player.pause();
      } else {
        if (_player.processingState == ProcessingState.completed) {
          await _player.seek(Duration.zero);
        }
        await _player.play();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.isMine ? AppColors.onPrimary : AppColors.primaryAccent;
    final track = fg.withValues(alpha: 0.25);

    return SizedBox(
      width: 190,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _toggle,
            child: _loading
                ? SizedBox(
                    width: 28,
                    height: 28,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child:
                          CircularProgressIndicator(strokeWidth: 2, color: fg),
                    ),
                  )
                : StreamBuilder<PlayerState>(
                    stream: _player.playerStateStream,
                    builder: (context, snap) {
                      final playing = snap.data?.playing ?? false;
                      final completed = snap.data?.processingState ==
                          ProcessingState.completed;
                      return Icon(
                        playing && !completed
                            ? Icons.pause_circle_filled_rounded
                            : IconlyBold.play,
                        color: fg,
                        size: 28,
                      );
                    },
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StreamBuilder<Duration>(
              stream: _player.positionStream,
              builder: (context, posSnap) {
                final pos = posSnap.data ?? Duration.zero;
                final dur = _player.duration ?? Duration.zero;
                final frac = dur.inMilliseconds == 0
                    ? 0.0
                    : (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: frac,
                        minHeight: 4,
                        backgroundColor: track,
                        valueColor: AlwaysStoppedAnimation<Color>(fg),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _loaded && dur > Duration.zero
                          ? '${_fmt(pos)} / ${_fmt(dur)}'
                          : 'Message vocal',
                      style: AppTextStyles.bodySm.copyWith(
                        color: fg.withValues(alpha: 0.85),
                        fontSize: 10,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
