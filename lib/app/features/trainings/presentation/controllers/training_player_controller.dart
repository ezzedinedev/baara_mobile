import 'package:get/get.dart';

import '../../../../core/utils/user_facing_error.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/training.dart';
import '../../domain/repositories/i_training_repository.dart';

/// Lecteur de modules d'une formation suivie : liste les modules,
/// affiche la progression globale et permet de marquer un module
/// comme terminé (POST trainingProgress). L'id provient du paramètre
/// de route `:id` ou de [Get.arguments].
class TrainingPlayerController extends GetxController {
  TrainingPlayerController(this._repository);

  final ITrainingRepository _repository;

  final isLoading = true.obs;
  final errorMessage = RxnString();
  final Rxn<Training> training = Rxn<Training>();

  /// Ids des modules terminés (état serveur + complétions locales optimistes).
  final RxSet<String> completedIds = <String>{}.obs;

  /// Id du module en cours d'envoi (pour l'indicateur de chargement).
  final updatingId = RxnString();

  String? get _id => Get.parameters['id'] ?? Get.arguments?.toString();

  List<TrainingModule> get modules => training.value?.modules ?? const [];

  int get completedCount => completedIds.length;

  int get totalCount => modules.length;

  double get progress => totalCount == 0 ? 0 : completedCount / totalCount;

  bool isCompleted(TrainingModule module) => completedIds.contains(module.id);

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
      final t = await _repository.getTrainingById(id);
      training.value = t;
      if (t == null) {
        errorMessage.value = 'Cette formation n\'existe plus.';
        return;
      }
      completedIds
        ..clear()
        ..addAll(t.modules.where((m) => m.isCompleted).map((m) => m.id));
    } catch (e) {
      errorMessage.value = userFacingError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markCompleted(TrainingModule module) async {
    final t = training.value;
    if (t == null || updatingId.value != null) return;
    if (isCompleted(module)) return;
    updatingId.value = module.id;
    try {
      // Envoie l'ensemble complet (déjà terminés + le nouveau) : le backend
      // remplace modules_completed par cette liste, sans fusion.
      final ok = await _repository.updateProgress(
        t.id,
        completedModuleIds: {...completedIds, module.id},
      );
      if (ok) {
        completedIds.add(module.id);
        if (completedCount >= totalCount && totalCount > 0) {
          AppToast.success(
            'Formation terminée',
            'Vous avez complété tous les modules.',
          );
        } else {
          AppToast.success('Module terminé', 'Progression enregistrée.');
        }
      } else {
        AppToast.error(
          'Échec',
          'Impossible d\'enregistrer la progression.',
        );
      }
    } catch (e) {
      AppToast.error('Échec', userFacingError(e));
    } finally {
      updatingId.value = null;
    }
  }
}
