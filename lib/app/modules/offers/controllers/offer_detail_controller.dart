import 'package:get/get.dart';

import '../../../data/providers/api_provider.dart';
import '../models/offer_model.dart';
import '../repositories/offer_repository.dart';

/// Controller dedie au detail d'une offre.
/// Lit l'identifiant via `Get.parameters['id']` et charge l'offre via
/// [OfferRepository.getOfferById]. Tient un etat `isLoading` / `errorMessage`
/// independant du listing pour ne pas bloquer la pagination en arriere-plan.
class OfferDetailController extends GetxController {
  OfferDetailController({ApiProvider? apiProvider}) {
    _repository = OfferRepository(apiProvider: apiProvider ?? Get.find());
  }

  late final OfferRepository _repository;

  final offer = Rxn<OfferModel>();
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  String? _offerId;

  @override
  void onInit() {
    super.onInit();
    _offerId = Get.parameters['id'];
    if (_offerId == null || _offerId!.isEmpty) {
      errorMessage.value = 'Identifiant d\'offre manquant.';
      return;
    }
    loadOffer();
  }

  Future<void> loadOffer() async {
    final id = _offerId;
    if (id == null || id.isEmpty) return;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final result = await _repository.getOfferById(id);
      if (result == null) {
        errorMessage.value = 'Offre introuvable.';
      } else {
        offer.value = result;
      }
    } catch (e) {
      errorMessage.value = _friendlyError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshOffer() async => loadOffer();

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('Unable to connect')) {
      return 'Connexion impossible. Verifiez votre reseau.';
    }
    return 'Erreur lors du chargement de l\'offre.';
  }
}
