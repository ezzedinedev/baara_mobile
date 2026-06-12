import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_motion.dart';
import 'package:opportune_bf/app/core/theme/app_shapes.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/common/press_scale.dart';

import '../controllers/story_controller.dart';

/// Composer de story TEXTE (façon « Aa » Facebook) : fond coloré + texte
/// centré, palette de couleurs, publication.
class StoryTextComposerScreen extends StatefulWidget {
  const StoryTextComposerScreen({super.key});

  @override
  State<StoryTextComposerScreen> createState() =>
      _StoryTextComposerScreenState();
}

class _StoryTextComposerScreenState extends State<StoryTextComposerScreen> {
  static const _palette = <String>[
    '#0E8A4D',
    '#2BA55B',
    '#0A5E36',
    '#2B7FFF',
    '#7A5CFA',
    '#EB4D8A',
    '#FF9D00',
    '#0CA6A6',
    '#374151',
  ];

  final _caption = TextEditingController();
  final _controller = Get.find<StoryController>();
  String _color = _palette.first;
  String _visibility = 'connections';

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Color _parse(String hex) => Color(int.parse(hex.replaceFirst('#', '0xFF')));

  void _publish() {
    final caption = _caption.text.trim();
    if (caption.isEmpty) return;
    // Optimiste : fermeture immédiate, envoi en arrière-plan (pas de popup).
    Get.back<void>();
    _controller.publish(
      caption: caption,
      backgroundColor: _color,
      visibility: _visibility,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = _parse(_color);
    return Scaffold(
      backgroundColor: bg,
      resizeToAvoidBottomInset: true,
      body: AnimatedContainer(
        duration: AppMotion.medium,
        curve: AppMotion.emphasized,
        color: bg,
        child: SafeArea(
          child: Column(
            children: [
              // Bouton fermer squircle haut-gauche.
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: PressScale(
                    onTap: () => Get.back<void>(),
                    curve: AppMotion.spring,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: AppShapes.squircleRadius(AppRadius.md),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.14),
                          width: 1,
                        ),
                      ),
                      child: const Icon(IconlyLight.close_square,
                          color: AppColors.onPrimary, size: 22),
                    ),
                  ),
                ),
              ),
              // Canvas texte — inchangé sauf le champ lui-même (pas de shape ici,
              // c'est un InputBorder.none = canvas libre).
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: TextField(
                      controller: _caption,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      maxLines: null,
                      maxLength: 250,
                      cursorColor: AppColors.onPrimary,
                      textCapitalization: TextCapitalization.sentences,
                      style: AppTextStyles.headlineMd.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                        hintText: 'Écrivez quelque chose…',
                        hintStyle: AppTextStyles.headlineMd.copyWith(
                          color: AppColors.onPrimary.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Palette de couleurs — bulles squircle (presque cercle, restent des
              // disques mais avec un rayon continu légèrement plus doux).
              SizedBox(
                height: 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: 8),
                  itemCount: _palette.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final hex = _palette[i];
                    final selected = hex == _color;
                    return PressScale(
                      haptic: false,
                      onTap: () => setState(() => _color = hex),
                      curve: AppMotion.spring,
                      child: AnimatedContainer(
                        duration: AppMotion.short,
                        curve: AppMotion.spring,
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _parse(hex),
                          // Squircle pour les bulles de couleur.
                          borderRadius: AppShapes.squircleRadius(16),
                          border: Border.all(
                            color: AppColors.onPrimary,
                            width: selected ? 3 : 1.5,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Barre basse : visibilité + publier.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    _VisChip(
                      label: 'Connexions',
                      icon: IconlyLight.user_1,
                      selected: _visibility == 'connections',
                      onTap: () => setState(() => _visibility = 'connections'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _VisChip(
                      label: 'Public',
                      icon: Icons.public_rounded,
                      selected: _visibility == 'public',
                      onTap: () => setState(() => _visibility = 'public'),
                    ),
                    const Spacer(),
                    // Bouton publier squircle pill.
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
                              color: AppColors.onPrimary,
                              borderRadius: AppShapes.pill,
                            ),
                            child: _controller.isPublishing.value
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: bg),
                                  )
                                : Text('Publier',
                                    style: AppTextStyles.buttonMd
                                        .copyWith(color: bg)),
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Chip de visibilité squircle pill ─────────────────────────────────────
class _VisChip extends StatelessWidget {
  const _VisChip({
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
      haptic: false,
      onTap: onTap,
      curve: AppMotion.spring,
      child: AnimatedContainer(
        duration: AppMotion.short,
        curve: AppMotion.emphasized,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.onPrimary
              : Colors.white.withValues(alpha: 0.2),
          borderRadius: AppShapes.pill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 15,
                color: selected ? AppColors.titleColor : AppColors.onPrimary),
            const SizedBox(width: 6),
            Text(label,
                style: AppTextStyles.labelSm.copyWith(
                  color: selected ? AppColors.titleColor : AppColors.onPrimary,
                  fontWeight: FontWeight.w700,
                )),
          ],
        ),
      ),
    );
  }
}
