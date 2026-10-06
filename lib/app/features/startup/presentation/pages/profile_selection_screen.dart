import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:baara/app/core/theme/app_motion.dart';
import 'package:baara/app/core/theme/app_shapes.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/app/core/widgets/widgets.dart';
import '../controllers/profile_selection_controller.dart';

/// Premier pas de l'inscription : le candidat choisit son parcours.
///
/// Deux options pleine largeur, chacune avec ce qu'elle apporte concrètement
/// (trois puces). La sélection se lit d'un coup d'œil : bordure forêt,
/// pastille citron, coche. « Continuer » reste neutre tant que rien n'est
/// choisi.
class ProfileSelectionScreen extends GetView<ProfileSelectionController> {
  const ProfileSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          WavyAuthHeader(
            height: 150,
            showLeading: true,
            onLeadingTap: () => Get.back(),
            foregroundIcon: AppIcons.profile,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RevealOnMount(
                    child: Semantics(
                      header: true,
                      child: Text(
                        'Quel est votre profil ?',
                        style: AppTextStyles.displayHero.copyWith(
                          fontSize: 28,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  RevealOnMount(
                    delay: const Duration(milliseconds: 60),
                    child: Text(
                      'Nous adaptons les offres et les formations à votre '
                      'situation.',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.bodyColor,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  RevealOnMount(
                    delay: const Duration(milliseconds: 120),
                    child: _ProfileOption(
                      type: ProfileType.jobseeker,
                      icon: AppIcons.workFilled,
                      title: 'Je cherche un emploi',
                      subtitle: 'Trouvez un poste et faites-vous recruter.',
                      perks: const ['Offres', 'Candidatures', 'CV gratuit'],
                      controller: controller,
                    ),
                  ),
                  const SizedBox(height: 14),
                  RevealOnMount(
                    delay: const Duration(milliseconds: 180),
                    child: _ProfileOption(
                      type: ProfileType.student,
                      icon: AppIcons.school,
                      title: 'Je suis étudiant',
                      subtitle: 'Décrochez un stage ou un premier emploi.',
                      perks: const ['Stages', 'Premier emploi', 'Formations'],
                      controller: controller,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
              child: Obx(
                () => AuthCtaButton(
                  label: 'Continuer',
                  onPressed:
                      controller.canContinue ? controller.onContinue : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  const _ProfileOption({
    required this.type,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.perks,
    required this.controller,
  });

  final ProfileType type;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> perks;
  final ProfileSelectionController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selected.value == type;
      final accent = AppColors.primaryAccent;

      return Semantics(
        button: true,
        selected: selected,
        label: '$title. $subtitle',
        excludeSemantics: true,
        child: PressScale(
          haptic: false,
          curve: AppMotion.springEmphasized,
          onTap: () {
            AppHaptics.tap();
            controller.select(type);
          },
          child: AnimatedContainer(
            duration: AppMotion.base,
            curve: AppMotion.emphasizedDecelerate,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              color: selected ? AppColors.surfaceSelected : AppColors.surfaceCard,
              borderRadius: AppShapes.squircleRadius(22),
              border: Border.all(
                color: selected ? accent : AppColors.outlineVariant,
                width: selected ? 2 : 1,
              ),
              boxShadow: selected ? AppColors.ambientShadow : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: AppMotion.base,
                  curve: AppMotion.emphasized,
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: selected
                        ? BaaraMark.brandLime
                        : AppColors.surfaceIconSoft,
                    borderRadius: AppShapes.squircleRadius(16),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: selected ? BaaraMark.brandForest : accent,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: AppTextStyles.titleLg.copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                color: AppColors.titleColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _Check(selected: selected),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.bodyColor,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final perk in perks)
                            _Perk(label: perk, selected: selected),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _Perk extends StatelessWidget {
  const _Perk({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.base,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: selected ? AppColors.surfaceCard : AppColors.surfaceLow,
        borderRadius: AppShapes.pill,
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSm.copyWith(
          color: AppColors.bodyColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Coche ronde : contour vide, puis pastille forêt avec coche citron.
class _Check extends StatelessWidget {
  const _Check({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.base,
      curve: AppMotion.springEmphasized,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.primaryAccent : Colors.transparent,
        border: Border.all(
          color: selected ? AppColors.primaryAccent : AppColors.outlineVariant,
          width: 2,
        ),
      ),
      child: AnimatedScale(
        scale: selected ? 1 : 0,
        duration: AppMotion.base,
        curve: AppMotion.springEmphasized,
        child: Icon(
          AppIcons.check,
          size: 14,
          color: Theme.of(context).brightness == Brightness.dark
              ? BaaraMark.brandForest
              : BaaraMark.brandLime,
        ),
      ),
    );
  }
}
