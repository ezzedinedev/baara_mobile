import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_motion.dart';
import 'package:opportune_bf/app/core/theme/app_shapes.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import 'package:opportune_bf/app/features/offers/presentation/controllers/offer_controller.dart';
import 'package:opportune_bf/app/features/offers/domain/entities/matched_offer.dart';
import 'package:opportune_bf/app/features/offers/domain/entities/offer.dart';
import 'package:opportune_bf/app/features/offers/presentation/widgets/offer_logo_hero.dart';
import 'package:opportune_bf/app/features/trainings/presentation/controllers/trainings_controller.dart';
import 'package:opportune_bf/app/features/trainings/presentation/widgets/training_card.dart';
import 'package:opportune_bf/app/features/profile/presentation/pages/profile_screen.dart';
import 'package:opportune_bf/app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:opportune_bf/app/features/messaging/presentation/controllers/messages_controller.dart';
import 'package:opportune_bf/app/features/suivi/presentation/pages/suivi_screen.dart';
import 'package:opportune_bf/app/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:opportune_bf/app/features/community/presentation/pages/community_feed_screen.dart';
import 'package:opportune_bf/app/features/community/presentation/controllers/community_controller.dart';
import 'package:opportune_bf/routes/app_routes.dart';
import 'opportunites_screen.dart';
import '../controllers/home_controller.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // Le contenu passe SOUS la barre glass (effet verre).
      extendBody: true,
      body: Obx(
        () => _LazyTabStack(
          index: controller.currentTabIndex.value,
          children: const [
            _DashboardTab(),
            OpportunitesScreen(),
            CommunityFeedScreen(),
            SuiviScreen(),
            ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: const _HomeBottomNav(),
    );
  }
}

/// Accueil = **digest qui oriente**, pas un miroir des onglets. On ne ré-affiche
/// plus les listes complètes d'offres/formations (elles vivent dans le hub
/// Opportunités) : top bar + accès rapides vers les actions profondes + teaser
/// de l'activité réseau. Pull-to-refresh rafraîchit les données des onglets.
class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  // Contrôleur dédié pour piloter le parallax du hero (le bandeau salutation
  // monte plus lentement que le contenu et zoome élastiquement au pull-to-refresh).
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offerController = Get.find<OfferController>();
    final trainingsController = Get.find<TrainingsController>();

    return AppRefreshIndicator(
      color: AppColors.primaryAccent,
      onRefresh: () async {
        await Future.wait([
          offerController.loadOffers(refresh: true),
          offerController.loadMatchedOffers(),
          trainingsController.loadTrainings(refresh: true),
        ]);
      },
      child: ListView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        // Espace pour que le dernier contenu dégage la barre glass flottante.
        padding: const EdgeInsets.only(bottom: 104),
        children: [
          // Hero en parallax : translation plus lente + zoom au pull + fondu.
          ParallaxHeader(
            controller: _scroll,
            parallaxFactor: 0.5,
            child: const _AccueilTopBar(),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
            child: _QuickAccessRow(),
          ),
          // Offres recommandées par l'IA (« Pour toi ») — visible si matchs.
          const _MatchSection(),
          // Dernières offres d'emploi (toujours visibles).
          const _OffersSection(),
          // Formations recommandées — la communauté vit désormais dans son
          // propre onglet, l'accueil reste un digest offres + formations.
          const _FormationsSection(),
        ],
      ),
    );
  }
}

/// Section « Formations pour toi » : aperçu vertical (jusqu'à 2 cartes) avec la
/// nouvelle carte formation. « Tout voir » bascule sur l'onglet Opportunités,
/// segment Formations présélectionné.
class _FormationsSection extends StatelessWidget {
  const _FormationsSection();

  static const _maxPreview = 2;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TrainingsController>();
    return Obx(() {
      final isLoading = controller.isLoading.value;
      final items = controller.trainings;

      if (isLoading && items.isEmpty) {
        return const Column(
          children: [
            SizedBox(height: AppSpacing.xxl),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
              child: TrainingCardSkeleton(),
            ),
          ],
        );
      }
      if (items.isEmpty) return const SizedBox.shrink();

      final preview = items.take(_maxPreview).toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xxl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
            child: SectionHeader(
              title: 'Formations pour toi',
              actionLabel: 'Tout voir',
              onAction: () {
                AppHaptics.tap();
                Get.find<HomeController>().openOpportunites(segment: 1);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < preview.length; i++)
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.pageH,
                0,
                AppSpacing.pageH,
                i == preview.length - 1 ? 0 : AppSpacing.md,
              ),
              child: TrainingCard(
                training: preview[i],
                // Tag Hero unique : évite un doublon avec l'onglet Formations
                // (mêmes cartes montées en même temps).
                heroTag: 'home-formation-${preview[i].id}',
                onTap: () {
                  AppHaptics.tap();
                  Get.toNamed(
                    AppRoutes.trainingDetail.replaceFirst(':id', preview[i].id),
                  );
                },
              ),
            ),
        ],
      );
    });
  }
}

/// Accès rapides en BENTO : raccourcis vers les actions profondes (gain de
/// taps), tuiles de tailles variées (squircle, profondeur douce, icônes
/// colorées, press spring). Ne duplique pas la bottom nav.
class _QuickAccessRow extends StatelessWidget {
  const _QuickAccessRow();

  @override
  Widget build(BuildContext context) {
    // Tuile vedette (large, à gauche) + 3 tuiles compactes empilées à droite.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Expanded(
            flex: 1,
            child: _BentoTile(
              icon: IconlyBold.work,
              color: AppColors.categoryBlue,
              label: 'Candidatures',
              caption: 'Suivre mes envois',
              route: AppRoutes.myApplications,
              feature: true,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 1,
            child: Column(
              children: const [
                _BentoTile(
                  icon: IconlyBold.document,
                  color: AppColors.categoryPurple,
                  label: 'Mon CV',
                  route: AppRoutes.profileCv,
                ),
                SizedBox(height: AppSpacing.sm),
                _BentoTile(
                  icon: IconlyBold.folder,
                  color: AppColors.categoryCyan,
                  label: 'Documents',
                  route: AppRoutes.profileDocuments,
                ),
                SizedBox(height: AppSpacing.sm),
                _BentoTile(
                  icon: IconlyBold.bookmark,
                  color: AppColors.categoryOrange,
                  label: 'Portfolio',
                  route: AppRoutes.profilePortfolio,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tuile bento squircle. [feature] = grand format (icône XL + caption),
/// sinon format compact (icône + label sur une ligne).
class _BentoTile extends StatelessWidget {
  const _BentoTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.route,
    this.caption,
    this.feature = false,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String route;
  final String? caption;
  final bool feature;

  @override
  Widget build(BuildContext context) {
    final iconBadge = Container(
      width: feature ? 52 : 40,
      height: feature ? 52 : 40,
      decoration: ShapeDecoration(
        color: color,
        shape: AppShapes.squircle(feature ? AppRadius.md : AppRadius.sm),
        shadows: [
          BoxShadow(
            color: color.withValues(alpha: 0.32),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(icon, size: feature ? 25 : 20, color: AppColors.onPrimary),
    );

    final content = feature
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              iconBadge,
              const Spacer(),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleMd.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              if (caption != null) ...[
                const SizedBox(height: 2),
                Text(
                  caption!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.hintColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          )
        : Row(
            children: [
              iconBadge,
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMd.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          );

    return PressScale(
      onTap: () {
        AppHaptics.tap();
        Get.toNamed(route);
      },
      child: Container(
        padding: EdgeInsets.all(feature ? AppSpacing.lg : AppSpacing.md),
        constraints: BoxConstraints(minHeight: feature ? 132 : 0),
        decoration: ShapeDecoration(
          color: AppColors.surfaceCard,
          shape: AppShapes.cardBordered(AppColors.outlineVariant),
          shadows: AppColors.lightShadow,
        ),
        child: content,
      ),
    );
  }
}

/// Section « Offres d'emploi » : aperçu horizontal des dernières offres
/// publiées. « Tout voir » bascule sur l'onglet Opportunités (segment Offres).
class _OffersSection extends StatelessWidget {
  const _OffersSection();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OfferController>();
    return Obx(() {
      final loading = controller.isLoading.value;
      final offers = controller.offers;

      if (loading && offers.isEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.xxl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
              child: SectionHeader(title: 'Offres d\'emploi', onAction: () {}),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 176,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
                itemCount: 3,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.md),
                itemBuilder: (_, __) => const _OfferRailSkeleton(),
              ),
            ),
          ],
        );
      }
      if (offers.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xxl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
            child: SectionHeader(
              title: 'Offres d\'emploi',
              actionLabel: 'Tout voir',
              onAction: () {
                AppHaptics.tap();
                Get.find<HomeController>().openOpportunites(segment: 0);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 176,
            child: AnimationLimiter(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
                itemCount: offers.length > 8 ? 8 : offers.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.md),
                itemBuilder: (_, i) => AnimationConfiguration.staggeredList(
                  position: i,
                  duration: AppMotion.medium,
                  child: SlideAnimation(
                    horizontalOffset: 32,
                    curve: AppMotion.emphasizedDecelerate,
                    child: FadeInAnimation(
                      child: _OfferRailCard(offer: offers[i]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

/// Carte d'offre compacte (rail horizontal de l'accueil), largeur fixe.
class _OfferRailCard extends StatelessWidget {
  const _OfferRailCard({required this.offer});
  final Offer offer;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: PressScale(
        onTap: () {
          AppHaptics.tap();
          Get.toNamed(AppRoutes.offerDetail.replaceFirst(':id', offer.id));
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: ShapeDecoration(
            color: AppColors.surfaceCard,
            shape: AppShapes.cardBordered(AppColors.outlineVariant),
            shadows: [...AppColors.lightShadow, ...AppColors.ambientShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Morphing logo offre → détail (actif uniquement sur l'Accueil).
                  OfferLogoHero(
                    offerId: offer.id,
                    activeWhenTab: 0,
                    child: BrandAvatar(
                      seed: offer.company.isEmpty ? offer.title : offer.company,
                      label:
                          offer.company.isEmpty ? offer.title : offer.company,
                      imageUrl: offer.companyLogo,
                      size: 38,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      offer.company.isEmpty ? 'Entreprise' : offer.company,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.primaryAccent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                offer.title.isEmpty ? 'Offre' : offer.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleMd.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  if (offer.location.isNotEmpty) ...[
                    Icon(IconlyLight.location,
                        size: 13, color: AppColors.hintColor),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        offer.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelSm
                            .copyWith(color: AppColors.hintColor),
                      ),
                    ),
                  ],
                ],
              ),
              if (offer.salary.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  offer.salary.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.titleColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Squelette shimmer d'une carte d'offre du rail (mime la vraie structure).
class _OfferRailSkeleton extends StatelessWidget {
  const _OfferRailSkeleton();

  Widget _bar(double w, double h, [double r = 7]) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(r),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: ShapeDecoration(
          color: AppColors.surfaceCard,
          shape: AppShapes.cardBordered(AppColors.outlineVariant),
        ),
        child: SkeletonCluster(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _bar(110, 11),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _bar(double.infinity, 13),
              const SizedBox(height: 8),
              _bar(150, 13),
              const Spacer(),
              _bar(120, 11),
              const SizedBox(height: 8),
              _bar(80, 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section « Pour toi » : offres recommandées par l'IA (match feed). Se charge
/// une fois au montage ; masquée si l'utilisateur n'a pas de CV ou aucun match.
class _MatchSection extends StatefulWidget {
  const _MatchSection();

  @override
  State<_MatchSection> createState() => _MatchSectionState();
}

class _MatchSectionState extends State<_MatchSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<OfferController>()) {
        Get.find<OfferController>().loadMatchedOffers();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OfferController>();
    return Obx(() {
      final matches = controller.matchedOffers;
      final loading = controller.isLoadingMatches.value;
      final error = controller.matchesError.value;

      // Échec de chargement : on garde la section visible avec un retry, plutôt
      // que de la faire disparaître en silence.
      if (matches.isEmpty && !loading && error != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.xxl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
              child: Text(
                'Pour toi',
                style:
                    AppTextStyles.titleLg.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
              child: AppCard(
                child: Row(
                  children: [
                    Icon(Icons.cloud_off_rounded,
                        size: 20, color: AppColors.hintColor),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Suggestions indisponibles pour le moment.',
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.bodyColor),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        AppHaptics.tap();
                        controller.loadMatchedOffers();
                      },
                      child: Text('Réessayer',
                          style: AppTextStyles.labelMd.copyWith(
                              color: AppColors.primaryAccent,
                              fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }

      // Vide (succès sans match, ex. pas de CV) : section masquée, l'accueil
      // reste épuré.
      if (matches.isEmpty && !loading) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xxl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
            child: SectionHeader(
              title: 'Pour toi',
              actionLabel: 'Tout voir',
              onAction: () {
                AppHaptics.tap();
                Get.find<HomeController>().changeTab(1);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 168,
            child: (loading && matches.isEmpty)
                ? ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.pageH),
                    itemCount: 3,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.md),
                    itemBuilder: (_, __) => const SizedBox(
                      width: 250,
                      child: SkeletonBox(
                          width: 250, height: 168, radius: AppRadius.md),
                    ),
                  )
                : AnimationLimiter(
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.pageH),
                      itemCount: matches.length > 8 ? 8 : matches.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: AppSpacing.md),
                      itemBuilder: (_, i) =>
                          AnimationConfiguration.staggeredList(
                        position: i,
                        duration: AppMotion.medium,
                        child: SlideAnimation(
                          horizontalOffset: 32,
                          curve: AppMotion.emphasizedDecelerate,
                          child: FadeInAnimation(
                            child: _MatchCard(offer: matches[i]),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      );
    });
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.offer});
  final MatchedOffer offer;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: PressScale(
        onTap: () {
          AppHaptics.tap();
          Get.toNamed(AppRoutes.offerDetail.replaceFirst(':id', offer.id));
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: ShapeDecoration(
            color: AppColors.surfaceCard,
            shape: AppShapes.cardBordered(AppColors.outlineVariant),
            // Ombres en couches : ambiante large + portée courte (profondeur).
            shadows: [...AppColors.lightShadow, ...AppColors.ambientShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  MatchScorePill(score: offer.score),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                offer.title.isEmpty ? 'Offre' : offer.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleMd.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.titleColor,
                  height: 1.2,
                ),
              ),
              if (offer.company.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  offer.company,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySm
                      .copyWith(color: AppColors.primaryAccent),
                ),
              ],
              const Spacer(),
              // Le « pourquoi » du match (explication IA) — l'intérêt de la
              // suggestion. À défaut, on retombe sur la localisation.
              if (offer.explanation.isNotEmpty)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        size: 14, color: AppColors.primaryAccent),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        offer.explanation,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.bodyColor,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                )
              else if (offer.location.isNotEmpty)
                Row(
                  children: [
                    Icon(IconlyLight.location,
                        size: 14, color: AppColors.hintColor),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        offer.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.hintColor),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Top bar plat (SafeArea) : avatar + "Bonjour" + vrai prénom, cloche à
/// droite. Tap avatar/greeting → onglet Profil ; tap cloche → notifications.
class _AccueilTopBar extends StatelessWidget {
  const _AccueilTopBar();

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  @override
  Widget build(BuildContext context) {
    final profileController = Get.find<ProfileController>();

    return Container(
      // Mesh de marque subtil sous la salutation (effet hero doux, dark-aware).
      decoration: BoxDecoration(gradient: AppColors.meshBrand),
      foregroundDecoration: BoxDecoration(gradient: AppColors.meshBrandGlow),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageH,
            AppSpacing.md,
            AppSpacing.pageH,
            AppSpacing.lg,
          ),
          child: Row(
            children: [
              Expanded(
                child: Obx(() {
                  final profile = profileController.profile.value;
                  final firstName = profile?.firstName.trim() ?? '';
                  final greetingName =
                      firstName.isEmpty ? 'Bienvenue' : firstName;
                  final initials = firstName.isEmpty ? 'OB' : firstName;

                  return InkWell(
                    onTap: () {
                      AppHaptics.tap();
                      Get.find<HomeController>().changeTab(4);
                    },
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          BrandAvatar(
                            seed: profile?.email ?? greetingName,
                            label: initials,
                            size: 48,
                            imageUrl: profile?.avatarUrl,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _greeting(),
                                  style: AppTextStyles.labelMd.copyWith(
                                    color: AppColors.bodyColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                // Prénom en typo expressive (lourde + serrée).
                                Text(
                                  greetingName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.displayHero
                                      .copyWith(fontSize: 24),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Accès rapide messagerie (déplacé de la bottom nav vers le haut).
              // Pastille = total des conversations non lues.
              Obx(() {
                final messages = Get.isRegistered<MessagesController>()
                    ? Get.find<MessagesController>()
                    : null;
                final unread = messages == null
                    ? 0
                    : messages.conversations
                        .fold<int>(0, (sum, c) => sum + c.unreadCount);
                final button = AppIconButton(
                  icon: IconlyLight.chat,
                  tooltip: 'Messages',
                  onTap: () {
                    AppHaptics.tap();
                    Get.toNamed(AppRoutes.messages);
                  },
                );
                if (unread <= 0) return button;
                return Badge(
                  label: Text(unread > 99 ? '99+' : '$unread'),
                  backgroundColor: AppColors.error,
                  child: button,
                );
              }),
              const SizedBox(width: AppSpacing.sm),
              Obx(() {
                final unread = Get.isRegistered<NotificationsController>()
                    ? Get.find<NotificationsController>().unreadCount.value
                    : 0;
                final bell = AppIconButton(
                  icon: IconlyLight.notification,
                  onTap: () {
                    AppHaptics.tap();
                    Get.toNamed(AppRoutes.notifications);
                  },
                );
                if (unread <= 0) return bell;
                return Badge(
                  label: Text(unread > 99 ? '99+' : '$unread'),
                  backgroundColor: AppColors.error,
                  child: bell,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ne monte un onglet qu'après la première visite — évite 5 écrans + APIs au boot.
class _LazyTabStack extends StatefulWidget {
  const _LazyTabStack({
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  @override
  State<_LazyTabStack> createState() => _LazyTabStackState();
}

class _LazyTabStackState extends State<_LazyTabStack> {
  final Set<int> _mountedTabs = {0};

  @override
  void didUpdateWidget(covariant _LazyTabStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _mountedTabs.add(widget.index);
  }

  @override
  Widget build(BuildContext context) {
    _mountedTabs.add(widget.index);
    return Stack(
      fit: StackFit.expand,
      children: List.generate(widget.children.length, (i) {
        if (!_mountedTabs.contains(i)) {
          return const SizedBox.shrink();
        }
        final active = i == widget.index;
        return Offstage(
          offstage: !active,
          child: TickerMode(
            enabled: active,
            child: widget.children[i],
          ),
        );
      }),
    );
  }
}

/// Badge non-lus (Material 3) sur une icône d'onglet, alimenté par le total
/// des conversations non lues. Réactif via Obx ; transparent si zéro.
/// Pastille de compteur sur un onglet de nav. [kind] : 'messages' (conversations
/// non lues) ou 'network' (demandes de connexion en attente). Réactif (Obx) ;
/// rien si compteur = 0 ou controller absent.
class _NavBadge extends StatelessWidget {
  const _NavBadge({required this.kind, required this.child});

  final String kind;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    switch (kind) {
      case 'messages':
        if (!Get.isRegistered<MessagesController>()) return child;
        final messages = Get.find<MessagesController>();
        return Obx(() => _wrap(
              messages.conversations
                  .fold<int>(0, (sum, c) => sum + c.unreadCount),
              child,
            ));
      case 'network':
        if (!Get.isRegistered<CommunityController>()) return child;
        final community = Get.find<CommunityController>();
        return Obx(() => _wrap(community.pendingConnections.length, child));
      default:
        return child;
    }
  }

  static Widget _wrap(int count, Widget child) {
    if (count <= 0) return child;
    return Badge(
      label: Text(count > 99 ? '99+' : '$count'),
      backgroundColor: AppColors.error,
      child: child,
    );
  }
}

/// Barre de navigation « glass » flottante : fond translucide + flou
/// d'arrière-plan (BackdropFilter), pill qui s'étire sur l'onglet actif (icône
/// + label). Le contenu défile dessous (Scaffold.extendBody) pour l'effet verre.
class _HomeBottomNav extends GetView<HomeController> {
  const _HomeBottomNav();

  // `badge` = source du compteur de pastille (null = aucune) :
  // 'network' → demandes de connexion en attente ; 'messages' → non-lus.
  static const _items =
      <({IconData icon, IconData active, String labelKey, String? badge})>[
    (
      icon: IconlyLight.home,
      active: IconlyBold.home,
      labelKey: 'nav.home',
      badge: null
    ),
    (
      icon: IconlyLight.work,
      active: IconlyBold.work,
      labelKey: 'nav.offers',
      badge: null
    ),
    (
      icon: IconlyLight.user,
      active: IconlyBold.user_3,
      labelKey: 'nav.network',
      badge: 'network'
    ),
    (
      icon: IconlyLight.category,
      active: IconlyBold.category,
      labelKey: 'nav.tracking',
      badge: null
    ),
    (
      icon: IconlyLight.profile,
      active: IconlyBold.profile,
      labelKey: 'nav.profile',
      badge: null
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        // Verre liquide flottant (chrome) : GlassSurface = blur + couche tonale
        // + liseré spéculaire, dans un RepaintBoundary.
        child: GlassSurface(
          borderRadius: AppShapes.pill,
          blurSigma: 20,
          boxShadow: AppColors.ambientShadow,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: SizedBox(
            height: 62,
            child: Obx(() {
              final current = controller.currentTabIndex.value;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (var i = 0; i < _items.length; i++)
                    _GlassNavItem(
                      item: _items[i],
                      selected: i == current,
                      onTap: () {
                        AppHaptics.tap();
                        controller.changeTab(i);
                      },
                    ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _GlassNavItem extends StatelessWidget {
  const _GlassNavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final ({IconData icon, IconData active, String labelKey, String? badge}) item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryAccent : AppColors.hintColor;
    // Icône avec micro-bascule de scale en spring quand l'onglet devient actif.
    Widget icon = AnimatedScale(
      scale: selected ? 1.0 : 0.92,
      duration: AppMotion.medium,
      curve: AppMotion.spring,
      child: Icon(selected ? item.active : item.icon, size: 22, color: color),
    );
    if (item.badge != null) icon = _NavBadge(kind: item.badge!, child: icon);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        // Sélection en spring : la pill « gonfle » avec un léger overshoot.
        duration: AppMotion.medium,
        curve: AppMotion.spring,
        height: 42,
        padding:
            EdgeInsets.symmetric(horizontal: selected ? 14 : 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryAccent.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: AppShapes.pill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            // Le nom « pousse » en spring sur l'onglet actif.
            AnimatedSize(
              duration: AppMotion.medium,
              curve: AppMotion.spring,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        item.labelKey.tr,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.clip,
                        style: AppTextStyles.labelSm.copyWith(
                          color: color,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
