import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import 'package:jobaway/app/core/constants/api_constants.dart';
import 'package:jobaway/app/core/theme/app_colors.dart';
import 'package:jobaway/app/core/theme/app_dimens.dart';
import 'package:jobaway/app/core/theme/app_motion.dart';
import 'package:jobaway/app/core/theme/app_shapes.dart';
import 'package:jobaway/app/core/theme/app_text_styles.dart';
import 'package:jobaway/app/core/theme/app_theme_controller.dart';
import 'package:jobaway/app/core/utils/haptics.dart';
import 'package:jobaway/routes/app_routes.dart';
import 'package:jobaway/app/core/widgets/widgets.dart';
import 'package:jobaway/app/features/streak/presentation/controllers/streak_controller.dart';
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
              _ProfileBody(profile: profile),
            ],
          ),
        );
      }),
    );
  }
}

// ── Corps : bascule « Ma Vue » / « Vue Recruteur » ──────────────────────────

/// Corps du profil sous le hero. Pour les candidats, une bascule segmentée
/// « Ma Vue » (profil éditable + réglages) / « Vue Recruteur » (aperçu lecture
/// seule de ce que voient les entreprises). Pour les autres types de compte, on
/// affiche directement la vue éditable.
class _ProfileBody extends StatefulWidget {
  const _ProfileBody({required this.profile});
  final Profile profile;

  @override
  State<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<_ProfileBody> {
  int _segment = 0; // 0 = Ma Vue, 1 = Vue Recruteur

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final isCandidate = profile.userType == 'candidate';

    if (!isCandidate) return _MyView(profile: profile);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: _ViewToggle(
            selected: _segment,
            onChanged: (i) {
              AppHaptics.tap();
              setState(() => _segment = i);
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Transition douce (fade + léger glissement vertical) entre les deux vues.
        AnimatedSwitcher(
          duration: AppMotion.medium,
          switchInCurve: AppMotion.emphasizedDecelerate,
          switchOutCurve: AppMotion.emphasizedAccelerate,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.02),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: _segment == 0
              ? KeyedSubtree(
                  key: const ValueKey('profile-ma-vue'),
                  child: _MyView(profile: profile),
                )
              : KeyedSubtree(
                  key: const ValueKey('profile-vue-recruteur'),
                  child: _RecruiterView(profile: profile),
                ),
        ),
      ],
    );
  }
}

/// Bascule segmentée « Ma Vue » / « Vue Recruteur » (pilule glissante en spring).
class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.selected, required this.onChanged});
  final int selected;
  final ValueChanged<int> onChanged;

  static const _labels = ['Ma Vue', 'Vue Recruteur'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: AppShapes.pill,
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final segWidth = (c.maxWidth - 8) / 2;
          return Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                alignment: selected == 0
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Container(
                  width: segWidth,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: AppShapes.pill,
                    boxShadow: AppColors.lightShadow,
                  ),
                ),
              ),
              Row(
                children: List.generate(2, (i) {
                  final active = i == selected;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(i),
                      child: Center(
                        child: Text(
                          _labels[i],
                          style: AppTextStyles.labelLg.copyWith(
                            color: active
                                ? AppColors.primaryAccent
                                : AppColors.hintColor,
                            fontWeight:
                                active ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// « Ma Vue » : sections à compléter + coordonnées + vidéo + documents + réglages.
class _MyView extends StatelessWidget {
  const _MyView({required this.profile});
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final isCandidate = profile.userType == 'candidate';
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          child: _StreakCard(),
        ),
        if (isCandidate) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _SectionsToComplete(profile: profile),
          ),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: _ContactCard(profile: profile),
        ),
        if (isCandidate) ...[
          const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: PresentationVideoCard(),
          ),
        ],
        const SizedBox(height: 18),
        const _DocumentsStrip(),
        const SizedBox(height: 18),
        const _CertificatesStrip(),
        const SizedBox(height: 6),
        const SettingsBody(),
      ],
    );
  }
}

/// Carte d'accès à la série quotidienne (gamification de rétention). Affiche la
/// flamme + le nombre de jours consécutifs ; tap → écran « Ma série ».
class _StreakCard extends StatelessWidget {
  const _StreakCard();

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<StreakController>()) return const SizedBox.shrink();
    final streak = Get.find<StreakController>();
    return PressScale(
      onTap: () {
        AppHaptics.tap();
        Get.toNamed(AppRoutes.streak);
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: ShapeDecoration(
          color: AppColors.surfaceCard,
          shape: AppShapes.cardBordered(AppColors.outlineVariant),
          shadows: AppColors.lightShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: AppShapes.squircleRadius(AppRadius.sm),
              ),
              child: Text('🔥', style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() {
                    final n = streak.currentStreak.value;
                    return Text(
                      n <= 0
                          ? 'Démarrez votre série'
                          : '$n jour${n > 1 ? "s" : ""} de suite',
                      style: AppTextStyles.titleMd
                          .copyWith(fontWeight: FontWeight.w800),
                    );
                  }),
                  const SizedBox(height: 2),
                  Text('Votre série de connexions quotidiennes',
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.hintColor)),
                ],
              ),
            ),
            Icon(IconlyLight.arrow_right_2, color: AppColors.outlineVariant),
          ],
        ),
      ),
    );
  }
}

/// Modèle d'une section de profil (libellé, icône, état rempli, route d'édition).
typedef _ProfileSection = ({
  String label,
  IconData icon,
  bool done,
  String route,
});

List<_ProfileSection> _sectionsFor(Profile p) => [
      (
        label: 'Titre',
        icon: IconlyLight.user,
        done: (p.headline ?? '').trim().isNotEmpty,
        route: AppRoutes.profileEdit,
      ),
      (
        label: 'Bio',
        icon: IconlyLight.document,
        done: (p.bio ?? '').trim().isNotEmpty,
        route: AppRoutes.profileEdit,
      ),
      (
        label: 'Compétences',
        icon: IconlyLight.star,
        done: p.skills.isNotEmpty,
        route: AppRoutes.profileParcours,
      ),
      (
        label: 'Expériences',
        icon: IconlyLight.work,
        done: p.experiences.isNotEmpty,
        route: AppRoutes.profileParcours,
      ),
      (
        label: 'Education',
        icon: Icons.school_outlined,
        done: p.educations.isNotEmpty,
        route: AppRoutes.profileParcours,
      ),
      (
        label: 'Langues',
        icon: Icons.translate_rounded,
        done: p.languages.isNotEmpty,
        route: AppRoutes.profileParcours,
      ),
    ];

/// Carte « Sections à compléter » : chips des sections encore vides, chacune
/// menant à l'écran d'édition adéquat. Masquée si le profil est complet.
class _SectionsToComplete extends StatelessWidget {
  const _SectionsToComplete({required this.profile});
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final missing = _sectionsFor(profile).where((s) => !s.done).toList();
    if (missing.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: ShapeDecoration(
          color: AppColors.warningSoft,
          shape: AppShapes.squircle(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded,
                    size: 18, color: AppColors.warningAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Sections à compléter',
                      style: AppTextStyles.titleMd
                          .copyWith(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Complétez votre profil pour augmenter vos chances auprès des recruteurs.',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.bodyColor),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in missing)
                  PressScale(
                    onTap: () {
                      AppHaptics.tap();
                      Get.toNamed(s.route);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: AppShapes.pill,
                        border: Border.all(
                            color: AppColors.warningAccent
                                .withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(s.icon,
                              size: 14, color: AppColors.warningAccent),
                          const SizedBox(width: 6),
                          Text(s.label,
                              style: AppTextStyles.labelSm.copyWith(
                                  color: AppColors.titleColor,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(width: 4),
                          Icon(IconlyLight.plus,
                              size: 14, color: AppColors.warningAccent),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// « Vue Recruteur » : aperçu lecture seule. N'affiche que les sections
/// complétées — exactement ce que voient les entreprises.
class _RecruiterView extends StatelessWidget {
  const _RecruiterView({required this.profile});
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final hasContent = (profile.bio ?? '').trim().isNotEmpty ||
        profile.skills.isNotEmpty ||
        profile.experiences.isNotEmpty ||
        profile.educations.isNotEmpty ||
        profile.languages.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bandeau explicatif.
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: ShapeDecoration(
              color: AppColors.categoryBlue.withValues(alpha: 0.10),
              shape: AppShapes.squircle(AppRadius.lg),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(IconlyLight.show, size: 20, color: AppColors.categoryBlue),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Voici comment votre profil apparaît aux recruteurs',
                        style: AppTextStyles.titleMd
                            .copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Seules les sections complétées sont visibles pour les entreprises.',
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.bodyColor, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (!hasContent)
            _RecruiterEmpty()
          else ...[
            if ((profile.bio ?? '').trim().isNotEmpty)
              _RecruiterCard(
                title: 'À propos',
                child: Text(profile.bio!,
                    style: AppTextStyles.bodyMd
                        .copyWith(color: AppColors.bodyColor, height: 1.5)),
              ),
            if (profile.skills.isNotEmpty)
              _RecruiterCard(
                title: 'Compétences',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in profile.skills)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color:
                              AppColors.primaryAccent.withValues(alpha: 0.10),
                          borderRadius: AppShapes.pill,
                        ),
                        child: Text(s,
                            style: AppTextStyles.labelSm.copyWith(
                                color: AppColors.primaryAccent,
                                fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ),
            if (profile.experiences.isNotEmpty)
              _RecruiterCard(
                title: 'Expériences',
                child: Column(
                  children: [
                    for (final e in profile.experiences)
                      _RecruiterLine(
                        icon: IconlyLight.work,
                        title: e.title,
                        subtitle: e.company,
                      ),
                  ],
                ),
              ),
            if (profile.educations.isNotEmpty)
              _RecruiterCard(
                title: 'Education',
                child: Column(
                  children: [
                    for (final e in profile.educations)
                      _RecruiterLine(
                        icon: Icons.school_outlined,
                        title: e.degree,
                        subtitle: e.institution,
                      ),
                  ],
                ),
              ),
            if (profile.languages.isNotEmpty)
              _RecruiterCard(
                title: 'Langues',
                child: Column(
                  children: [
                    for (final l in profile.languages)
                      _RecruiterLine(
                        icon: Icons.translate_rounded,
                        title: l.name,
                        subtitle: l.level,
                      ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _RecruiterEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: ShapeDecoration(
        color: AppColors.surfaceCard,
        shape: AppShapes.cardBordered(AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(IconlyLight.profile, size: 36, color: AppColors.hintColor),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Votre profil public est encore vide',
            textAlign: TextAlign.center,
            style: AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Complétez vos sections dans « Ma Vue » pour apparaître auprès des recruteurs.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.hintColor),
          ),
        ],
      ),
    );
  }
}

class _RecruiterCard extends StatelessWidget {
  const _RecruiterCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: ShapeDecoration(
        color: AppColors.surfaceCard,
        shape: AppShapes.cardBordered(AppColors.outlineVariant),
        shadows: AppColors.lightShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _RecruiterLine extends StatelessWidget {
  const _RecruiterLine(
      {required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withValues(alpha: 0.10),
              borderRadius: AppShapes.squircleRadius(AppRadius.sm),
            ),
            child: Icon(icon, size: 17, color: AppColors.primaryAccent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleMd
                        .copyWith(fontWeight: FontWeight.w700, fontSize: 14)),
                if (subtitle.trim().isNotEmpty)
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.hintColor)),
              ],
            ),
          ),
        ],
      ),
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

class _CertificatesStrip extends StatelessWidget {
  const _CertificatesStrip();

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ProfileController>()) return const SizedBox.shrink();
    final controller = Get.find<ProfileController>();
    return Obx(() {
      final items = controller.trainingCertificates;
      if (items.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: SectionHeader(title: 'Certificats'),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 106,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (_, i) => _CertificateCard(item: items[i]),
            ),
          ),
        ],
      );
    });
  }
}

class _CertificateCard extends StatelessWidget {
  const _CertificateCard({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final title = (item['training_title'] ??
            item['title'] ??
            item['name'] ??
            'Certificat')
        .toString();
    final issued = (item['issued_at'] ?? item['created_at'] ?? '').toString();
    return SizedBox(
      width: 176,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: ShapeDecoration(
          color: AppColors.surfaceCard,
          shape: AppShapes.cardBordered(
            AppColors.outlineVariant.withValues(alpha: 0.2),
          ),
          shadows: AppColors.lightShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.successSoft,
                borderRadius: AppShapes.squircleRadius(AppRadius.sm),
              ),
              child: Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.successAccent,
                size: 21,
              ),
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.titleColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (issued.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                issued,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.hintColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
