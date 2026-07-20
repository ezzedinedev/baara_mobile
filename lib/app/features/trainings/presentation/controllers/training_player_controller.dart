import 'package:get/get.dart';

import '../../../../core/utils/user_facing_error.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/repositories/quiz_repository.dart';
import '../../domain/entities/quiz.dart';
import '../../domain/entities/training.dart';
import '../../domain/repositories/i_training_repository.dart';

/// Lecteur de modules d'une formation suivie : liste les modules,
/// affiche la progression globale et permet de marquer un module
/// comme terminé (POST trainingProgress). L'id provient du paramètre
/// de route `:id` ou de [Get.arguments].
class TrainingPlayerController extends GetxController {
  TrainingPlayerController(this._repository, this._quizRepository);

  final ITrainingRepository _repository;
  final QuizRepository _quizRepository;

  /// Chargement des quiz d'un module, le temps d'ouvrir l'épreuve.
  final loadingQuizModuleId = RxnString();

  final isLoading = true.obs;
  final errorMessage = RxnString();
  final Rxn<Training> training = Rxn<Training>();

  /// Ids des modules terminés (état serveur + complétions locales optimistes).
  final RxSet<String> completedIds = <String>{}.obs;

  /// Id du module en cours d'envoi (pour l'indicateur de chargement).
  final updatingId = RxnString();

  /// Id figé au montage, et non relu à chaque appel.
  ///
  /// `Get.parameters` reflète la route COURANTE : en revenant du quiz (dont la
  /// route porte aussi un paramètre `:id`), un rechargement allait chercher la
  /// formation avec l'identifiant du quiz — et affichait « Cette formation
  /// n'existe plus » à la sortie de chaque épreuve.
  late final String? _id =
      Get.parameters['id'] ?? Get.arguments?.toString();

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
      // Dernier verrou avant le contenu : le lecteur ne doit jamais s'ouvrir sur
      // une formation non honorée (payante non payée). Le backend ne renvoie de
      // toute façon plus les URLs des leçons dans ce cas.
      if (!t.isEnrolled) {
        errorMessage.value =
            'Inscrivez-vous à cette formation pour accéder aux leçons.';
        return;
      }
      completedIds
        ..clear()
        ..addAll(t.modules.where((m) => m.isCompleted).map((m) => m.id));

      await _loadQuizStates(t);
    } catch (e) {
      errorMessage.value = userFacingError(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// État des quiz, chargé avec la formation.
  ///
  /// L'apprenant doit voir d'un coup d'œil où il en est — quiz déjà validé,
  /// meilleur score, tentatives restantes — sans avoir à ouvrir l'épreuve pour
  /// le découvrir.
  final quizzesByModule = <String, List<QuizSummary>>{}.obs;

  Future<void> _loadQuizStates(Training training) async {
    final modules = training.modules.where((m) => m.hasQuiz).toList();
    if (modules.isEmpty) {
      quizzesByModule.clear();
      return;
    }

    final results = await Future.wait(
      modules.map((m) async {
        try {
          return MapEntry(m.id, await _quizRepository.quizzesOfModule(m.id));
        } catch (_) {
          // Un module dont les quiz ne se chargent pas ne doit pas faire
          // échouer tout le parcours : la carte reste, sans état.
          return MapEntry(m.id, <QuizSummary>[]);
        }
      }),
    );

    quizzesByModule.assignAll(Map.fromEntries(results));
  }

  List<QuizSummary> quizzesFor(TrainingModule module) =>
      quizzesByModule[module.id] ?? const [];

  /// Quiz d'un module, rafraîchis à la demande (variante A/B choisie par le
  /// serveur). L'épreuve elle-même n'est jamais chargée ici : elle n'est tirée
  /// qu'au démarrage de la tentative.
  Future<List<QuizSummary>> quizzesOf(TrainingModule module) async {
    final cached = quizzesFor(module);
    if (cached.isNotEmpty) return cached;

    if (loadingQuizModuleId.value != null) return const [];
    loadingQuizModuleId.value = module.id;
    try {
      final quizzes = await _quizRepository.quizzesOfModule(module.id);
      quizzesByModule[module.id] = quizzes;
      return quizzes;
    } catch (e) {
      AppToast.error('Quiz indisponible', userFacingError(e));
      return const [];
    } finally {
      loadingQuizModuleId.value = null;
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
