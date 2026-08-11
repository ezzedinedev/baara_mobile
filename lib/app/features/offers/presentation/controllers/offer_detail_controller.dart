import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:baara/app/core/services/offline_apply_queue.dart';
import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/utils/offline_error.dart';
import 'package:baara/app/core/utils/user_facing_error.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/app/core/widgets/common/app_toast.dart';
import 'package:baara/app/core/widgets/common/sheet_handle.dart';
import 'package:baara/app/core/widgets/common/success_sheet.dart';
import 'package:baara/app/core/widgets/effects/celebration_overlay.dart';
import 'package:baara/app/core/widgets/gradient_button.dart';
import 'package:baara/routes/app_routes.dart';
import '../../../../data/models/ai_models.dart';
import '../../../ia/domain/repositories/i_ia_repository.dart';
import '../../domain/entities/offer.dart';
import '../../domain/exceptions/missing_skills_exception.dart';
import '../../domain/repositories/i_offer_repository.dart';

class OfferDetailController extends GetxController {
  final IOfferRepository _repository;
  final IIaRepository _iaRepository;

  OfferDetailController(this._repository, this._iaRepository);

  final offer = Rxn<Offer>();
  final aiMatchScore = Rxn<AiMatchScore>();
  final isLoading = true.obs;
  final isAiLoading = false.obs;
  final errorMessage = RxnString();
  final isApplying = false.obs;
  final isAiActionLoading = false.obs;
  final hasApplied = false.obs;
  final isSaved = false.obs;
  final isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    final id = Get.parameters['id'];
    if (id != null) {
      fetchOfferDetail(id);
    } else {
      errorMessage.value = "ID de l'offre manquant";
      isLoading.value = false;
    }
  }

  Future<void> fetchOfferDetail(String id) async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      final result = await _repository.getOfferById(id);
      if (result != null) {
        offer.value = result;
        // Initialise l'état bouton depuis ce que le backend renvoie pour l'user
        // connecté (is_saved / is_applied). null = non auth → on laisse false.
        if (result.isSaved != null) isSaved.value = result.isSaved!;
        if (result.isApplied != null) hasApplied.value = result.isApplied!;
      } else {
        errorMessage.value = "Offre introuvable";
      }
    } catch (e) {
      errorMessage.value = "Erreur de chargement";
    } finally {
      isLoading.value = false;
    }
  }

  // NOTE: pas de score IA par offre ici. Le backend n'expose AUCUN endpoint de
  // score par offre — `POST /offers/{id}/match` est un alias de `apply`/`swipe`
  // qui CRÉE une candidature. L'appeler au chargement soumettait donc une
  // candidature fantôme à chaque consultation. Le score reste disponible en
  // masse via `/ai/match/feed` (feed "Pour vous"). Les observables
  // `aiMatchScore`/`isAiLoading` sont conservés : le banner se masque seul tant
  // qu'aucun score n'est fourni (cf. _buildAiMatchBanner).

  /// Candidature réelle à l'offre (POST /applications via le repo).
  Future<void> apply({Map<String, dynamic>? screeningAnswers}) async {
    final o = offer.value;
    if (o == null || isApplying.value || hasApplied.value) return;
    isApplying.value = true;
    try {
      final result = await _repository.applyToOffer(
        o.id,
        screeningAnswers: screeningAnswers,
      );
      hasApplied.value = true;
      // Le seuil de match est décidé par le backend (`matching.match_threshold`)
      // et porté par `isMatch` : le rejouer ici avec un 60 en dur désynchronise
      // l'app dès que la config serveur change.
      if (result.isMatch) {
        AppHaptics.success();
        Get.toNamed(AppRoutes.offerMatch, arguments: {
          'offerTitle': o.title,
          'company': o.company,
          'score': result.score,
        });
      } else {
        // Pas d'écran de match dédié ici : on célèbre la candidature envoyée
        // par un burst de confetti + haptique succès, puis une feuille de
        // confirmation (SuccessIllustration) si un contexte est disponible,
        // sinon un toast de repli.
        AppHaptics.success();
        showCelebration();
        _showApplySuccess(o);
      }
    } on MissingSkillsException catch (e) {
      // Pas une erreur à balayer d'un toast : la candidature aurait été
      // écartée automatiquement. On explique, et on emmène le candidat au bon
      // endroit plutôt que de le laisser buter sur le bouton.
      AppHaptics.error();
      _promptCompleteSkills(e.message);
    } catch (e) {
      if (isOfflineError(e)) {
        await _queueOffline(o, screeningAnswers: screeningAnswers);
      } else {
        AppToast.error('Candidature non envoyée', userFacingError(e));
      }
    } finally {
      isApplying.value = false;
    }
  }

  void _promptCompleteSkills(String message) {
    Get.bottomSheet<void>(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              const SizedBox(height: 12),
              Text(
                'Complétez vos compétences',
                style:
                    AppTextStyles.titleLg.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style:
                    AppTextStyles.bodyMd.copyWith(color: AppColors.bodyColor),
              ),
              const SizedBox(height: 20),
              GradientButton(
                label: 'COMPLÉTER MON CV',
                textColor: AppColors.onPrimary,
                height: 52,
                borderRadius: 14,
                onPressed: () {
                  AppHaptics.tap();
                  Get.back<void>();
                  Get.toNamed<void>(AppRoutes.profileCvManual);
                },
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  /// Hors-ligne : on met la candidature en file d'attente (renvoyee au retour
  /// du reseau) et on bascule l'etat en « postule » de facon optimiste.
  Future<void> _queueOffline(
    Offer o, {
    Map<String, dynamic>? screeningAnswers,
  }) async {
    await Get.find<OfflineApplyQueue>().enqueue(PendingApply(
      offerId: o.id,
      offerTitle: o.title,
      company: o.company,
      logoUrl: o.companyLogo,
      queuedAt: DateTime.now(),
      screeningAnswers: screeningAnswers,
    ));
    hasApplied.value = true;
    AppHaptics.success();
    AppToast.info(
      'Candidature enregistrée',
      'Hors ligne — elle sera envoyée dès le retour du réseau.',
    );
  }

  /// Affiche la confirmation de candidature envoyée : feuille de succès
  /// (SuccessIllustration) si un contexte est disponible, sinon toast de repli.
  /// Méthode synchrone → pas d'usage de BuildContext à travers un gap async.
  void _showApplySuccess(Offer o) {
    final ctx = Get.context;
    if (ctx == null) {
      AppToast.action(
        title: 'Candidature envoyée',
        message: '${o.company} · ${o.title}',
        actionLabel: 'Voir mon suivi',
        onAction: () =>
            Get.offAllNamed(AppRoutes.home, arguments: {'tab': 3}),
      );
      return;
    }
    showSuccessSheet(
      ctx,
      title: 'Candidature envoyée !',
      message: '${o.company} · ${o.title}\n'
          'Votre candidature a bien été transmise au recruteur.',
    );
  }

  Future<Map<String, dynamic>?> adaptCv() async {
    final o = offer.value;
    if (o == null || isAiActionLoading.value) return null;
    isAiActionLoading.value = true;
    try {
      return await _iaRepository.cvAdapt(o.id);
    } catch (e) {
      AppToast.error('CV non adapté', userFacingError(e));
      return null;
    } finally {
      isAiActionLoading.value = false;
    }
  }

  /// Adapte le CV à l'offre, enregistre les suggestions, puis postule.
  ///
  /// Trois appels distincts, et c'est nécessaire : `/ai/cv/adapt/apply` veut
  /// dire « appliquer les suggestions AU CV » — il ne crée aucune candidature.
  /// L'implémentation précédente l'appelait seul, avec `offer_id` au lieu de
  /// `suggestions` : elle repartait en 422 sans jamais rien envoyer, tout en
  /// affichant « Candidature envoyée ».
  Future<void> adaptCvAndApply() async {
    final o = offer.value;
    if (o == null || isAiActionLoading.value || hasApplied.value) return;
    isAiActionLoading.value = true;
    try {
      final adaptation = await _iaRepository.cvAdapt(o.id);
      final suggestions = adaptation['suggestions'];
      if (suggestions is Map<String, dynamic> && suggestions.isNotEmpty) {
        // Non bloquant : si aucune suggestion n'est applicable (422
        // `no_applicable_suggestion`), le CV reste tel quel et on postule
        // quand même — l'utilisateur a demandé à candidater, pas à éditer.
        try {
          await _iaRepository.cvAdaptApply(suggestions);
        } catch (_) {}
      }
    } catch (e) {
      AppToast.error('CV non adapté', userFacingError(e));
      isAiActionLoading.value = false;
      return;
    }
    isAiActionLoading.value = false;
    // `apply()` porte déjà la candidature réelle, la file hors-ligne, l'écran
    // de match et la bascule `hasApplied`.
    await apply();
  }

  /// Toggle favori optimiste : on bascule l'état localement tout de suite, puis
  /// on confirme côté API (save/unsave). En cas d'échec, on rétablit l'état et
  /// on prévient l'utilisateur.
  Future<void> toggleSave() async {
    final currentOffer = offer.value;
    if (currentOffer == null || isSaving.value) return;

    final previous = isSaved.value;
    final next = !previous;
    isSaved.value = next; // optimiste
    isSaving.value = true;
    try {
      final success = next
          ? await _repository.saveOffer(currentOffer.id)
          : await _repository.unsaveOffer(currentOffer.id);
      if (!success) {
        isSaved.value = previous; // rollback
        AppToast.error('Action impossible', 'Réessaie dans un instant.');
        return;
      }
      if (next) {
        AppToast.success('Offre enregistrée', currentOffer.title);
      } else {
        AppToast.info('Retirée des favoris', currentOffer.title);
      }
    } catch (e) {
      isSaved.value = previous; // rollback
      AppToast.error('Action impossible', userFacingError(e));
    } finally {
      isSaving.value = false;
    }
  }
}
