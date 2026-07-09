import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import 'package:opportune_bf/app/features/offers/presentation/controllers/offer_controller.dart';
import 'package:opportune_bf/app/features/trainings/presentation/controllers/trainings_controller.dart';
import 'home_accueil_top_bar.dart';
import 'home_formations_section.dart';
import 'home_match_section.dart';
import 'home_offers_section.dart';
import 'home_quick_access.dart';

/// Accueil = **digest qui oriente**, pas un miroir des onglets. On ne ré-affiche
/// plus les listes complètes d'offres/formations (elles vivent dans le hub
/// Opportunités) : top bar + accès rapides vers les actions profondes + teaser
/// de l'activité réseau. Pull-to-refresh rafraîchit les données des onglets.
class HomeDashboardTab extends StatefulWidget {
  const HomeDashboardTab({super.key});

  @override
  State<HomeDashboardTab> createState() => _HomeDashboardTabState();
}

class _HomeDashboardTabState extends State<HomeDashboardTab> {
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
            child: const HomeAccueilTopBar(),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
            child: HomeQuickAccessRow(),
          ),
          // Offres recommandées par l'IA (« Pour toi ») — visible si matchs.
          const HomeMatchSection(),
          // Dernières offres d'emploi (toujours visibles).
          const HomeOffersSection(),
          // Formations recommandées — la communauté vit désormais dans son
          // propre onglet, l'accueil reste un digest offres + formations.
          const HomeFormationsSection(),
        ],
      ),
    );
  }
}
