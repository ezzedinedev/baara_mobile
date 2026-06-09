import 'package:get/get.dart';
import 'package:opportune_bf/app/core/utils/user_facing_error.dart';
import 'package:opportune_bf/app/core/widgets/common/app_toast.dart';
import '../../../../data/models/ai_models.dart';
import '../../domain/entities/offer.dart';
import '../../domain/repositories/i_offer_repository.dart';

class OfferDetailController extends GetxController {
  final IOfferRepository _repository;

  OfferDetailController(this._repository);

  final offer = Rxn<Offer>();
  final aiMatchScore = Rxn<AiMatchScore>();
  final isLoading = true.obs;
  final isAiLoading = false.obs;
  final errorMessage = RxnString();
  final isApplying = false.obs;
  final hasApplied = false.obs;

  @override
  void onInit() {
    super.onInit();
    final id = Get.parameters['id'];
    if (id != null) {
      fetchOfferDetail(id);
    } else {
      errorMessage.value = "ID de l'offre manquant";
      isLoading.value = false;
    }
  }

  Future<void> fetchOfferDetail(String id) async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      final result = await _repository.getOfferById(id);
      if (result != null) {
        offer.value = result;
      } else {
        errorMessage.value = "Offre introuvable";
      }
    } catch (e) {
      errorMessage.value = "Erreur de chargement";
    } finally {
      isLoading.value = false;
    }
  }

  // NOTE: pas de score IA par offre ici. Le backend n'expose AUCUN endpoint de
  // score par offre — `POST /offers/{id}/match` est un alias de `apply`/`swipe`
  // qui CRÉE une candidature. L'appeler au chargement soumettait donc une
  // candidature fantôme à chaque consultation. Le score reste disponible en
  // masse via `/ai/match/feed` (feed "Pour vous"). Les observables
  // `aiMatchScore`/`isAiLoading` sont conservés : le banner se masque seul tant
  // qu'aucun score n'est fourni (cf. _buildAiMatchBanner).

  /// Candidature réelle à l'offre (POST /applications via le repo).
  Future<void> apply() async {
    final o = offer.value;
    if (o == null || isApplying.value || hasApplied.value) return;
    isApplying.value = true;
    try {
      await _repository.applyToOffer(o.id);
      hasApplied.value = true;
      AppToast.success('Candidature envoyée', '${o.company} · ${o.title}');
    } catch (e) {
      AppToast.error('Candidature non envoyée', userFacingError(e));
    } finally {
      isApplying.value = false;
    }
  }

  Future<void> toggleSave() async {
    final currentOffer = offer.value;
    if (currentOffer == null) return;
    
    // Logique simplifiée pour le toggle
    final success = await _repository.saveOffer(currentOffer.id);
    if (success) {
      Get.snackbar("Succès", "Offre mise à jour");
    }
  }
}
