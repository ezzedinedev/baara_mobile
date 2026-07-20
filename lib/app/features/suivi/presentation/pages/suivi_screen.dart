import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import 'package:jobaway/app/core/theme/app_colors.dart';
import 'package:jobaway/app/core/theme/app_dimens.dart';
import 'package:jobaway/app/core/theme/app_motion.dart';
import 'package:jobaway/app/core/theme/app_shapes.dart';
import 'package:jobaway/app/core/theme/app_text_styles.dart';
import 'package:jobaway/app/core/utils/haptics.dart';
import 'package:jobaway/app/core/utils/map_navigation.dart';
import 'package:jobaway/app/core/utils/relative_time.dart';
import 'package:jobaway/app/core/widgets/widgets.dart';
import 'package:jobaway/routes/app_routes.dart';

import '../../../community/domain/entities/profile_viewer.dart';
import '../../../offers/data/models/application_model.dart';
import '../../../offers/data/models/interview_detail_model.dart';
import '../../../offers/data/models/upcoming_interview_model.dart';
import '../../../offers/domain/entities/matched_offer.dart';
import '../../../offers/domain/entities/offer.dart';
import '../../../offers/presentation/widgets/offer_logo_hero.dart';
import '../controllers/suivi_controller.dart';

/// Hub « Suivi » — l'équivalent repensé du « Boards » d'Edomatch. Un seul écran,
/// cinq onglets scrollables qui agrègent le parcours candidat déjà présent dans
/// l'app : qui a vu mon profil, mes candidatures, mes matchs IA, mes entretiens
/// et mes offres favorites. Aucune donnée nouvelle inventée — tout vient des
/// controllers existants via [SuiviController].
class SuiviScreen extends StatelessWidget {
  const SuiviScreen({super.key});

  static const _tabs = <({String label, IconData icon})>[
    (label: 'Visiteurs', icon: IconlyLight.show),
    (label: 'Candidatures', icon: IconlyLight.paper),
    (label: 'Matchs', icon: IconlyLight.activity),
    (label: 'Entretiens', icon: IconlyLight.calendar),
    (label: 'Favoris', icon: IconlyLight.bookmark),
  ];

  @override
  Widget build(BuildContext context) {
    final suivi = Get.find<SuiviController>();

    return Material(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: DefaultTabController(
          length: _tabs.length,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // En-tête plat (cohérent avec SankTabShell) : titre + sous-titre.
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageH,
                  AppSpacing.md,
                  AppSpacing.pageH,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suivi',
                      style: AppTextStyles.displayMd.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ton parcours : visites, candidatures, matchs et entretiens.',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.bodyColor,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              // Barre d'onglets scrollable — souligné vert sur l'onglet actif,
              // à la Edomatch (mais branché sur le design system).
              _SuiviTabBar(tabs: _tabs),
              const SizedBox(height: AppSpacing.xs),
              Expanded(
                child: TabBarView(
                  children: [
                    _VisitorsTab(suivi: suivi),
                    _ApplicationsTab(suivi: suivi),
                    _MatchesTab(suivi: suivi),
                    _InterviewsTab(suivi: suivi),
                    _FavoritesTab(suivi: suivi),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// TabBar maison : scrollable, indicateur souligné fin, libellés + icônes.
class _SuiviTabBar extends StatelessWidget {
  const _SuiviTabBar({required this.tabs});
  final List<({String label, IconData icon})> tabs;

  @override
  Widget build(BuildContext context) {
    return TabBar(
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageH - 4),
      labelColor: AppColors.primaryAccent,
      unselectedLabelColor: AppColors.hintColor,
      labelStyle: AppTextStyles.labelLg.copyWith(fontWeight: FontWeight.w800),
      unselectedLabelStyle:
          AppTextStyles.labelLg.copyWith(fontWeight: FontWeight.w600),
      indicatorColor: AppColors.primaryAccent,
      indicatorWeight: 3,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: AppColors.outlineVariant.withValues(alpha: 0.4),
      splashFactory: NoSplash.splashFactory,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      onTap: (_) => AppHaptics.tap(),
      tabs: [
        for (final t in tabs)
          Tab(
            height: 44,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(t.icon, size: 17),
                const SizedBox(width: 6),
                Text(t.label),
              ],
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Onglet 1 — Visiteurs
// ─────────────────────────────────────────────────────────────────────────────
class _VisitorsTab extends StatelessWidget {
  const _VisitorsTab({required this.suivi});
  final SuiviController suivi;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (suivi.visitorsLoading.value && suivi.profileViews.value == null) {
        return const _SuiviSkeleton(kind: _SkKind.tile);
      }
      if (suivi.visitorsError.value != null &&
          suivi.profileViews.value == null) {
        return ErrorStateView(
          message: suivi.visitorsError.value!,
          illustration: const ErrorIllustration(),
          onRetry: suivi.loadVisitors,
        );
      }
      final result = suivi.profileViews.value;
      final viewers = result?.viewers ?? const <ProfileViewer>[];
      if (viewers.isEmpty) {
        return _EmptyTab(
          illustration: const EmptyPeopleIllustration(),
          title: 'Aucune vue de profil',
          subtitle: 'Quand des entreprises consulteront votre profil, elles '
              'apparaîtront ici.',
          onRefresh: suivi.loadVisitors,
        );
      }
      return _RefreshList(
        onRefresh: suivi.loadVisitors,
        children: [
          _SectionTitle(
            '${result!.total} personne${result.total > 1 ? 's' : ''} '
            'ont vu votre profil',
          ),
          const SizedBox(height: AppSpacing.md),
          for (final v in viewers) _VisitorTile(viewer: v),
        ],
      );
    });
  }
}

class _VisitorTile extends StatelessWidget {
  const _VisitorTile({required this.viewer});
  final ProfileViewer viewer;

  @override
  Widget build(BuildContext context) {
    final name = viewer.fullName.isEmpty ? 'Membre' : viewer.fullName;
    return _CardShell(
      onTap: () {
        AppHaptics.tap();
        Get.toNamed(AppRoutes.communityProfile.replaceFirst(':id', viewer.id));
      },
      child: Row(
        children: [
          BrandAvatar(
            seed: viewer.id,
            label: name,
            size: 46,
            imageUrl: viewer.avatarUrl,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleMd
                        .copyWith(fontWeight: FontWeight.w700)),
                if ((viewer.headline ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(viewer.headline!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.hintColor)),
                ],
              ],
            ),
          ),
          if (viewer.viewedAt != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(relativeTimeFr(viewer.viewedAt),
                style:
                    AppTextStyles.labelSm.copyWith(color: AppColors.hintColor)),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Onglet 2 — Candidatures (Entreprises intéressées + Emplois postulés)
// ─────────────────────────────────────────────────────────────────────────────
class _ApplicationsTab extends StatelessWidget {
  const _ApplicationsTab({required this.suivi});
  final SuiviController suivi;

  @override
  Widget build(BuildContext context) {
    final apps = suivi.applications;
    return Obx(() {
      if (apps.isLoading.value && apps.applications.isEmpty) {
        return const _SuiviSkeleton(kind: _SkKind.offer);
      }
      if (apps.errorMessage.value != null && apps.applications.isEmpty) {
        return ErrorStateView(
          message: apps.errorMessage.value!,
          illustration: const ErrorIllustration(),
          onRetry: apps.load,
        );
      }
      final interested = suivi.interestedApplications;
      final all = apps.applications.toList();
      if (all.isEmpty) {
        return _EmptyTab(
          illustration: const EmptyApplicationsIllustration(),
          title: 'Aucune candidature',
          subtitle: 'Vous n\'avez postulé à aucun emploi pour le moment. '
              'Explorez les offres et tentez votre chance !',
          actionLabel: 'Voir les offres',
          onAction: () => Get.toNamed(AppRoutes.offers),
          onRefresh: apps.load,
        );
      }
      return _RefreshList(
        onRefresh: apps.load,
        children: [
          _SectionTitle('Entreprises intéressées'),
          const SizedBox(height: AppSpacing.md),
          if (interested.isEmpty)
            _InlineEmpty(
              icon: IconlyLight.work,
              message: 'Aucune entreprise intéressée pour l\'instant.',
            )
          else
            for (final a in interested) _ApplicationMiniCard(app: a),
          const SizedBox(height: AppSpacing.xl),
          _SectionTitle('Emplois auxquels j\'ai postulé'),
          const SizedBox(height: AppSpacing.md),
          for (final a in all) _ApplicationMiniCard(app: a),
        ],
      );
    });
  }
}

class _ApplicationMiniCard extends StatelessWidget {
  const _ApplicationMiniCard({required this.app});
  final ApplicationModel app;

  @override
  Widget build(BuildContext context) {
    final style = _statusStyle(app.status);
    final title = app.offer?.title ?? 'Offre #${app.offerId}';
    final company = app.offer?.company ?? '';
    final matchPct =
        (app.aiMatchScore <= 1 ? app.aiMatchScore * 100 : app.aiMatchScore)
            .round();

    return _CardShell(
      onTap: () {
        AppHaptics.tap();
        Get.toNamed(AppRoutes.offerDetail.replaceFirst(':id', app.offerId));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BrandAvatar(
                seed: company.isEmpty ? title : company,
                label: company.isEmpty ? title : company,
                imageUrl: app.offer?.companyLogo,
                size: 44,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleMd
                            .copyWith(fontWeight: FontWeight.w800)),
                    if (company.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(company,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySm
                              .copyWith(color: AppColors.primaryAccent)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusPill(
                  label: style.label,
                  color: style.color,
                  icon: style.icon,
                  dense: true),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(IconlyLight.calendar, size: 14, color: AppColors.hintColor),
              const SizedBox(width: 4),
              Text(_formatDate(app.appliedAt),
                  style: AppTextStyles.bodySm
                      .copyWith(color: AppColors.hintColor)),
              const Spacer(),
              if (matchPct > 0) MatchScorePill(score: matchPct, dense: true),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Onglet 3 — Matchs (recommandations IA)
// ─────────────────────────────────────────────────────────────────────────────
class _MatchesTab extends StatelessWidget {
  const _MatchesTab({required this.suivi});
  final SuiviController suivi;

  @override
  Widget build(BuildContext context) {
    final offers = suivi.offers;
    return Obx(() {
      if (offers.isLoadingMatches.value && offers.matchedOffers.isEmpty) {
        return const _SuiviSkeleton(kind: _SkKind.offer);
      }
      if (offers.matchesError.value != null && offers.matchedOffers.isEmpty) {
        return ErrorStateView(
          message: offers.matchesError.value!,
          illustration: const ErrorIllustration(),
          onRetry: offers.loadMatchedOffers,
        );
      }
      final matches = offers.matchedOffers.toList();
      if (matches.isEmpty) {
        return _EmptyTab(
          illustration: const EmptyOffersIllustration(),
          title: 'Aucun match en attente',
          subtitle: 'Complétez votre CV pour recevoir des recommandations '
              'd\'offres adaptées à votre profil.',
          onRefresh: offers.loadMatchedOffers,
        );
      }
      return _RefreshList(
        onRefresh: offers.loadMatchedOffers,
        children: [for (final m in matches) _MatchMiniCard(offer: m)],
      );
    });
  }
}

class _MatchMiniCard extends StatelessWidget {
  const _MatchMiniCard({required this.offer});
  final MatchedOffer offer;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      onTap: () {
        AppHaptics.tap();
        Get.toNamed(AppRoutes.offerDetail.replaceFirst(':id', offer.id));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MatchScorePill(score: offer.score, dense: true),
              const Spacer(),
              Icon(IconlyLight.arrow_right_2,
                  size: 18, color: AppColors.hintColor),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(offer.title.isEmpty ? 'Offre' : offer.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleMd.copyWith(
                  fontWeight: FontWeight.w800, color: AppColors.titleColor)),
          if (offer.company.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(offer.company,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySm
                    .copyWith(color: AppColors.primaryAccent)),
          ],
          if (offer.explanation.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome_rounded,
                    size: 14, color: AppColors.primaryAccent),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(offer.explanation,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.bodyColor, height: 1.25)),
                ),
              ],
            ),
          ] else if (offer.location.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(IconlyLight.location,
                    size: 14, color: AppColors.hintColor),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(offer.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.hintColor)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Onglet 4 — Entretiens
// ─────────────────────────────────────────────────────────────────────────────
/// Deux sources coexistent côté backend et l'onglet n'en lisait qu'une :
/// - `interviews` : les vraies convocations (table `interviews`), y compris
///   celles en attente de réponse — c'est là que vit la fonctionnalité ;
/// - `upcomingInterviews` : une vue dérivée des candidatures
///   (`status = interview` + date posée), utile pour l'itinéraire et le .ics.
///
/// L'onglet n'affichait que la seconde, donc il restait vide tant qu'un
/// recruteur n'avait pas basculé la candidature à la main. On affiche les deux.
class _InterviewsTab extends StatelessWidget {
  const _InterviewsTab({required this.suivi});
  final SuiviController suivi;

  @override
  Widget build(BuildContext context) {
    final apps = suivi.applications;
    return Obx(() {
      final invitations = apps.interviews.toList();
      final upcoming = apps.upcomingInterviews.toList();

      if (apps.isLoading.value && invitations.isEmpty && upcoming.isEmpty) {
        return const _SuiviSkeleton(kind: _SkKind.interview);
      }
      if (invitations.isEmpty && upcoming.isEmpty) {
        return _EmptyTab(
          illustration: const EmptyApplicationsIllustration(),
          title: 'Pas d\'entretiens en attente',
          subtitle: 'Vos prochains entretiens avec les recruteurs '
              's\'afficheront ici.',
          onRefresh: apps.load,
        );
      }

      // Une convocation déjà datée apparaît dans les deux listes : on ne garde
      // sa carte « à venir » (itinéraire, calendrier) que si elle n'est pas
      // déjà présente comme invitation.
      final invitedApplicationIds =
          invitations.map((i) => i.applicationId).whereType<String>().toSet();
      final extraUpcoming = upcoming
          .where((u) => !invitedApplicationIds.contains(u.applicationId))
          .toList();

      return _RefreshList(
        onRefresh: apps.load,
        children: [
          for (final i in invitations) _InterviewInvitationCard(item: i),
          for (final i in extraUpcoming) _InterviewMiniCard(item: i),
        ],
      );
    });
  }
}

/// Convocation issue de la table `interviews` : statut, date, modalité, et
/// renvoi vers « Mes candidatures » quand une réponse est attendue (c'est là que
/// vivent les actions accepter / proposer une autre date).
class _InterviewInvitationCard extends StatelessWidget {
  const _InterviewInvitationCard({required this.item});
  final InterviewDetailModel item;

  @override
  Widget build(BuildContext context) {
    final when = item.scheduledAt != null ? _formatDate(item.scheduledAt!) : null;

    return PressScale(
      onTap: () {
        AppHaptics.tap();
        Get.toNamed<void>(AppRoutes.myApplications);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
                Expanded(
                  child: Text(
                    item.offer?.title ?? 'Entretien',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleMd.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.titleColor,
                    ),
                  ),
                ),
                StatusPill(
                  label: item.statusLabel,
                  color: AppColors.warningAccent,
                ),
              ],
            ),
            if ((item.offer?.companyName ?? '').isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                item.offer!.companyName!,
                style: AppTextStyles.bodySm
                    .copyWith(color: AppColors.primaryAccent),
              ),
            ],
            if (when != null || item.typeLabel != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(IconlyLight.calendar,
                      size: 14, color: AppColors.hintColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      [when, item.typeLabel].whereType<String>().join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.bodyColor),
                    ),
                  ),
                ],
              ),
            ],
            if (item.canRespond) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Réponse attendue — appuyez pour répondre',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.warningAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InterviewMiniCard extends StatelessWidget {
  const _InterviewMiniCard({required this.item});
  final UpcomingInterview item;

  @override
  Widget build(BuildContext context) {
    final iv = item.interview;
    final when =
        iv?.dateHuman ?? (iv?.date != null ? _formatDate(iv!.date!) : null);
    final canRoute =
        (iv?.hasCoordinates ?? false) && iv?.lat != null && iv?.lng != null;
    final canCalendar = (iv?.icsUrl ?? '').isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: ShapeDecoration(
        color: AppColors.warningSoft,
        shape: AppShapes.squircle(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.offerTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.w800)),
          if ((item.companyName ?? '').isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(item.companyName!,
                style:
                    AppTextStyles.bodySm.copyWith(color: AppColors.bodyColor)),
          ],
          if (when != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(IconlyLight.calendar,
                    size: 15, color: AppColors.warningAccent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(when,
                      style: AppTextStyles.labelMd.copyWith(
                          color: AppColors.warningAccent,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
          if ((iv?.address ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(IconlyLight.location,
                    size: 15, color: AppColors.hintColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(iv!.address!,
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.bodyColor)),
                ),
              ],
            ),
          ],
          if (canRoute || canCalendar) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (canRoute)
                  Expanded(
                    child: _InterviewAction(
                      icon: Icons.directions_rounded,
                      label: 'Itinéraire',
                      onTap: () {
                        AppHaptics.tap();
                        MapNavigationLauncher.openCoordinates(
                            iv!.lat!, iv.lng!);
                      },
                    ),
                  ),
                if (canRoute && canCalendar) const SizedBox(width: 10),
                if (canCalendar)
                  Expanded(
                    child: _InterviewAction(
                      icon: IconlyLight.calendar,
                      label: 'Calendrier',
                      onTap: () {
                        AppHaptics.tap();
                        MapNavigationLauncher.openIcs(iv!.icsUrl!);
                      },
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InterviewAction extends StatelessWidget {
  const _InterviewAction(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppShapes.squircleRadius(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: ShapeDecoration(
          color: AppColors.surfaceCard,
          shape: AppShapes.squircle(AppRadius.sm),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.primaryAccent),
            const SizedBox(width: 6),
            Text(label,
                style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.primaryAccent,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Onglet 5 — Favoris
// ─────────────────────────────────────────────────────────────────────────────
class _FavoritesTab extends StatelessWidget {
  const _FavoritesTab({required this.suivi});
  final SuiviController suivi;

  @override
  Widget build(BuildContext context) {
    final offers = suivi.offers;
    return Obx(() {
      if (offers.isLoadingSaved.value && offers.savedOffers.isEmpty) {
        return const _SuiviSkeleton(kind: _SkKind.offer);
      }
      final saved = offers.savedOffers.toList();
      if (saved.isEmpty) {
        return _EmptyTab(
          illustration: const EmptyOffersIllustration(),
          title: 'Aucun favori',
          subtitle: 'Touchez le marque-page sur une offre pour la retrouver '
              'ici à tout moment.',
          actionLabel: 'Voir les offres',
          onAction: () => Get.toNamed(AppRoutes.offers),
          onRefresh: offers.loadSavedOffers,
        );
      }
      return _RefreshList(
        onRefresh: offers.loadSavedOffers,
        children: [for (final o in saved) _FavoriteOfferCard(offer: o)],
      );
    });
  }
}

class _FavoriteOfferCard extends StatelessWidget {
  const _FavoriteOfferCard({required this.offer});
  final Offer offer;

  @override
  Widget build(BuildContext context) {
    final description = offer.description.trim();
    return _CardShell(
      onTap: () {
        AppHaptics.tap();
        Get.toNamed(AppRoutes.offerDetail.replaceFirst(':id', offer.id));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Morphing logo offre → détail (actif uniquement sur l'onglet Suivi).
              OfferLogoHero(
                offerId: offer.id,
                activeWhenTab: 3,
                child: BrandAvatar(
                  seed: offer.company.isEmpty ? offer.title : offer.company,
                  label: offer.company.isEmpty ? offer.title : offer.company,
                  imageUrl: offer.companyLogo,
                  size: 44,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(offer.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleMd
                            .copyWith(fontWeight: FontWeight.w800)),
                    if (offer.company.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(offer.company,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySm
                              .copyWith(color: AppColors.primaryAccent)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(IconlyBold.bookmark,
                  size: 20, color: AppColors.primaryAccent),
            ],
          ),
          // Petite description pour densifier la carte (évite le vide).
          if (description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySm
                  .copyWith(color: AppColors.bodyColor, height: 1.35),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              if (offer.location.isNotEmpty) ...[
                Icon(IconlyLight.location,
                    size: 14, color: AppColors.hintColor),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(offer.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.hintColor)),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              if (offer.contractType.isNotEmpty)
                _MetaChip(label: offer.contractType),
              if (offer.salary.trim().isNotEmpty) ...[
                const SizedBox(width: 8),
                Flexible(child: _MetaChip(label: offer.salary.trim())),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Petite pastille méta (type de contrat, salaire) pour les cartes d'offres.
class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: AppShapes.pill,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.labelSm
            .copyWith(color: AppColors.bodyColor, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Briques partagées de l'écran
// ─────────────────────────────────────────────────────────────────────────────

/// Liste rafraîchissable avec animations staggered (entrée des cartes).
class _RefreshList extends StatelessWidget {
  const _RefreshList({required this.onRefresh, required this.children});
  final Future<void> Function() onRefresh;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppRefreshIndicator(
      color: AppColors.primaryAccent,
      onRefresh: onRefresh,
      child: AnimationLimiter(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageH, AppSpacing.md, AppSpacing.pageH, 120),
          children: AnimationConfiguration.toStaggeredList(
            duration: AppMotion.medium,
            childAnimationBuilder: (w) => SlideAnimation(
              verticalOffset: AppMotion.listSlideOffset,
              curve: AppMotion.emphasizedDecelerate,
              child: FadeInAnimation(child: w),
            ),
            children: children,
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.w800));
  }
}

/// Carte blanche standard du hub (squircle + ombres en couches + accent option).
class _CardShell extends StatelessWidget {
  const _CardShell({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TouchBloom(
        onTap: onTap,
        borderRadius: AppShapes.squircleRadius(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          // Profondeur par ombres en couches uniquement (pas de liseré/contour :
          // le double bordure + ombre faisait « bricolé »).
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: AppShapes.squircleRadius(AppRadius.lg),
            boxShadow: [...AppColors.lightShadow, ...AppColors.ambientShadow],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// État vide d'un onglet : illustration + texte + « Actualiser » (et action
/// optionnelle secondaire), enveloppé dans un scroll rafraîchissable.
class _EmptyTab extends StatelessWidget {
  const _EmptyTab({
    required this.illustration,
    required this.title,
    required this.subtitle,
    required this.onRefresh,
    this.actionLabel,
    this.onAction,
  });

  final Widget illustration;
  final String title;
  final String subtitle;
  final Future<void> Function() onRefresh;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AppRefreshIndicator(
      color: AppColors.primaryAccent,
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                EmptyState(
                  illustration: illustration,
                  title: title,
                  subtitle: subtitle,
                  actionLabel: actionLabel,
                  onAction: onAction,
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton.icon(
                  onPressed: () {
                    AppHaptics.tap();
                    onRefresh();
                  },
                  icon: Icon(Icons.refresh_rounded,
                      size: 18, color: AppColors.primaryAccent),
                  label: Text('Actualiser',
                      style: AppTextStyles.labelMd.copyWith(
                          color: AppColors.primaryAccent,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Petit état vide en ligne (au sein d'une section, ex. « Entreprises
/// intéressées » sans résultat).
class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: AppShapes.squircleRadius(AppRadius.md),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.hintColor),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(message,
                style:
                    AppTextStyles.bodySm.copyWith(color: AppColors.bodyColor)),
          ),
        ],
      ),
    );
  }
}

/// Forme de squelette selon le type de contenu de l'onglet.
enum _SkKind { tile, offer, interview }

/// Squelettes de chargement « premium » : placeholders shimmer qui **miment la
/// vraie structure** de chaque carte (avatar + lignes + pastilles), au lieu de
/// boîtes génériques. Le cadre de carte reste plein ; seules les barres internes
/// scintillent (via [SkeletonCluster]). Entrée en cascade douce.
class _SuiviSkeleton extends StatelessWidget {
  const _SuiviSkeleton({required this.kind});
  final _SkKind kind;

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageH, AppSpacing.md, AppSpacing.pageH, 40),
        children: AnimationConfiguration.toStaggeredList(
          duration: AppMotion.medium,
          childAnimationBuilder: (w) => SlideAnimation(
            verticalOffset: AppMotion.listSlideOffset,
            curve: AppMotion.emphasizedDecelerate,
            child: FadeInAnimation(child: w),
          ),
          children: [
            for (var i = 0; i < 6; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _SkeletonCardFrame(
                  tinted: kind == _SkKind.interview,
                  child: switch (kind) {
                    _SkKind.tile => const _SkTile(),
                    _SkKind.offer => const _SkOffer(),
                    _SkKind.interview => const _SkInterview(),
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Petite barre grise (élément de squelette).
Widget _skBar(double w, double h, [double r = 7]) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(r),
      ),
    );

Widget _skCircle(double d) => Container(
      width: d,
      height: d,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        shape: BoxShape.circle,
      ),
    );

/// Cadre de carte (plein) qui enveloppe un cluster shimmer.
class _SkeletonCardFrame extends StatelessWidget {
  const _SkeletonCardFrame({required this.child, this.tinted = false});
  final Widget child;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: tinted ? AppColors.warningSoft : AppColors.surfaceCard,
        borderRadius: AppShapes.squircleRadius(AppRadius.lg),
        border: tinted ? null : Border.all(color: AppColors.outlineVariant),
      ),
      child: SkeletonCluster(child: child),
    );
  }
}

class _SkTile extends StatelessWidget {
  const _SkTile();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _skCircle(46),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _skBar(140, 12),
            const SizedBox(height: 8),
            _skBar(90, 10),
          ],
        ),
        const Spacer(),
        _skBar(36, 10),
      ],
    );
  }
}

class _SkOffer extends StatelessWidget {
  const _SkOffer();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _skCircle(44),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _skBar(150, 13),
                const SizedBox(height: 8),
                _skBar(96, 11),
              ],
            ),
            const Spacer(),
            _skBar(58, 22, 999),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _skBar(double.infinity, 10),
        const SizedBox(height: 7),
        _skBar(220, 10),
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          _skBar(72, 18, 999),
          const SizedBox(width: 8),
          _skBar(96, 18, 999)
        ]),
      ],
    );
  }
}

class _SkInterview extends StatelessWidget {
  const _SkInterview();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _skBar(190, 13),
        const SizedBox(height: 8),
        _skBar(120, 11),
        const SizedBox(height: AppSpacing.md),
        _skBar(150, 12),
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          Expanded(child: _skBar(double.infinity, 38, 12)),
          const SizedBox(width: 10),
          Expanded(child: _skBar(double.infinity, 38, 12)),
        ]),
      ],
    );
  }
}

// ── Mapping statut candidature (local au hub) ──────────────────────────────
class _StatusStyle {
  const _StatusStyle(this.label, this.color, this.icon);
  final String label;
  final Color color;
  final IconData icon;
}

_StatusStyle _statusStyle(ApplicationStatus status) {
  switch (status) {
    case ApplicationStatus.newApp:
      return _StatusStyle('Envoyée', AppColors.primaryAccent, IconlyLight.send);
    case ApplicationStatus.shortlisted:
      return _StatusStyle(
          'Présélectionné', AppColors.successAccent, IconlyBold.star);
    case ApplicationStatus.interview:
      return _StatusStyle(
          'Entretien', AppColors.warningAccent, IconlyLight.calendar);
    case ApplicationStatus.rejected:
      return _StatusStyle('Non retenue', AppColors.errorAccent,
          Icons.do_not_disturb_on_rounded);
  }
}

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
