import 'package:flutter/material.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:get/get.dart';

import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_dimens.dart';
import 'package:baara/app/core/theme/app_motion.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/app/core/widgets/widgets.dart';
import 'package:baara/app/features/offers/presentation/controllers/offer_controller.dart';
import 'package:baara/app/features/offers/presentation/pages/offer_list_screen.dart';
import 'package:baara/app/features/offers/presentation/widgets/offer_swipe_deck.dart';
import 'package:baara/app/features/trainings/presentation/controllers/trainings_controller.dart';
import 'package:baara/app/features/trainings/presentation/pages/trainings_screen.dart';
import '../controllers/home_controller.dart';

/// Hub « Opportunités » : un seul en-tête + un segmented control qui bascule
/// entre Offres et Formations (Concours à venir). Réunit deux contenus de même
/// intention — « saisir une opportunité » — sous une navigation unique, au lieu
/// de deux onglets distincts. Les corps réutilisent les écrans existants en
/// mode `embedded` (sans leur propre en-tête).
class OpportunitesScreen extends StatefulWidget {
  const OpportunitesScreen({super.key});

  @override
  State<OpportunitesScreen> createState() => _OpportunitesScreenState();
}

class _OpportunitesScreenState extends State<OpportunitesScreen> {
  /// Mode d'affichage des offres : false = liste, true = découverte (swipe).
  /// Le swipe est conservé ici comme un MODE de l'onglet Offres (et non sur
  /// l'accueil, pour ne plus dupliquer le contenu).
  bool _offersSwipe = false;

  static const _segments = ['Offres', 'Formations'];

  @override
  Widget build(BuildContext context) {
    final home = Get.find<HomeController>();
    return ColoredBox(
      color: AppColors.background,
      child: SankTabShell(
        title: 'Opportunités',
        subtitle: 'Offres et formations pour ton profil.',
        headerActions: [
          Obx(() {
            final segment = home.opportunitesTab.value;
            return AppIconButton(
              icon: AppIcons.filter,
              tooltip: 'Filtrer',
              onTap: () {
                AppHaptics.tap();
                if (segment == 0) {
                  openOffersFilter(context, Get.find<OfferController>());
                } else {
                  openTrainingsFilter(context, Get.find<TrainingsController>());
                }
              },
            );
          }),
          Obx(() {
            if (home.opportunitesTab.value != 0) {
              return const SizedBox.shrink();
            }
            return AppIconButton(
              icon: _offersSwipe
                  ? Icons.view_agenda_rounded
                  : Icons.swipe_rounded,
              tooltip: _offersSwipe ? 'Vue liste' : 'Mode découverte (swipe)',
              onTap: () {
                AppHaptics.tap();
                setState(() => _offersSwipe = !_offersSwipe);
              },
            );
          }),
        ],
        headerChild: Obx(() => SegmentedControl(
              segments: _segments,
              selected: home.opportunitesTab.value,
              onChanged: (i) {
                AppHaptics.tap();
                home.opportunitesTab.value = i;
              },
            )),
        body: Obx(() {
          final segment = home.opportunitesTab.value;
          return IndexedStack(
            index: segment,
            children: [
              _offersSwipe
                  ? const _OffersSwipeView()
                  : const OfferListScreen(embedded: true),
              const TrainingsScreen(embedded: true),
            ],
          );
        }),
      ),
    );
  }
}

/// Mode « Découverte » : le deck d'offres swipeable (réutilise [OfferSwipeDeck]).
class _OffersSwipeView extends StatelessWidget {
  const _OffersSwipeView();

  @override
  Widget build(BuildContext context) {
    final offerController = Get.find<OfferController>();
    return AppRefreshIndicator(
      color: AppColors.primaryAccent,
      onRefresh: () => offerController.loadOffers(refresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageH, AppSpacing.md, AppSpacing.pageH, AppSpacing.xxl),
        children: [
          Center(
            child: OfferSwipeDeck(controller: offerController, height: 480),
          ),
        ],
      ),
    );
  }
}

/// Segmented control « pilule » animé (sélecteur glissant). Réutilisable.
class SegmentedControl extends StatelessWidget {
  const SegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.icons,
  });

  final List<String> segments;
  final int selected;
  final ValueChanged<int> onChanged;
  final List<IconData>? icons;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = segments.length;
        final innerWidth = constraints.maxWidth - 8; // padding 4 de chaque côté
        final segWidth = innerWidth / count;
        return Container(
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surfaceLow,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Stack(
            children: [
              // Pilule sélectionnée qui glisse.
              AnimatedAlign(
                duration: AppMotion.base,
                curve: AppMotion.standard,
                alignment: Alignment(
                  count == 1 ? 0 : (selected / (count - 1)) * 2 - 1,
                  0,
                ),
                child: Container(
                  width: segWidth,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    boxShadow: AppColors.lightShadow,
                  ),
                ),
              ),
              Row(
                children: List.generate(count, (i) {
                  final active = i == selected;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(i),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (icons != null) ...[
                              Icon(
                                icons![i],
                                size: 16,
                                color: active
                                    ? AppColors.primaryAccent
                                    : AppColors.hintColor,
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              segments[i],
                              style: AppTextStyles.labelLg.copyWith(
                                color: active
                                    ? AppColors.titleColor
                                    : AppColors.hintColor,
                                fontWeight:
                                    active ? FontWeight.w800 : FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}
