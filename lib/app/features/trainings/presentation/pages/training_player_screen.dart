import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';

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
                  onRetry: controller.load,
                );
              }
              final t = controller.training.value;
              if (t == null) {
                return const SizedBox.shrink();
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
        icon: IconlyLight.document,
        title: 'Aucun module',
        subtitle: 'Cette formation ne contient pas encore de modules.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        _ProgressCard(title: training.title),
        const SizedBox(height: 18),
        SectionHeader(title: 'Programme (${modules.length})'),
        const SizedBox(height: 10),
        ...modules.asMap().entries.map(
              (e) => Obx(() {
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
      ],
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
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.lightShadow,
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
                        color: AppColors.primary,
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
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.primary),
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
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.lightShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PressScale(
            onTap: onOpen,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: completed
                        ? AppColors.success.withValues(alpha: 0.16)
                        : AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: completed
                      ? const Icon(IconlyBold.tick_square,
                          size: 18, color: AppColors.success)
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
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: AppColors.hintColor),
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
          const Icon(IconlyBold.tick_square,
              size: 18, color: AppColors.success),
          const SizedBox(width: 8),
          Text(
            'Terminé',
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
    }
    return SizedBox(
      width: double.infinity,
      child: PressScale(
        onTap: busy ? null : onComplete,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppColors.onPrimary),
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
