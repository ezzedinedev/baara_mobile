import 'package:get/get.dart';

import '../../../core/network/api_provider.dart';
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
  }

  Future<void> loadOffers({bool refresh = false}) async {
    if (refresh) {
      currentPage.value = 1;
      offers.clear();
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final result = await _repository.getOffers(
        page: currentPage.value,
        perPage: perPage,
        filter: filter.value,
      );

      if (refresh) {
        offers.value = result.items;
      } else {
        offers.addAll(result.items);
      }

      hasNextPage.value = result.hasNextPage;
      totalOffers.value = result.total;
    } catch (e) {
      errorMessage.value = _friendlyError(e);
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

  Future<void> loadSavedOffers({bool refresh = false}) async {
    if (refresh) {
      currentPage.value = 1;
      savedOffers.clear();
    }

    isLoading.value = true;

    try {
      final result = await _repository.getSavedOffers(
        page: currentPage.value,
        perPage: perPage,
      );

      if (refresh) {
        savedOffers.value = result;
      } else {
        savedOffers.addAll(result);
      }
    } catch (e) {
      errorMessage.value = _friendlyError(e);
    } finally {
      isLoading.value = false;
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

  Future<bool> saveOffer(String offerId) async {
    final index = offers.indexWhere((o) => o.id == offerId);
    if (index == -1 || savedOffers.any((o) => o.id == offerId)) {
      return false;
    }
    final offer = offers[index];
    savedOffers.add(offer);

    try {
      final success = await _repository.saveOffer(offerId);
      if (!success) {
        savedOffers.removeWhere((o) => o.id == offerId);
      }
      return success;
    } catch (_) {
      savedOffers.removeWhere((o) => o.id == offerId);
      return false;
    }
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
    isLoadingApplications.value = true;
    applicationsError.value = '';
    try {
      final list = await _repository.getMyApplications(
        page: 1,
        perPage: 50,
        status: statusFilter,
      );
      myApplications.assignAll(list);
      // Sync local : les offres deja candidatees sont marquees applied.
      appliedOfferIds.addAll(list.map((a) => a.offerId));
    } catch (e) {
      applicationsError.value = _friendlyError(e);
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
    return 'Erreur lors du chargement des offres.';
  }
}
