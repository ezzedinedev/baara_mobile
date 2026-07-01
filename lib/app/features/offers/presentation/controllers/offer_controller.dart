import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:opportune_bf/app/core/services/offline_apply_queue.dart';
import 'package:opportune_bf/app/core/utils/offline_error.dart';
import 'package:opportune_bf/app/core/utils/user_facing_error.dart';
import 'package:opportune_bf/app/core/widgets/common/app_toast.dart';
import 'package:opportune_bf/app/core/widgets/effects/celebration_overlay.dart';
import '../../domain/entities/offer.dart';
import '../../domain/entities/matched_offer.dart';
import '../../domain/entities/sector_option.dart';
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

  // ── Recherche + filtres (appliqués CÔTÉ SERVEUR — parité web) ──────────
  // Chaque changement déclenche un rechargement depuis l'API (cf. workers
  // dans onInit). La recherche est débouncée (450 ms) pour ne pas marteler
  // le backend à chaque frappe.
  final searchQuery = ''.obs;
  final activeContract = RxnString();
  final remoteOnly = false.obs;
  // Secteur sélectionné (id) — peuplé par [sectors] (GET /offers/sectors/list).
  final selectedSectorId = RxnString();
  // Tri : 'boosted' (défaut, offres mises en avant d'abord) ou 'recent'.
  final sortMode = 'boosted'.obs;
  // Persistant ici (plus dans build()) : la saisie de recherche survit aux
  // rebuilds (liste + bascule liste/découverte).
  final searchCtrl = TextEditingController();

  // Secteurs d'activité pour le filtre.
  final sectors = <SectorOption>[].obs;
  final isLoadingSectors = false.obs;

  // Mute les workers de rechargement le temps d'un reset groupé de filtres
  // (évite N rechargements concurrents quand on remet tout à zéro).
  bool _muteFilterReload = false;

  bool get hasActiveFilter =>
      activeContract.value != null ||
      remoteOnly.value ||
      selectedSectorId.value != null ||
      searchQuery.value.trim().isNotEmpty;

  @override
  void onClose() {
    searchCtrl.dispose();
    super.onClose();
  }

  void _onFilterChanged() {
    if (_muteFilterReload) return;
    loadOffers(refresh: true);
  }

  /// Offres visibles. Le serveur a déjà appliqué recherche/secteur/etc. ; on
  /// garde un filtre client léger sur contrat/télétravail (mêmes prédicats que
  /// le serveur → aucun masquage) pour un retour instantané sur les puces.
  List<Offer> get filteredOffers {
    return offers.where((o) {
      if (activeContract.value != null &&
          o.contractType != activeContract.value) {
        return false;
      }
      if (remoteOnly.value && !o.isRemote) return false;
      return true;
    }).toList();
  }

  /// Charge les secteurs pour le filtre (silencieux en cas d'échec).
  Future<void> loadSectors() async {
    try {
      isLoadingSectors.value = true;
      sectors.assignAll(await _repository.getSectors());
    } catch (_) {
      // Filtre secteur simplement indisponible — non bloquant.
    } finally {
      isLoadingSectors.value = false;
    }
  }

  void clearFilters() {
    _muteFilterReload = true;
    activeContract.value = null;
    remoteOnly.value = false;
    selectedSectorId.value = null;
    searchQuery.value = '';
    searchCtrl.clear();
    _muteFilterReload = false;
    loadOffers(refresh: true);
  }

  /// Instantané des filtres actifs (mêmes clés que l'API /offers), pour créer
  /// une alerte emploi à partir de la recherche courante.
  Map<String, dynamic> currentFilters() {
    return <String, dynamic>{
      if (searchQuery.value.trim().isNotEmpty) 'search': searchQuery.value.trim(),
      if (selectedSectorId.value != null) 'sector_id': selectedSectorId.value,
      if (activeContract.value != null) 'contract_type': activeContract.value,
      if (remoteOnly.value) 'is_remote': true,
      'sort': sortMode.value,
    };
  }

  /// Applique un jeu de filtres sauvegardé (alerte emploi) à la liste : un seul
  /// rechargement, même logique que [clearFilters].
  void applySavedFilters(Map<String, dynamic> filters) {
    _muteFilterReload = true;
    final search = filters['search']?.toString() ?? '';
    searchQuery.value = search;
    searchCtrl.text = search;
    selectedSectorId.value = filters['sector_id']?.toString();
    activeContract.value = filters['contract_type']?.toString();
    remoteOnly.value = filters['is_remote'] == true || filters['is_remote'] == 1;
    final sort = filters['sort']?.toString();
    if (sort != null && sort.isNotEmpty) sortMode.value = sort;
    _muteFilterReload = false;
    loadOffers(refresh: true);
  }

  // ── Recommandations IA (match feed) ────────────────────────────────────
  final matchedOffers = <MatchedOffer>[].obs;
  final isLoadingMatches = false.obs;
  // Distingue « pas de suggestions » d'un « échec de chargement » (avant : tout
  // était avalé, la section disparaissait sans explication).
  final matchesError = RxnString();

  Future<void> loadMatchedOffers() async {
    if (isLoadingMatches.value) return;
    try {
      isLoadingMatches.value = true;
      matchesError.value = null;
      matchedOffers.assignAll(await _repository.getMatchedOffers(limit: 12));
    } catch (e) {
      matchesError.value = userFacingError(e);
    } finally {
      isLoadingMatches.value = false;
    }
  }

  Map<String, MatchedOffer> get _matchesByOfferId => {
        for (final match in matchedOffers) match.id: match,
      };

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

  /// Score de compatibilite IA affiche sur la carte.
  /// Source unique : `/ai/match/feed`. Si le backend ne renvoie pas de score
  /// pour cette offre, on affiche 0 plutot qu'un score local invente.
  int scoreForOffer(Offer offer) {
    return _matchesByOfferId[offer.id]?.score ?? 0;
  }

  String matchExplanationForOffer(Offer offer) {
    return _matchesByOfferId[offer.id]?.explanation ?? '';
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
      AppToast.warning(
          'Déjà postulé', 'Vous avez déjà candidaté à ${offer.title}.');
      return;
    }
    try {
      await _repository.applyToOffer(offer.id);
      appliedOfferIds.add(offer.id);
      // Burst de confetti de célébration (sans écran dédié) en plus du toast.
      showCelebration();
      AppToast.success(
          'Candidature envoyée', '${offer.company} · ${offer.title}');
    } catch (e) {
      if (isOfflineError(e)) {
        await _queueOfflineApply(offer);
      } else {
        AppToast.error('Candidature non envoyée', userFacingError(e));
      }
    }
  }

  /// Met une candidature en file d'attente hors-ligne et marque l'offre comme
  /// postulee de facon optimiste (renvoi auto au retour du reseau).
  Future<void> _queueOfflineApply(Offer offer) async {
    await Get.find<OfflineApplyQueue>().enqueue(PendingApply(
      offerId: offer.id,
      offerTitle: offer.title,
      company: offer.company,
      logoUrl: offer.companyLogo,
      queuedAt: DateTime.now(),
    ));
    appliedOfferIds.add(offer.id);
    AppToast.info(
      'Candidature enregistrée',
      'Hors ligne — envoi dès le retour du réseau.',
    );
  }

  @override
  void onInit() {
    super.onInit();
    // Filtres passés en arguments (ex. depuis une alerte emploi sauvegardée) :
    // appliqués AVANT le premier chargement, donc pris en compte d'emblée sans
    // déclencher de rechargement (les workers ne sont pas encore enregistrés).
    final args = Get.arguments;
    if (args is Map && args['filters'] is Map) {
      final f = Map<String, dynamic>.from(args['filters'] as Map);
      final search = f['search']?.toString() ?? '';
      searchQuery.value = search;
      searchCtrl.text = search;
      selectedSectorId.value = f['sector_id']?.toString();
      activeContract.value = f['contract_type']?.toString();
      remoteOnly.value = f['is_remote'] == true || f['is_remote'] == 1;
      final sort = f['sort']?.toString();
      if (sort != null && sort.isNotEmpty) sortMode.value = sort;
    }
    loadOffers();
    loadSavedOffers();
    loadSectors();
    loadMatchedOffers();

    // Rechargement serveur sur changement de filtre. La recherche est débouncée
    // (450 ms) ; les autres filtres rechargent immédiatement. Les workers ne se
    // déclenchent que sur CHANGEMENT → pas de double-chargement à l'init.
    debounce<String>(searchQuery, (_) => _onFilterChanged(),
        time: const Duration(milliseconds: 450));
    ever<String?>(activeContract, (_) => _onFilterChanged());
    ever<bool>(remoteOnly, (_) => _onFilterChanged());
    ever<String?>(selectedSectorId, (_) => _onFilterChanged());
    ever<String>(sortMode, (_) => _onFilterChanged());
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
      final result = await _repository.getOffers(
        page: currentPage.value,
        search: searchQuery.value,
        sectorId: selectedSectorId.value,
        contractType: activeContract.value,
        isRemote: remoteOnly.value ? true : null,
        sort: sortMode.value,
      );

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

  /// Charge les offres enregistrées depuis le backend (GET /offers/saved/list).
  /// Alimente l'onglet Favoris du hub Suivi et l'état des cœurs de la liste.
  Future<void> loadSavedOffers() async {
    isLoadingSaved.value = true;
    try {
      savedOffers.assignAll(await _repository.getSavedOffers());
    } finally {
      isLoadingSaved.value = false;
    }
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
    } catch (e) {
      if (isOfflineError(e)) {
        final offer = offers.firstWhereOrNull((o) => o.id == offerId);
        if (offer != null) {
          await _queueOfflineApply(offer);
        } else {
          await Get.find<OfflineApplyQueue>().enqueue(PendingApply(
            offerId: offerId,
            offerTitle: 'Offre',
            company: '',
            queuedAt: DateTime.now(),
          ));
          appliedOfferIds.add(offerId);
        }
        // Optimiste : l'UI considere l'offre postulee (renvoi differe).
        return true;
      }
      return false;
    } finally {
      isApplyingToOfferId.value = null;
    }
  }

  bool hasAppliedToOffer(String offerId) => appliedOfferIds.contains(offerId);
}
