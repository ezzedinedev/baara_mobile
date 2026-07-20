import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:jobaway/app/core/theme/app_colors.dart';
import 'package:jobaway/app/core/theme/app_dimens.dart';
import 'package:jobaway/app/core/theme/app_motion.dart';
import 'package:jobaway/app/core/theme/app_shapes.dart';
import 'package:jobaway/app/core/theme/app_text_styles.dart';
import 'package:jobaway/app/core/utils/haptics.dart';
import 'package:jobaway/app/core/widgets/widgets.dart';
import '../controllers/profile_selection_controller.dart';

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
            foregroundIcon: IconlyLight.profile,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RevealOnMount(
                    child: Text('Choisissez votre profil',
                        style:
                            AppTextStyles.displayHero.copyWith(fontSize: 28)),
                  ),
                  const SizedBox(height: 7),
                  Container(
                      width: 46,
                      height: 4,
                      decoration: BoxDecoration(
                          color: AppColors.primaryAccent,
                          borderRadius: AppShapes.pill)),
                  const SizedBox(height: 8),
                  RevealOnMount(
                    delay: const Duration(milliseconds: 60),
                    child: Text(
                        'Sélectionnez le profil qui correspond à votre situation.',
                        style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.bodyColor,
                            height: 1.35,
                            fontSize: 13)),
                  ),
                  const SizedBox(height: 22),
                  // Deux cartes pleine largeur, l'une SOUS l'autre, de MÊME
                  // taille. Le recrutement (entreprise) se fait sur le web.
                  RevealOnMount(
                    delay: const Duration(milliseconds: 120),
                    child: _ProfileCard(
                      type: ProfileType.jobseeker,
                      icon: IconlyBold.work,
                      title: 'Je cherche un emploi',
                      subtitle: 'Trouvez un emploi et soyez recruté.',
                      gradient: AppColors.primaryGradient,
                      glow: AppColors.primaryAccent,
                      controller: controller,
                    ),
                  ),
                  const SizedBox(height: 12),
                  RevealOnMount(
                    delay: const Duration(milliseconds: 175),
                    child: _ProfileCard(
                      type: ProfileType.student,
                      icon: Icons.school_rounded,
                      title: 'Je suis étudiant',
                      subtitle: 'Cherchez un emploi ou un stage.',
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.secondary, AppColors.primary],
                      ),
                      glow: AppColors.secondary,
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
              padding: const EdgeInsets.fromLTRB(26, 6, 26, 22),
              child: Obx(() => AuthCtaButton(
                  label: 'Continuer',
                  onPressed:
                      controller.canContinue ? controller.onContinue : null)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte de profil verticale, élégante et de taille fixe (utilisée dans un
/// `Row` + `IntrinsicHeight` pour deux cartes parfaitement égales) : icône
/// « travaillée » (badge dégradé glossy) + titre + sous-titre, avec un état
/// sélectionné vivant (bordure + glow + coche qui pop).
class _ProfileCard extends StatelessWidget {
  final ProfileType type;
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final Color glow;
  final ProfileSelectionController controller;

  const _ProfileCard({
    required this.type,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.glow,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isSelected = controller.selected.value == type;
      return PressScale(
        haptic: false,
        curve: AppMotion.springEmphasized,
        onTap: () {
          AppHaptics.tap();
          controller.select(type);
        },
        child: AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.emphasizedDecelerate,
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                isSelected ? AppColors.surfaceSelected : AppColors.surfaceCard,
            borderRadius: AppShapes.squircleRadius(AppRadius.xl),
            border: Border.all(
                color: isSelected
                    ? AppColors.primaryAccent
                    : AppColors.outlineVariant.withValues(alpha: 0.25),
                width: isSelected ? 1.6 : 0.8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryAccent.withValues(alpha: 0.18),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : AppColors.lightShadow,
          ),
          child: Row(
            children: [
              _CraftedIcon(icon: icon, gradient: gradient, glow: glow),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleLg.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        letterSpacing: -0.3,
                        color: isSelected
                            ? AppColors.primaryAccent
                            : AppColors.titleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.bodyColor,
                        height: 1.3,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _SelectDot(isSelected: isSelected),
            ],
          ),
        ),
      );
    });
  }
}

/// Icône « travaillée » : badge dégradé en squircle, reflet glossy en haut et
/// halo coloré dessous (effet 3D/matière), avec une icône pleine au centre.
class _CraftedIcon extends StatelessWidget {
  const _CraftedIcon({
    required this.icon,
    required this.gradient,
    required this.glow,
  });

  final IconData icon;
  final Gradient gradient;
  final Color glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: AppShapes.squircleRadius(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: glow.withValues(alpha: 0.34),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Reflet glossy : voile clair en haut qui s'estompe (matière brillante).
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: AppShapes.squircleRadius(AppRadius.md),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [
                    AppColors.onPrimary.withValues(alpha: 0.28),
                    AppColors.onPrimary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Icon(icon, color: AppColors.onPrimary, size: 27),
          ),
        ],
      ),
    );
  }
}

/// Pastille de sélection : se remplit en vert avec une coche qui « pop ».
class _SelectDot extends StatelessWidget {
  const _SelectDot({required this.isSelected});
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.medium,
      curve: AppMotion.springEmphasized,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? AppColors.primaryAccent : Colors.transparent,
        border: Border.all(
          color:
              isSelected ? AppColors.primaryAccent : AppColors.outlineVariant,
          width: 2,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primaryAccent.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: AnimatedScale(
        scale: isSelected ? 1.0 : 0.0,
        duration: AppMotion.medium,
        curve: AppMotion.springEmphasized,
        child: const Icon(Icons.check_rounded,
            size: 15, color: AppColors.onPrimary),
      ),
    );
  }
}
