import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';

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
              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: controller.load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  children: [
                    _ScoreGauge(value: score.overall),
                    const SizedBox(height: 28),
                    if (score.breakdown.isNotEmpty) ...[
                      const SectionHeader(title: 'Détail par axe'),
                      const SizedBox(height: 12),
                      ..._breakdownEntries(score.breakdown)
                          .map((e) => _AxisBar(label: e.key, value: e.value)),
                      const SizedBox(height: 20),
                    ],
                    if (score.suggestions.isNotEmpty) ...[
                      const SectionHeader(title: 'Pistes d\'amélioration'),
                      const SizedBox(height: 12),
                      ...score.suggestions.map((s) => _SuggestionCard(data: s)),
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
  if (value >= 75) return AppColors.success;
  if (value >= 45) return AppColors.warning;
  return AppColors.error;
}

class _ScoreGauge extends StatelessWidget {
  const _ScoreGauge({required this.value});
  final int value;

  @override
  Widget build(BuildContext context) {
    final color = scoreColor(value);
    return Center(
      child: SizedBox(
        width: 168,
        height: 168,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 168,
              height: 168,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value / 100),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => CircularProgressIndicator(
                  value: v,
                  strokeWidth: 12,
                  backgroundColor: AppColors.surfaceHigh,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$value',
                  style: AppTextStyles.displayMd.copyWith(
                    fontSize: 46,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                Text('/ 100',
                    style: AppTextStyles.bodySm
                        .copyWith(color: AppColors.hintColor)),
              ],
            ),
          ],
        ),
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
              Text('$value%',
                  style: AppTextStyles.labelMd.copyWith(
                      color: scoreColor(value), fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value / 100),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOut,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 8,
                backgroundColor: AppColors.surfaceHigh,
                valueColor: AlwaysStoppedAnimation<Color>(scoreColor(value)),
              ),
            ),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.lightShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lightbulb_outline_rounded,
                color: AppColors.primaryDark, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.titleMd
                        .copyWith(fontWeight: FontWeight.w800)),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(desc,
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.bodyColor, height: 1.4)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreSkeleton extends StatelessWidget {
  const _ScoreSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        const Center(
          child: SkeletonBox(
              width: 168, height: 168, shape: BoxShape.circle),
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
            child: SkeletonBox(width: double.infinity, height: 76, radius: 18),
          ),
      ],
    );
  }
}
