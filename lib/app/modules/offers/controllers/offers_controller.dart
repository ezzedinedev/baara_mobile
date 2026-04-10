import 'package:get/get.dart';

import '../../../data/providers/api_provider.dart';
import '../repositories/offer_repository.dart';
import '../models/offer_model.dart';

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
    try {
      final success = await _repository.saveOffer(offerId);
      if (success) {
        final index = offers.indexWhere((o) => o.id == offerId);
        if (index != -1) {
          savedOffers.add(offers[index]);
        }
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> unsaveOffer(String offerId) async {
    try {
      final success = await _repository.unsaveOffer(offerId);
      if (success) {
        savedOffers.removeWhere((o) => o.id == offerId);
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> applyToOffer(String offerId,
      {Map<String, dynamic>? data}) async {
    try {
      return await _repository.applyToOffer(offerId, data: data);
    } catch (e) {
      return false;
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
