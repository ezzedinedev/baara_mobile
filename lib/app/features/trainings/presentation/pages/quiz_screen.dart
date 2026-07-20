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

import '../../domain/entities/quiz.dart';
import '../controllers/quiz_controller.dart';

/// Passage d'un quiz.
///
/// L'écran est volontairement fermé : pas de retour arrière discret, pas de
/// contenu sélectionnable, et une sortie de l'app rend la copie (surveillance
/// stricte). Le chronomètre affiché vient du serveur — l'app ne fait que le
/// décompter.
class QuizScreen extends GetView<QuizController> {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Tous les états observés sont lus ICI, dans le corps de l'Obx.
      // Les glisser dans un `Builder` imbriqué les sortirait du périmètre
      // réactif — son callback s'exécute après la fermeture de l'observation —
      // et l'écran resterait figé sur le squelette de chargement.
      final result = controller.result.value;
      final isLoading = controller.isLoading.value;
      final error = controller.errorMessage.value;
      final attempt = controller.attempt.value;

      final Widget body;
      if (result != null) {
        body = _ResultView(result: result);
      } else if (isLoading) {
        body = const PageSkeleton(showHero: false);
      } else if (attempt != null) {
        // Une épreuve est en cours : elle prime. Un incident réseau se signale
        // par un toast, il ne fait pas disparaître la copie.
        body = const _QuizBody();
      } else if (error != null) {
        body = ErrorStateView(
          message: error,
          illustration: const ErrorIllustration(),
          onRetry: controller.start,
        );
      } else {
        body = const SizedBox.shrink();
      }

      return PopScope(
        // Quitter en cours d'épreuve n'est pas anodin : on demande confirmation,
        // et abandonner soumet la copie en l'état.
        canPop: result != null || attempt == null,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _confirmQuit(context);
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(child: body),
        ),
      );
    });
  }

  Future<void> _confirmQuit(BuildContext context) async {
    final quit = await showConfirmSheet(
      context: context,
      icon: IconlyBold.danger,
      iconColor: AppColors.errorAccent,
      title: 'Abandonner le quiz ?',
      message: 'Votre copie sera envoyée en l\'état et la tentative sera '
          'comptabilisée.',
      confirmLabel: 'Abandonner',
      cancelLabel: 'Continuer le quiz',
      isDestructive: true,
    );
    if (quit == true) {
      await controller.submit();
    }
  }
}

class _QuizBody extends StatelessWidget {
  const _QuizBody();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<QuizController>();

    // Le contenu de l'épreuve n'est pas sélectionnable : pas de copier-coller
    // vers une IA ou un moteur de recherche pendant l'épreuve.
    return SelectionContainer.disabled(
      child: Column(
        children: [
          const _QuizHeader(),
          Expanded(
            child: Obx(() {
              final question = controller.currentQuestion;
              if (question == null) return const SizedBox.shrink();

              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                children: [
                  Text(
                    'Question ${controller.currentIndex.value + 1} sur '
                    '${controller.questions.length}',
                    style: AppTextStyles.labelSm
                        .copyWith(color: AppColors.hintColor),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    question.prompt,
                    style: AppTextStyles.titleLg.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.titleColor,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  for (final option in question.options)
                    _OptionTile(
                      option: option,
                      selected: controller.answers[question.id] == option.id,
                      onTap: () {
                        AppHaptics.tap();
                        controller.selectOption(question.id, option.id);
                      },
                    ),
                ],
              );
            }),
          ),
          const _QuizFooter(),
        ],
      ),
    );
  }
}

class _QuizHeader extends StatelessWidget {
  const _QuizHeader();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<QuizController>();

    return Obx(() {
      final attempt = controller.attempt.value;
      final total = controller.questions.length;
      final progress = total == 0 ? 0.0 : controller.answeredCount / total;

      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    attempt?.title ?? 'Quiz',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleMd.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.titleColor,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const _Countdown(),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: AppColors.surfaceHighest,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
              ),
            ),
            if (controller.incidentCount.value > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              _ProctoringWarning(count: controller.incidentCount.value),
            ],
          ],
        ),
      );
    });
  }
}

/// Le compte à rebours passe au rouge dans la dernière minute.
class _Countdown extends StatelessWidget {
  const _Countdown();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<QuizController>();

    return Obx(() {
      final seconds = controller.secondsRemaining.value;
      final urgent = seconds <= 60;
      final minutes = seconds ~/ 60;
      final rest = seconds % 60;
      final color = urgent ? AppColors.errorAccent : AppColors.primaryAccent;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(IconlyLight.time_circle, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              '$minutes:${rest.toString().padLeft(2, '0')}',
              style: AppTextStyles.labelMd.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _ProctoringWarning extends StatelessWidget {
  const _ProctoringWarning({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warningAccent.withValues(alpha: 0.12),
        borderRadius: AppShapes.squircleRadius(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(IconlyBold.danger, size: 14, color: AppColors.warningAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$count incident${count > 1 ? 's' : ''} de surveillance signalé'
              '${count > 1 ? 's' : ''} au formateur.',
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.warningAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final QuizOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: PressScale(
        onTap: onTap,
        curve: AppMotion.spring,
        child: AnimatedContainer(
          duration: AppMotion.short,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: selected ? AppColors.surfaceSelected : AppColors.surfaceLow,
            borderRadius: AppShapes.squircleRadius(AppRadius.md),
            border: Border.all(
              color: selected ? AppColors.primaryLight : AppColors.outlineVariant,
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 20,
                color: selected ? AppColors.primaryAccent : AppColors.hintColor,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  option.text,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.titleColor,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    height: 1.35,
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

class _QuizFooter extends StatelessWidget {
  const _QuizFooter();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<QuizController>();

    return Obx(() {
      final busy = controller.isSubmitting.value;
      final last = controller.isLastQuestion;

      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.lg,
        ),
        child: Row(
          children: [
            if (controller.currentIndex.value > 0) ...[
              AppIconButton(
                icon: IconlyLight.arrow_left_2,
                onTap: () {
                  AppHaptics.tap();
                  controller.previous();
                },
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: GradientButton(
                label: last ? 'VALIDER MES RÉPONSES' : 'QUESTION SUIVANTE',
                isLoading: busy,
                textColor: AppColors.onPrimary,
                height: 52,
                borderRadius: 14,
                onPressed: busy
                    ? null
                    : () {
                        AppHaptics.tap();
                        if (last) {
                          _confirmSubmit(context, controller);
                        } else {
                          controller.next();
                        }
                      },
              ),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _confirmSubmit(
    BuildContext context,
    QuizController controller,
  ) async {
    if (!controller.allAnswered) {
      AppToast.info(
        'Questions sans réponse',
        'Répondez à toutes les questions avant de valider.',
      );
      return;
    }

    final ok = await showConfirmSheet(
      context: context,
      icon: IconlyBold.tick_square,
      iconColor: AppColors.primaryAccent,
      title: 'Valider vos réponses ?',
      message: 'Vous ne pourrez plus modifier votre copie.',
      confirmLabel: 'Valider',
      cancelLabel: 'Revoir mes réponses',
    );
    if (ok == true) {
      await controller.submit();
    }
  }
}

/// Résultat corrigé par le serveur.
class _ResultView extends StatelessWidget {
  const _ResultView({required this.result});

  final QuizResult result;

  @override
  Widget build(BuildContext context) {
    final passed = result.passed;
    final accent = passed ? AppColors.primaryAccent : AppColors.errorAccent;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xxl,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      children: [
        Center(
          child: ScoreRing(
            value: result.scorePct,
            color: accent,
            size: 140,
            suffix: '/ 100',
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          result.expired
              ? 'Temps écoulé'
              : passed
                  ? 'Quiz validé'
                  : 'Quiz non validé',
          textAlign: TextAlign.center,
          style: AppTextStyles.displayMd.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.titleColor,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          result.expired
              ? 'La tentative a été invalidée : vous avez dépassé le temps '
                  'imparti.'
              : '${result.earnedPoints} / ${result.totalPoints} points · '
                  'minimum requis ${result.passingScore} %',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.bodyColor),
        ),
        if (result.alertTriggered) ...[
          const SizedBox(height: AppSpacing.lg),
          _ProctoringWarning(count: result.severeIncidentCount),
        ],
        const SizedBox(height: AppSpacing.xl),
        if (result.remainingAttempts != null)
          Text(
            result.remainingAttempts! > 0
                ? 'Tentatives restantes : ${result.remainingAttempts}'
                : 'Vous avez utilisé toutes vos tentatives.',
            textAlign: TextAlign.center,
            style: AppTextStyles.labelMd.copyWith(color: AppColors.hintColor),
          ),
        const SizedBox(height: AppSpacing.xl),
        GradientButton(
          label: 'RETOUR À LA FORMATION',
          textColor: AppColors.onPrimary,
          height: 52,
          borderRadius: 14,
          onPressed: () {
            AppHaptics.tap();
            Get.back<QuizResult>(result: result);
          },
        ),
      ],
    );
  }
}
