part of '../home_controller.dart';

extension HomeControllerLoadSwipe on HomeController {
  Future<void> loadPublishedContent() async {
    await Future.wait([
      reloadOffers(),
      reloadFormations(),
    ]);
  }

  Future<void> reloadOffers() async {
    isLoadingOffers.value = true;
    offersLoadError.value = '';

    try {
      final rawItems = await _fetchPublishedOffers();
      final parsed = rawItems
          .map(_parseOffer)
          .whereType<HomeOfferPreview>()
          .toList(growable: false);

      offers.assignAll(parsed);
      currentOfferIndex.value = 0;
      offerDragDx.value = 0;
      pendingMatch.value = null;
    } on Exception catch (error) {
      offersLoadError.value = _friendlyErrorMessage(
        error,
        fallback: 'Impossible de charger les offres publiees.',
      );
      if (offers.isEmpty) {
        offers.clear();
      }
    } finally {
      isLoadingOffers.value = false;
    }
  }

  Future<void> reloadFormations() async {
    isLoadingFormations.value = true;
    formationsLoadError.value = '';

    try {
      final response = await _apiProvider.getJson(ApiConstants.trainings);
      if (response['success'] != true) {
        throw Exception(
          _extractApiMessage(
            response,
            fallback: 'Impossible de charger les formations disponibles.',
          ),
        );
      }

      final parsed = _extractItems(response['data'])
          .map(_parseTraining)
          .whereType<HomeFormationPreview>()
          .toList(growable: false);

      formations.assignAll(parsed);
    } on Exception catch (error) {
      formationsLoadError.value = _friendlyErrorMessage(
        error,
        fallback: 'Impossible de charger les formations disponibles.',
      );
      if (formations.isEmpty) {
        formations.clear();
      }
    } finally {
      isLoadingFormations.value = false;
    }
  }

  void onOfferChanged(int index) {
    currentOfferIndex.value = index;
  }

  void updateOfferDrag(double deltaX) {
    if (isOfferAnimating.value || offers.isEmpty) {
      return;
    }
    offerDragDx.value += deltaX;
  }

  Future<void> endOfferDrag(double velocityX) async {
    if (isOfferAnimating.value || offers.isEmpty) {
      return;
    }

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
}
