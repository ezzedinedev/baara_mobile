import 'package:flutter/material.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:video_player/video_player.dart';

import 'package:baara/app/core/constants/api_constants.dart';
import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_dimens.dart';
import 'package:baara/app/core/theme/app_motion.dart';
import 'package:baara/app/core/theme/app_shapes.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/app/core/widgets/widgets.dart';

/// Lecteur vidéo inline premium pour la carte de publication.
///
/// PERF : le [VideoPlayerController] n'est créé qu'au **premier tap** (jamais au
/// build de la carte), démarre **muet**, et est **disposé** dès que le widget
/// quitte l'arbre. Pas d'autoplay au scroll (tap-to-play).
///
/// États gérés : poster (avant tap), chargement, lecture (contrôles minimaux),
/// erreur discrète si la vidéo ne charge pas.
class PostVideoPlayer extends StatefulWidget {
  const PostVideoPlayer({super.key, required this.url, this.name});

  /// URL brute renvoyée par le backend (résolue via [ApiConstants]).
  final String? url;
  final String? name;

  @override
  State<PostVideoPlayer> createState() => _PostVideoPlayerState();
}

class _PostVideoPlayerState extends State<PostVideoPlayer> {
  VideoPlayerController? _controller;
  bool _initializing = false;
  bool _error = false;
  bool _muted = true;
  bool _showControls = true;

  String? get _resolvedUrl => ApiConstants.resolveMediaUrl(widget.url);

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  Future<void> _start() async {
    if (_initializing || _controller != null) return;
    final url = _resolvedUrl;
    if (url == null || url.isEmpty) {
      setState(() => _error = true);
      return;
    }
    AppHaptics.tap();
    setState(() {
      _initializing = true;
      _error = false;
    });
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      controller
        ..setVolume(0) // démarre muet
        ..setLooping(false)
        ..addListener(_onTick);
      _controller = controller;
      setState(() => _initializing = false);
      await controller.play();
    } catch (_) {
      await controller.dispose();
      if (mounted) {
        setState(() {
          _initializing = false;
          _error = true;
        });
      }
    }
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null) return;
    AppHaptics.tap();
    setState(() {
      if (c.value.isPlaying) {
        c.pause();
      } else {
        // Reprise depuis le début si la vidéo est terminée.
        if (c.value.position >= c.value.duration) {
          c.seekTo(Duration.zero);
        }
        c.play();
      }
      _showControls = true;
    });
  }

  void _toggleMute() {
    final c = _controller;
    if (c == null) return;
    AppHaptics.tap();
    setState(() {
      _muted = !_muted;
      c.setVolume(_muted ? 0 : 1);
    });
  }

  void _openFullscreen() {
    final c = _controller;
    if (c == null) return;
    AppHaptics.tap();
    Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => _FullscreenVideo(controller: c),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final ready = c != null && c.value.isInitialized;
    final aspect = ready ? c.value.aspectRatio : 16 / 9;

    return ClipRRect(
      borderRadius: AppShapes.squircleRadius(AppRadius.sm),
      child: AspectRatio(
        aspectRatio: aspect <= 0 ? 16 / 9 : aspect,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (ready)
              GestureDetector(
                onTap: () => setState(() => _showControls = !_showControls),
                child: VideoPlayer(c),
              )
            else
              _poster(),
            if (ready) _controlsOverlay(c),
          ],
        ),
      ),
    );
  }

  // ── Poster (avant 1er tap / chargement / erreur) ───────────────────────────
  Widget _poster() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceHighest,
            AppColors.onDark.withValues(alpha: 0.92),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!_error)
            Center(
              child: PressScale(
                onTap: _start,
                curve: AppMotion.springEmphasized,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.onDark.withValues(alpha: 0.42),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.onPrimary.withValues(alpha: 0.22),
                      width: 1,
                    ),
                  ),
                  child: _initializing
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: AppLoader(
                            color: AppColors.onPrimary,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(AppIcons.play,
                          color: AppColors.onPrimary, size: 38),
                ),
              ),
            )
          else
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded,
                      color: AppColors.onPrimary.withValues(alpha: 0.7),
                      size: 30),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Vidéo indisponible',
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.onPrimary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          // Pastille vidéo + nom, bas-gauche.
          Positioned(
            left: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: AppShapes.pill,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppIcons.video, size: 13, color: Colors.white),
                  SizedBox(width: 4),
                  Text('Vidéo',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Contrôles minimaux (play/pause, progression, son, plein écran) ─────────
  Widget _controlsOverlay(VideoPlayerController c) {
    final playing = c.value.isPlaying;
    return AnimatedOpacity(
      opacity: _showControls || !playing ? 1 : 0,
      duration: AppMotion.short,
      curve: AppMotion.standard,
      child: IgnorePointer(
        ignoring: !(_showControls || !playing),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Scrim bas pour lisibilité des contrôles.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
            ),
            // Gros bouton play/pause centré.
            Center(
              child: PressScale(
                onTap: _togglePlay,
                curve: AppMotion.springEmphasized,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.42),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    playing ? Icons.pause_rounded : AppIcons.play,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
            ),
            // Barre du bas : progression fine + son + plein écran.
            Positioned(
              left: 10,
              right: 6,
              bottom: 8,
              child: Row(
                children: [
                  Expanded(
                    child: VideoProgressIndicator(
                      c,
                      allowScrubbing: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      colors: VideoProgressColors(
                        playedColor: AppColors.primary,
                        bufferedColor: Colors.white24,
                        backgroundColor: Colors.white12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _RoundCtrl(
                    icon:
                        _muted ? AppIcons.volumeOff : AppIcons.volumeUp,
                    onTap: _toggleMute,
                  ),
                  _RoundCtrl(
                    icon: Icons.fullscreen_rounded,
                    onTap: _openFullscreen,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Petit bouton de contrôle circulaire (chrome lecteur).
class _RoundCtrl extends StatelessWidget {
  const _RoundCtrl({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      curve: AppMotion.spring,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.42),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

/// Vue plein écran : réutilise le même [VideoPlayerController] (pas de
/// ré-initialisation) ; ne le dispose pas (propriété de [PostVideoPlayer]).
class _FullscreenVideo extends StatefulWidget {
  const _FullscreenVideo({required this.controller});
  final VideoPlayerController controller;

  @override
  State<_FullscreenVideo> createState() => _FullscreenVideoState();
}

class _FullscreenVideoState extends State<_FullscreenVideo> {
  VideoPlayerController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onTick);
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _c.removeListener(_onTick);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aspect = _c.value.aspectRatio;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: aspect <= 0 ? 16 / 9 : aspect,
              child: GestureDetector(
                onTap: () {
                  AppHaptics.tap();
                  setState(() {
                    _c.value.isPlaying ? _c.pause() : _c.play();
                  });
                },
                child: VideoPlayer(_c),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 16,
            child: VideoProgressIndicator(
              _c,
              allowScrubbing: true,
              colors: VideoProgressColors(
                playedColor: AppColors.primary,
                bufferedColor: Colors.white24,
                backgroundColor: Colors.white12,
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: _RoundCtrl(
                  icon: AppIcons.closeSquare,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
