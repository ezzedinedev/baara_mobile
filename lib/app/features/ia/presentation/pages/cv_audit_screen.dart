import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
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
              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: controller.load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  children: [
                    _QualityCard(
                      quality: audit.overallQuality,
                      atsFriendly: audit.atsFriendly,
                    ),
                    const SizedBox(height: 24),
                    if (audit.keywordsMissing.isNotEmpty) ...[
                      const SectionHeader(title: 'Mots-clés manquants'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: audit.keywordsMissing
                            .map((k) => _KeywordChip(label: k))
                            .toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (sections.isNotEmpty) ...[
                      const SectionHeader(title: 'Revue par section'),
                      const SizedBox(height: 12),
                      ...sections.map(
                        (e) => _SectionCard(sectionKey: e.key, value: e.value),
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
  if (v >= 75) return AppColors.success;
  if (v >= 45) return AppColors.warning;
  return AppColors.error;
}

class _QualityCard extends StatelessWidget {
  const _QualityCard({required this.quality, required this.atsFriendly});
  final int quality;
  final bool atsFriendly;

  @override
  Widget build(BuildContext context) {
    final color = _qualityColor(quality);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.lightShadow,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            height: 88,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: quality / 100),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => SizedBox(
                    width: 88,
                    height: 88,
                    child: CircularProgressIndicator(
                      value: v,
                      strokeWidth: 8,
                      backgroundColor: AppColors.surfaceHigh,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                ),
                Text('$quality',
                    style: AppTextStyles.headlineMd
                        .copyWith(fontWeight: FontWeight.w900, color: color)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Qualité globale',
                    style: AppTextStyles.titleMd
                        .copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
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
    final color = atsFriendly ? AppColors.success : AppColors.warning;
    final bg = atsFriendly ? AppColors.successSoft : AppColors.warningSoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            atsFriendly
                ? Icons.check_circle_rounded
                : Icons.warning_amber_rounded,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMd
            .copyWith(color: AppColors.warning, fontWeight: FontWeight.w700),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.lightShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(_prettify(sectionKey),
                    style: AppTextStyles.titleMd
                        .copyWith(fontWeight: FontWeight.w800)),
              ),
              if (score != null)
                Text('$score%',
                    style: AppTextStyles.labelMd.copyWith(
                        color: _qualityColor(score),
                        fontWeight: FontWeight.w800)),
            ],
          ),
          if (feedback.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(feedback,
                style: AppTextStyles.bodySm
                    .copyWith(color: AppColors.bodyColor, height: 1.4)),
          ],
          const SizedBox(height: 12),
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
                        AppToast.error('Réécriture indisponible pour le moment.');
                      }
                    },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSelected,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (busy)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      )
                    else
                      const Icon(IconlyLight.edit,
                          size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(busy ? 'Réécriture…' : 'Réécrire avec l\'IA',
                        style: AppTextStyles.labelMd.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700)),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollCtrl) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Proposition IA — ${_prettify(section)}',
                  style: AppTextStyles.titleLg
                      .copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  child: Text(text,
                      style: AppTextStyles.bodyMd
                          .copyWith(color: AppColors.titleColor, height: 1.5)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  onPressed: () {
                    AppHaptics.tap();
                    Navigator.of(ctx).pop();
                  },
                  child: Text('Fermer',
                      style: AppTextStyles.titleMd.copyWith(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w700)),
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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        const SkeletonBox(width: double.infinity, height: 128, radius: 22),
        const SizedBox(height: 24),
        const SkeletonBox(width: 180, height: 20, radius: 8),
        const SizedBox(height: 12),
        for (var i = 0; i < 3; i++)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: SkeletonBox(width: double.infinity, height: 110, radius: 18),
          ),
      ],
    );
  }
}
