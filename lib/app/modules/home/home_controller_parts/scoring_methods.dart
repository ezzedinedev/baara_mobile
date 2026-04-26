part of '../home_controller.dart';

extension HomeControllerScoring on HomeController {
  HomeOfferPreview offerAtOffset(int offset) {
    if (offers.isEmpty) {
      throw StateError('Aucune offre disponible');
    }

    final index = (currentOfferIndex.value + offset) % offers.length;
    return offers[index];
  }

  int scoreForOffset(int offset) {
    return scoreForOffer(offerAtOffset(offset));
  }

  int scoreForOffer(HomeOfferPreview offer) {
    final profileSkills =
        candidateProfile.skills.map((skill) => skill.toLowerCase()).toSet();
    final requiredSkills =
        offer.requiredSkills.map((skill) => skill.toLowerCase()).toList();

    var skillMatches = 0;
    for (final skill in requiredSkills) {
      if (profileSkills.contains(skill)) {
        skillMatches += 1;
      }
    }

    final skillScore = requiredSkills.isEmpty
        ? 50
        : ((skillMatches / requiredSkills.length) * 50).round();

    final locationScore = candidateProfile.preferredLocations
            .map((e) => e.toLowerCase())
            .any((location) => offer.location.toLowerCase().contains(location))
        ? 20
        : 5;

    final contractScore = candidateProfile.preferredContracts
            .map((e) => e.toLowerCase())
            .contains(offer.contractType.toLowerCase())
        ? 15
        : 4;

    final experienceGap =
        candidateProfile.experienceYears - offer.minYearsExperience;
    final experienceScore = experienceGap >= 0
        ? 15
        : experienceGap == -1
            ? 9
            : 3;

    final total = skillScore + locationScore + contractScore + experienceScore;
    return total.clamp(0, 100);
  }

  Future<void> _animateBackToCenter() async {
    isOfferAnimating.value = true;
    offerDragDx.value = 0;
    await Future<void>.delayed(const Duration(milliseconds: 180));
    isOfferAnimating.value = false;
  }

  Future<void> _animateSwipe(bool toRight) async {
    if (isOfferAnimating.value || offers.isEmpty) {
      return;
    }

    final swipedOffer = offerAtOffset(0);
    final swipedScore = scoreForOffer(swipedOffer);

    isOfferAnimating.value = true;
    offerDragDx.value = toRight ? 420 : -420;
    await Future<void>.delayed(const Duration(milliseconds: 210));
    currentOfferIndex.value = (currentOfferIndex.value + 1) % offers.length;
    offerDragDx.value = 0;
    isOfferAnimating.value = false;

    if (!toRight) {
      return;
    }

    // Swipe droite = candidature reelle. On envoie POST /applications au
    // backend ; ApplicationMatchingService calcule ai_match_score, cree la
    // conversation avec le recruteur (firstOrCreate) et fire la notification
    // 'new_application'. Si score < seuil (config matching.auto_filter_threshold)
    // l'application est creee avec status=rejected — on remonte le retour
    // serveur a l'UI sans pre-filter cote client.
    pendingMatch.value = HomeOfferMatchResult(
      offer: swipedOffer,
      score: swipedScore,
    );
    unawaited(_submitSwipeApplication(swipedOffer, swipedScore));
  }

  /// Postule directement à une offre (sans animation swipe). Utilisé quand
  /// l'utilisateur tape sur "Postuler" depuis la liste verticale ou un
  /// détail offre — l'overlay match s'affiche quand même via pendingMatch.
  Future<void> applyToOfferDirect(HomeOfferPreview offer) async {
    final score = scoreForOffer(offer);
    pendingMatch.value = HomeOfferMatchResult(offer: offer, score: score);
    await _submitSwipeApplication(offer, score);
  }

  Future<void> _submitSwipeApplication(
    HomeOfferPreview offer,
    int localScore,
  ) async {
    if (offer.id.isEmpty) return;
    try {
      final token = await const AuthTokenStore().readToken();
      final response = await _apiProvider.postJson(
        ApiConstants.applications,
        {'offer_id': offer.id},
        headers: ApiConstants.authHeaders(token),
      );

      final success = response['success'] == true;
      final statusCode = response['statusCode'] as int?;
      final created = success && (statusCode == 200 || statusCode == 201);

      if (!created) {
        final apiMessage = _extractApiMessage(response, fallback: '');
        final lower = apiMessage.toLowerCase();
        // Cas typés : on remonte un feedback clair à l'utilisateur au lieu
        // d'avaler silencieusement (l'overlay match donnait l'illusion d'un
        // succès alors que la candidature n'avait pas été créée backend).
        final reasonNoCv = lower.contains('cv') &&
            (lower.contains('creer') ||
                lower.contains('importer') ||
                lower.contains('avant'));
        final reasonAlreadyApplied = lower.contains('deja');
        final reasonOfferGone = lower.contains('disponible');

        final title = reasonNoCv
            ? 'CV requis'
            : reasonAlreadyApplied
                ? 'Déjà postulé'
                : reasonOfferGone
                    ? 'Offre indisponible'
                    : 'Candidature non envoyée';
        final body = reasonNoCv
            ? 'Crée ou importe ton CV avant de postuler à ${offer.company}.'
            : reasonAlreadyApplied
                ? '${offer.company} - ${offer.title} : tu as déjà candidaté.'
                : reasonOfferGone
                    ? '${offer.title} chez ${offer.company} n\'est plus active.'
                    : apiMessage.isEmpty
                        ? 'Impossible d\'envoyer la candidature pour ${offer.company}.'
                        : apiMessage;

        _addNotification(
          title: title,
          body: body,
          category: 'Offre',
          icon: reasonNoCv
              ? Icons.description_outlined
              : Icons.report_outlined,
        );

        // Snackbar visible immédiatement — la notif reste pour l'historique,
        // mais l'utilisateur a besoin du feedback en direct après son swipe.
        // Si CV manquant, on lui propose d'aller le créer (CTA -> landing CV
        // builder où il choisit Assistant IA / Manuel / Import).
        Get.snackbar(
          title,
          body,
          backgroundColor: AppColors.errorSoft,
          colorText: AppColors.errorStrong,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 14,
          duration: Duration(seconds: reasonNoCv ? 6 : 4),
          mainButton: reasonNoCv
              ? TextButton(
                  onPressed: () {
                    Get.closeAllSnackbars();
                    Get.toNamed(AppRoutes.profileCvBuilder);
                  },
                  child: Text(
                    'Créer mon CV',
                    style: AppTextStyles.titleMd.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                )
              : null,
        );
        return;
      }

      // Le backend renvoie l'application avec ai_match_score reel + status.
      final appData = _asMap(response['data']);
      final rawServerScore = _asInt(appData?['ai_match_score']);
      final serverScore = rawServerScore == 0 ? localScore : rawServerScore;
      final status = _asString(appData?['status']) ?? '';

      final wasFiltered = status == 'rejected';
      _addNotification(
        title: wasFiltered
            ? 'Score trop faible'
            : 'Candidature envoyée',
        body: wasFiltered
            ? '${offer.company} : votre profil ne correspond pas encore'
                ' à cette offre ($serverScore%).'
            : '${offer.company} - ${offer.title} (compatibilité $serverScore%)',
        category: 'Offre',
        icon: wasFiltered
            ? Icons.report_outlined
            : Icons.local_offer_outlined,
      );

      // Confirme aussi via snackbar pour que le user voie immédiatement que
      // sa candidature est partie (sans devoir aller dans les notifs).
      if (!wasFiltered) {
        Get.snackbar(
          'Candidature envoyée',
          '${offer.company} - ${offer.title}',
          backgroundColor: AppColors.successSoft,
          colorText: AppColors.primary,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 14,
          duration: const Duration(seconds: 3),
        );
      }
    } on Exception catch (e) {
      // Échec réseau ou parsing : on prévient l'utilisateur au lieu de
      // laisser l'overlay match suggérer un succès inexistant.
      final msg = e.toString().contains('Unable to connect')
          ? 'Connexion impossible. Vérifiez votre réseau.'
          : 'Une erreur est survenue. Réessayez.';
      _addNotification(
        title: 'Candidature non envoyée',
        body: '${offer.company} - ${offer.title} : $msg',
        category: 'Offre',
        icon: Icons.cloud_off_outlined,
      );
      Get.snackbar(
        'Candidature non envoyée',
        msg,
        backgroundColor: AppColors.errorSoft,
        colorText: AppColors.errorStrong,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
        duration: const Duration(seconds: 4),
      );
    }
  }

}
