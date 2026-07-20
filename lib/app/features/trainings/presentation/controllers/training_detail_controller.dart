import 'package:get/get.dart';

import '../../../../core/utils/user_facing_error.dart';
import '../../domain/entities/training.dart';
import '../../domain/repositories/i_training_repository.dart';

/// Détail d'une formation. L'id provient du paramètre de route `:id`
/// (cf. trainings_screen → Get.toNamed(trainingDetail.replaceFirst(':id', id))).
class TrainingDetailController extends GetxController {
  TrainingDetailController(this._repository);

  final ITrainingRepository _repository;

  final isLoading = true.obs;
  final errorMessage = RxnString();
  final Rxn<Training> training = Rxn<Training>();
  final isEnrolling = false.obs;
  final isSubmittingReview = false.obs;
  // Vrai dès qu'une inscription réussit dans cette session — l'entité Training
  // est immuable, donc on s'appuie sur ce flag pour basculer le bouton bas en
  // « Continuer » sans recharger.
  final justEnrolled = false.obs;

  /// L'utilisateur a-t-il accès au parcours (déjà inscrit ou vient de s'inscrire) ?
  bool get isEnrolled =>
      justEnrolled.value || (training.value?.isEnrolled ?? false);

  /// Id figé au montage : `Get.parameters` suit la route courante, donc le
  /// relire après une navigation (quiz, paiement…) viserait la mauvaise entité.
  late final String? _id =
      Get.parameters['id'] ?? Get.arguments?.toString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    final id = _id;
    if (id == null || id.isEmpty) {
      isLoading.value = false;
      errorMessage.value = 'Formation introuvable.';
      return;
    }
    isLoading.value = true;
    errorMessage.value = null;
    try {
      training.value = await _repository.getTrainingById(id);
      if (training.value == null) {
        errorMessage.value = 'Cette formation n\'existe plus.';
      }
    } catch (e) {
      errorMessage.value = userFacingError(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// [applicationData] : le dossier d'inscription, quand le formateur l'exige.
  Future<bool> enroll({Map<String, dynamic>? applicationData}) async {
    final t = training.value;
    if (t == null || isEnrolling.value) return false;
    isEnrolling.value = true;
    try {
      final ok = await _repository.enrollInTraining(
        t.id,
        applicationData: applicationData,
      );
      if (ok) justEnrolled.value = true;
      return ok;
    } catch (_) {
      return false;
    } finally {
      isEnrolling.value = false;
    }
  }

  Future<bool> submitReview({required int rating, String? comment}) async {
    final t = training.value;
    if (t == null || isSubmittingReview.value) return false;
    isSubmittingReview.value = true;
    try {
      return await _repository.reviewTraining(
        t.id,
        rating: rating,
        comment: comment,
      );
    } catch (_) {
      return false;
    } finally {
      isSubmittingReview.value = false;
    }
  }
}
