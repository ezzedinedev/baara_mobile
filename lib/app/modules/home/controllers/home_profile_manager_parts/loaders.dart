part of '../home_profile_manager.dart';

extension HomeProfileManagerLoaders on HomeProfileManager {
  Future<void> loadAll() async {
    await Future.wait([
      loadProfile(),
      loadCv(),
      loadPortfolio(),
    ]);
  }

  Future<void> loadProfile() async {
    isLoadingProfile.value = true;
    profileLoadError.value = '';

    try {
      final token = await _readToken();
      final response = await _apiProvider.getJson(
        ApiConstants.profile,
        headers: ApiConstants.authHeadersWithoutContentType(token),
      );

      if (response['success'] != true) {
        throw Exception(
          _extractApiMessage(
            response,
            fallback: 'Impossible de charger le profil.',
          ),
        );
      }

      final data = _asMap(response['data']) ?? const <String, dynamic>{};
      profile.value = _parseProfile(data);
      preferences.value =
          _parsePreferences(_asMap(data['user'])?['preferences']);

      // Synchronise la locale GetX avec la pref utilisateur.
      applyAppLocale(preferences.value.language);

      // NE PAS synchroniser le theme depuis le backend au load — la
      // pref locale (SharedPreferences) est la source de verite. Le
      // toggle dans le profil pousse vers backend (cross-device) mais
      // au demarrage on ne ramene jamais le backend sur le local pour
      // eviter qu'une valeur serveur erronee force le mode sombre a
      // chaque entree dans l'app.
    } on Exception catch (error) {
      profileLoadError.value = _friendlyErrorMessage(
        error,
        fallback: 'Impossible de charger le profil.',
      );
    } finally {
      isLoadingProfile.value = false;
    }
  }

  Future<void> loadCv() async {
    isLoadingCv.value = true;
    cvLoadError.value = '';

    try {
      final token = await _readToken();
      final response = await _apiProvider.getJson(
        ApiConstants.profileCv,
        headers: ApiConstants.authHeadersWithoutContentType(token),
      );

      if (response['success'] != true) {
        throw Exception(
          _extractApiMessage(response,
              fallback: 'Impossible de charger le CV.'),
        );
      }

      final data = response['data'];
      final uploaded = _parseUploadedCvFromPayload(data);
      if (uploaded != null) {
        uploadedCv.value = uploaded;
      }

      cvSections.assignAll(
        _extractItems(data).map(_parseCvSection).whereType<HomeCvSection>(),
      );
    } on Exception catch (error) {
      cvLoadError.value = _friendlyErrorMessage(
        error,
        fallback: 'Impossible de charger le CV.',
      );
    } finally {
      isLoadingCv.value = false;
    }
  }

  Future<void> loadPortfolio() async {
    isLoadingPortfolio.value = true;
    portfolioLoadError.value = '';

    try {
      final token = await _readToken();
      final response = await _apiProvider.getJson(
        ApiConstants.profilePortfolio,
        headers: ApiConstants.authHeadersWithoutContentType(token),
      );

      if (response['success'] != true) {
        throw Exception(
          _extractApiMessage(
            response,
            fallback: 'Impossible de charger le portfolio.',
          ),
        );
      }

      portfolioItems.assignAll(
        _extractItems(response['data'])
            .map(_parsePortfolioItem)
            .whereType<HomePortfolioItem>(),
      );
    } on Exception catch (error) {
      portfolioLoadError.value = _friendlyErrorMessage(
        error,
        fallback: 'Impossible de charger le portfolio.',
      );
    } finally {
      isLoadingPortfolio.value = false;
    }
  }

}
