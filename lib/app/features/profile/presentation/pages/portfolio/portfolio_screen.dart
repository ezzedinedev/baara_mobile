import 'package:flutter/material.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:get/get.dart';

import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_dimens.dart';
import 'package:baara/app/core/theme/app_shapes.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/app/core/widgets/widgets.dart';
import 'package:baara/routes/app_routes.dart';

import '../../controllers/portfolio_controller.dart';
import '../../../domain/entities/portfolio_item.dart';

/// Portfolio du candidat : liste des réalisations (CRUD câblé à l'API).
class PortfolioScreen extends GetView<PortfolioController> {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: Obx(
        () => controller.items.isEmpty
            ? const SizedBox.shrink()
            : PressScale(
                onTap: () {
                  AppHaptics.tap();
                  Get.toNamed(AppRoutes.profilePortfolioEdit);
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: ShapeDecoration(
                    color: AppColors.primary,
                    shape: AppShapes.squircle(AppRadius.lg),
                    shadows: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                      ...AppColors.ambientShadow,
                    ],
                  ),
                  child:
                      const Icon(AppIcons.add, color: AppColors.onPrimary),
                ),
              ),
      ),
      body: Column(
        children: [
          WavyContentHeader(
            title: 'Portfolio',
            subtitle: 'Vos réalisations et projets',
            height: 200,
            gradient: AppColors.heroProfileGradient,
            onLeadingTap: () => Get.back<void>(),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const _PortfolioSkeleton();
              }
              if (controller.errorMessage.value != null) {
                return ErrorStateView(
                  message: controller.errorMessage.value!,
                  illustration: const ErrorIllustration(),
                  onRetry: controller.load,
                );
              }
              if (controller.items.isEmpty) {
                return EmptyState(
                  illustration: const EmptyPortfolioIllustration(),
                  title: 'Aucune réalisation',
                  subtitle:
                      'Ajoutez vos projets, créations et accomplissements pour valoriser votre profil.',
                  actionLabel: 'Ajouter un projet',
                  onAction: () => Get.toNamed(AppRoutes.profilePortfolioEdit),
                );
              }
              return AppRefreshIndicator(
                color: AppColors.primaryAccent,
                onRefresh: controller.load,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 96),
                  itemCount: controller.items.length,
                  itemBuilder: (context, index) => RevealOnMount(
                    delay: Duration(milliseconds: 60 * index),
                    child: _PortfolioCard(item: controller.items[index]),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _PortfolioCard extends StatelessWidget {
  const _PortfolioCard({required this.item});
  final PortfolioItem item;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PortfolioController>();
    return PressScale(
      onTap: () {
        AppHaptics.tap();
        Get.toNamed(AppRoutes.profilePortfolioEdit, arguments: item);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
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
                _TypeBadge(type: item.type),
                const Spacer(),
                Obx(() => controller.deletingId.value == item.id
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: AppLoader(
                          size: 18,
                          strokeWidth: 2,
                          color: AppColors.errorAccent,
                        ),
                      )
                    : GestureDetector(
                        onTap: () => _confirmDelete(context, controller),
                        child: Icon(AppIcons.delete,
                            size: 20, color: AppColors.hintColor),
                      )),
              ],
            ),
            const SizedBox(height: 10),
            Text(item.title,
                style: AppTextStyles.titleMd
                    .copyWith(fontWeight: FontWeight.w800)),
            if ((item.description ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(item.description!,
                  style: AppTextStyles.bodySm
                      .copyWith(color: AppColors.bodyColor, height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
            ],
            if (item.techStack.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: item.techStack
                    .map((t) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: AppShapes.pill,
                          ),
                          child: Text(t,
                              style: AppTextStyles.labelSm.copyWith(
                                  color: AppColors.surfaceSelected,
                                  fontWeight: FontWeight.w700)),
                        ))
                    .toList(),
              ),
            ],
            if ((item.externalUrl ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.link_rounded,
                      size: 14, color: AppColors.primaryAccent),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(item.externalUrl!,
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.primaryAccent),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, PortfolioController controller) async {
    final confirmed = await showConfirmSheet(
      context: context,
      icon: AppIcons.delete,
      iconColor: AppColors.errorAccent,
      title: 'Supprimer ce projet ?',
      message: 'Cette action est définitive.',
      confirmLabel: 'Supprimer',
      isDestructive: true,
    );
    if (confirmed == true) {
      AppHaptics.confirm();
      final ok = await controller.delete(item);
      if (ok) {
        AppToast.success('Projet supprimé');
      } else {
        AppToast.error('Suppression impossible', 'Réessayez dans un instant.');
      }
    }
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});
  final PortfolioItemType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppShapes.pill,
      ),
      child: Text(type.label,
          style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onPrimary, fontWeight: FontWeight.w700)),
    );
  }
}

class _PortfolioSkeleton extends StatelessWidget {
  const _PortfolioSkeleton();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (var i = 0; i < 4; i++)
          const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: SkeletonBox(width: double.infinity, height: 130, radius: 20),
          ),
      ],
    );
  }
}
