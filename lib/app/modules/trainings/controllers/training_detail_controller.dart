import 'package:get/get.dart';

import '../../../data/providers/api_provider.dart';
import '../models/training_model.dart';
import '../repositories/training_repository.dart';

/// Controller dedie au detail d'une formation. Lit l'identifiant via
/// `Get.parameters['id']` et charge la formation via
/// [TrainingRepository.getTrainingById]. Etat independant du listing.
class TrainingDetailController extends GetxController {
  TrainingDetailController({ApiProvider? apiProvider}) {
    _repository = TrainingRepository(apiProvider: apiProvider ?? Get.find());
  }

  late final TrainingRepository _repository;

  final training = Rxn<TrainingModel>();
  final isLoading = false.obs;
  final isEnrolling = false.obs;
  final errorMessage = ''.obs;

  String? _trainingId;

  @override
  void onInit() {
    super.onInit();
    _trainingId = Get.parameters['id'];
    if (_trainingId == null || _trainingId!.isEmpty) {
      errorMessage.value = 'Identifiant de formation manquant.';
      return;
    }
    loadTraining();
  }

  Future<void> loadTraining() async {
    final id = _trainingId;
    if (id == null || id.isEmpty) return;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final result = await _repository.getTrainingById(id);
      if (result == null) {
        errorMessage.value = 'Formation introuvable.';
      } else {
        training.value = result;
      }
    } catch (e) {
      errorMessage.value = _friendlyError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshTraining() async => loadTraining();

  /// Inscrit l'utilisateur a la formation puis met a jour `training.isEnrolled`
  /// localement pour basculer le CTA. Renvoie le succes pour permettre a la UI
  /// d'afficher un toast adapte.
  Future<bool> enroll() async {
    final current = training.value;
    if (current == null || isEnrolling.value) return false;

    isEnrolling.value = true;
    try {
      final success = await _repository.enrollToTraining(current.id);
      if (success) {
        // Reflete localement l'etat inscrit (le backend renverra le flag a la
        // prochaine recharge mais on evite un round-trip).
        training.value = TrainingModel(
          id: current.id,
          title: current.title,
          providerName: current.providerName,
          providerLogo: current.providerLogo,
          location: current.location,
          format: current.format,
          level: current.level,
          lessons: current.lessons,
          rating: current.rating,
          enrolledCount: current.enrolledCount + 1,
          status: current.status,
          priceLabel: current.priceLabel,
          price: current.price,
          sector: current.sector,
          description: current.description,
          durationLabel: current.durationLabel,
          startDateLabel: current.startDateLabel,
          deadlineLabel: current.deadlineLabel,
          certificationLabel: current.certificationLabel,
          languageLabel: current.languageLabel,
          objectives: current.objectives,
          requirements: current.requirements,
          modules: current.modules,
          contactLabel: current.contactLabel,
          isBookmarked: current.isBookmarked,
          isEnrolled: true,
          coverUrl: current.coverUrl,
        );
      }
      return success;
    } catch (_) {
      return false;
    } finally {
      isEnrolling.value = false;
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('Unable to connect')) {
      return 'Connexion impossible. Verifiez votre reseau.';
    }
    return 'Erreur lors du chargement de la formation.';
  }
}
