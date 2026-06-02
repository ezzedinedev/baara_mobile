import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/routes/app_routes.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import '../controllers/profile_controller.dart';
import '../../domain/entities/profile.dart';

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

        return DefaultTabController(
          length: 4,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: _ProfileHero(profile: profile),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 3,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.bodyColor,
                      labelStyle: AppTextStyles.titleMd.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      unselectedLabelStyle: AppTextStyles.titleMd.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      tabs: const [
                        Tab(text: 'Infos'),
                        Tab(text: 'Parcours'),
                        Tab(text: 'Documents'),
                        Tab(text: 'Compte'),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              children: [
                _InfosTab(profile: profile),
                _ParcoursTab(profile: profile),
                const _DocumentsTab(),
                _CompteTab(controller: controller),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _DocumentsTab extends StatelessWidget {
  const _DocumentsTab();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: IconlyLight.document,
      title: 'Aucun document',
      subtitle:
          'Vos diplômes, certificats et attestations apparaîtront ici. '
          'Ajoutez-les depuis l\'espace web pour les retrouver sur mobile.',
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
                        imageUrl: profile.avatarUrl!,
                        fit: BoxFit.cover,
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

class _InfosTab extends StatelessWidget {
  const _InfosTab({required this.profile});
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (profile.bio != null && profile.bio!.isNotEmpty) ...[
          const SectionHeader(title: 'À propos'),
          const SizedBox(height: 12),
          BrandCard(
            child: Text(
              profile.bio!,
              style: AppTextStyles.bodyMd.copyWith(height: 1.6),
            ),
          ),
          const SizedBox(height: 24),
        ],
        const SectionHeader(title: 'Informations'),
        const SizedBox(height: 12),
        BrandCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _InfoTile(icon: IconlyLight.message, label: 'Email', value: profile.email),
              _InfoDivider(),
              _InfoTile(icon: IconlyLight.call, label: 'Téléphone', value: profile.phone),
              _InfoDivider(),
              _InfoTile(icon: IconlyLight.location, label: 'Localisation', value: '${profile.city}, ${profile.country}'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (profile.skills.isNotEmpty) ...[
          const SectionHeader(title: 'Compétences'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: profile.skills.map((s) => _SkillChip(label: s)).toList(),
          ),
          const SizedBox(height: 24),
        ],
        if (profile.languages.isNotEmpty) ...[
          const SectionHeader(title: 'Langues'),
          const SizedBox(height: 12),
          BrandCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: profile.languages.asMap().entries.map((entry) {
                final isLast = entry.key == profile.languages.length - 1;
                return Column(
                  children: [
                    ListTile(
                      leading: const Icon(IconlyLight.discovery, color: AppColors.primary),
                      title: Text(entry.value.name, style: AppTextStyles.titleMd),
                      trailing: Text(entry.value.level, style: AppTextStyles.labelMd),
                    ),
                    if (!isLast) _InfoDivider(),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ],
    );
  }
}

class _ParcoursTab extends StatelessWidget {
  const _ParcoursTab({required this.profile});
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionHeader(
          title: 'Expériences',
          actionLabel: 'Ajouter',
          onAction: () => Get.toNamed(AppRoutes.profileEdit),
        ),
        const SizedBox(height: 12),
        if (profile.experiences.isEmpty)
          const _EmptySection(message: 'Aucune expérience renseignée.')
        else
          ...profile.experiences.map((exp) => _ExperienceCard(experience: exp)),
        const SizedBox(height: 24),
        SectionHeader(
          title: 'Formations',
          actionLabel: 'Ajouter',
          onAction: () => Get.toNamed(AppRoutes.profileEdit),
        ),
        const SizedBox(height: 12),
        if (profile.educations.isEmpty)
          const _EmptySection(message: 'Aucune formation renseignée.')
        else
          ...profile.educations.map((edu) => _EducationCard(education: edu)),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _CompteTab extends StatelessWidget {
  const _CompteTab({required this.controller});
  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(title: 'Actions'),
        const SizedBox(height: 12),
        BrandCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _SettingsTile(
                icon: IconlyLight.send,
                label: 'Mes candidatures',
                color: AppColors.categoryBlue,
                onTap: () => Get.toNamed(AppRoutes.myApplications),
              ),
              _InfoDivider(),
              _SettingsTile(
                icon: IconlyLight.notification,
                label: 'Notifications',
                color: AppColors.categoryOrange,
                onTap: () => Get.toNamed(AppRoutes.settings),
              ),
              _InfoDivider(),
              _SettingsTile(
                icon: IconlyLight.lock,
                label: 'Sécurité & Confidentialité',
                color: AppColors.categoryPurple,
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Application'),
        const SizedBox(height: 12),
        BrandCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _SettingsTile(
                icon: IconlyLight.info_circle,
                label: 'Aide & Support',
                color: AppColors.categoryCyan,
                onTap: () {},
              ),
              _InfoDivider(),
              _SettingsTile(
                icon: IconlyLight.paper,
                label: 'Conditions Générales',
                color: AppColors.categoryGray,
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        BrandCard(
          onTap: () => _confirmLogout(context),
          borderColor: AppColors.error.withValues(alpha: 0.3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(IconlyLight.logout, color: AppColors.error),
              const SizedBox(width: 12),
              Text(
                'Se déconnecter',
                style: AppTextStyles.titleMd.copyWith(color: AppColors.error, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showConfirmSheet(
      context: context,
      icon: Icons.logout_rounded,
      iconColor: AppColors.error,
      title: 'Se déconnecter ?',
      message: 'Vous devrez vous reconnecter pour accéder à votre compte.',
      confirmLabel: 'Se déconnecter',
      isDestructive: true,
    );
    if (confirmed == true) {
      AppHaptics.confirm();
      await controller.logout();
    }
  }
}

// --- Common Sub-Widgets ---

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.11),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.bodyColor,
                  ),
                ),
                Text(
                  value,
                  style: AppTextStyles.titleMd.copyWith(
                    fontWeight: FontWeight.w700,
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

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.icon, required this.label, required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        AppHaptics.tap();
        onTap();
      },
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.w700)),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.outlineVariant,
      ),
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({required this.experience});
  final Experience experience;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BrandCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: AppColors.surfaceLow, borderRadius: BorderRadius.circular(12)),
              child: const Icon(IconlyLight.work, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(experience.title, style: AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.w800)),
                  Text(experience.company, style: AppTextStyles.bodyMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        IconlyLight.calendar,
                        size: 14,
                        color: AppColors.hintColor,
                      ),
                      const SizedBox(width: 4),
                      Text('${experience.startDate.month}/${experience.startDate.year} - ${experience.isCurrent ? "Présent" : "${experience.endDate?.month}/${experience.endDate?.year}"}', style: AppTextStyles.bodySm),
                      const SizedBox(width: 12),
                      Icon(
                        IconlyLight.location,
                        size: 14,
                        color: AppColors.hintColor,
                      ),
                      const SizedBox(width: 4),
                      Text(experience.location, style: AppTextStyles.bodySm),
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

class _EducationCard extends StatelessWidget {
  const _EducationCard({required this.education});
  final Education education;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BrandCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: AppColors.surfaceLow, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.school_outlined, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(education.degree, style: AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.w800)),
                  Text(education.institution, style: AppTextStyles.bodyMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        IconlyLight.calendar,
                        size: 14,
                        color: AppColors.hintColor,
                      ),
                      const SizedBox(width: 4),
                      Text('${education.startDate.year} - ${education.endDate?.year ?? "Présent"}', style: AppTextStyles.bodySm),
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

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        message,
        style: AppTextStyles.bodyMd.copyWith(
          color: AppColors.bodyColor,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _InfoDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, indent: 60, endIndent: 16, color: AppColors.outlineVariant.withValues(alpha: 0.1));
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
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
