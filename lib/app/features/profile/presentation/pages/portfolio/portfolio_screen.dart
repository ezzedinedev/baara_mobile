import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import 'package:opportune_bf/routes/app_routes.dart';

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
            : FloatingActionButton(
                backgroundColor: AppColors.primary,
                onPressed: () {
                  AppHaptics.tap();
                  Get.toNamed(AppRoutes.profilePortfolioEdit);
                },
                child: const Icon(Icons.add_rounded, color: AppColors.onPrimary),
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
                  onRetry: controller.load,
                );
              }
              if (controller.items.isEmpty) {
                return EmptyState(
                  icon: IconlyLight.work,
                  title: 'Aucune réalisation',
                  subtitle:
                      'Ajoutez vos projets, créations et accomplissements pour valoriser votre profil.',
                  actionLabel: 'Ajouter un projet',
                  onAction: () =>
                      Get.toNamed(AppRoutes.profilePortfolioEdit),
                );
              }
              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: controller.load,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 96),
                  itemCount: controller.items.length,
                  itemBuilder: (context, index) =>
                      _PortfolioCard(item: controller.items[index]),
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
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.lightShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _TypeBadge(type: item.type),
                const Spacer(),
                Obx(() => controller.deletingId.value == item.id
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.error),
                        ),
                      )
                    : GestureDetector(
                        onTap: () => _confirmDelete(context, controller),
                        child: Icon(IconlyLight.delete,
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
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSelected,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(t,
                              style: AppTextStyles.labelSm.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700)),
                        ))
                    .toList(),
              ),
            ],
            if ((item.externalUrl ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.link_rounded,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(item.externalUrl!,
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.primary),
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
      icon: IconlyLight.delete,
      iconColor: AppColors.error,
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
      decoration: BoxDecoration(
        color: AppColors.surfaceIconSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(type.label,
          style: AppTextStyles.labelSm.copyWith(
              color: AppColors.primaryDark, fontWeight: FontWeight.w700)),
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
