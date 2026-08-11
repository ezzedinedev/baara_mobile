import 'package:flutter/material.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';

import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_dimens.dart' show AppRadius;
import 'package:baara/app/core/theme/app_motion.dart';
import 'package:baara/app/core/theme/app_shapes.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/app/core/widgets/widgets.dart';
import 'package:baara/routes/app_routes.dart';

import '../../domain/entities/quiz.dart';
import '../../domain/entities/training.dart';
import '../controllers/training_player_controller.dart';
import 'training_lesson_screen.dart';

/// Lecteur de modules d'une formation suivie. Liste les modules avec leur
/// état (terminé / à faire), une barre de progression globale, et un bouton
/// "Marquer comme terminé" par module. Données via [TrainingPlayerController].
class TrainingPlayerScreen extends GetView<TrainingPlayerController> {
  const TrainingPlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          WavyContentHeader(
            title: 'Suivre la formation',
            subtitle: 'Avancez module par module',
            height: 200,
            gradient: AppColors.heroTrainingsGradient,
            onLeadingTap: () => Get.back<void>(),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const _PlayerSkeleton();
              }
              if (controller.errorMessage.value != null) {
                return ErrorStateView(
                  message: controller.errorMessage.value!,
                  illustration: const ErrorIllustration(),
                  onRetry: controller.load,
                );
              }
              final t = controller.training.value;
              if (t == null) {
                return ErrorStateView(
                  message: 'Formation introuvable ou indisponible.',
                  illustration: const ErrorIllustration(),
                  onRetry: controller.load,
                );
              }
              return _Content(training: t);
            }),
          ),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.training});
  final Training training;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TrainingPlayerController>();
    final modules = training.modules;

    if (modules.isEmpty) {
      return const EmptyState(
        illustration: EmptyTrainingsIllustration(),
        title: 'Aucun module',
        subtitle: 'Cette formation ne contient pas encore de modules.',
      );
    }

    return AnimationLimiter(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          _ProgressCard(title: training.title),
          const SizedBox(height: 18),
          SectionHeader(title: 'Programme (${modules.length})'),
          const SizedBox(height: 10),
          ...modules.asMap().entries.map(
                (e) => AnimationConfiguration.staggeredList(
                  position: e.key,
                  duration: AppMotion.medium,
                  child: SlideAnimation(
                    curve: AppMotion.emphasizedDecelerate,
                    verticalOffset: AppMotion.listSlideOffset,
                    child: FadeInAnimation(
                      child: Obx(() {
                        final module = e.value;
                        return _ModuleCard(
                          index: e.key + 1,
                          module: module,
                          completed: controller.isCompleted(module),
                          busy: controller.updatingId.value == module.id,
                          onOpen: () {
                            AppHaptics.tap();
                            Get.to(
                              () => TrainingLessonScreen(
                                training: training,
                                initialIndex: e.key,
                              ),
                              transition: Transition.rightToLeft,
                            );
                          },
                          onComplete: () {
                            AppHaptics.tap();
                            controller.markCompleted(module);
                          },
                        );
                      }),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TrainingPlayerController>();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: AppColors.surfaceCard,
        shape: AppShapes.squircle(AppRadius.lg),
        shadows: AppColors.lightShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleLg.copyWith(fontWeight: FontWeight.w800),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          Obx(() {
            final progress = controller.progress;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Progression',
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.hintColor),
                    ),
                    const Spacer(),
                    Text(
                      '${controller.completedCount}/${controller.totalCount}',
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.primaryAccent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.surfaceHigh,
                    valueColor: AlwaysStoppedAnimation(AppColors.primaryAccent),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.index,
    required this.module,
    required this.completed,
    required this.busy,
    required this.onOpen,
    required this.onComplete,
  });

  final int index;
  final TrainingModule module;
  final bool completed;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          PressScale(
            curve: AppMotion.spring,
            onTap: onOpen,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(
                    color: completed
                        ? AppColors.successAccent.withValues(alpha: 0.16)
                        : AppColors.primaryLight,
                    shape: AppShapes.squircle(AppRadius.xs),
                  ),
                  child: completed
                      ? Icon(AppIcons.tickSquare,
                          size: 18, color: AppColors.successAccent)
                      : Text(
                          '$index',
                          style: AppTextStyles.labelMd.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module.title,
                        style: AppTextStyles.titleMd
                            .copyWith(fontWeight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          if (module.duration > 0) ...[
                            Text(
                              '${module.duration} min',
                              style: AppTextStyles.bodySm
                                  .copyWith(color: AppColors.hintColor),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            module.typeLabel,
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.primaryAccent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(AppIcons.arrowRight, color: AppColors.hintColor),
              ],
            ),
          ),
          if (module.description.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              module.description,
              style: AppTextStyles.bodyMd
                  .copyWith(color: AppColors.bodyColor, height: 1.4),
            ),
          ],
          if (module.hasQuiz) ...[
            const SizedBox(height: 10),
            _QuizButton(module: module),
          ],
          const SizedBox(height: 12),
          _CompleteButton(
            completed: completed,
            busy: busy,
            onComplete: onComplete,
          ),
        ],
      ),
    );
  }
}

/// Accès à l'épreuve du module. Une leçon de type quiz était jusqu'ici affichée
/// comme du simple texte : il n'existait aucun moteur de quiz sur mobile.
class _QuizButton extends StatelessWidget {
  const _QuizButton({required this.module});

  final TrainingModule module;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TrainingPlayerController>();

    return Obx(() {
      final busy = controller.loadingQuizModuleId.value == module.id;
      final quizzes = controller.quizzesFor(module);

      // L'état vient du serveur : quiz déjà validé, meilleur score, tentatives
      // restantes. L'apprenant ne devrait jamais avoir à ouvrir l'épreuve pour
      // savoir où il en est.
      final allPassed = quizzes.isNotEmpty && quizzes.every((q) => q.passed);
      final bestScore = quizzes
          .map((q) => q.bestScore)
          .whereType<int>()
          .fold<int?>(null, (a, b) => a == null || b > a ? b : a);
      final exhausted =
          quizzes.isNotEmpty && !allPassed && quizzes.every((q) => q.isExhausted);

      final Color accent;
      final String label;
      if (allPassed) {
        accent = AppColors.successAccent;
        label = bestScore != null
            ? 'Quiz validé · $bestScore %'
            : 'Quiz validé';
      } else if (exhausted) {
        accent = AppColors.errorAccent;
        label = 'Tentatives épuisées'
            '${bestScore != null ? ' · $bestScore %' : ''}';
      } else {
        accent = AppColors.warningAccent;
        final attempted = quizzes.any((q) => q.attemptsUsed > 0);
        label = attempted
            ? 'Reprendre le quiz'
                '${bestScore != null ? ' · meilleur score $bestScore %' : ''}'
            : (module.quizCount > 1
                ? '${module.quizCount} quiz à passer'
                : 'Passer le quiz du module');
      }

      return PressScale(
        curve: AppMotion.spring,
        onTap: busy || exhausted ? null : () => _open(context, controller),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: ShapeDecoration(
            color: accent.withValues(alpha: 0.10),
            shape: AppShapes.squircle(AppRadius.sm),
          ),
          child: Row(
            children: [
              Icon(
                allPassed ? AppIcons.tickSquare : AppIcons.document,
                size: 16,
                color: accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.labelMd.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (busy)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: AppLoader(size: 14, strokeWidth: 2, color: accent),
                )
              else if (!exhausted)
                Icon(AppIcons.arrowRight, size: 16, color: accent),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _open(
    BuildContext context,
    TrainingPlayerController controller,
  ) async {
    AppHaptics.tap();
    final quizzes = await controller.quizzesOf(module);
    if (quizzes.isEmpty) return;

    if (quizzes.length == 1) {
      await _launch(quizzes.first, controller);
      return;
    }

    if (!context.mounted) return;
    await Get.bottomSheet<void>(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              const SizedBox(height: 12),
              Text(
                'Quiz du module',
                style:
                    AppTextStyles.titleLg.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              for (final quiz in quizzes)
                _QuizChoiceTile(
                  quiz: quiz,
                  onTap: () {
                    Get.back<void>();
                    _launch(quiz, controller);
                  },
                ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _launch(
    QuizSummary quiz,
    TrainingPlayerController controller,
  ) async {
    if (quiz.isExhausted) {
      AppToast.info(
        'Tentatives épuisées',
        'Vous avez utilisé toutes vos tentatives pour ce quiz.',
      );
      return;
    }

    await Get.toNamed<void>(
      AppRoutes.trainingQuiz.replaceFirst(':id', quiz.id),
    );
    // Réussir un quiz peut valider le module côté serveur : on recharge plutôt
    // que de deviner l'état localement.
    await controller.load();
  }
}

class _QuizChoiceTile extends StatelessWidget {
  const _QuizChoiceTile({required this.quiz, required this.onTap});

  final QuizSummary quiz;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PressScale(
        onTap: onTap,
        curve: AppMotion.spring,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: ShapeDecoration(
            color: AppColors.surfaceLow,
            shape: AppShapes.squircle(AppRadius.sm),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.title,
                      style: AppTextStyles.labelMd
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${quiz.durationMinutes} min · réussite à '
                      '${quiz.passingScore} %'
                      '${quiz.remainingAttempts != null ? ' · ${quiz.remainingAttempts} tentative(s) restante(s)' : ''}',
                      style: AppTextStyles.labelSm
                          .copyWith(color: AppColors.hintColor),
                    ),
                  ],
                ),
              ),
              if (quiz.passed)
                Icon(AppIcons.tickSquare,
                    size: 18, color: AppColors.successAccent),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompleteButton extends StatelessWidget {
  const _CompleteButton({
    required this.completed,
    required this.busy,
    required this.onComplete,
  });

  final bool completed;
  final bool busy;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    if (completed) {
      return Row(
        children: [
          Icon(AppIcons.tickSquare,
              size: 18, color: AppColors.successAccent),
          const SizedBox(width: 8),
          Text(
            'Terminé',
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.successAccent,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
    }
    return SizedBox(
      width: double.infinity,
      child: PressScale(
        curve: AppMotion.spring,
        onTap: busy ? null : onComplete,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: AppColors.primary,
            shape: AppShapes.squircle(AppRadius.sm),
          ),
          child: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: AppLoader(
                    size: 18,
                    strokeWidth: 2,
                    color: AppColors.onPrimary,
                  ),
                )
              : Text(
                  'Marquer comme terminé',
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
    );
  }
}

class _PlayerSkeleton extends StatelessWidget {
  const _PlayerSkeleton();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: double.infinity, height: 110, radius: 20),
          SizedBox(height: 18),
          SkeletonBox(width: 160, height: 20, radius: 8),
          SizedBox(height: 12),
          SkeletonBox(width: double.infinity, height: 120, radius: 16),
          SizedBox(height: 12),
          SkeletonBox(width: double.infinity, height: 120, radius: 16),
        ],
      ),
    );
  }
}
