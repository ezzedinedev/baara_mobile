import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../home/presentation/controllers/home_controller.dart';

/// Hero du logo d'une offre — morphing fluide **carte → écran de détail**
/// (tag `offer-logo-<id>`, partagé avec `OfferDetailScreen`).
///
/// La même offre peut apparaître dans plusieurs onglets montés en même temps
/// (liste d'offres, favoris du hub Suivi, rail d'accueil). Deux `Hero` au même
/// tag dans le même sous-arbre = crash. Pour l'éviter, le Hero n'est **émis que
/// lorsque l'onglet hôte est l'onglet courant** ([activeWhenTab]) : il y a donc
/// toujours **au plus un** `offer-logo-<id>` au moment de la navigation.
///
/// Hors du shell à onglets (écran poussé en plein écran, ex. liste standalone),
/// passer `activeWhenTab: null` → Hero toujours actif (aucun conflit possible,
/// la route est alors la route source).
class OfferLogoHero extends StatelessWidget {
  const OfferLogoHero({
    super.key,
    required this.offerId,
    required this.child,
    this.activeWhenTab,
  });

  final String offerId;
  final Widget child;

  /// Index de l'onglet du home shell où ce Hero doit être actif (0 Accueil,
  /// 1 Offre, 3 Suivi…). `null` = toujours actif (hors shell).
  final int? activeWhenTab;

  @override
  Widget build(BuildContext context) {
    if (activeWhenTab == null || !Get.isRegistered<HomeController>()) {
      return Hero(tag: 'offer-logo-$offerId', child: child);
    }
    final home = Get.find<HomeController>();
    return Obx(
      () => home.currentTabIndex.value == activeWhenTab
          ? Hero(tag: 'offer-logo-$offerId', child: child)
          : child,
    );
  }
}
