import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../core/services/quiz_proctoring_service.dart';
import '../../../../core/utils/user_facing_error.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/repositories/quiz_repository.dart';
import '../../domain/entities/quiz.dart';

/// Déroulé d'une tentative de quiz, surveillance comprise.
///
/// Le contrôleur ne décide de rien : il ne connaît pas les bonnes réponses, ne
/// calcule pas le score, et n'invalide pas la tentative. Il transporte les
/// réponses, affiche le temps que le serveur lui a annoncé, et **signale** les
/// écarts. Toutes les sanctions sont prononcées par le backend — un client
/// modifié ne peut donc que se dénoncer moins, pas se noter mieux.
///
/// Surveillance stricte, telle que demandée :
/// - capture d'écran bloquée (Android) ou détectée et signalée (iOS) ;
/// - sortie de l'app pendant l'épreuve = incident **et soumission immédiate**
///   de la tentative en l'état ;
/// - temps écoulé = soumission automatique (le serveur refuse de toute façon
///   une réponse hors délai).
class QuizController extends GetxController with WidgetsBindingObserver {
  QuizController(this._repository);

  final QuizRepository _repository;

  final isLoading = true.obs;
  final isSubmitting = false.obs;
  final errorMessage = RxnString();

  final Rxn<QuizAttempt> attempt = Rxn<QuizAttempt>();
  final Rxn<QuizResult> result = Rxn<QuizResult>();

  /// question_id → option_id.
  final answers = <String, String>{}.obs;
  final currentIndex = 0.obs;
  final secondsRemaining = 0.obs;

  /// Incidents signalés pendant CETTE tentative — sert uniquement à prévenir
  /// l'apprenant ; le décompte qui compte est celui du serveur.
  final incidentCount = 0.obs;

  Timer? _ticker;
  bool _finished = false;

  String get _quizId => Get.parameters['id'] ?? Get.arguments?.toString() ?? '';

  List<QuizQuestion> get questions => attempt.value?.questions ?? const [];

  QuizQuestion? get currentQuestion =>
      currentIndex.value < questions.length ? questions[currentIndex.value] : null;

  bool get isLastQuestion => currentIndex.value >= questions.length - 1;

  bool get allAnswered =>
      questions.isNotEmpty && questions.every((q) => answers.containsKey(q.id));

  int get answeredCount => answers.length;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    start();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    QuizProctoringService.instance.stop();
    super.onClose();
  }

  Future<void> start() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final started = await _repository.start(_quizId);
      attempt.value = started;
      secondsRemaining.value = started.secondsRemaining;
      _startTicker();

      await QuizProctoringService.instance.start(
        onScreenshot: () => _reportIncident(QuizIncidentType.screenshot),
      );
    } catch (e) {
      errorMessage.value = userFacingError(e);
    } finally {
      isLoading.value = false;
    }
  }

  void selectOption(String questionId, String optionId) {
    answers[questionId] = optionId;
  }

  void next() {
    if (!isLastQuestion) currentIndex.value++;
  }

  void previous() {
    if (currentIndex.value > 0) currentIndex.value--;
  }

  void goTo(int index) {
    if (index >= 0 && index < questions.length) currentIndex.value = index;
  }

  /// Soumission volontaire. Le serveur corrige et tranche.
  Future<void> submit() async {
    await _submit();
  }

  // ── Surveillance ────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_finished || attempt.value == null) return;

    // L'app quitte le premier plan : consultation d'une autre app, écran
    // partagé, barre de notifications tirée à fond… On signale, puis on rend
    // la copie en l'état. C'est le contrat « strict » : quitter l'épreuve, c'est
    // la terminer.
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _reportIncident(QuizIncidentType.appBackgrounded);
      _submit(reason: _EndReason.leftApp);
    }
  }

  void _reportIncident(QuizIncidentType type) {
    if (_finished) return;
    incidentCount.value++;
    _repository.reportIncident(_quizId, type: type);
  }

  // ── Interne ─────────────────────────────────────────────────────────────

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (secondsRemaining.value <= 0) {
        _ticker?.cancel();
        _submit(reason: _EndReason.timeout);
        return;
      }
      secondsRemaining.value--;
    });
  }

  Future<void> _submit({_EndReason reason = _EndReason.manual}) async {
    if (_finished || isSubmitting.value || attempt.value == null) return;
    isSubmitting.value = true;
    _ticker?.cancel();

    try {
      // Les questions sans réponse partent vides : le serveur les compte comme
      // fausses. On ne bloque pas une soumission forcée (temps écoulé, sortie
      // d'app) pour cause de questionnaire incomplet.
      final payload = <String, String>{
        for (final q in questions) q.id: answers[q.id] ?? '',
      };
      if (reason == _EndReason.manual) {
        payload.removeWhere((_, value) => value.isEmpty);
      }

      result.value = await _repository.submit(_quizId, answers: payload);

      // La copie n'est close qu'une fois le serveur ayant répondu. La marquer
      // close avant l'appel condamnait la tentative au moindre échec réseau :
      // plus aucune soumission n'était acceptée, et la copie était perdue.
      _finished = true;
      await QuizProctoringService.instance.stop();
    } catch (e) {
      // Une soumission qui échoue ne doit pas faire disparaître la copie sous
      // un écran d'erreur : on prévient, et l'épreuve reprend là où elle en
      // était. Le chronomètre serveur, lui, n'a jamais été mis en pause.
      AppToast.error('Envoi impossible', userFacingError(e));
      _startTicker();
    } finally {
      isSubmitting.value = false;
    }
  }
}

enum _EndReason { manual, timeout, leftApp }
