import 'package:get/get.dart';
import 'package:opportune_bf/app/core/services/offline_apply_queue.dart';
import 'package:opportune_bf/app/core/utils/offline_error.dart';
import 'package:opportune_bf/app/core/utils/user_facing_error.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/common/app_toast.dart';
import 'package:opportune_bf/app/core/widgets/common/success_sheet.dart';
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
        // Initialise l'état bouton depuis ce que le backend renvoie pour l'user
        // connecté (is_saved / is_applied). null = non auth → on laisse false.
        if (result.isSaved != null) isSaved.value = result.isSaved!;
        if (result.isApplied != null) hasApplied.value = result.isApplied!;
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
        // Pas d'écran de match dédié ici : on célèbre la candidature envoyée
        // par un burst de confetti + haptique succès, puis une feuille de
        // confirmation (SuccessIllustration) si un contexte est disponible,
        // sinon un toast de repli.
        AppHaptics.success();
        showCelebration();
        _showApplySuccess(o);
      }
    } catch (e) {
      if (isOfflineError(e)) {
        await _queueOffline(o);
      } else {
        AppToast.error('Candidature non envoyée', userFacingError(e));
      }
    } finally {
      isApplying.value = false;
    }
  }

  /// Hors-ligne : on met la candidature en file d'attente (renvoyee au retour
  /// du reseau) et on bascule l'etat en « postule » de facon optimiste.
  Future<void> _queueOffline(Offer o) async {
    await Get.find<OfflineApplyQueue>().enqueue(PendingApply(
      offerId: o.id,
      offerTitle: o.title,
      company: o.company,
      logoUrl: o.companyLogo,
      queuedAt: DateTime.now(),
    ));
    hasApplied.value = true;
    AppHaptics.success();
    AppToast.info(
      'Candidature enregistrée',
      'Hors ligne — elle sera envoyée dès le retour du réseau.',
    );
  }

  /// Affiche la confirmation de candidature envoyée : feuille de succès
  /// (SuccessIllustration) si un contexte est disponible, sinon toast de repli.
  /// Méthode synchrone → pas d'usage de BuildContext à travers un gap async.
  void _showApplySuccess(Offer o) {
    final ctx = Get.context;
    if (ctx == null) {
      AppToast.success('Candidature envoyée', '${o.company} · ${o.title}');
      return;
    }
    showSuccessSheet(
      ctx,
      title: 'Candidature envoyée !',
      message: '${o.company} · ${o.title}\n'
          'Votre candidature a bien été transmise au recruteur.',
    );
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
