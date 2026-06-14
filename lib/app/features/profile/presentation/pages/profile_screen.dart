import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import 'package:opportune_bf/app/core/constants/api_constants.dart';
import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_shapes.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/theme/app_theme_controller.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/routes/app_routes.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import '../controllers/profile_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/documents_controller.dart';
import '../../data/models/candidate_document_model.dart';
import '../../domain/entities/profile.dart';
import '../widgets/presentation_video_card.dart';
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
        return AppRefreshIndicator(
          color: AppColors.primaryAccent,
          onRefresh: controller.fetchProfile,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _ProfileHero(profile: profile),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _ContactCard(profile: profile),
              ),
              if (profile.userType == 'candidate') ...[
                const SizedBox(height: 18),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: const PresentationVideoCard(),
                ),
              ],
              const SizedBox(height: 18),
              const _DocumentsStrip(),
              const SizedBox(height: 6),
              const SettingsBody(),
            ],
          ),
        );
      }),
    );
  }
}

// ── Hero Mesh ─────────────────────────────────────────────────────────────────

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.profile});
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      // Fond mesh brand (vert vibrant en light, désaturé foncé en dark)
      decoration: BoxDecoration(gradient: AppColors.meshBrand),
      foregroundDecoration: BoxDecoration(gradient: AppColors.meshBrandGlow),
      child: Column(
        children: [
          SizedBox(height: topPadding + 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Titre hero dark-aware (pas onPrimary blanc — mesh n'est pas
                // un dégradé plein)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      label: 'Titre: Profil de ${profile.fullName}',
                      child: Text(
                        'Profil',
                        style: AppTextStyles.displayHero.copyWith(
                          color: AppColors.titleColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 60,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent.withValues(alpha: 0.55),
                        borderRadius: AppShapes.pill,
                      ),
                    ),
                  ],
                ),
                // Boutons d'action header (AppIconButton, thème mesh-aware)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Obx(() {
                      final theme = Get.find<AppThemeController>();
                      final isDark = theme.isDarkMode.value;
                      return AppIconButton(
                        icon: isDark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        onTap: () {
                          if (Get.isRegistered<SettingsController>()) {
                            Get.find<SettingsController>().setDarkMode(!isDark);
                          } else {
                            theme.setDarkMode(!isDark);
                          }
                        },
                      );
                    }),
                    const SizedBox(width: 10),
                    AppIconButton(
                      icon: IconlyLight.edit,
                      onTap: () => Get.toNamed(AppRoutes.profileEdit),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Fond surface arrondi en haut qui émerge du mesh
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(40)),
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
                          color: AppColors.titleColor,
                        ),
                      ),
                      if (profile.headline != null &&
                          profile.headline!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          profile.headline!,
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.primaryAccent,
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
    );
  }
}

class _FloatingAvatar extends StatelessWidget {
  const _FloatingAvatar({required this.profile});
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();
    final pct = profile.completionPercent;
    return SizedBox(
      width: 116,
      height: 116,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Anneau de complétion du profil
          SizedBox(
            width: 112,
            height: 112,
            child: CircularProgressIndicator(
              value: pct / 100,
              strokeWidth: 4,
              backgroundColor: AppColors.outlineVariant.withValues(alpha: 0.45),
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
            ),
          ),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceLow,
                  border: Border.all(color: AppColors.surfaceCard, width: 4),
                  boxShadow: [
                    ...AppColors.lightShadow,
                    ...AppColors.ambientShadow,
                  ],
                ),
                child: ClipOval(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      (profile.avatarUrl ?? '').isEmpty
                          ? Icon(
                              IconlyLight.profile,
                              size: 60,
                              color: AppColors.primaryAccent,
                            )
                          : CachedNetworkImage(
                              imageUrl: ApiConstants.resolveMediaUrl(
                                      profile.avatarUrl) ??
                                  '',
                              fit: BoxFit.cover,
                              placeholder: (_, __) => ColoredBox(
                                color: AppColors.surfaceLow,
                                child: Icon(IconlyLight.profile,
                                    size: 60, color: AppColors.primaryAccent),
                              ),
                              // Avatar cassé/404 → fallback icône
                              errorWidget: (_, __, ___) => ColoredBox(
                                color: AppColors.surfaceLow,
                                child: Icon(IconlyLight.profile,
                                    size: 60, color: AppColors.primaryAccent),
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
                    boxShadow: [
                      ...AppColors.lightShadow,
                      ...AppColors.ambientShadow,
                    ],
                  ),
                  child: const Icon(
                    IconlyLight.camera,
                    size: 18,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ],
          ),
          // Pastille du % de complétion en heroNumber + AnimatedCount
          Align(
            alignment: Alignment.topCenter,
            child: AnimatedCount(
              value: pct,
              builder: (ctx, v) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: AppShapes.pill,
                  border: Border.all(color: AppColors.surfaceCard, width: 2),
                ),
                child: Text(
                  '$v%',
                  style: AppTextStyles.heroNumber.copyWith(
                    color: AppColors.onPrimary,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberBadge extends StatelessWidget {
  const _MemberBadge({required this.isComplete});
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final color =
        isComplete ? AppColors.successAccent : AppColors.warningAccent;
    final bg = isComplete ? AppColors.successSoft : AppColors.warningSoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppShapes.pill,
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isComplete
                ? IconlyBold.shield_done
                : Icons.workspace_premium_rounded,
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
    return AppRefreshIndicator(
      onRefresh: Get.find<ProfileController>().fetchProfile,
      child: ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: errorMessage.isNotEmpty
                ? ErrorStateView(
                    message: errorMessage,
                    illustration: const ErrorIllustration(),
                    onRetry: Get.find<ProfileController>().fetchProfile)
                : const EmptyState(
                    illustration: EmptyPeopleIllustration(),
                    title: 'Profil indisponible',
                    subtitle:
                        'Impossible de charger votre profil pour le moment.',
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

// ── Coordonnées ───────────────────────────────────────────────────────────────

/// Carte « Coordonnées » en squircle. L'ancêtre Material (requis par InkWell)
/// est fourni par le [Material] transparent qui enveloppe le [Container].
class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.profile});
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    void edit() {
      AppHaptics.tap();
      Get.toNamed(AppRoutes.profileEdit);
    }

    final phone = profile.phone.trim();
    final email = profile.email.trim();
    final city = profile.city.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Coordonnées'),
        // Material(transparency) requis : le Container seul ne fournit pas le
        // contexte Material nécessaire aux InkWell enfants (_ContactRow).
        Material(
          type: MaterialType.transparency,
          child: Container(
            decoration: ShapeDecoration(
              color: AppColors.surfaceCard,
              shape: AppShapes.cardBordered(AppColors.outlineVariant),
              shadows: [
                ...AppColors.lightShadow,
                ...AppColors.ambientShadow,
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _ContactRow(
                  icon: IconlyLight.call,
                  color: AppColors.categoryBlue,
                  value: phone.isEmpty ? 'Ajouter un numéro' : phone,
                  muted: phone.isEmpty,
                  onTap: edit,
                ),
                _rowDivider(),
                _ContactRow(
                  icon: IconlyLight.message,
                  color: AppColors.categoryOrange,
                  value: email.isEmpty ? 'Ajouter un email' : email,
                  muted: email.isEmpty,
                  onTap: edit,
                ),
                _rowDivider(),
                _ContactRow(
                  icon: IconlyLight.location,
                  color: AppColors.categoryCyan,
                  value: city.isEmpty ? 'Ajouter une ville' : city,
                  muted: city.isEmpty,
                  onTap: edit,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _rowDivider() => Divider(
        height: 1,
        thickness: 1,
        indent: 60,
        color: AppColors.outlineVariant.withValues(alpha: 0.35),
      );
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.color,
    required this.value,
    required this.onTap,
    this.muted = false,
  });

  final IconData icon;
  final Color color;
  final String value;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _SquareTileIcon(icon: icon, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleMd.copyWith(
                  color: muted ? AppColors.hintColor : AppColors.titleColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(IconlyLight.arrow_right_2, color: AppColors.outlineVariant),
          ],
        ),
      ),
    );
  }
}

/// Icône carrée squircle colorée (coins continus, langage 2026).
class _SquareTileIcon extends StatelessWidget {
  const _SquareTileIcon({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        // Squircle xs8 perçu (coins continus)
        borderRadius: AppShapes.squircleRadius(AppRadius.xs),
      ),
      child: Icon(icon, color: AppColors.onPrimary, size: 19),
    );
  }
}

// ── Mes documents ─────────────────────────────────────────────────────────────

/// Bande horizontale « Mes documents » : vraies pièces du candidat (synchro
/// `DocumentsController`), avec carte « Ajouter » en fin de liste.
class _DocumentsStrip extends StatelessWidget {
  const _DocumentsStrip();

  @override
  Widget build(BuildContext context) {
    final docs = Get.isRegistered<DocumentsController>()
        ? Get.find<DocumentsController>()
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: SectionHeader(
            title: 'Mes documents',
            actionLabel: 'Voir tout',
            onAction: () {
              AppHaptics.tap();
              Get.toNamed(AppRoutes.profileDocuments);
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 106,
          child: docs == null
              ? _list(const [_AddDocCard()])
              : Obx(() {
                  if (docs.isLoading.value && docs.documents.isEmpty) {
                    return _list(const [
                      SkeletonBox(
                          height: 106, width: 124, radius: AppRadius.md),
                      SkeletonBox(
                          height: 106, width: 124, radius: AppRadius.md),
                      SkeletonBox(
                          height: 106, width: 124, radius: AppRadius.md),
                    ]);
                  }
                  final items = docs.documents;
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    itemCount: items.length + 1,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.md),
                    itemBuilder: (context, i) {
                      if (i >= items.length) return const _AddDocCard();
                      final doc = items[i];
                      return _DocCard(
                        doc: doc,
                        onTap: () {
                          AppHaptics.tap();
                          docs.open(doc);
                        },
                      );
                    },
                  );
                }),
        ),
      ],
    );
  }

  Widget _list(List<Widget> children) => ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: children.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, i) => children[i],
      );
}

class _DocCard extends StatelessWidget {
  const _DocCard({required this.doc, required this.onTap});
  final CandidateDocument doc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 124,
      // Material requis pour l'InkWell enfant — borderRadius en squircle
      child: Material(
        color: AppColors.surfaceCard,
        borderRadius: AppShapes.cardRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppShapes.cardRadius,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: ShapeDecoration(
              shape: AppShapes.cardBordered(
                AppColors.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vignette squircle
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withValues(alpha: 0.12),
                    borderRadius: AppShapes.squircleRadius(AppRadius.sm),
                  ),
                  child: Icon(
                    doc.isImage ? IconlyBold.image : IconlyBold.document,
                    color: AppColors.primaryAccent,
                    size: 20,
                  ),
                ),
                const Spacer(),
                Text(
                  doc.typeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.hintColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  doc.title.isEmpty ? doc.originalFilename : doc.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.titleColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddDocCard extends StatelessWidget {
  const _AddDocCard();

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: () {
        AppHaptics.tap();
        Get.toNamed(AppRoutes.profileDocuments);
      },
      child: SizedBox(
        width: 124,
        child: Container(
          decoration: ShapeDecoration(
            color: AppColors.surfaceLow,
            shape: AppShapes.cardBordered(
              AppColors.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(IconlyLight.plus, color: AppColors.primaryAccent, size: 26),
              const SizedBox(height: 6),
              Text(
                'Ajouter',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.primaryAccent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
