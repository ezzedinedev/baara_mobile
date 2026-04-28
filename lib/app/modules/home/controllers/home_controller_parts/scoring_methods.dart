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
    //
    // L'overlay "C'est un match" n'est PAS affiche de facon optimiste : il
    // est defini dans _submitSwipeApplication uniquement si le backend a
    // accepte la candidature. Sinon (CV manquant, deja postule, score trop
    // bas), on ne ment pas a l'utilisateur.
    unawaited(_submitSwipeApplication(swipedOffer, swipedScore));
  }

  /// Postule directement à une offre (sans animation swipe). Utilisé quand
  /// l'utilisateur tape sur "Postuler" depuis la liste verticale ou un
  /// détail offre. L'overlay match n'est affiché qu'après confirmation API.
  Future<void> applyToOfferDirect(HomeOfferPreview offer) async {
    final score = scoreForOffer(offer);
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
            ? 'Ajoutez votre CV pour candidater à cette offre.'
            : reasonAlreadyApplied
                ? 'Vous avez déjà postulé à ${offer.title}.'
                : reasonOfferGone
                    ? 'Cette offre n\'est plus disponible.'
                    : apiMessage.isEmpty
                        ? 'Votre candidature n\'a pas pu être envoyée.'
                        : apiMessage;

        _addNotification(
          title: title,
          body: body,
          category: 'Offre',
          icon: reasonNoCv
              ? Icons.description_outlined
              : Icons.report_outlined,
        );

        // CV manquant : c'est un blocage actionnable, donc on remplace le
        // snackbar par un bottom sheet premium (illustration + double CTA).
        // Plus visible, plus pro, et coherent avec showConfirmSheet utilise
        // ailleurs (logout, suppression portfolio).
        if (reasonNoCv) {
          final ctx = Get.context;
          if (ctx != null && ctx.mounted) {
            final goCreate = await showConfirmSheet(
              context: ctx,
              icon: Icons.description_outlined,
              iconColor: AppColors.primary,
              title: 'CV requis',
              message:
                  'Ajoutez votre CV pour postuler aux offres qui vous intéressent. Cela ne prend que quelques minutes.',
              confirmLabel: 'Créer mon CV',
              cancelLabel: 'Plus tard',
            );
            if (goCreate == true) {
              Get.toNamed(AppRoutes.profileCvBuilder);
            }
            return;
          }
        }

        // Snackbar visible immédiatement — la notif reste pour l'historique,
        // mais l'utilisateur a besoin du feedback en direct après son swipe.
        Get.snackbar(
          title,
          body,
          backgroundColor: AppColors.errorSoft,
          colorText: AppColors.errorStrong,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 14,
          duration: const Duration(seconds: 4),
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
        // Overlay "C'est un match" affiche UNIQUEMENT apres confirmation
        // backend : pas de match si CV manquant ou autre echec.
        pendingMatch.value = HomeOfferMatchResult(
          offer: offer,
          score: serverScore,
        );
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
      // Échec réseau ou parsing : on prévient l'utilisateur via snackbar
      // (l'overlay match n'est pas affiché tant que l'API n'a pas confirmé).
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
