import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:video_player/video_player.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_motion.dart';
import 'package:opportune_bf/app/core/theme/app_shapes.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/common/press_scale.dart';

import '../controllers/story_controller.dart';

/// Aperçu plein écran avant publication : légende + visibilité + Publier.
class StoryComposerScreen extends StatefulWidget {
  const StoryComposerScreen({
    super.key,
    required this.mediaPath,
    this.isVideo = false,
  });
  final String mediaPath;
  final bool isVideo;

  @override
  State<StoryComposerScreen> createState() => _StoryComposerScreenState();
}

class _StoryComposerScreenState extends State<StoryComposerScreen> {
  final _caption = TextEditingController();
  final _controller = Get.find<StoryController>();
  String _visibility = 'connections';
  VideoPlayerController? _video;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      _video = VideoPlayerController.file(File(widget.mediaPath))
        ..setLooping(true)
        ..setVolume(0)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            _video!.play();
          }
        });
    }
  }

  @override
  void dispose() {
    _caption.dispose();
    _video?.dispose();
    super.dispose();
  }

  void _publish() {
    // Optimiste : on ferme tout de suite, l'envoi se fait en arrière-plan et la
    // barre se rafraîchit quand c'est prêt (pas de popup « envoyée »).
    final caption = _caption.text.trim();
    Get.back<void>();
    _controller.publish(
      mediaPath: widget.mediaPath,
      caption: caption,
      visibility: _visibility,
    );
  }

  Widget _preview() {
    if (widget.isVideo) {
      final v = _video;
      if (v == null || !v.value.isInitialized) {
        return const Center(
          child: CircularProgressIndicator(
              color: AppColors.onPrimary, strokeWidth: 2),
        );
      }
      return Center(
        child: AspectRatio(
          aspectRatio: v.value.aspectRatio,
          child: VideoPlayer(v),
        ),
      );
    }
    return Image.file(File(widget.mediaPath), fit: BoxFit.contain);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Média plein écran (image ou vidéo) — canvas inchangé.
          Positioned.fill(child: _preview()),
          // Scrim bas pour lisibilité des contrôles.
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
            ),
          ),
          // Fermer — bouton squircle haut-gauche.
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: _RoundBtn(
                  icon: IconlyLight.close_square,
                  onTap: () => Get.back<void>(),
                ),
              ),
            ),
          ),
          // Contrôles bas.
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Champ légende squircle cohérent avec la charte.
                    TextField(
                      controller: _caption,
                      style: AppTextStyles.bodyMd
                          .copyWith(color: AppColors.onPrimary),
                      maxLines: 3,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Ajouter une légende…',
                        hintStyle: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.onPrimary.withValues(alpha: 0.7)),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.14),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: AppShapes.squircleRadius(AppRadius.lg),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppShapes.squircleRadius(AppRadius.lg),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppShapes.squircleRadius(AppRadius.lg),
                          borderSide: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        _VisibilityChip(
                          label: 'Mes connexions',
                          icon: IconlyLight.user_1,
                          selected: _visibility == 'connections',
                          onTap: () =>
                              setState(() => _visibility = 'connections'),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _VisibilityChip(
                          label: 'Public',
                          icon: Icons.public_rounded,
                          selected: _visibility == 'public',
                          onTap: () => setState(() => _visibility = 'public'),
                        ),
                        const Spacer(),
                        // Bouton Publier squircle pill spring.
                        Obx(() => PressScale(
                              onTap: _controller.isPublishing.value
                                  ? null
                                  : () {
                                      AppHaptics.success();
                                      _publish();
                                    },
                              curve: AppMotion.springEmphasized,
                              child: AnimatedContainer(
                                duration: AppMotion.short,
                                curve: AppMotion.emphasized,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: AppShapes.pill,
                                ),
                                child: _controller.isPublishing.value
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.onPrimary,
                                        ),
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('Publier',
                                              style: AppTextStyles.buttonMd
                                                  .copyWith(
                                                      color:
                                                          AppColors.onPrimary)),
                                          const SizedBox(width: 6),
                                          const Icon(IconlyLight.send,
                                              size: 16,
                                              color: AppColors.onPrimary),
                                        ],
                                      ),
                              ),
                            )),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bouton fermer squircle chrome ─────────────────────────────────────────
class _RoundBtn extends StatelessWidget {
  const _RoundBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      curve: AppMotion.spring,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: AppShapes.squircleRadius(AppRadius.md),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.14),
            width: 1,
          ),
        ),
        child: Icon(icon, color: AppColors.onPrimary, size: 22),
      ),
    );
  }
}

// ── Chip de visibilité squircle pill ─────────────────────────────────────
class _VisibilityChip extends StatelessWidget {
  const _VisibilityChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      haptic: false,
      curve: AppMotion.spring,
      child: AnimatedContainer(
        duration: AppMotion.short,
        curve: AppMotion.emphasized,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : Colors.white.withValues(alpha: 0.16),
          borderRadius: AppShapes.pill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.onPrimary),
            const SizedBox(width: 6),
            Text(label,
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.w700,
                )),
          ],
        ),
      ),
    );
  }
}
