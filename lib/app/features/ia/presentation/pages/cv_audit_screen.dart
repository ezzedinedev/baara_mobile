import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_motion.dart';
import 'package:opportune_bf/app/core/theme/app_shapes.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';

import '../controllers/cv_audit_controller.dart';

/// Audit qualité du CV : score global, compatibilité ATS, mots-clés manquants
/// et revue section par section avec réécriture IA à la demande.
class CvAuditScreen extends GetView<CvAuditController> {
  const CvAuditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          WavyContentHeader(
            title: 'Audit de CV',
            subtitle: 'Diagnostic complet et conseils pour vous démarquer',
            height: 200,
            gradient: AppColors.heroTrainingsGradient,
            onLeadingTap: () => Get.back(),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const _AuditSkeleton();
              }
              if (controller.errorMessage.value != null) {
                return ErrorStateView(
                  message: controller.errorMessage.value!,
                  illustration: const ErrorIllustration(),
                  onRetry: controller.load,
                );
              }
              final audit = controller.audit.value;
              if (audit == null) {
                return ErrorStateView(
                  message: 'Aucun audit disponible pour le moment.',
                  onRetry: controller.load,
                );
              }
              final sections = audit.sections.entries.toList();
              return AppRefreshIndicator(
                color: AppColors.primaryAccent,
                onRefresh: controller.load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.xxl,
                    AppSpacing.xl,
                    40,
                  ),
                  children: [
                    RevealOnMount(
                      duration: AppMotion.long,
                      child: _QualityCard(
                        quality: audit.overallQuality,
                        atsFriendly: audit.atsFriendly,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    if (audit.keywordsMissing.isNotEmpty) ...[
                      RevealOnMount(
                        delay: AppMotion.stagger,
                        duration: AppMotion.medium,
                        child:
                            const SectionHeader(title: 'Mots-clés manquants'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      RevealOnMount(
                        delay: AppMotion.stagger * 2,
                        duration: AppMotion.medium,
                        child: Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: audit.keywordsMissing
                              .map((k) => _KeywordChip(label: k))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                    if (sections.isNotEmpty) ...[
                      RevealOnMount(
                        delay: AppMotion.stagger,
                        duration: AppMotion.medium,
                        child: const SectionHeader(title: 'Revue par section'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ...sections.indexed.map(
                        (e) => RevealOnMount(
                          delay: AppMotion.stagger * (e.$1 + 2),
                          duration: AppMotion.medium,
                          child: _SectionCard(
                              sectionKey: e.$2.key, value: e.$2.value),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

String _prettify(String key) {
  final cleaned = key.replaceAll('_', ' ').replaceAll('-', ' ').trim();
  if (cleaned.isEmpty) return key;
  return cleaned[0].toUpperCase() + cleaned.substring(1);
}

Color _qualityColor(int v) {
  if (v >= 75) return AppColors.successAccent;
  if (v >= 45) return AppColors.warningAccent;
  return AppColors.errorAccent;
}

class _QualityCard extends StatelessWidget {
  const _QualityCard({required this.quality, required this.atsFriendly});
  final int quality;
  final bool atsFriendly;

  @override
  Widget build(BuildContext context) {
    final color = _qualityColor(quality);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: ShapeDecoration(
        color: AppColors.surfaceCard,
        shape: AppShapes.cardBordered(AppColors.outlineVariant),
        shadows: [
          ...AppColors.lightShadow,
          ...AppColors.ambientShadow,
        ],
      ),
      child: Row(
        children: [
          ScoreRing(
            value: quality,
            color: color,
            size: 88,
            strokeWidth: 8,
            valueFontSize: 26,
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Qualité globale',
                  style: AppTextStyles.titleMd
                      .copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.sm),
                _AtsBadge(atsFriendly: atsFriendly),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AtsBadge extends StatelessWidget {
  const _AtsBadge({required this.atsFriendly});
  final bool atsFriendly;

  @override
  Widget build(BuildContext context) {
    final color =
        atsFriendly ? AppColors.successAccent : AppColors.warningAccent;
    final bg = atsFriendly ? AppColors.successSoft : AppColors.warningSoft;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppShapes.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            atsFriendly ? IconlyBold.tick_square : Icons.warning_amber_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              atsFriendly
                  ? 'Compatible logiciels RH (ATS)'
                  : 'À optimiser pour les ATS',
              style: AppTextStyles.labelSm
                  .copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeywordChip extends StatelessWidget {
  const _KeywordChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: AppShapes.squircleRadius(AppRadius.sm),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMd.copyWith(
          color: AppColors.warningAccent,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.sectionKey, required this.value});
  final String sectionKey;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CvAuditController>();

    String feedback;
    int? score;
    if (value is Map) {
      feedback = (value['feedback'] ??
              value['message'] ??
              value['comment'] ??
              value['detail'] ??
              '')
          .toString();
      final s = value['score'];
      if (s is num) score = (s <= 1 ? s * 100 : s).round();
    } else {
      feedback = value?.toString() ?? '';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: ShapeDecoration(
        color: AppColors.surfaceCard,
        shape: AppShapes.cardBordered(AppColors.outlineVariant),
        shadows: [
          ...AppColors.lightShadow,
          ...AppColors.ambientShadow,
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _prettify(sectionKey),
                  style: AppTextStyles.titleMd
                      .copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (score != null)
                Text(
                  '$score%',
                  style: AppTextStyles.labelMd.copyWith(
                    color: _qualityColor(score),
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          if (feedback.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              feedback,
              style: AppTextStyles.bodySm
                  .copyWith(color: AppColors.bodyColor, height: 1.4),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Obx(() {
            final busy = controller.rewritingSection.value == sectionKey;
            return PressScale(
              onTap: busy
                  ? null
                  : () async {
                      AppHaptics.tap();
                      final result =
                          await controller.rewriteSection(sectionKey);
                      if (!context.mounted) return;
                      if (result != null && result.isNotEmpty) {
                        _showRewriteSheet(context, sectionKey, result);
                      } else if (result == null) {
                        AppToast.error(
                            'Réécriture indisponible pour le moment.');
                      }
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSelected,
                  borderRadius: AppShapes.squircleRadius(AppRadius.sm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (busy)
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryAccent),
                        ),
                      )
                    else
                      Icon(
                        IconlyLight.edit,
                        size: 16,
                        color: AppColors.primaryAccent,
                      ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      busy ? 'Réécriture…' : 'Réécrire avec l\'IA',
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.primaryAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showRewriteSheet(BuildContext context, String section, String text) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheetTop),
        ),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollCtrl) => Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHighest,
                    borderRadius: AppShapes.pill,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Proposition IA — ${_prettify(section)}',
                style:
                    AppTextStyles.titleLg.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  child: Text(
                    text,
                    style: AppTextStyles.bodyMd
                        .copyWith(color: AppColors.titleColor, height: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppShapes.pill,
                    ),
                  ),
                  onPressed: () {
                    AppHaptics.tap();
                    Navigator.of(ctx).pop();
                  },
                  child: Text(
                    'Fermer',
                    style: AppTextStyles.titleMd.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuditSkeleton extends StatelessWidget {
  const _AuditSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xxl,
        AppSpacing.xl,
        40,
      ),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        SkeletonBox(
          width: double.infinity,
          height: 128,
          radius: AppRadius.xl * 1.7,
        ),
        const SizedBox(height: AppSpacing.xxl),
        const SkeletonBox(width: 180, height: 20, radius: 8),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: SkeletonBox(
              width: double.infinity,
              height: 110,
              radius: AppRadius.xl * 1.7,
            ),
          ),
      ],
    );
  }
}
