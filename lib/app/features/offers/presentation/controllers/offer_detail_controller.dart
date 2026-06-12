import 'package:get/get.dart';
import 'package:opportune_bf/app/core/utils/user_facing_error.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/common/app_toast.dart';
import 'package:opportune_bf/app/core/widgets/effects/celebration_overlay.dart';
import 'package:opportune_bf/routes/app_routes.dart';
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
  final isSaved = false.obs;
  final isSaving = false.obs;

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
      final result = await _repository.applyToOffer(o.id);
      hasApplied.value = true;
      if (result.isMatch && result.score >= 60) {
        Get.toNamed(AppRoutes.offerMatch, arguments: {
          'offerTitle': o.title,
          'company': o.company,
          'score': result.score,
        });
      } else {
        // Pas d'écran de match dédié ici : on célèbre quand même la candidature
        // envoyée par un burst de confetti + haptique succès, en plus du toast.
        AppHaptics.success();
        showCelebration();
        AppToast.success('Candidature envoyée', '${o.company} · ${o.title}');
      }
    } catch (e) {
      AppToast.error('Candidature non envoyée', userFacingError(e));
    } finally {
      isApplying.value = false;
    }
  }

  /// Toggle favori optimiste : on bascule l'état localement tout de suite, puis
  /// on confirme côté API (save/unsave). En cas d'échec, on rétablit l'état et
  /// on prévient l'utilisateur.
  Future<void> toggleSave() async {
    final currentOffer = offer.value;
    if (currentOffer == null || isSaving.value) return;

    final previous = isSaved.value;
    final next = !previous;
    isSaved.value = next; // optimiste
    isSaving.value = true;
    try {
      final success = next
          ? await _repository.saveOffer(currentOffer.id)
          : await _repository.unsaveOffer(currentOffer.id);
      if (!success) {
        isSaved.value = previous; // rollback
        AppToast.error('Action impossible', 'Réessaie dans un instant.');
        return;
      }
      if (next) {
        AppToast.success('Offre enregistrée', currentOffer.title);
      } else {
        AppToast.info('Retirée des favoris', currentOffer.title);
      }
    } catch (e) {
      isSaved.value = previous; // rollback
      AppToast.error('Action impossible', userFacingError(e));
    } finally {
      isSaving.value = false;
    }
  }
}
