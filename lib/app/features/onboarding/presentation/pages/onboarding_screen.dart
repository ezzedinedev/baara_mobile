import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:baara/app/core/theme/app_dimens.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:baara/app/core/theme/app_motion.dart';
import 'package:baara/app/core/theme/app_shapes.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/app/core/widgets/widgets.dart';
import '../controllers/onboarding_controller.dart';

/// Premiers pas après l'inscription, dans le langage du splash : fond vert
/// forêt, pastille citron, personnage Baara en filigrane.
///
/// Quatre étapes : profil, CV, opportunités, puis notifications. La demande
/// système de notifications n'arrive qu'à la dernière étape, après avoir dit
/// à quoi elles servent ; « Plus tard » termine sans la déclencher.
class OnboardingScreen extends GetView<OnboardingController> {
  const OnboardingScreen({super.key});

  static const _steps =
      <({IconData icon, String title, String body, String cta})>[
    (
      icon: AppIcons.personFilled,
      title: 'Complétez votre profil',
      body: "Ajoutez votre photo, votre titre et vos compétences depuis "
          "l'onglet Profil pour attirer les recruteurs.",
      cta: 'Suivant',
    ),
    (
      icon: AppIcons.document,
      title: 'Créez ou importez votre CV',
      body: 'Un CV à jour multiplie vos chances. Importez un PDF ou '
          'créez-le avec l\'assistant Baara.',
      cta: 'Suivant',
    ),
    (
      icon: AppIcons.workFilled,
      title: 'Découvrez vos opportunités',
      body: 'Swipez les offres qui vous correspondent, postulez en un geste '
          'et suivez vos candidatures.',
      cta: 'Suivant',
    ),
    (
      icon: AppIcons.notificationFilled,
      title: 'Ne ratez aucune réponse',
      body: 'Soyez prévenu dès qu\'un recruteur vous répond ou qu\'une offre '
          'correspond à votre profil.',
      cta: 'Activer les notifications',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    assert(_steps.length == OnboardingController.stepCount);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: BaaraMark.brandForest,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: BaaraMark.brandForest,
        body: Stack(
          children: [
            // Halo citron et personnage en filigrane, comme les en-têtes.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.35),
                    radius: 0.9,
                    colors: [
                      BaaraMark.brandLime.withValues(alpha: 0.16),
                      BaaraMark.brandLime.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -70,
              bottom: -60,
              child: ExcludeSemantics(
                child: BaaraMark(
                  size: 300,
                  color: Colors.white.withValues(alpha: 0.05),
                  headColor: BaaraMark.brandLime.withValues(alpha: 0.08),
                ),
              ),
            ),
            SafeArea(
              child: Obx(() {
                final step = controller.currentStep.value;
                final isLast = step >= _steps.length - 1;
                final data = _steps[step];

                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 48,
                        child: Row(
                          children: [
                            Text(
                              '${step + 1} / ${_steps.length}',
                              style: AppTextStyles.labelMd.copyWith(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                            const Spacer(),
                            if (!isLast)
                              TextButton(
                                onPressed: controller.skip,
                                child: Text(
                                  'Passer',
                                  style: AppTextStyles.labelLg.copyWith(
                                    color:
                                        Colors.white.withValues(alpha: 0.75),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: reduceMotion
                              ? Duration.zero
                              : AppMotion.medium,
                          switchInCurve: AppMotion.emphasizedDecelerate,
                          switchOutCurve: AppMotion.exit,
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween(
                                begin: const Offset(0.06, 0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          ),
                          child: _StepBody(
                            key: ValueKey(step),
                            icon: data.icon,
                            title: data.title,
                            body: data.body,
                          ),
                        ),
                      ),
                      _StepDots(current: step, total: _steps.length),
                      const SizedBox(height: 24),
                      AuthCtaButton(
                        label: data.cta,
                        backgroundColor: BaaraMark.brandLime,
                        foregroundColor: BaaraMark.brandForest,
                        isLoading: controller.isBusy.value,
                        onPressed: controller.isBusy.value
                            ? null
                            : () {
                                AppHaptics.tap();
                                controller.next(isLast: isLast);
                              },
                      ),
                      // Toujours la même hauteur réservée : le bouton
                      // principal ne saute pas d'une étape à l'autre.
                      SizedBox(
                        height: 52,
                        child: isLast
                            ? Center(
                                child: TextButton(
                                  onPressed: controller.skip,
                                  child: Text(
                                    'Plus tard',
                                    style: AppTextStyles.labelLg.copyWith(
                                      color: Colors.white
                                          .withValues(alpha: 0.75),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: ShapeDecoration(
            color: BaaraMark.brandLime,
            shape: AppShapes.squircle(AppRadius.xl),
            shadows: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Icon(icon, size: 42, color: BaaraMark.brandForest),
        ),
        const SizedBox(height: 36),
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.displayHero.copyWith(
              color: Colors.white,
              fontSize: 30,
              height: 1.12,
              letterSpacing: -0.6,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          body,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyLg.copyWith(
            color: Colors.white.withValues(alpha: 0.78),
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Étape ${current + 1} sur $total',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            AnimatedContainer(
              duration: AppMotion.base,
              curve: AppMotion.emphasized,
              width: i == current ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == current
                    ? BaaraMark.brandLime
                    : Colors.white.withValues(alpha: 0.25),
                borderRadius: AppShapes.pill,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
