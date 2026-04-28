import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme_controller.dart';
import '../../../core/utils/haptics.dart';
import '../../../../routes/app_routes.dart';
import '../../../core/widgets/widgets.dart';
import '../controllers/profile_controller.dart';
import '../models/profile_model.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<AppThemeController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Obx(
            () => WavyContentHeader(
              title: 'profile.title'.tr,
              subtitle: 'profile.subtitle'.tr,
              gradient: AppColors.heroProfileGradient,
              actions: [
                WavyHeaderActionButton(
                  icon: themeController.isDarkMode.value
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  onTap: () {
                    AppHaptics.tap();
                    themeController.toggle();
                  },
                ),
                const SizedBox(width: 8),
                WavyHeaderActionButton(
                  icon: Icons.edit_outlined,
                  onTap: () {
                    AppHaptics.tap();
                    Get.toNamed(AppRoutes.profileEdit);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
        final profile = controller.profile.value;
        final isLoading = controller.isLoadingProfile.value;
        final errorMessage = controller.errorMessage.value;

        if (isLoading && profile == null) {
          return const _ProfileSkeleton();
        }

        if (profile == null) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: controller.loadProfile,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.7,
                  child: errorMessage.isNotEmpty
                      ? ErrorStateView(
                          message: errorMessage,
                          onRetry: controller.loadProfile,
                        )
                      : const EmptyState(
                          icon: Icons.person_outline_rounded,
                          title: 'Profil indisponible',
                          subtitle:
                              'Impossible de charger votre profil pour le moment.',
                        ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _ProfileHeader(profile: profile),
              const SizedBox(height: 18),
              if ((profile.bio ?? '').isNotEmpty) ...[
                _ProfileSection(
                  title: 'À propos',
                  icon: Icons.person_outline_rounded,
                  child: Text(
                    profile.bio!,
                    style: AppTextStyles.bodyMd.copyWith(height: 1.45),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              if (profile.skills.isNotEmpty) ...[
                _ProfileSection(
                  title: 'Compétences',
                  icon: Icons.star_outline_rounded,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: profile.skills
                        .map((skill) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceIconSoft,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                skill,
                                style: AppTextStyles.bodySm.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              if (profile.experiences.isNotEmpty) ...[
                _ProfileSection(
                  title: 'Expériences',
                  icon: Icons.work_outline_rounded,
                  child: Column(
                    children: profile.experiences
                        .map((exp) => _ExperienceTile(experience: exp))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              if (profile.educations.isNotEmpty)
                _ProfileSection(
                  title: 'Formations',
                  icon: Icons.school_outlined,
                  child: Column(
                    children: profile.educations
                        .map((edu) => _EducationTile(education: edu))
                        .toList(),
                  ),
                ),
            ],
          ),
        );
            }),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final ProfileModel profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.profileGradientTop,
            AppColors.profileGradientMid,
            AppColors.profileGradientBottom,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.22),
        ),
        boxShadow: AppColors.ambientShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceIconSoft,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: (profile.avatarUrl ?? '').isEmpty
                ? const Icon(
                    Icons.person_rounded,
                    color: AppColors.primary,
                    size: 40,
                  )
                : CachedNetworkImage(
                    imageUrl: profile.avatarUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.person_rounded,
                      color: AppColors.primary,
                      size: 40,
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headlineMd,
                ),
                const SizedBox(height: 4),
                Text(
                  profile.headline ?? profile.email,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.bodyColor,
                  ),
                ),
                if (profile.city.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.bodyColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        [profile.city, profile.country]
                            .where((s) => s.isNotEmpty)
                            .join(', '),
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.bodyColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.surfaceIconSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Text(title, style: AppTextStyles.titleLg),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ExperienceTile extends StatelessWidget {
  const _ExperienceTile({required this.experience});

  final ExperienceModel experience;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8, right: 12),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(experience.title, style: AppTextStyles.titleMd),
                const SizedBox(height: 2),
                Text(
                  '${experience.company} · ${experience.dateLabel}',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.bodyColor,
                  ),
                ),
                if ((experience.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    experience.description!,
                    style: AppTextStyles.bodySm.copyWith(height: 1.4),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EducationTile extends StatelessWidget {
  const _EducationTile({required this.education});

  final EducationModel education;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8, right: 12),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(education.degree, style: AppTextStyles.titleMd),
                const SizedBox(height: 2),
                Text(
                  education.institution,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.bodyColor,
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

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const SkeletonCluster(
            child: Row(
              children: [
                SkeletonBox(height: 78, width: 78, shape: BoxShape.circle),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(height: 18, width: 180),
                      SizedBox(height: 8),
                      SkeletonBox(height: 12, width: 140),
                      SizedBox(height: 8),
                      SkeletonBox(height: 10, width: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.all(16),
          child: const SkeletonCluster(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 14, width: 120),
                SizedBox(height: 12),
                SkeletonBox(height: 10, width: double.infinity),
                SizedBox(height: 6),
                SkeletonBox(height: 10, width: double.infinity),
                SizedBox(height: 6),
                SkeletonBox(height: 10, width: 180),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
