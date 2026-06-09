import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import 'package:opportune_bf/app/core/constants/api_constants.dart';
import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/routes/app_routes.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import '../controllers/profile_controller.dart';
import '../../domain/entities/profile.dart';
import 'settings_screen.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        final profile = controller.profile.value;
        final isLoading = controller.isLoading.value;
        final errorMessage = controller.errorMessage.value;

        if (isLoading && profile == null) {
          return const _ProfileSkeleton();
        }

        if (profile == null) {
          return _ErrorOrEmptyState(errorMessage: errorMessage ?? '');
        }

        // Profil = identité (hero) + réglages groupés (SettingsBody), en un
        // seul défilement. Les infos détaillées (CV, parcours) s'éditent via
        // les réglages ("Informations personnelles").
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.fetchProfile,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _ProfileHero(profile: profile),
              const SizedBox(height: 8),
              const SettingsBody(),
            ],
          ),
        );
      }),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.profile});
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.heroProfileGradient,
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: TopoPainter())),
          Column(
            children: [
              SizedBox(height: topPadding + 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          label: 'Titre: Profil de ${profile.fullName}',
                          child: Text(
                            'Profil',
                            style: AppTextStyles.displayMd.copyWith(
                              color: AppColors.onPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: 32,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 60,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.onPrimary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                    _HeroActionButton(
                      icon: IconlyLight.edit,
                      onTap: () => Get.toNamed(AppRoutes.profileEdit),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: Column(
                  children: [
                    Transform.translate(
                      offset: const Offset(0, -50),
                      child: Column(
                        children: [
                          _FloatingAvatar(profile: profile),
                          const SizedBox(height: 16),
                          Text(
                            profile.fullName,
                            style: AppTextStyles.headlineMd.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                            ),
                          ),
                          if (profile.headline != null && profile.headline!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              profile.headline!,
                              style: AppTextStyles.bodyMd.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 12),
                          _MemberBadge(isComplete: profile.isProfileComplete),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FloatingAvatar extends StatelessWidget {
  const _FloatingAvatar({required this.profile});
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceLow,
            border: Border.all(color: AppColors.surfaceCard, width: 4),
            boxShadow: AppColors.ambientShadow,
          ),
          child: ClipOval(
            child: Stack(
              fit: StackFit.expand,
              children: [
                (profile.avatarUrl ?? '').isEmpty
                    ? const Icon(
                        Icons.person_rounded,
                        size: 60,
                        color: AppColors.primary,
                      )
                    : CachedNetworkImage(
                        imageUrl:
                            ApiConstants.resolveMediaUrl(profile.avatarUrl) ?? '',
                        fit: BoxFit.cover,
                        placeholder: (_, __) => ColoredBox(
                          color: AppColors.surfaceLow,
                          child: const Icon(Icons.person_rounded,
                              size: 60, color: AppColors.primary),
                        ),
                        // Avatar cassé/404 → fallback icône (au lieu du X rouge
                        // par défaut de CachedNetworkImage).
                        errorWidget: (_, __, ___) => ColoredBox(
                          color: AppColors.surfaceLow,
                          child: const Icon(Icons.person_rounded,
                              size: 60, color: AppColors.primary),
                        ),
                      ),
                Obx(() => controller.isUploadingAvatar.value
                    ? ColoredBox(
                        color: AppColors.onDark.withValues(alpha: 0.45),
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.onPrimary),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink()),
              ],
            ),
          ),
        ),
        PressScale(
          onTap: () {
            AppHaptics.tap();
            controller.pickAndUploadAvatar();
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: AppColors.lightShadow,
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              size: 18,
              color: AppColors.onPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  const _HeroActionButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: () {
        AppHaptics.tap();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.onPrimary.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.onPrimary.withValues(alpha: 0.3),
          ),
        ),
        child: Icon(icon, color: AppColors.onPrimary, size: 22),
      ),
    );
  }
}

class _MemberBadge extends StatelessWidget {
  const _MemberBadge({required this.isComplete});
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final color = isComplete ? AppColors.success : AppColors.warning;
    final bg = isComplete ? AppColors.successSoft : AppColors.warningSoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isComplete ? Icons.verified_user_rounded : Icons.workspace_premium_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            isComplete ? 'Profil complet' : 'Membre standard',
            style: AppTextStyles.labelSm.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorOrEmptyState extends StatelessWidget {
  const _ErrorOrEmptyState({required this.errorMessage});
  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: Get.find<ProfileController>().fetchProfile,
      child: ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: errorMessage.isNotEmpty
                ? ErrorStateView(message: errorMessage, onRetry: Get.find<ProfileController>().fetchProfile)
                : const EmptyState(
                    icon: IconlyLight.profile,
                    title: 'Profil indisponible',
                    subtitle: 'Impossible de charger votre profil pour le moment.',
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
      padding: EdgeInsets.zero,
      children: const [
        SkeletonBox(height: 250, width: double.infinity),
        SizedBox(height: 24),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: SkeletonBox(height: 180, radius: 24),
        ),
        SizedBox(height: 24),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: SkeletonBox(height: 200, radius: 24),
        ),
      ],
    );
  }
}
