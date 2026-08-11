import 'package:flutter/material.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:get/get.dart';
import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_dimens.dart';
import 'package:baara/app/core/theme/app_motion.dart';
import 'package:baara/app/core/theme/app_shapes.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/widgets/widgets.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/routes/app_routes.dart';

import '../../controllers/cv_import_controller.dart';

/// Import d'un CV existant (PDF/DOCX/TXT) → analyse IA → amélioration → application.
/// Flux complet câblé à l'API via [CvImportController].
class CvImportScreen extends GetView<CvImportController> {
  const CvImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          WavyContentHeader(
            title: 'Importer un CV',
            subtitle: "Améliorez un CV existant avec l'IA",
            height: 200,
            gradient: AppColors.heroProfileGradient,
            onLeadingTap: () => Get.back<void>(),
          ),
          Expanded(
            child: Obx(() {
              switch (controller.step.value) {
                case CvImportStep.analyzing:
                  return const CvImportProcessingSkeleton(
                    label: 'Analyse de votre CV en cours…',
                    activeStep: 0,
                  );
                case CvImportStep.improving:
                  return const CvImportProcessingSkeleton(
                    label: "Amélioration par l'IA en cours…",
                    activeStep: 1,
                  );
                case CvImportStep.applying:
                  return const CvImportProcessingSkeleton(
                    label: 'Application à votre profil…',
                    activeStep: 2,
                  );
                case CvImportStep.review:
                  return _ReviewStep(controller: controller);
                case CvImportStep.improved:
                  return _ImprovedStep(controller: controller);
                case CvImportStep.done:
                  return const _DoneStep();
                case CvImportStep.pick:
                  return _PickStep(controller: controller);
              }
            }),
          ),
        ],
      ),
    );
  }
}

// ── Étape 1 : sélection du fichier ──────────────────────────────────────
class _PickStep extends StatelessWidget {
  const _PickStep({required this.controller});
  final CvImportController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RevealOnMount(
            child: _UploadZone(onTap: controller.pickAndAnalyze),
          ),
          Obx(() {
            final err = controller.errorMessage.value;
            if (err == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: RevealOnMount(
                child: _ErrorBanner(message: err),
              ),
            );
          }),
          const SizedBox(height: AppSpacing.xxl),
          SectionLabel('Comment ça marche ?'),
          const SizedBox(height: AppSpacing.lg),
          RevealOnMount(
            delay: const Duration(milliseconds: 60),
            child: const _HowItWorksStep(
                number: 1, label: 'Importez votre CV (PDF, DOCX, TXT)'),
          ),
          const SizedBox(height: AppSpacing.md),
          RevealOnMount(
            delay: const Duration(milliseconds: 120),
            child: const _HowItWorksStep(
                number: 2, label: "L'IA analyse et l'améliore"),
          ),
          const SizedBox(height: AppSpacing.md),
          RevealOnMount(
            delay: const Duration(milliseconds: 180),
            child: const _HowItWorksStep(
                number: 3, label: 'Appliquez-le à votre profil'),
          ),
        ],
      ),
    );
  }
}

// ── Étape 2 : revue de l'analyse ────────────────────────────────────────
class _ReviewStep extends StatelessWidget {
  const _ReviewStep({required this.controller});
  final CvImportController controller;

  @override
  Widget build(BuildContext context) {
    final score = controller.cvScore.value;
    final scoreColor = score >= 75
        ? AppColors.successAccent
        : (score >= 45 ? AppColors.warningAccent : AppColors.errorAccent);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _FileChip(name: controller.filename.value ?? 'Votre CV'),
                const SizedBox(height: AppSpacing.xl),
                DecoratedBox(
                  decoration: ShapeDecoration(
                    color: AppColors.surfaceCard,
                    shape: AppShapes.cardBordered(AppColors.outlineVariant),
                    shadows: [
                      ...AppColors.lightShadow,
                      ...AppColors.ambientShadow,
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Row(
                      children: [
                        ScoreRing(
                          value: score,
                          color: scoreColor,
                          size: 76,
                          strokeWidth: 8,
                          valueFontSize: 24,
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Score de votre CV',
                                  style: AppTextStyles.titleMd
                                      .copyWith(fontWeight: FontWeight.w800)),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                "Notre IA peut le réécrire pour le rendre plus clair, mieux structuré et compatible ATS.",
                                style: AppTextStyles.bodySm.copyWith(
                                    color: AppColors.bodyColor, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if ((controller.summary.value ?? '').isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLow,
                      borderRadius: AppShapes.squircleRadius(AppRadius.md),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        controller.summary.value!,
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.bodyColor, height: 1.5),
                      ),
                    ),
                  ),
                ],
                Obx(() {
                  final err = controller.errorMessage.value;
                  if (err == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.lg),
                    child: _ErrorBanner(message: err),
                  );
                }),
              ],
            ),
          ),
        ),
        CvStickyActionBar(
          primaryLabel: "Améliorer avec l'IA",
          onPrimary: controller.improve,
          secondaryLabel: 'Choisir un autre fichier',
          onSecondary: controller.reset,
        ),
      ],
    );
  }
}

// ── Étape 3 : amélioration prête ────────────────────────────────────────
class _ImprovedStep extends StatelessWidget {
  const _ImprovedStep({required this.controller});
  final CvImportController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DecoratedBox(
                  decoration: ShapeDecoration(
                    color: AppColors.successSoft,
                    shape: AppShapes.cardBordered(
                      AppColors.successAccent.withValues(alpha: 0.25),
                    ),
                    shadows: [...AppColors.ambientShadow],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            color: AppColors.successAccent, size: 28),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Votre CV a été amélioré',
                                  style: AppTextStyles.titleMd
                                      .copyWith(fontWeight: FontWeight.w800)),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                "L'IA a réécrit et structuré le contenu. Appliquez-le pour mettre à jour votre profil.",
                                style: AppTextStyles.bodySm.copyWith(
                                    color: AppColors.bodyColor, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Obx(() {
                  final err = controller.errorMessage.value;
                  if (err == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.lg),
                    child: _ErrorBanner(message: err),
                  );
                }),
              ],
            ),
          ),
        ),
        CvStickyActionBar(
          primaryLabel: 'Appliquer à mon CV',
          onPrimary: () async {
            final ok = await controller.apply();
            if (ok) {
              AppToast.success(
                  'CV mis à jour', 'Votre profil a été enrichi.');
            }
          },
        ),
      ],
    );
  }
}

// ── Étape finale ────────────────────────────────────────────────────────
class _DoneStep extends StatelessWidget {
  const _DoneStep();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.successSoft,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.successAccent.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Icon(AppIcons.tickSquare,
                        size: 44, color: AppColors.successAccent),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text('CV mis à jour !',
                      style: AppTextStyles.titleLg
                          .copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Votre CV importé a été appliqué à votre profil Baara.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMd
                        .copyWith(color: AppColors.bodyColor, height: 1.45),
                  ),
                ],
              ),
            ),
          ),
        ),
        CvStickyActionBar(
          primaryLabel: "Voir l'aperçu",
          onPrimary: () => Get.offNamed(AppRoutes.profileCvPreview),
          secondaryLabel: 'Terminer',
          onSecondary: () => Get.back<void>(),
        ),
      ],
    );
  }
}

// ── Widgets partagés ────────────────────────────────────────────────────
class _FileChip extends StatelessWidget {
  const _FileChip({required this.name});
  final String name;
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceSelected,
        borderRadius: AppShapes.squircleRadius(AppRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(AppIcons.document, color: AppColors.primaryAccent, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style:
                    AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: AppShapes.squircleRadius(AppRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded,
                color: AppColors.errorAccent, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodySm
                    .copyWith(color: AppColors.errorStrong, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grande zone d'upload tappable avec bordure pointillée simulée.
class _UploadZone extends StatelessWidget {
  const _UploadZone({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: () {
        AppHaptics.tap();
        onTap();
      },
      curve: AppMotion.spring,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          borderRadius: AppShapes.squircleRadius(AppRadius.lg),
          border: Border.all(color: AppColors.primaryLight, width: 1.6),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          child: _UploadZoneContent(),
        ),
      ),
    );
  }
}

class _UploadZoneContent extends StatelessWidget {
  const _UploadZoneContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.surfaceIconSoft,
            shape: BoxShape.circle,
          ),
          child: Icon(AppIcons.upload,
              color: AppColors.primaryAccent, size: 32),
        ),
        const SizedBox(height: 18),
        Text('Choisir un fichier',
            style: AppTextStyles.titleMd, textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(
          'PDF, DOCX, TXT · max 10 Mo',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.hintColor),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Étape numérotée de la section « Comment ça marche ? ».
class _HowItWorksStep extends StatelessWidget {
  const _HowItWorksStep({required this.number, required this.label});
  final int number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: AppTextStyles.labelSm.copyWith(color: AppColors.onPrimary),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: AppTextStyles.bodyMd)),
      ],
    );
  }
}
