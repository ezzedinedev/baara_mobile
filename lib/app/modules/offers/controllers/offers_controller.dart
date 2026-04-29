import 'package:get/get.dart';

import '../../../core/network/api_provider.dart';
import '../../../core/services/local_cache_service.dart';
import '../data/models/application_model.dart';
import '../data/models/offer_model.dart';
import '../data/repositories/offer_repository.dart';

class OffersController extends GetxController {
  OffersController({ApiProvider? apiProvider}) {
    _repository = OfferRepository(apiProvider: apiProvider ?? Get.find());
  }

  late final OfferRepository _repository;

  final offers = <OfferModel>[].obs;
  final featuredOffers = <OfferModel>[].obs;
  final savedOffers = <OfferModel>[].obs;
  final sectors = <SectorModel>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final isLoadingSaved = false.obs;
  final savedOffersError = ''.obs;
  final errorMessage = ''.obs;

  final currentPage = 1.obs;
  final hasNextPage = false.obs;
  final totalOffers = 0.obs;

  final filter = Rxn<OfferFilter>();
  final selectedOffer = Rxn<OfferModel>();

  /// Cache local des offres auxquelles l'utilisateur vient de postuler.
  /// Alimenté optimistement et confirmé/rollback selon la réponse backend.
  final appliedOfferIds = <String>{}.obs;
  final isApplyingToOfferId = RxnString();
  final lastApplication = Rxn<ApplicationModel>();

  static const int perPage = 20;

  @override
  void onInit() {
    super.onInit();
    loadOffers();
    loadSectors();
    loadFeaturedOffers();
    // Hydrate les favoris au boot pour que `isOfferSaved()` reflete l'etat
    // serveur des le premier rendu des cards (sinon le cœur reste vide
    // jusqu'au premier toggle).
    loadSavedOffers(refresh: true);
  }

  Future<void> loadOffers({bool refresh = false}) async {
    if (refresh) {
      currentPage.value = 1;
      offers.clear();
    }

    // 1. Hydrate-from-cache : si la liste est vide (premier mount, ou
    // refresh) on tente d'afficher immediatement la derniere version
    // connue stockee sur disque. Pas de spinner si on a du cache.
    if (offers.isEmpty && currentPage.value == 1) {
      final cached =
          await LocalCacheService.instance.readMap(CacheKeys.offersList);
      if (cached != null) {
        try {
          final parsed = _repository.parsePaginatedResponse(cached);
          offers.value = parsed.items;
          hasNextPage.value = parsed.hasNextPage;
          totalOffers.value = parsed.total;
        } catch (_) {
          // Cache corrompu / shape change → on l'ignore et on attendra
          // le fetch backend pour repeupler.
        }
      }
    }

    // 2. Fetch backend en background. Spinner uniquement si vraiment
    // rien a montrer (cache miss + liste vide).
    final shouldShowSpinner = offers.isEmpty;
    isLoading.value = shouldShowSpinner;
    errorMessage.value = '';

    try {
      final result = await _repository.getOffers(
        page: currentPage.value,
        perPage: perPage,
        filter: filter.value,
        // Cache uniquement la 1ere page sans filtre — la pagination et
        // les filtres font exploser le nombre de cles autrement.
        onRaw: (currentPage.value == 1 && filter.value == null)
            ? (raw) =>
                LocalCacheService.instance.writeJson(CacheKeys.offersList, raw)
            : null,
      );

      if (refresh || currentPage.value == 1) {
        offers.value = result.items;
      } else {
        offers.addAll(result.items);
      }

      hasNextPage.value = result.hasNextPage;
      totalOffers.value = result.total;
    } catch (e) {
      // Si on n'a rien (pas de cache + fetch echoue), surface l'erreur.
      // Sinon le user voit le cache stale, on log silencieusement.
      if (offers.isEmpty) {
        errorMessage.value = _friendlyError(e);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreOffers() async {
    if (isLoadingMore.value || !hasNextPage.value) return;

    isLoadingMore.value = true;
    currentPage.value++;

    try {
      final result = await _repository.getOffers(
        page: currentPage.value,
        perPage: perPage,
        filter: filter.value,
      );

      offers.addAll(result.items);
      hasNextPage.value = result.hasNextPage;
    } catch (e) {
      currentPage.value--;
      errorMessage.value = _friendlyError(e);
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> loadFeaturedOffers() async {
    try {
      final result = await _repository.getFeaturedOffers();
      featuredOffers.value = result;
    } catch (e) {
      // Silent fail for featured
    }
  }

  /// Recharge la liste des offres sauvegardees. Pattern stale-while-revalidate :
  /// hydrate cache → fetch backend → reecrit cache.
  Future<void> loadSavedOffers({bool refresh = false}) async {
    if (isLoadingSaved.value) return;

    // Hydrate-from-cache si vide.
    if (savedOffers.isEmpty) {
      final cached =
          await LocalCacheService.instance.readMap(CacheKeys.savedOffers);
      if (cached != null) {
        try {
          savedOffers.assignAll(_repository.parseSavedOffersResponse(cached));
        } catch (_) {/* ignore cache obsolete */}
      }
    }

    final shouldShowSpinner = savedOffers.isEmpty;
    isLoadingSaved.value = shouldShowSpinner;
    savedOffersError.value = '';

    try {
      final result = await _repository.getSavedOffers(
        page: 1,
        perPage: perPage,
        onRaw: (raw) => LocalCacheService.instance
            .writeJson(CacheKeys.savedOffers, raw),
      );

      if (refresh) {
        savedOffers.assignAll(result);
      } else {
        savedOffers.addAll(result);
      }
    } catch (e) {
      if (savedOffers.isEmpty) {
        savedOffersError.value = _friendlyError(e);
      }
    } finally {
      isLoadingSaved.value = false;
    }
  }

  Future<void> loadSectors() async {
    try {
      final result = await _repository.getSectors();
      sectors.value = result;
    } catch (e) {
      // Silent fail
    }
  }

  void applyFilter(OfferFilter? newFilter) {
    filter.value = newFilter;
    loadOffers(refresh: true);
  }

  void clearFilter() {
    filter.value = null;
    loadOffers(refresh: true);
  }

  /// Marque une offre comme favori. Optimiste : ajoute immediatement a
  /// `savedOffers` (en remontant l'offre depuis n'importe quelle liste
  /// connue : paginated, featured, ou detail), puis confirme/rollback selon
  /// la reponse backend.
  Future<bool> saveOffer(String offerId) async {
    if (savedOffers.any((o) => o.id == offerId)) return true;

    final offer = _findOfferEverywhere(offerId);
    if (offer != null) {
      savedOffers.add(offer);
    }

    try {
      final success = await _repository.saveOffer(offerId);
      if (success) {
        // Si on n'avait pas l'offre en cache local (ex: tap depuis une
        // notification), on rafraichit depuis le serveur pour hydrater
        // la liste favoris.
        if (offer == null) {
          await loadSavedOffers(refresh: true);
        }
      } else {
        savedOffers.removeWhere((o) => o.id == offerId);
      }
      return success;
    } catch (_) {
      savedOffers.removeWhere((o) => o.id == offerId);
      return false;
    }
  }

  /// Recherche une [OfferModel] dans toutes les listes locales connues.
  /// Utilise par `saveOffer` pour permettre l'ajout aux favoris quel que
  /// soit l'ecran d'origine (liste, carousel featured, detail, deck tinder).
  OfferModel? _findOfferEverywhere(String offerId) {
    for (final list in <List<OfferModel>>[
      offers,
      featuredOffers,
      savedOffers,
    ]) {
      final i = list.indexWhere((o) => o.id == offerId);
      if (i != -1) return list[i];
    }
    final selected = selectedOffer.value;
    if (selected != null && selected.id == offerId) return selected;
    return null;
  }

  Future<bool> unsaveOffer(String offerId) async {
    final removedIndex = savedOffers.indexWhere((o) => o.id == offerId);
    if (removedIndex == -1) {
      return false;
    }
    final previous = savedOffers[removedIndex];
    savedOffers.removeAt(removedIndex);

    try {
      final success = await _repository.unsaveOffer(offerId);
      if (!success) {
        savedOffers.insert(removedIndex, previous);
      }
      return success;
    } catch (_) {
      savedOffers.insert(removedIndex, previous);
      return false;
    }
  }

  /// Postule à une offre. Miroir du flux Laravel :
  /// - l'UI appelle cette méthode avec l'id de l'offre + les réponses de screening
  ///   éventuelles (questions posées par l'employeur)
  /// - en cas de succès, l'offre est marquée comme postulée localement
  /// - en cas d'échec, le résultat porte la raison typée + un message friendly FR
  ///
  /// L'UI doit examiner `result.reason` pour router vers la bonne action
  /// (ex: `noCv` → diriger vers l'écran de CV, `alreadyApplied` → snackbar info).
  Future<ApplyResult> applyToOffer(
    String offerId, {
    Map<String, dynamic>? screeningAnswers,
  }) async {
    if (isApplyingToOfferId.value == offerId) {
      return ApplyResult.failure(
        ApplyFailureReason.unknown,
        'Candidature en cours, merci de patienter.',
      );
    }
    if (appliedOfferIds.contains(offerId)) {
      return ApplyResult.failure(
        ApplyFailureReason.alreadyApplied,
        'Vous avez déjà postulé à cette offre.',
      );
    }

    isApplyingToOfferId.value = offerId;
    appliedOfferIds.add(offerId);

    try {
      final application = await _repository.applyToOffer(
        offerId,
        screeningAnswers: screeningAnswers,
      );
      lastApplication.value = application;
      return ApplyResult.success(application);
    } on ApplyException catch (e) {
      if (e.reason != ApplyFailureReason.alreadyApplied) {
        appliedOfferIds.remove(offerId);
      }
      return ApplyResult.failure(e.reason, e.message);
    } catch (_) {
      appliedOfferIds.remove(offerId);
      return ApplyResult.failure(
        ApplyFailureReason.network,
        'Connexion impossible. Vérifiez votre réseau.',
      );
    } finally {
      isApplyingToOfferId.value = null;
    }
  }

  bool hasAppliedToOffer(String offerId) => appliedOfferIds.contains(offerId);

  /// Liste des candidatures du candidat connecte depuis le backend
  /// (`GET /api/v1/applications`). Synchronise aussi `appliedOfferIds`
  /// pour que les cards des offres deja postulees affichent l'etat correct.
  final myApplications = <ApplicationModel>[].obs;
  final isLoadingApplications = false.obs;
  final applicationsError = ''.obs;

  Future<void> loadMyApplications({String? statusFilter}) async {
    if (isLoadingApplications.value) return;

    // Hydrate-from-cache si vide. Cache uniquement le cas "sans filtre"
    // (le statusFilter est session-only, pas la peine de cacher chaque
    // combinaison).
    if (myApplications.isEmpty && statusFilter == null) {
      final cached =
          await LocalCacheService.instance.readMap(CacheKeys.myApplications);
      if (cached != null) {
        try {
          myApplications
              .assignAll(_repository.parseMyApplicationsResponse(cached));
          appliedOfferIds.addAll(myApplications.map((a) => a.offerId));
        } catch (_) {/* ignore */}
      }
    }

    final shouldShowSpinner = myApplications.isEmpty;
    isLoadingApplications.value = shouldShowSpinner;
    applicationsError.value = '';
    try {
      final list = await _repository.getMyApplications(
        page: 1,
        perPage: 50,
        status: statusFilter,
        onRaw: statusFilter == null
            ? (raw) => LocalCacheService.instance
                .writeJson(CacheKeys.myApplications, raw)
            : null,
      );
      myApplications.assignAll(list);
      appliedOfferIds.addAll(list.map((a) => a.offerId));
    } catch (e) {
      if (myApplications.isEmpty) {
        applicationsError.value = _friendlyError(e);
      }
    } finally {
      isLoadingApplications.value = false;
    }
  }

  Future<void> loadOfferDetail(String offerId) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final offer = await _repository.getOfferById(offerId);
      selectedOffer.value = offer;
    } catch (e) {
      errorMessage.value = _friendlyError(e);
    } finally {
      isLoading.value = false;
    }
  }

  bool isOfferSaved(String offerId) {
    return savedOffers.any((o) => o.id == offerId);
  }

  @override
  Future<void> refresh() async {
    await Future.wait([
      loadOffers(refresh: true),
      loadSavedOffers(refresh: true),
    ]);
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('Unable to connect')) {
      return 'Connexion impossible. Verifiez votre reseau.';
    }
    // Format `_ApiCallException` : "API 403: <msg backend>". On extrait le
    // message pour le rendre actionnable a l'utilisateur (ex: "Seuls les
    // comptes candidat peuvent gerer les candidatures.").
    final apiMatch = RegExp(r'^API \d+: (.+)$').firstMatch(message);
    if (apiMatch != null) {
      return apiMatch.group(1) ?? 'Erreur serveur';
    }
    return 'Erreur lors du chargement.';
  }
}
