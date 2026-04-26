part of '../home_profile_manager.dart';

extension HomeProfileManagerSaves on HomeProfileManager {
  Future<void> saveProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String city,
    required String region,
    required String headline,
    required String summary,
    required List<String> skills,
  }) async {
    isSavingProfile.value = true;

    try {
      final token = await _readToken();
      final response = await _apiProvider.putJson(
        ApiConstants.profile,
        {
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'phone': phone,
          'city': city,
          'region': region,
          'headline': headline,
          'summary': summary,
          'skills': skills,
        },
        headers: ApiConstants.authHeaders(token),
      );

      if (response['success'] != true) {
        throw Exception(
          _extractApiMessage(
            response,
            fallback: 'Impossible de mettre le profil a jour.',
          ),
        );
      }

      final data = _asMap(response['data']) ?? const <String, dynamic>{};
      final user = _asMap(data['user']) ?? const <String, dynamic>{};
      final candidateProfile =
          _asMap(data['profile']) ?? const <String, dynamic>{};

      profile.value = profile.value.copyWith(
        firstName: _asString(user['first_name']) ?? firstName,
        lastName: _asString(user['last_name']) ?? lastName,
        email: _asString(user['email']) ?? email,
        phone: _asString(user['phone']) ?? phone,
        city: _asString(user['city']) ?? city,
        region: _asString(user['region']) ?? region,
        headline: _asString(candidateProfile['headline']) ?? headline,
        summary: _asString(candidateProfile['summary']) ?? summary,
        skills: _asStringList(candidateProfile['skills']).isNotEmpty
            ? _asStringList(candidateProfile['skills'])
            : skills,
      );
    } finally {
      isSavingProfile.value = false;
    }
  }

  Future<void> savePreferences(HomeProfilePreferences nextPreferences) async {
    isSavingPreferences.value = true;

    try {
      final token = await _readToken();
      final response = await _apiProvider.putJson(
        ApiConstants.profilePreferences,
        {
          'notifications_enabled': nextPreferences.notificationsEnabled,
          'offer_updates': nextPreferences.offerUpdates,
          'application_updates': nextPreferences.applicationUpdates,
          'match_alerts': nextPreferences.matchAlerts,
          'message_alerts': nextPreferences.messageAlerts,
          'training_updates': nextPreferences.trainingUpdates,
          'theme': nextPreferences.theme,
          'language': nextPreferences.language,
        },
        headers: ApiConstants.authHeaders(token),
      );

      if (response['success'] != true) {
        throw Exception(
          _extractApiMessage(
            response,
            fallback: 'Impossible de sauvegarder les preferences.',
          ),
        );
      }

      final data = _asMap(response['data']) ?? const <String, dynamic>{};
      preferences.value = _parsePreferences(data['preferences']);
    } finally {
      isSavingPreferences.value = false;
    }
  }

  Future<void> uploadAvatar(XFile file) async {
    isUploadingAvatar.value = true;

    try {
      final token = await _readToken();
      final bytes = await file.readAsBytes();
      final response = await _apiProvider.sendMultipart(
        ApiConstants.profileAvatar,
        method: 'POST',
        headers: ApiConstants.authHeadersWithoutContentType(token),
        files: [
          ApiMultipartFile(
            field: 'avatar',
            bytes: bytes,
            filename: file.name.isEmpty ? 'avatar.jpg' : file.name,
          ),
        ],
      );

      if (response['success'] != true) {
        throw Exception(
          _extractApiMessage(
            response,
            fallback: 'Impossible de mettre la photo a jour.',
          ),
        );
      }

      final data = _asMap(response['data']) ?? const <String, dynamic>{};
      profile.value = profile.value.copyWith(
        avatarUrl: _resolveAssetUrl(_asString(data['avatar_url']) ?? ''),
      );
    } finally {
      isUploadingAvatar.value = false;
    }
  }

  Future<void> uploadCvFile({
    required Uint8List bytes,
    required String filename,
  }) async {
    isUploadingCvFile.value = true;

    try {
      // Backend : POST /profile/cv-builder/import/analyze (stateless).
      // Champ multipart obligatoire = `cv_file` (cf. CvBuilderApiController@importAnalyze).
      // La réponse est `{filename, chars, extracted_preview, extracted_text, analysis}`
      // — pas une URL stable. Pour conserver le fichier, il faudrait chaîner
      // `/import/apply` qui persiste les `extracted_fields`. À retravailler si
      // le module veut afficher un PDF rejouable.
      final token = await _readToken();
      final response = await _apiProvider.sendMultipart(
        ApiConstants.profileCvImportAnalyze,
        method: 'POST',
        headers: ApiConstants.authHeadersWithoutContentType(token),
        files: [
          ApiMultipartFile(
            field: 'cv_file',
            bytes: bytes,
            filename: filename.trim().isEmpty ? 'cv.pdf' : filename.trim(),
          ),
        ],
      );

      if (response['success'] != true) {
        throw Exception(
          _extractApiMessage(
            response,
            fallback: 'Impossible d\'importer le CV.',
          ),
        );
      }

      final saved = _parseUploadedCvFromPayload(
        response['data'],
        fallbackFileName: filename,
      );
      uploadedCv.value = saved ??
          HomeUploadedCv(
            fileName: filename,
            url: '',
            mimeType: '',
            uploadedAt: DateTime.now(),
          );
    } finally {
      isUploadingCvFile.value = false;
    }
  }

  Future<void> saveCv(List<HomeCvSection> sections) async {
    isSavingCv.value = true;

    try {
      final token = await _readToken();
      final response = await _apiProvider.postJson(
        ApiConstants.profileCv,
        {
          'sections': sections
              .asMap()
              .entries
              .map(
                (entry) => {
                  if (entry.value.id != null && entry.value.id!.isNotEmpty)
                    'id': entry.value.id,
                  'section_type': entry.value.sectionType,
                  'title': entry.value.title,
                  'organization': entry.value.organization,
                  'start_date': _formatIsoDate(entry.value.startDate),
                  'end_date': _formatIsoDate(entry.value.endDate),
                  'is_current': entry.value.isCurrent,
                  'description': entry.value.description,
                  'missions': entry.value.missions,
                  'achievements': entry.value.achievements,
                  'level': entry.value.level,
                  'mention': entry.value.mention,
                  'external_url': entry.value.externalUrl,
                  'display_order': entry.key,
                },
              )
              .toList(growable: false),
        },
        headers: ApiConstants.authHeaders(token),
      );

      if (response['success'] != true) {
        throw Exception(
          _extractApiMessage(
            response,
            fallback: 'Impossible de sauvegarder le CV.',
          ),
        );
      }

      cvSections.assignAll(
        _extractItems(response['data'])
            .map(_parseCvSection)
            .whereType<HomeCvSection>(),
      );
    } finally {
      isSavingCv.value = false;
    }
  }

  Future<void> savePortfolioItem(
    HomePortfolioItem item, {
    List<ApiMultipartFile> mediaFiles = const [],
  }) async {
    isSavingPortfolio.value = true;

    try {
      final token = await _readToken();
      final response = await _apiProvider.sendMultipart(
        item.id == null
            ? ApiConstants.profilePortfolio
            : '${ApiConstants.profilePortfolio}/${item.id}',
        method: item.id == null ? 'POST' : 'PUT',
        headers: ApiConstants.authHeadersWithoutContentType(token),
        fields: {
          'item_type': item.itemType,
          'title': item.title,
          'description': item.description,
          'results': item.results,
          'external_url': item.externalUrl,
          'display_order': '${item.displayOrder}',
          'is_public': item.isPublic ? '1' : '0',
          'visibility': item.isPublic ? 'public' : 'private',
          'tech_stack': jsonEncode(item.techStack),
          'media_urls': jsonEncode(item.mediaUrls),
        },
        files: mediaFiles,
      );

      if (response['success'] != true) {
        throw Exception(
          _extractApiMessage(
            response,
            fallback: 'Impossible de sauvegarder le projet.',
          ),
        );
      }

      final saved = _parsePortfolioItem(response['data']);
      if (saved == null) {
        throw Exception('Reponse portfolio invalide.');
      }

      final items = portfolioItems.toList(growable: true);
      final existingIndex = items.indexWhere((entry) => entry.id == saved.id);
      if (existingIndex >= 0) {
        items[existingIndex] = saved;
      } else {
        items.add(saved);
      }
      items.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      portfolioItems.assignAll(items);
    } finally {
      isSavingPortfolio.value = false;
    }
  }

  Future<void> deletePortfolioItem(HomePortfolioItem item) async {
    if (item.id == null) {
      return;
    }

    isSavingPortfolio.value = true;

    try {
      final token = await _readToken();
      final response = await _apiProvider.deleteJson(
        '${ApiConstants.profilePortfolio}/${item.id}',
        headers: ApiConstants.authHeadersWithoutContentType(token),
      );

      if (response['success'] != true) {
        throw Exception(
          _extractApiMessage(
            response,
            fallback: 'Impossible de supprimer le projet.',
          ),
        );
      }

      portfolioItems.removeWhere((entry) => entry.id == item.id);
    } finally {
      isSavingPortfolio.value = false;
    }
  }
}