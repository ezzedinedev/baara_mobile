part of '../home_controller.dart';

extension HomeControllerFormations on HomeController {
  HomeFormationPreview? formationById(String id) {
    for (final formation in formations) {
      if (formation.id == id) {
        return formation;
      }
    }
    return null;
  }

  Future<void> loadFormationLearningDetail(
    HomeFormationPreview formation,
  ) async {
    if (formation.id.isEmpty || loadingLearningFormationId.value != null) {
      return;
    }

    loadingLearningFormationId.value = formation.id;

    try {
      Map<String, String>? headers;
      try {
        final token = await const AuthTokenStore().readToken();
        headers = ApiConstants.authHeadersWithoutContentType(token);
      } on Exception {
        headers = null;
      }

      final response = await _apiProvider.getJson(
        '${ApiConstants.trainings}/${formation.id}',
        headers: headers,
      );

      if (response['success'] != true || response['data'] == null) {
        return;
      }

      final detailed = _parseTraining(response['data']);
      if (detailed == null) {
        return;
      }

      final index = formations.indexWhere((item) => item.id == formation.id);
      if (index < 0) {
        formations.add(detailed);
        return;
      }

      final current = formations[index];
      formations[index] = detailed.copyWith(
        isEnrolled: current.isEnrolled || detailed.isEnrolled,
        modules: detailed.modules.isEmpty ? current.modules : detailed.modules,
        enrolledCount: detailed.enrolledCount == 0
            ? current.enrolledCount
            : detailed.enrolledCount,
      );
    } finally {
      loadingLearningFormationId.value = null;
    }
  }

  Future<bool> enrollInFormation(HomeFormationPreview formation) async {
    if (formation.id.isEmpty) {
      Get.snackbar(
        'Formation',
        'Cette formation ne peut pas encore etre suivie.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    final current = formationById(formation.id) ?? formation;
    if (current.isEnrolled) {
      return true;
    }

    if (enrollingFormationId.value != null) {
      return false;
    }

    enrollingFormationId.value = formation.id;

    try {
      final token = await const AuthTokenStore().readToken();
      final response = await _apiProvider.postJson(
        '${ApiConstants.trainings}/${formation.id}/enroll',
        {},
        headers: ApiConstants.authHeaders(token),
      );

      if (response['success'] != true) {
        final message = _extractApiMessage(
          response,
          fallback: 'Inscription impossible pour cette formation.',
        );
        if (_isAlreadyEnrolledMessage(message)) {
          _markFormationAsEnrolled(formation.id, incrementCount: false);
          return true;
        }
        throw Exception(
          message,
        );
      }

      _markFormationAsEnrolled(formation.id);
      _addNotification(
        title: 'Formation suivie',
        body: 'Vous suivez maintenant ${formation.title}.',
        category: 'Formation',
        icon: Icons.school_outlined,
      );

      return true;
    } on Exception catch (error) {
      if (_isAlreadyEnrolledMessage(error.toString())) {
        _markFormationAsEnrolled(formation.id, incrementCount: false);
        return true;
      }
      Get.snackbar(
        'Formation',
        _friendlyErrorMessage(
          error,
          fallback: 'Inscription impossible pour cette formation.',
        ),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      enrollingFormationId.value = null;
    }
  }

  bool _isAlreadyEnrolledMessage(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('deja inscrit') ||
        normalized.contains('deja inscrite') ||
        normalized.contains('déjà inscrit') ||
        normalized.contains('déjà inscrite') ||
        normalized.contains('already enrolled') ||
        normalized.contains('already registered');
  }

  void _markFormationAsEnrolled(
    String formationId, {
    bool incrementCount = true,
  }) {
    final index =
        formations.indexWhere((formation) => formation.id == formationId);
    if (index < 0) {
      return;
    }

    final formation = formations[index];
    formations[index] = formation.copyWith(
      isEnrolled: true,
      enrolledCount: formation.isEnrolled
          ? formation.enrolledCount
          : formation.enrolledCount + (incrementCount ? 1 : 0),
    );
  }

  Future<bool> completeFormationLesson(
    HomeFormationPreview formation,
    HomeTrainingLesson lesson,
  ) async {
    if (lesson.isCompleted) {
      return true;
    }

    if (completingLessonId.value != null) {
      return false;
    }

    completingLessonId.value = lesson.id;

    try {
      if (formation.id.isNotEmpty && lesson.backendId.isNotEmpty) {
        final token = await const AuthTokenStore().readToken();
        final response = await _apiProvider.postJson(
          '${ApiConstants.trainings}/${formation.id}/progress',
          {'module_id': lesson.backendId},
          headers: ApiConstants.authHeaders(token),
        );

        if (response['success'] != true) {
          throw Exception(
            _extractApiMessage(
              response,
              fallback: 'Impossible de sauvegarder la progression.',
            ),
          );
        }
      }

      _markLessonAsCompleted(formation.id, lesson.id);
      return true;
    } on Exception catch (error) {
      Get.snackbar(
        'Formation',
        _friendlyErrorMessage(
          error,
          fallback: 'Impossible de sauvegarder la progression.',
        ),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      completingLessonId.value = null;
    }
  }

  void _markLessonAsCompleted(String formationId, String lessonId) {
    final index =
        formations.indexWhere((formation) => formation.id == formationId);
    if (index < 0) {
      return;
    }

    final formation = formations[index];
    final updatedModules = formation.modules
        .map(
          (module) => module.id == lessonId
              ? module.copyWith(isCompleted: true)
              : module,
        )
        .toList(growable: false);

    formations[index] = formation.copyWith(modules: updatedModules);

    if (updatedModules.isNotEmpty &&
        updatedModules.every((module) => module.isCompleted)) {
      _addNotification(
        title: 'Formation terminee',
        body: 'Vous avez termine ${formation.title}.',
        category: 'Formation',
        icon: Icons.verified_outlined,
      );
    }
  }

}
