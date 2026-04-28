import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';

import '../../../../routes/app_routes.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../controllers/profile_controller.dart';
import '../data/models/profile_model.dart';

/// Liste du portfolio du candidat — projets, réalisations, travaux.
/// S'appuie entièrement sur [ProfileController] qui expose déjà l'API backend.
class PortfolioScreen extends GetView<ProfileController> {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.portfolioProjects.isEmpty &&
          !controller.isLoadingPortfolio.value) {
        controller.loadPortfolio();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Portfolio', style: AppTextStyles.headlineSm),
        leading: IconButton(
          tooltip: 'Retour',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            AppHaptics.tap();
            Navigator.of(context).maybePop();
          },
        ),
      ),
      body: Obx(() {
        final isLoading = controller.isLoadingPortfolio.value;
        final projects = controller.portfolioProjects;
        final errorMessage = controller.errorMessage.value;

        if (isLoading && projects.isEmpty) {
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, __) => const OfferCardSkeleton(height: 200),
          );
        }

        if (projects.isEmpty) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: controller.loadPortfolio,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.7,
                  child: errorMessage.isNotEmpty
                      ? ErrorStateView(
                          message: errorMessage,
                          onRetry: controller.loadPortfolio,
                        )
                      : EmptyState(
                          icon: Icons.folder_open_outlined,
                          title: 'Aucun projet',
                          subtitle:
                              'Ajoutez vos meilleurs projets, ils seront visibles par les recruteurs dès que vous postulez.',
                          actionLabel: 'Ajouter un projet',
                          onAction: () {
                            AppHaptics.tap();
                            Get.toNamed(AppRoutes.profilePortfolioEdit);
                          },
                        ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.loadPortfolio,
          child: AnimationLimiter(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: projects.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final project = projects[index];
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 300),
                  child: SlideAnimation(
                    verticalOffset: 16,
                    child: FadeInAnimation(
                      child: _ProjectCard(
                        project: project,
                        onTap: () {
                          AppHaptics.tap();
                          Get.toNamed(
                            AppRoutes.profilePortfolioEdit,
                            arguments: project,
                          );
                        },
                        onDelete: () async {
                          AppHaptics.confirm();
                          final ok = await _confirmDelete(context);
                          if (ok != true) return;
                          await controller.deleteProject(project.id);
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          AppHaptics.tap();
          Get.toNamed(AppRoutes.profilePortfolioEdit);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouveau projet'),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showConfirmSheet(
      context: context,
      icon: Icons.delete_outline_rounded,
      iconColor: AppColors.error,
      title: 'Supprimer ce projet ?',
      message: 'Cette action est définitive.',
      confirmLabel: 'Supprimer',
      isDestructive: true,
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.onTap,
    required this.onDelete,
  });

  final PortfolioProjectModel project;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final hasImage = project.images.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.2),
          ),
          boxShadow: AppColors.lightShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: project.images.first,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.surfaceIconSoft,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.primary,
                      size: 36,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleLg,
                        ),
                        if (project.description.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            project.description,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.bodyColor,
                              height: 1.4,
                            ),
                          ),
                        ],
                        if (project.tags.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: project.tags
                                .take(4)
                                .map(
                                  (tag) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceIconSoft,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      tag,
                                      style: AppTextStyles.labelSm.copyWith(
                                        color: AppColors.primary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (value) {
                      if (value == 'delete') onDelete();
                      if (value == 'edit') onTap();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 10),
                            Text('Modifier'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: AppColors.error,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Supprimer',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
