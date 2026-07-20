import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import 'package:jobaway/app/core/services/offline_apply_queue.dart';
import 'package:jobaway/app/core/theme/app_colors.dart';
import 'package:jobaway/app/core/utils/haptics.dart';
import 'package:jobaway/app/core/utils/offline_error.dart';
import 'package:jobaway/app/core/utils/user_facing_error.dart';
import 'package:jobaway/app/core/widgets/common/app_toast.dart';
import 'package:jobaway/app/core/widgets/common/confirm_sheet.dart';
import 'package:jobaway/app/core/widgets/effects/celebration_overlay.dart';
import 'package:jobaway/routes/app_routes.dart';
import '../../domain/entities/offer.dart';
import '../../domain/entities/matched_offer.dart';
import '../../domain/entities/sector_option.dart';
import '../../domain/exceptions/missing_skills_exception.dart';
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

  int? scoreForOffset(int offset) {
    final o = offerAtOffset(offset);
    return o == null ? null : scoreForOffer(o);
  }

  /// Score de compatibilité IA affiché sur la carte.
  ///
  /// Il est porté par l'offre elle-même (`match_score`, calculé par le backend
  /// pour la page demandée) ; le feed `/ai/match/feed` ne sert plus que de
  /// complément, car il ne couvre qu'un top-N. `null` = score inconnu → le badge
  /// est masqué, au lieu d'afficher un « 0 % » qui se lisait comme un vrai score.
  int? scoreForOffer(Offer offer) {
    return offer.matchScore ?? _matchesByOfferId[offer.id]?.score;
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

    // Un swipe droite envoie une vraie candidature, irréversible côté serveur :
    // on confirme AVANT de laisser partir la carte, pour qu'un geste accidentel
    // se rattrape par un simple « Annuler » (la carte revient au centre).
    final needsConfirm =
        toRight && swiped != null && !appliedOfferIds.contains(swiped.id);
    if (needsConfirm && !await _confirmApply(swiped)) {
      await _animateBackToCenter();
      return;
    }

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

  /// Feuille de confirmation de candidature. Gèle le deck pendant l'affichage.
  /// Sans contexte (aucune UI montée) on refuse : mieux vaut ne rien envoyer
  /// que de postuler sans que l'utilisateur ait pu valider.
  Future<bool> _confirmApply(Offer offer) async {
    final context = Get.context;
    if (context == null) return false;

    isOfferAnimating.value = true;
    final confirmed = await showConfirmSheet(
      context: context,
      icon: IconlyBold.heart,
      iconColor: AppColors.primary,
      title: 'Postuler chez ${offer.company} ?',
      message: '${offer.title} · ${offer.location}\n'
          'Votre profil et votre CV seront transmis au recruteur.',
      confirmLabel: 'Postuler',
    );
    isOfferAnimating.value = false;
    return confirmed ?? false;
  }

  Future<void> _applySwiped(Offer offer) async {
    if (offer.id.isEmpty) return;
    if (appliedOfferIds.contains(offer.id)) {
      AppToast.warning(
          'Déjà postulé', 'Vous avez déjà candidaté à ${offer.title}.');
      return;
    }
    try {
      final result = await _repository.applyToOffer(offer.id);
      appliedOfferIds.add(offer.id);

      // Match : écran de célébration plein écran (le seuil est décidé par le
      // backend via `matching.match_threshold`, on ne le rejoue pas ici).
      if (result.isMatch) {
        AppHaptics.success();
        await Get.toNamed<void>(AppRoutes.offerMatch, arguments: {
          'offerTitle': offer.title,
          'company': offer.company,
          'score': result.score,
        });
        return;
      }

      // Pas de match : burst de confetti de célébration en plus du toast.
      showCelebration();
      AppToast.success(
          'Candidature envoyée', '${offer.company} · ${offer.title}');
    } on MissingSkillsException catch (e) {
      // Le swipe passe par la même API : sans compétences, la candidature serait
      // écartée automatiquement. On le dit, on ne la compte pas comme envoyée.
      AppHaptics.error();
      AppToast.warning('Complétez vos compétences', e.message);
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

  bool hasAppliedToOffer(String offerId) => appliedOfferIds.contains(offerId);
}
