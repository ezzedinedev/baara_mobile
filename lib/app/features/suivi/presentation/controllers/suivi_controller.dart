import 'package:get/get.dart';

import '../../../community/presentation/controllers/community_controller.dart';
import '../../../community/domain/entities/profile_viewer.dart';
import '../../../offers/data/models/application_model.dart';
import '../../../offers/presentation/controllers/applications_controller.dart';
import '../../../offers/presentation/controllers/offer_controller.dart';

/// Façade mince du hub « Suivi » (l'équivalent du « Boards » d'Edomatch).
///
/// Ne duplique **aucun** état : elle agrège les controllers déjà injectés
/// ([OfferController], [ApplicationsController], [CommunityController]) et n'ajoute
/// que ce qui n'existe pas ailleurs — la liste des visiteurs de profil, qui était
/// jusqu'ici chargée localement par l'écran `ProfileViewsScreen`.
class SuiviController extends GetxController {
  SuiviController({
    required OfferController offers,
    required ApplicationsController applications,
    required CommunityController community,
  })  : _offers = offers,
        _applications = applications,
        _community = community;

  final OfferController _offers;
  final ApplicationsController _applications;
  final CommunityController _community;

  OfferController get offers => _offers;
  ApplicationsController get applications => _applications;

  // ── Visiteurs (la seule donnée propre au hub) ─────────────────────────────
  final profileViews = Rxn<ProfileViewsResult>();
  final visitorsLoading = true.obs;
  final visitorsError = RxnString();

  @override
  void onInit() {
    super.onInit();
    refreshAll();
  }

  /// Rafraîchit toutes les sources du hub en parallèle. Appelé à l'ouverture de
  /// l'onglet (via `HomeController.changeTab`) et en pull-to-refresh.
  Future<void> refreshAll() async {
    await Future.wait([
      _applications.load(),
      _offers.loadMatchedOffers(),
      _offers.loadSavedOffers(),
      loadVisitors(),
    ]);
  }

  Future<void> loadVisitors() async {
    visitorsLoading.value = true;
    visitorsError.value = null;
    try {
      profileViews.value = await _community.fetchProfileViews();
    } catch (_) {
      visitorsError.value = 'Impossible de charger les visiteurs de profil.';
    } finally {
      visitorsLoading.value = false;
    }
  }

  /// Candidatures où l'employeur a montré de l'intérêt (présélection / entretien)
  /// → section « Entreprises intéressées ».
  List<ApplicationModel> get interestedApplications =>
      _applications.applications
          .where((a) =>
              a.status == ApplicationStatus.shortlisted ||
              a.status == ApplicationStatus.interview)
          .toList();
}
