import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../controllers/training_detail_controller.dart';
import '../data/models/training_model.dart';

/// Detail d'une formation — hero (cover image / fallback gradient
/// violet-cyan), metadonnees, description, modules, objectifs, prerequis,
/// CTA "S'inscrire" / "Continuer" en bottom bar.
class TrainingDetailScreen extends GetView<TrainingDetailController> {
  const TrainingDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        final isLoading = controller.isLoading.value;
        final error = controller.errorMessage.value;
        final training = controller.training.value;

        if (isLoading && training == null) {
          return const _TrainingDetailSkeleton();
        }

        if (training == null) {
          return SafeArea(
            child: Column(
              children: [
                const _MinimalBackBar(),
                Expanded(
                  child: ErrorStateView(
                    message: error.isEmpty ? 'Formation introuvable.' : error,
                    onRetry: controller.refreshTraining,
                  ),
                ),
              ],
            ),
          );
        }

        return _TrainingDetailContent(training: training);
      }),
      bottomNavigationBar: Obx(() {
        final training = controller.training.value;
        if (training == null) return const SizedBox.shrink();
        return _EnrollBottomBar(training: training);
      }),
    );
  }
}

class _TrainingDetailContent extends StatelessWidget {
  const _TrainingDetailContent({required this.training});

  final TrainingModel training;

  @override
  Widget build(BuildContext context) {
    final isFree = training.price == null || training.price == 0;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => Get.find<TrainingDetailController>().refreshTraining(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          // ───────── HERO ─────────
          RevealOnMount(
            duration: const Duration(milliseconds: 540),
            offsetY: 18,
            child: _TrainingHero(training: training),
          ),
          const SizedBox(height: 18),
          // ───────── Bandeau prix + certification ─────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: _PriceBanner(training: training, isFree: isFree),
          ),
          const SizedBox(height: 14),
          // ───────── Metas (provider / format / level / etc.) ─────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: _MetaGrid(training: training),
          ),
          const SizedBox(height: 22),
          // ───────── Description ─────────
          if (training.description.trim().isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: _SectionTitle(
                icon: IconlyLight.document,
                title: 'À propos de la formation',
                color: AppColors.categoryPurple,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: BrandCard(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                borderColor: AppColors.outlineVariant.withValues(alpha: 0.18),
                shadow: BrandCardShadow.none,
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    training.description,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.bodyColor,
                      height: 1.55,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
          ],
          // ───────── Objectives ─────────
          if (training.objectives.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: _SectionTitle(
                icon: IconlyLight.tick_square,
                title: 'Objectifs pédagogiques',
                color: AppColors.successStrong,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: _BulletList(
                items: training.objectives,
                color: AppColors.successStrong,
                icon: IconlyBold.tick_square,
              ),
            ),
            const SizedBox(height: 22),
          ],
          // ───────── Requirements ─────────
          if (training.requirements.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: _SectionTitle(
                icon: IconlyLight.info_square,
                title: 'Prérequis',
                color: AppColors.categoryOrange,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: _BulletList(
                items: training.requirements,
                color: AppColors.categoryOrange,
                icon: IconlyBold.info_square,
              ),
            ),
            const SizedBox(height: 22),
          ],
          // ───────── Modules ─────────
          if (training.modules.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Row(
                children: [
                  const _SectionTitle(
                    icon: IconlyLight.paper,
                    title: 'Programme',
                    color: AppColors.categoryBlue,
                  ),
                  const Spacer(),
                  Text(
                    '${training.modules.length} module${training.modules.length > 1 ? 's' : ''}',
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.hintColor,
                      fontSize: 11,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Column(
                children: List.generate(training.modules.length, (i) {
                  final module = training.modules[i];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: i == training.modules.length - 1 ? 0 : 8,
                    ),
                    child: _ModuleTile(index: i + 1, module: module),
                  );
                }),
              ),
            ),
            const SizedBox(height: 22),
          ],
          // ───────── Date / langue / contact ─────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: _InfoStrip(training: training),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}

class _TrainingHero extends StatelessWidget {
  const _TrainingHero({required this.training});

  final TrainingModel training;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final hasCover = training.coverUrl.trim().isNotEmpty;
    return SizedBox(
      width: double.infinity,
      height: 280 + topPadding,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image ou fallback gradient violet → cyan.
          if (hasCover)
            KenBurnsImage(image: NetworkImage(training.coverUrl))
          else
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.categoryPurple,
                    AppColors.categoryPurpleDeep,
                    AppColors.categoryCyan,
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
              child: const Center(
                child: Icon(
                  IconlyBold.paper,
                  color: AppColors.onPrimary,
                  size: 72,
                ),
              ),
            ),
          // Voile d'image pour lisibilite du texte.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: AppColors.imageScrim,
                stops: AppColors.imageScrimStops,
              ),
            ),
          ),
          // Top bar : back + bookmark.
          Positioned(
            top: topPadding + 8,
            left: 12,
            right: 12,
            child: Row(
              children: [
                WavyHeaderLeadingButton(
                  onTap: () {
                    AppHaptics.tap();
                    Navigator.of(context).maybePop();
                  },
                ),
                const Spacer(),
                if (training.isBookmarked)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.onPrimary.withValues(alpha: 0.20),
                      borderRadius: AppRadius.pill,
                      border: Border.all(
                        color: AppColors.onPrimary.withValues(alpha: 0.30),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          IconlyBold.bookmark,
                          size: 14,
                          color: AppColors.onPrimary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Sauvegardée',
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.onPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Titre + meta posés sur le voile bas.
          Positioned(
            left: 20,
            right: 20,
            bottom: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (training.level.isNotEmpty)
                      _GlassTag(
                        icon: IconlyLight.chart,
                        label: training.level,
                      ),
                    if (training.format.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _GlassTag(
                        icon: IconlyLight.video,
                        label: training.format,
                      ),
                    ],
                    const Spacer(),
                    if (training.rating > 0)
                      _GlassTag(
                        icon: IconlyBold.star,
                        iconColor: AppColors.warning,
                        label: training.rating.toStringAsFixed(1),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  training.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.displayMd.copyWith(
                    color: AppColors.onPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        training.providerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleMd.copyWith(
                          color: AppColors.onPrimary.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (training.sector.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.onPrimary.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          training.sector,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.onPrimary.withValues(alpha: 0.85),
                            fontSize: 11,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassTag extends StatelessWidget {
  const _GlassTag({
    required this.icon,
    required this.label,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.onPrimary.withValues(alpha: 0.22),
        borderRadius: AppRadius.pill,
        border: Border.all(
          color: AppColors.onPrimary.withValues(alpha: 0.32),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor ?? AppColors.onPrimary),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceBanner extends StatelessWidget {
  const _PriceBanner({required this.training, required this.isFree});

  final TrainingModel training;
  final bool isFree;

  @override
  Widget build(BuildContext context) {
    final color =
        isFree ? AppColors.successStrong : AppColors.categoryOrange;
    final softBg = isFree
        ? AppColors.successSoft
        : AppColors.categoryOrange.withValues(alpha: 0.12);
    final hasCert = training.certificationLabel.isNotEmpty &&
        !training.certificationLabel.toLowerCase().contains('aucun') &&
        !training.certificationLabel.toLowerCase().contains('non');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [softBg, softBg.withValues(alpha: 0.55)],
        ),
        borderRadius: AppRadius.lg,
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: AppRadius.md,
            ),
            child: Icon(
              isFree ? IconlyBold.shield_done : IconlyBold.wallet,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFree ? 'Formation gratuite' : 'Tarif',
                  style: AppTextStyles.labelSm.copyWith(
                    color: color,
                    fontSize: 10,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  training.priceLabel,
                  style: AppTextStyles.titleLg.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (hasCert) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppColors.successDark.withValues(alpha: 0.10),
                borderRadius: AppRadius.pill,
                border: Border.all(
                  color: AppColors.successDark.withValues(alpha: 0.30),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    IconlyLight.shield_done,
                    size: 13,
                    color: AppColors.successDark,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Certifiée',
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.successDark,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaGrid extends StatelessWidget {
  const _MetaGrid({required this.training});

  final TrainingModel training;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      _MetaTile(
        icon: IconlyLight.profile,
        label: 'Organisme',
        value: training.providerName,
        color: AppColors.categoryPurple,
      ),
      _MetaTile(
        icon: IconlyLight.video,
        label: 'Format',
        value: training.format,
        color: AppColors.categoryBlue,
      ),
      _MetaTile(
        icon: IconlyLight.chart,
        label: 'Niveau',
        value: training.level,
        color: AppColors.categoryOrange,
      ),
      _MetaTile(
        icon: IconlyLight.time_circle,
        label: 'Durée',
        value: training.durationLabel,
        color: AppColors.categoryCyan,
      ),
      _MetaTile(
        icon: IconlyLight.message,
        label: 'Langue',
        value: training.languageLabel,
        color: AppColors.categoryPink,
      ),
      _MetaTile(
        icon: IconlyLight.profile,
        label: 'Inscrits',
        value: '${training.enrolledCount}',
        color: AppColors.successStrong,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final tileWidth = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: tiles
              .map((t) => SizedBox(width: tileWidth, child: t))
              .toList(),
        );
      },
    );
  }
}

class _MetaTile extends StatelessWidget {
  const _MetaTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return BrandCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      radius: 14,
      borderColor: AppColors.outlineVariant.withValues(alpha: 0.18),
      shadow: BrandCardShadow.none,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: AppRadius.sm,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.hintColor,
                    fontSize: 9,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? '—' : value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMd.copyWith(
                    color: AppColors.titleColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: AppRadius.sm,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: AppTextStyles.headlineSm.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({
    required this.items,
    required this.color,
    required this.icon,
  });

  final List<String> items;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: BrandCard(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        borderColor: AppColors.outlineVariant.withValues(alpha: 0.18),
        shadow: BrandCardShadow.none,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(items.length, (i) {
          return Padding(
            padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    items[i],
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.bodyColor,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        ),
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({required this.index, required this.module});

  final int index;
  final TrainingModule module;

  String _formatDuration(int minutes) {
    if (minutes <= 0) return '';
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final duration = _formatDuration(module.duration);
    final isCompleted = module.isCompleted;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppRadius.md,
        border: Border.all(
          color: isCompleted
              ? AppColors.successStrong.withValues(alpha: 0.30)
              : AppColors.outlineVariant.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isCompleted
                    ? [
                        AppColors.successStrong,
                        AppColors.successStrong.withValues(alpha: 0.7),
                      ]
                    : [
                        AppColors.categoryBlue,
                        AppColors.categoryBlue.withValues(alpha: 0.7),
                      ],
              ),
              borderRadius: AppRadius.sm,
            ),
            alignment: Alignment.center,
            child: isCompleted
                ? const Icon(
                    IconlyBold.tick_square,
                    color: AppColors.onPrimary,
                    size: 16,
                  )
                : Text(
                    '$index',
                    style: AppTextStyles.titleMd.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  module.title.isEmpty ? 'Module $index' : module.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMd.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                if (module.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    module.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.bodyColor,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (duration.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: AppRadius.pill,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    IconlyLight.time_circle,
                    size: 11,
                    color: AppColors.hintColor,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    duration,
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.bodyColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoStrip extends StatelessWidget {
  const _InfoStrip({required this.training});

  final TrainingModel training;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    if (training.startDateLabel.isNotEmpty &&
        !training.startDateLabel.toLowerCase().contains('non')) {
      rows.add(_InfoRow(
        icon: IconlyLight.calendar,
        color: AppColors.categoryBlue,
        label: training.startDateLabel,
      ));
    }
    if (training.deadlineLabel.isNotEmpty &&
        !training.deadlineLabel.toLowerCase().contains('pas de')) {
      rows.add(_InfoRow(
        icon: IconlyLight.time_circle,
        color: AppColors.warning,
        label: training.deadlineLabel,
      ));
    }
    if (training.contactLabel.isNotEmpty &&
        !training.contactLabel.toLowerCase().contains('non')) {
      rows.add(_InfoRow(
        icon: IconlyLight.message,
        color: AppColors.categoryPurple,
        label: training.contactLabel,
      ));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: BrandCard(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        borderColor: AppColors.outlineVariant.withValues(alpha: 0.18),
        shadow: BrandCardShadow.none,
        child: Column(
          children: List.generate(rows.length, (i) {
            return Padding(
              padding: EdgeInsets.only(bottom: i == rows.length - 1 ? 0 : 10),
              child: rows[i],
            );
          }),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: AppRadius.sm,
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.bodyColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _MinimalBackBar extends StatelessWidget {
  const _MinimalBackBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              AppHaptics.tap();
              Navigator.of(context).maybePop();
            },
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppColors.titleColor,
          ),
        ],
      ),
    );
  }
}

class _EnrollBottomBar extends StatelessWidget {
  const _EnrollBottomBar({required this.training});

  final TrainingModel training;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TrainingDetailController>();
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          border: Border(
            top: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.18),
            ),
          ),
          boxShadow: AppColors.lightShadow,
        ),
        child: Obx(() {
          final isEnrolling = controller.isEnrolling.value;
          final isEnrolled = controller.training.value?.isEnrolled ?? false;

          if (isEnrolled) {
            return FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.successSoft,
                foregroundColor: AppColors.successStrong,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.md,
                  side: BorderSide(
                    color: AppColors.successStrong.withValues(alpha: 0.3),
                  ),
                ),
              ),
              onPressed: () {
                AppHaptics.tap();
                AppToast.info(
                  'Déjà inscrit',
                  'Vous êtes inscrit à cette formation. Le suivi des modules sera bientôt disponible.',
                );
              },
              icon: const Icon(IconlyBold.tick_square, size: 20),
              label: Text(
                'Continuer la formation',
                style: AppTextStyles.buttonLg.copyWith(
                  color: AppColors.successStrong,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            );
          }

          return FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.categoryPurple,
              foregroundColor: AppColors.onPrimary,
              minimumSize: const Size.fromHeight(52),
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.md,
              ),
            ),
            onPressed: isEnrolling
                ? null
                : () async {
                    AppHaptics.tap();
                    final success = await controller.enroll();
                    if (success) {
                      AppToast.success(
                        'Inscription confirmée',
                        'Vous êtes inscrit à "${training.title}".',
                      );
                    } else {
                      AppToast.error(
                        'Inscription impossible',
                        'Veuillez réessayer dans quelques instants.',
                      );
                    }
                  },
            icon: isEnrolling
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation(AppColors.onPrimary),
                    ),
                  )
                : const Icon(IconlyBold.bookmark, size: 20),
            label: Text(
              isEnrolling ? 'Inscription…' : "S'inscrire à la formation",
              style: AppTextStyles.buttonLg.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Skeleton plein ecran pendant le chargement initial du detail formation.
class _TrainingDetailSkeleton extends StatelessWidget {
  const _TrainingDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        SkeletonBox(width: double.infinity, height: 280, radius: 0),
        SizedBox(height: 18),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: SkeletonBox(height: 64, radius: 18),
        ),
        SizedBox(height: 14),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Row(
            children: [
              Expanded(child: SkeletonBox(height: 60, radius: 14)),
              SizedBox(width: 10),
              Expanded(child: SkeletonBox(height: 60, radius: 14)),
            ],
          ),
        ),
        SizedBox(height: 22),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: SkeletonBox(height: 140, radius: 18),
        ),
      ],
    );
  }
}
