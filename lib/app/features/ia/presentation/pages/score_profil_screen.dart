import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_dimens.dart';
import 'package:baara/app/core/theme/app_motion.dart';
import 'package:baara/app/core/theme/app_shapes.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/widgets/widgets.dart';

import '../controllers/score_profil_controller.dart';

/// Score de profil intelligent : jauge globale + décomposition par axe +
/// suggestions d'amélioration. Données via [ScoreProfilController].
class ScoreProfilScreen extends GetView<ScoreProfilController> {
  const ScoreProfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          WavyContentHeader(
            title: 'Score de profil',
            subtitle: 'Votre profil vu par l\'IA de recrutement',
            height: 200,
            gradient: AppColors.heroProfileGradient,
            onLeadingTap: () => Get.back(),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const _ScoreSkeleton();
              }
              if (controller.errorMessage.value != null) {
                return ErrorStateView(
                  message: controller.errorMessage.value!,
                  illustration: const ErrorIllustration(),
                  onRetry: controller.load,
                );
              }
              final score = controller.score.value;
              if (score == null) {
                return ErrorStateView(
                  message: 'Aucun score disponible pour le moment.',
                  onRetry: controller.load,
                );
              }
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
                      child: _ScoreGauge(value: score.overall),
                    ),
                    const SizedBox(height: 28),
                    if (score.breakdown.isNotEmpty) ...[
                      RevealOnMount(
                        delay: AppMotion.stagger,
                        duration: AppMotion.medium,
                        child: const SectionHeader(title: 'Détail par axe'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ..._breakdownEntries(score.breakdown).indexed.map(
                            (e) => RevealOnMount(
                              delay: AppMotion.stagger * (e.$1 + 2),
                              duration: AppMotion.medium,
                              child:
                                  _AxisBar(label: e.$2.key, value: e.$2.value),
                            ),
                          ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                    if (score.suggestions.isNotEmpty) ...[
                      RevealOnMount(
                        delay: AppMotion.stagger,
                        duration: AppMotion.medium,
                        child: const SectionHeader(
                            title: 'Pistes d\'amélioration'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ...score.suggestions.indexed.map(
                        (e) => RevealOnMount(
                          delay: AppMotion.stagger * (e.$1 + 2),
                          duration: AppMotion.medium,
                          child: _SuggestionCard(data: e.$2),
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

  /// Normalise les valeurs du breakdown en pourcentage 0-100.
  List<MapEntry<String, int>> _breakdownEntries(Map<String, dynamic> raw) {
    return raw.entries.map((e) {
      final v = e.value;
      double pct;
      if (v is num) {
        pct = v <= 1 ? v * 100 : v.toDouble();
      } else if (v is Map && v['score'] is num) {
        final s = (v['score'] as num).toDouble();
        pct = s <= 1 ? s * 100 : s;
      } else {
        pct = 0;
      }
      return MapEntry(e.key, pct.clamp(0, 100).round());
    }).toList();
  }
}

String prettifyKey(String key) {
  final cleaned = key.replaceAll('_', ' ').replaceAll('-', ' ').trim();
  if (cleaned.isEmpty) return key;
  return cleaned[0].toUpperCase() + cleaned.substring(1);
}

Color scoreColor(int value) {
  if (value >= 75) return AppColors.successAccent;
  if (value >= 45) return AppColors.warningAccent;
  return AppColors.errorAccent;
}

class _ScoreGauge extends StatelessWidget {
  const _ScoreGauge({required this.value});
  final int value;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScoreRing(
        value: value,
        color: scoreColor(value),
        size: 168,
        strokeWidth: 12,
        valueFontSize: 46,
        suffix: '/ 100',
      ),
    );
  }
}

class _AxisBar extends StatelessWidget {
  const _AxisBar({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(prettifyKey(label), style: AppTextStyles.labelMd),
              AnimatedCount(
                value: value,
                builder: (_, v) => Text(
                  '$v%',
                  style: AppTextStyles.labelMd.copyWith(
                    color: scoreColor(value),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) {
              final color = scoreColor(value);
              return ClipRRect(
                borderRadius: AppShapes.pill,
                child: Container(
                  height: 8,
                  width: constraints.maxWidth,
                  color: AppColors.surfaceHigh,
                  alignment: Alignment.centerLeft,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: value / 100),
                    duration: AppMotion.long,
                    curve: AppMotion.emphasizedDecelerate,
                    builder: (context, v, _) => Container(
                      height: 8,
                      width: constraints.maxWidth * v,
                      decoration: BoxDecoration(
                        borderRadius: AppShapes.pill,
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            color.withValues(alpha: 0.55),
                            color,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final title =
        (data['title'] ?? data['label'] ?? data['category'] ?? 'Suggestion')
            .toString();
    final desc = (data['description'] ??
            data['message'] ??
            data['detail'] ??
            data['text'] ??
            '')
        .toString();

    return PressScale(
      onTap: null,
      child: Container(
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceIconSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lightbulb_outline_rounded,
                color: AppColors.primaryAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleMd
                        .copyWith(fontWeight: FontWeight.w800),
                  ),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      desc,
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.bodyColor, height: 1.4),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreSkeleton extends StatelessWidget {
  const _ScoreSkeleton();

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
        const Center(
          child: SkeletonBox(width: 168, height: 168, shape: BoxShape.circle),
        ),
        const SizedBox(height: 28),
        for (var i = 0; i < 4; i++)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: SkeletonBox(width: double.infinity, height: 28, radius: 8),
          ),
        const SizedBox(height: 12),
        for (var i = 0; i < 3; i++)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: SkeletonBox(
              width: double.infinity,
              height: 76,
              radius: AppRadius.xl * 1.7,
            ),
          ),
      ],
    );
  }
}
