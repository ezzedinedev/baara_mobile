import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_motion.dart';
import 'package:opportune_bf/app/core/theme/app_shapes.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import 'package:opportune_bf/routes/app_routes.dart';

import '../../domain/entities/training.dart';
import '../controllers/training_detail_controller.dart';
import 'training_payment_screen.dart';

/// Détail d'une formation — design "MasterClass" : hero banner aux couleurs de
/// marque + bouton play, onglets Contenu / Description, barre de progression et liste
/// de leçons, CTA bas (S'inscrire / Commencer). La logique métier reste celle
/// du [TrainingDetailController] (chargement, inscription, accès au parcours).
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
                    message: (error == null || error.isEmpty)
                        ? 'Formation introuvable.'
                        : error,
                    illustration: const ErrorIllustration(),
                    onRetry: controller.load,
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

enum _DetailTab { content, description }

class _TrainingDetailContent extends StatefulWidget {
  const _TrainingDetailContent({required this.training});

  final Training training;

  @override
  State<_TrainingDetailContent> createState() => _TrainingDetailContentState();
}

class _TrainingDetailContentState extends State<_TrainingDetailContent> {
  _DetailTab _tab = _DetailTab.content;
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final training = widget.training;
    return SafeArea(
      bottom: false,
      child: AnimationLimiter(
        child: ListView(
          controller: _scrollCtrl,
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 120),
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 320),
            childAnimationBuilder: (child) => SlideAnimation(
              verticalOffset: 18,
              child: FadeInAnimation(child: child),
            ),
            children: [
              _DetailTopBar(title: training.format),
              const SizedBox(height: 12),
              // Hero banner avec parallax au défilement (translation + zoom doux).
              ParallaxHeader(
                controller: _scrollCtrl,
                parallaxFactor: 0.55,
                fade: false,
                child: _CourseHeroBanner(training: training),
              ),
              const SizedBox(height: 18),
              Text(
                training.title,
                style: AppTextStyles.displayHero.copyWith(fontSize: 26),
              ),
              const SizedBox(height: 6),
              Text(
                'Créé par ${training.providerName.isEmpty ? "—" : training.providerName}',
                style:
                    AppTextStyles.bodySm.copyWith(color: AppColors.bodyColor),
              ),
              const SizedBox(height: 4),
              Text(
                '${training.modules.length} '
                '${training.modules.length > 1 ? "leçons" : "leçon"}',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.hintColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              _TabSwitcher(
                current: _tab,
                onChanged: (next) {
                  AppHaptics.tap();
                  setState(() => _tab = next);
                },
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _tab == _DetailTab.content
                    ? _ContentTab(
                        key: const ValueKey('content'), training: training)
                    : _DescriptionTab(
                        key: const ValueKey('description'), training: training),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailTopBar extends StatelessWidget {
  const _DetailTopBar({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppBackButton(onTap: () => Navigator.of(context).maybePop()),
        const Spacer(),
        Text(
          title.isEmpty ? 'Formation' : title,
          style: AppTextStyles.titleLg.copyWith(fontWeight: FontWeight.w800),
        ),
        const Spacer(),
        // Espace équilibré (largeur du bouton retour) pour garder le titre
        // centré, sans contrôle décoratif inutile.
        const SizedBox(width: 42),
      ],
    );
  }
}

/// Banner hero — gradient violet, titre cours, bouton play central, pastilles
/// format décoratives.
class _CourseHeroBanner extends StatelessWidget {
  const _CourseHeroBanner({required this.training});
  final Training training;

  @override
  Widget build(BuildContext context) {
    final hasCover = training.coverUrl.trim().isNotEmpty;
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryDark,
              AppColors.primary,
              AppColors.primaryMedium,
            ],
            stops: [0.0, 0.55, 1.0],
          ),
          borderRadius: AppShapes.squircleRadius(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.32),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (hasCover)
              Positioned.fill(
                child: Hero(
                  tag: 'training-cover-${training.id}',
                  child: Image.network(
                    training.coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            if (hasCover)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryDark.withValues(alpha: 0.60),
                        AppColors.primary.withValues(alpha: 0.48),
                        AppColors.primaryMedium.withValues(alpha: 0.38),
                      ],
                    ),
                  ),
                ),
              ),
            const Positioned.fill(child: CustomPaint(painter: TopoPainter())),
            Positioned(
              top: -40,
              right: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.onPrimary.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -20,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.onPrimary.withValues(alpha: 0.06),
                ),
              ),
            ),
            // Bouton play central : pastille squircle en verre, press spring.
            Center(
              child: Container(
                width: 76,
                height: 76,
                alignment: Alignment.center,
                decoration: ShapeDecoration(
                  color: AppColors.onPrimary.withValues(alpha: 0.20),
                  shape: AppShapes.squircle(
                    AppRadius.lg,
                    side: AppColors.onPrimary.withValues(alpha: 0.36),
                    width: 1.4,
                  ),
                ),
                child: const Icon(
                  IconlyLight.play,
                  color: AppColors.onPrimary,
                  size: 40,
                ),
              ),
            ),
            // Bandeau d'infos en verre liquide (chrome hero 2026).
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: GlassSurface(
                borderRadius: AppShapes.squircleRadius(AppRadius.md),
                blurSigma: 14,
                tintAlpha: 0.18,
                color: AppColors.onDark,
                borderColor: AppColors.onPrimary.withValues(alpha: 0.22),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      training.title.trim().isEmpty
                          ? 'FORMATION'
                          : training.title.trim().toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleLg.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        height: 1.15,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Row(
                      children: [
                        _HeroFormatPill(
                          icon: Icons.signal_wifi_off_rounded,
                          label: 'OFFLINE',
                        ),
                        SizedBox(width: 8),
                        _HeroFormatPill(
                          icon: Icons.devices_other_rounded,
                          label: 'HYBRIDE',
                        ),
                        SizedBox(width: 8),
                        _HeroFormatPill(
                          icon: Icons.public_rounded,
                          label: 'ONLINE',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroFormatPill extends StatelessWidget {
  const _HeroFormatPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.onPrimary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.onPrimary.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.onPrimary, size: 13),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabSwitcher extends StatelessWidget {
  const _TabSwitcher({required this.current, required this.onChanged});
  final _DetailTab current;
  final ValueChanged<_DetailTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TabButton(
            label: 'Contenu',
            selected: current == _DetailTab.content,
            onTap: () => onChanged(_DetailTab.content),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TabButton(
            label: 'Description',
            selected: current == _DetailTab.description,
            onTap: () => onChanged(_DetailTab.description),
          ),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = AppShapes.squircleRadius(AppRadius.sm);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: AnimatedContainer(
          duration: AppMotion.short,
          height: 48,
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primaryDark,
                    ],
                  )
                : null,
            color: selected ? null : AppColors.surfaceLow,
            borderRadius: radius,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primaryDark.withValues(alpha: 0.30),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.titleMd.copyWith(
              color: selected ? AppColors.onPrimary : AppColors.bodyColor,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _ContentTab extends StatelessWidget {
  const _ContentTab({super.key, required this.training});

  final Training training;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TrainingDetailController>();

    if (training.modules.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: EmptyState(
          illustration: EmptyTrainingsIllustration(),
          title: 'Aucune leçon disponible',
          subtitle:
              'Cette formation ne contient pas encore de modules. Revenez plus tard.',
        ),
      );
    }

    return Obx(() {
      final isEnrolled = controller.isEnrolled;
      final completed = training.modules.where((m) => m.isCompleted).length;
      final total = training.modules.length;
      final percent = total == 0 ? 0 : (completed / total * 100).round();
      final ratio = total == 0 ? 0.0 : completed / total;

      return Column(
        children: [
          if (isEnrolled) ...[
            _ProgressCard(
              percent: percent,
              ratio: ratio.clamp(0.0, 1.0),
              completed: completed,
              total: total,
            ),
            const SizedBox(height: 14),
          ],
          ...List.generate(training.modules.length, (index) {
            final lesson = training.modules[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == training.modules.length - 1 ? 0 : 12,
              ),
              child: _LessonRow(
                index: index + 1,
                lesson: lesson,
                isLocked: !isEnrolled,
                onTap: () {
                  AppHaptics.tap();
                  if (!isEnrolled) {
                    AppToast.info(
                      'Inscription requise',
                      'Inscrivez-vous à la formation pour accéder aux leçons.',
                    );
                    return;
                  }
                  Get.toNamed<void>(
                    AppRoutes.trainingPlayer.replaceFirst(':id', training.id),
                  );
                },
              ),
            );
          }),
        ],
      );
    });
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.percent,
    required this.ratio,
    required this.completed,
    required this.total,
  });

  final int percent;
  final double ratio;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: ShapeDecoration(
        color: AppColors.surfaceCard,
        shape: AppShapes.cardBordered(
          AppColors.outlineVariant.withValues(alpha: 0.18),
        ),
        shadows: AppColors.lightShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Progression',
                style: AppTextStyles.titleMd.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '$percent%',
                style: AppTextStyles.titleMd.copyWith(
                  color: AppColors.primaryAccent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: AppColors.surfaceHigh,
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$completed sur $total leçon(s) terminée(s)',
            style: AppTextStyles.bodySm,
          ),
        ],
      ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({
    required this.index,
    required this.lesson,
    required this.isLocked,
    required this.onTap,
  });

  final int index;
  final TrainingModule lesson;
  final bool isLocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle =
        lesson.duration > 0 ? '${lesson.duration} min' : lesson.typeLabel;
    // Couleur d'état claire : terminé (succès), verrouillé (atténué), à faire.
    final stateColor = lesson.isCompleted
        ? AppColors.successAccent
        : isLocked
            ? AppColors.hintColor
            : AppColors.primaryAccent;
    return PressScale(
      curve: AppMotion.spring,
      onTap: onTap,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
          decoration: ShapeDecoration(
            color: AppColors.surfaceCard,
            shape: AppShapes.cardBordered(
              AppColors.outlineVariant.withValues(alpha: 0.18),
            ),
            shadows: AppColors.lightShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: ShapeDecoration(
                  color: stateColor.withValues(alpha: 0.12),
                  shape: AppShapes.squircle(AppRadius.sm),
                ),
                child: Icon(
                  lesson.isCompleted
                      ? IconlyLight.tick_square
                      : isLocked
                          ? IconlyLight.lock
                          : IconlyLight.play,
                  color: stateColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title.isEmpty
                          ? 'Leçon ${index.toString().padLeft(2, '0')}'
                          : lesson.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleMd.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.bodyColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (lesson.isCompleted)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.successSoft,
                    borderRadius: AppShapes.pill,
                  ),
                  child: Text(
                    'Terminé',
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.successStrong,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                )
              else if (isLocked)
                Icon(IconlyLight.lock, size: 16, color: AppColors.hintColor)
              else
                Icon(IconlyLight.arrow_right_2,
                    size: 20, color: AppColors.hintColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _DescriptionTab extends StatelessWidget {
  const _DescriptionTab({super.key, required this.training});

  final Training training;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusChipsRow(training: training),
        const SizedBox(height: 16),
        _DetailSection(
          title: 'Description',
          icon: IconlyLight.paper,
          color: AppColors.categoryBlue,
          child: Text(
            training.description.isEmpty
                ? 'Description non fournie.'
                : training.description,
            style: AppTextStyles.bodyMd.copyWith(
              height: 1.5,
              color: AppColors.bodyColor,
            ),
          ),
        ),
        const SizedBox(height: 14),
        _MetaGrid(training: training),
        const SizedBox(height: 14),
        _ReviewPrompt(training: training),
        const SizedBox(height: 14),
        _BulletSection(
          title: 'Objectifs',
          icon: IconlyLight.danger,
          color: AppColors.successDark,
          items: training.objectives.isEmpty
              ? const ['Objectifs non précisés.']
              : training.objectives,
        ),
        const SizedBox(height: 14),
        _BulletSection(
          title: 'Prérequis',
          icon: Icons.rule_rounded,
          color: AppColors.secondary,
          items: training.requirements.isEmpty
              ? const ['Prérequis non précisés.']
              : training.requirements,
        ),
        const SizedBox(height: 14),
        _DetailSection(
          title: 'Contact',
          icon: Icons.business_outlined,
          color: AppColors.categoryPink,
          child: Text(
            training.providerName.isEmpty ? '—' : training.providerName,
            style: AppTextStyles.titleMd.copyWith(color: AppColors.titleColor),
          ),
        ),
      ],
    );
  }
}

class _ReviewPrompt extends StatelessWidget {
  const _ReviewPrompt({required this.training});

  final Training training;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TrainingDetailController>();
    return Obx(() {
      if (!controller.isEnrolled) return const SizedBox.shrink();
      return _DetailSection(
        title: 'Avis',
        icon: IconlyBold.star,
        color: AppColors.warningAccent,
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Partagez votre retour sur cette formation.',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.bodyColor,
                  height: 1.4,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => _showReviewDialog(context, controller),
              icon: Icon(
                IconlyLight.edit,
                size: 16,
                color: AppColors.primaryAccent,
              ),
              label: Text(
                'Noter',
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.primaryAccent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _showReviewDialog(
    BuildContext context,
    TrainingDetailController controller,
  ) async {
    var rating = 5;
    final commentCtrl = TextEditingController();
    final ok = await Get.dialog<bool>(
      StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: AppShapes.squircleRadius(AppRadius.lg),
          ),
          title: Text(
            'Votre avis',
            style: AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      onPressed: () => setState(() => rating = i),
                      icon: Icon(
                        i <= rating ? IconlyBold.star : IconlyLight.star,
                        color: AppColors.warningAccent,
                      ),
                    ),
                ],
              ),
              TextField(
                controller: commentCtrl,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Commentaire optionnel',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back<bool>(result: false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Get.back<bool>(result: true),
              child: const Text('Envoyer'),
            ),
          ],
        ),
      ),
    );
    final comment = commentCtrl.text;
    commentCtrl.dispose();
    if (ok != true) return;
    final sent = await controller.submitReview(
      rating: rating,
      comment: comment,
    );
    if (sent) {
      AppToast.success('Avis envoyé');
    } else {
      AppToast.error('Avis non envoyé', 'Réessayez dans un instant.');
    }
  }
}

class _StatusChipsRow extends StatelessWidget {
  const _StatusChipsRow({required this.training});

  final Training training;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (training.status.isNotEmpty)
          _StatusChip(
            text: training.status,
            background: AppColors.successSoft,
            textColor: AppColors.primaryAccent,
          ),
        if (training.level.isNotEmpty)
          _StatusChip(
            text: training.level,
            background: AppColors.categoryBlueSoft,
            textColor: AppColors.categoryBlue,
          ),
        if (training.format.isNotEmpty)
          _StatusChip(
            text: training.format,
            background: AppColors.warningSoft,
            textColor: AppColors.warningAccent,
          ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.text,
    required this.background,
    required this.textColor,
  });

  final String text;
  final Color background;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSm.copyWith(
          color: textColor,
          letterSpacing: 0.2,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetaGrid extends StatelessWidget {
  const _MetaGrid({required this.training});

  final Training training;

  @override
  Widget build(BuildContext context) {
    final items = <_MetaEntry>[
      _MetaEntry(
        icon: IconlyLight.paper,
        color: AppColors.categoryCyan,
        title: 'Modules',
        value: '${training.modules.length} module(s)',
      ),
      _MetaEntry(
        icon: IconlyLight.time_circle,
        color: AppColors.categoryPink,
        title: 'Durée',
        value: training.durationLabel,
      ),
      _MetaEntry(
        icon: IconlyLight.calendar,
        color: AppColors.secondary,
        title: 'Début',
        value: training.startDateLabel,
      ),
      _MetaEntry(
        icon: IconlyLight.time_square,
        color: AppColors.warningAccent,
        title: 'Limite',
        value: training.deadlineLabel,
      ),
      _MetaEntry(
        icon: IconlyLight.location,
        color: AppColors.categoryBlue,
        title: 'Lieu',
        value: training.location,
      ),
      _MetaEntry(
        icon: Icons.public_outlined,
        color: AppColors.categoryGray,
        title: 'Langue',
        value: training.languageLabel,
      ),
      _MetaEntry(
        icon: IconlyLight.wallet,
        color: AppColors.categoryOrange,
        title: 'Prix',
        value: training.priceLabel,
      ),
      _MetaEntry(
        icon: IconlyLight.shield_done,
        color: AppColors.successDark,
        title: 'Certificat',
        value: training.certificationLabel,
      ),
      _MetaEntry(
        icon: IconlyLight.profile,
        color: AppColors.primaryMedium,
        title: 'Inscrits',
        value: '${training.enrolledCount}',
      ),
      _MetaEntry(
        icon: IconlyBold.star,
        color: AppColors.warningAccent,
        title: 'Note',
        value: training.rating.toStringAsFixed(1),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 106,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _MetaTile(entry: items[index]),
    );
  }
}

class _MetaEntry {
  const _MetaEntry({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;
}

class _MetaTile extends StatelessWidget {
  const _MetaTile({required this.entry});

  final _MetaEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: AppColors.surfaceCard,
        shape: AppShapes.cardBordered(
          AppColors.outlineVariant.withValues(alpha: 0.18),
        ),
        shadows: AppColors.lightShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: entry.color.withValues(alpha: 0.12),
              shape: AppShapes.squircle(AppRadius.xs),
            ),
            child: Icon(entry.icon, color: entry.color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.title.toUpperCase(),
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.hintColor,
                    fontSize: 9.5,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.value.isEmpty ? '—' : entry.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMd.copyWith(
                    color: AppColors.titleColor,
                    fontSize: 13,
                    height: 1.2,
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

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: AppColors.surfaceCard,
        shape: AppShapes.cardBordered(
          AppColors.outlineVariant.withValues(alpha: 0.18),
        ),
        shadows: AppColors.lightShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: ShapeDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: AppShapes.squircle(AppRadius.xs),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Text(title, style: AppTextStyles.titleLg),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _BulletSection extends StatelessWidget {
  const _BulletSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: title,
      icon: icon,
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: AppTextStyles.bodyMd.copyWith(
                          height: 1.45,
                          color: AppColors.bodyColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

/// Barre d'action bas : "Commencer/Revoir" si inscrit, "Suivre" si gratuit,
/// message paiement si payant (le paiement en ligne n'est pas encore câblé).
class _EnrollBottomBar extends StatelessWidget {
  const _EnrollBottomBar({required this.training});

  final Training training;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TrainingDetailController>();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
        // CTA posée sur un panneau de verre liquide (chrome sticky 2026).
        child: GlassSurface(
          borderRadius: AppShapes.squircleRadius(AppRadius.lg),
          blurSigma: 18,
          boxShadow: AppColors.ambientShadow,
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Obx(() {
            final isEnrolling = controller.isEnrolling.value;
            final isEnrolled = controller.isEnrolled;
            final hasModules = training.modules.isNotEmpty;
            final completedAll =
                hasModules && training.modules.every((m) => m.isCompleted);
            final isPaid = training.price != null && training.price! > 0;

            final label = isEnrolled
                ? (!hasModules
                    ? 'AUCUNE LEÇON DISPONIBLE'
                    : completedAll
                        ? 'REVOIR LA FORMATION'
                        : 'COMMENCER MAINTENANT')
                : (isPaid
                    ? "S'INSCRIRE • ${training.priceLabel}"
                    : 'SUIVRE LA FORMATION');

            final disabled = isEnrolling || (isEnrolled && !hasModules);

            return GradientButton(
              label: label,
              isLoading: isEnrolling,
              textColor: AppColors.onPrimary,
              height: 52,
              borderRadius: 14,
              onPressed: disabled
                  ? null
                  : () => _onPressed(context, controller, isEnrolled, isPaid),
            );
          }),
        ),
      ),
    );
  }

  Future<void> _onPressed(
    BuildContext context,
    TrainingDetailController controller,
    bool isEnrolled,
    bool isPaid,
  ) async {
    AppHaptics.tap();

    if (isEnrolled) {
      Get.toNamed<void>(
        AppRoutes.trainingPlayer.replaceFirst(':id', training.id),
      );
      return;
    }

    if (isPaid) {
      Get.to<void>(() => TrainingPaymentScreen(training: training));
      return;
    }

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
            icon: const Icon(IconlyLight.arrow_left_2),
            color: AppColors.titleColor,
          ),
        ],
      ),
    );
  }
}

/// Skeleton plein écran pendant le chargement initial du détail formation.
class _TrainingDetailSkeleton extends StatelessWidget {
  const _TrainingDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 42),
          SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 16 / 10,
            child: SkeletonBox(width: double.infinity, radius: AppRadius.xl),
          ),
          SizedBox(height: 18),
          SkeletonBox(width: 220, height: 24, radius: 8),
          SizedBox(height: 10),
          SkeletonBox(width: 140, height: 14, radius: 8),
          SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: SkeletonBox(height: 48, radius: 14)),
              SizedBox(width: 12),
              Expanded(child: SkeletonBox(height: 48, radius: 14)),
            ],
          ),
          SizedBox(height: 16),
          SkeletonBox(height: 70, radius: 16),
          SizedBox(height: 12),
          SkeletonBox(height: 70, radius: 16),
        ],
      ),
    );
  }
}
