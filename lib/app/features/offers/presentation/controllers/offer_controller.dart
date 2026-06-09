import 'dart:async';

import 'package:get/get.dart';

import 'package:opportune_bf/app/core/utils/user_facing_error.dart';
import 'package:opportune_bf/app/core/widgets/common/app_toast.dart';
import '../../domain/entities/offer.dart';
import '../../domain/entities/matched_offer.dart';
import '../../domain/repositories/i_offer_repository.dart';

class OfferController extends GetxController {
  final IOfferRepository _repository;
  OfferController(this._repository);

  // Observables pour la liste des offres
  final offers = <Offer>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final errorMessage = ''.obs;
  
  // Pagination
  final currentPage = 1.obs;
  final hasNextPage = true.obs;

  // Favoris
  final savedOffers = <Offer>[].obs;
  final isLoadingSaved = false.obs;

  // Candidatures (IDs des offres postulées)
  final appliedOfferIds = <String>{}.obs;
  final isApplyingToOfferId = RxnString();

  // ── Recherche + filtres (client-side, sur les offres déjà chargées) ────
  final searchQuery = ''.obs;
  final activeContract = RxnString();
  final remoteOnly = false.obs;

  bool get hasActiveFilter =>
      activeContract.value != null || remoteOnly.value;

  /// Offres visibles après recherche + filtres. La liste s'appuie dessus ;
  /// le deck swipe (Découverte) garde l'ensemble complet.
  List<Offer> get filteredOffers {
    final q = searchQuery.value.trim().toLowerCase();
    return offers.where((o) {
      if (activeContract.value != null &&
          o.contractType != activeContract.value) {
        return false;
      }
      if (remoteOnly.value && !o.isRemote) return false;
      if (q.isNotEmpty) {
        final match = o.title.toLowerCase().contains(q) ||
            o.company.toLowerCase().contains(q) ||
            o.location.toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  void clearFilters() {
    activeContract.value = null;
    remoteOnly.value = false;
  }

  // ── Recommandations IA (match feed) ────────────────────────────────────
  final matchedOffers = <MatchedOffer>[].obs;
  final isLoadingMatches = false.obs;

  Future<void> loadMatchedOffers() async {
    if (isLoadingMatches.value) return;
    try {
      isLoadingMatches.value = true;
      matchedOffers.assignAll(await _repository.getMatchedOffers(limit: 12));
    } catch (_) {
    } finally {
      isLoadingMatches.value = false;
    }
  }

  // ── Deck swipe (Accueil) ──────────────────────────────────────────────
  // Pile de cartes type Tinder : drag horizontal, badges PASSER/INTÉRESSÉ,
  // rewind, et candidature réelle au swipe droite. Le deck est cyclique
  // (modulo offers.length) comme l'implémentation d'origine.
  final currentOfferIndex = 0.obs;
  final offerDragDx = 0.0.obs;
  final isOfferAnimating = false.obs;

  /// Offre à `offset` cartes du sommet (cyclique). Null si aucune offre.
  Offer? offerAtOffset(int offset) {
    if (offers.isEmpty) return null;
    final i = (currentOfferIndex.value + offset) % offers.length;
    return offers[i];
  }

  int scoreForOffset(int offset) {
    final o = offerAtOffset(offset);
    return o == null ? 0 : scoreForOffer(o);
  }

  /// Score de compatibilité affiché sur la carte. Heuristique déterministe
  /// et stable par offre (placeholder du vrai score IA `/offers/{id}/match`,
  /// branchable plus tard sans changer l'UI).
  int scoreForOffer(Offer offer) {
    final seed = offer.id.isNotEmpty ? offer.id : offer.title;
    final h = seed.codeUnits.fold<int>(7, (a, c) => (a * 31 + c) & 0x7fffffff);
    return 62 + (h % 33); // 62..94
  }

  void updateOfferDrag(double deltaX) {
    if (isOfferAnimating.value || offers.isEmpty) return;
    offerDragDx.value += deltaX;
  }

  Future<void> endOfferDrag(double velocityX) async {
    if (isOfferAnimating.value || offers.isEmpty) return;
    final drag = offerDragDx.value;
    final shouldSwipe = drag.abs() > 110 || velocityX.abs() > 850;
    if (!shouldSwipe) {
      await _animateBackToCenter();
      return;
    }
    await _animateSwipe(drag >= 0);
  }

  Future<void> swipeOfferLeft() => _animateSwipe(false);
  Future<void> swipeOfferRight() => _animateSwipe(true);

  void rewindOffer() {
    if (isOfferAnimating.value || offers.isEmpty) return;
    currentOfferIndex.value =
        (currentOfferIndex.value - 1 + offers.length) % offers.length;
    offerDragDx.value = 0;
  }

  Future<void> _animateBackToCenter() async {
    isOfferAnimating.value = true;
    offerDragDx.value = 0;
    await Future<void>.delayed(const Duration(milliseconds: 180));
    isOfferAnimating.value = false;
  }

  Future<void> _animateSwipe(bool toRight) async {
    if (isOfferAnimating.value || offers.isEmpty) return;
    final swiped = offerAtOffset(0);

    isOfferAnimating.value = true;
    offerDragDx.value = toRight ? 420 : -420;
    await Future<void>.delayed(const Duration(milliseconds: 210));
    currentOfferIndex.value = (currentOfferIndex.value + 1) % offers.length;
    offerDragDx.value = 0;
    isOfferAnimating.value = false;

    // Swipe droite = candidature réelle (POST /applications via le repo).
    if (toRight && swiped != null) {
      unawaited(_applySwiped(swiped));
    }
  }

  Future<void> _applySwiped(Offer offer) async {
    if (offer.id.isEmpty) return;
    if (appliedOfferIds.contains(offer.id)) {
      AppToast.warning('Déjà postulé', 'Vous avez déjà candidaté à ${offer.title}.');
      return;
    }
    try {
      await _repository.applyToOffer(offer.id);
      appliedOfferIds.add(offer.id);
      AppToast.success('Candidature envoyée', '${offer.company} · ${offer.title}');
    } catch (e) {
      AppToast.error('Candidature non envoyée', userFacingError(e));
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadOffers();
    loadSavedOffers();
  }

  Future<void> loadOffers({bool refresh = false}) async {
    if (refresh) {
      currentPage.value = 1;
      offers.clear();
      hasNextPage.value = true;
    }

    if (!hasNextPage.value || (isLoading.value && !refresh)) return;

    isLoading.value = offers.isEmpty;
    isLoadingMore.value = offers.isNotEmpty;
    errorMessage.value = '';

    try {
      final result = await _repository.getOffers(page: currentPage.value);
      
      if (refresh) {
        offers.assignAll(result);
      } else {
        offers.addAll(result);
      }

      hasNextPage.value = result.isNotEmpty; // Simplification pour l'exemple
      if (result.isNotEmpty) currentPage.value++;
      
    } catch (e) {
      errorMessage.value = "Erreur de chargement";
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> loadSavedOffers() async {
    // Note: Cette partie nécessiterait une extension de l'interface si on veut être strict
    // Pour l'instant on se concentre sur la structure
  }

  bool isOfferSaved(String offerId) {
    return savedOffers.any((o) => o.id == offerId);
  }

  Future<void> toggleSaveOffer(Offer offer) async {
    final isSaved = isOfferSaved(offer.id);
    final success = isSaved 
        ? await _repository.unsaveOffer(offer.id)
        : await _repository.saveOffer(offer.id);

    if (success) {
      if (isSaved) {
        savedOffers.removeWhere((o) => o.id == offer.id);
      } else {
        savedOffers.add(offer);
      }
    }
  }

  Future<bool> applyToOffer(String offerId) async {
    if (appliedOfferIds.contains(offerId)) return true;
    isApplyingToOfferId.value = offerId;
    try {
      await _repository.applyToOffer(offerId);
      appliedOfferIds.add(offerId);
      return true;
    } catch (_) {
      return false;
    } finally {
      isApplyingToOfferId.value = null;
    }
  }

  bool hasAppliedToOffer(String offerId) => appliedOfferIds.contains(offerId);
}
