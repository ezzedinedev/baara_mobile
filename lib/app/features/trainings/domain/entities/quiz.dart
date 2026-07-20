// Modèles du quiz.
//
// Rien ici ne permet de connaître la bonne réponse : le serveur n'envoie que
// des libellés d'options, corrige lui-même et renvoie le score. C'est la base
// de l'anti-triche — un client compromis ne peut pas lire le corrigé, parce
// qu'il ne l'a jamais reçu.

/// Règles de surveillance annoncées par le serveur pour ce quiz.
class QuizProctoring {
  const QuizProctoring({this.alertThreshold, this.autoFail = false});

  factory QuizProctoring.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const QuizProctoring();
    return QuizProctoring(
      alertThreshold: _asIntOrNull(json['alert_threshold']),
      autoFail: json['auto_fail'] == true,
    );
  }

  /// Nombre d'incidents graves à partir duquel l'épreuve est signalée.
  final int? alertThreshold;

  /// Au-delà du seuil, la tentative est invalidée (décision serveur).
  final bool autoFail;
}

/// Un quiz tel que présenté avant de commencer.
class QuizSummary {
  const QuizSummary({
    required this.id,
    required this.title,
    this.instructions,
    required this.durationMinutes,
    required this.passingScore,
    this.maxAttempts,
    required this.attemptsUsed,
    this.remainingAttempts,
    this.bestScore,
    required this.passed,
    required this.hasActiveAttempt,
    required this.proctoring,
  });

  factory QuizSummary.fromJson(Map<String, dynamic> json) {
    return QuizSummary(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Quiz',
      instructions: json['instructions']?.toString(),
      durationMinutes: _asInt(json['duration_minutes']),
      passingScore: _asInt(json['passing_score']),
      maxAttempts: _asIntOrNull(json['max_attempts']),
      attemptsUsed: _asInt(json['attempts_used']),
      remainingAttempts: _asIntOrNull(json['remaining_attempts']),
      bestScore: _asIntOrNull(json['best_score']),
      passed: json['passed'] == true,
      hasActiveAttempt: json['has_active_attempt'] == true,
      proctoring: QuizProctoring.fromJson(
        json['proctoring'] is Map
            ? Map<String, dynamic>.from(json['proctoring'] as Map)
            : null,
      ),
    );
  }

  final String id;
  final String title;
  final String? instructions;
  final int durationMinutes;
  final int passingScore;
  final int? maxAttempts;
  final int attemptsUsed;
  final int? remainingAttempts;
  final int? bestScore;
  final bool passed;
  final bool hasActiveAttempt;
  final QuizProctoring proctoring;

  bool get isExhausted => remainingAttempts != null && remainingAttempts! <= 0;
}

class QuizOption {
  const QuizOption({required this.id, required this.text});

  factory QuizOption.fromJson(Map<String, dynamic> json) => QuizOption(
        id: json['id']?.toString() ?? '',
        text: json['text']?.toString() ?? '',
      );

  final String id;
  final String text;
}

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.prompt,
    required this.points,
    required this.options,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final raw = json['options'];
    return QuizQuestion(
      id: json['id']?.toString() ?? '',
      prompt: json['prompt']?.toString() ?? '',
      points: _asInt(json['points']),
      options: raw is List
          ? raw
              .whereType<Map>()
              .map((o) => QuizOption.fromJson(Map<String, dynamic>.from(o)))
              .toList(growable: false)
          : const [],
    );
  }

  final String id;
  final String prompt;
  final int points;
  final List<QuizOption> options;
}

/// Une tentative en cours : l'épreuve tirée pour ce candidat, et l'échéance.
class QuizAttempt {
  const QuizAttempt({
    required this.quizId,
    required this.title,
    this.instructions,
    required this.passingScore,
    required this.durationMinutes,
    required this.secondsRemaining,
    required this.attemptNumber,
    required this.questions,
    required this.proctoring,
  });

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    final raw = json['questions'];
    return QuizAttempt(
      quizId: json['quiz_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Quiz',
      instructions: json['instructions']?.toString(),
      passingScore: _asInt(json['passing_score']),
      durationMinutes: _asInt(json['duration_minutes']),
      secondsRemaining: _asInt(json['seconds_remaining']),
      attemptNumber: _asInt(json['attempt_number']),
      questions: raw is List
          ? raw
              .whereType<Map>()
              .map((q) => QuizQuestion.fromJson(Map<String, dynamic>.from(q)))
              .toList(growable: false)
          : const [],
      proctoring: QuizProctoring.fromJson(
        json['proctoring'] is Map
            ? Map<String, dynamic>.from(json['proctoring'] as Map)
            : null,
      ),
    );
  }

  final String quizId;
  final String title;
  final String? instructions;
  final int passingScore;
  final int durationMinutes;

  /// Temps restant annoncé par le serveur au moment de la réponse. On ne se fie
  /// pas à l'horloge du téléphone, qui peut être reculée à la main.
  final int secondsRemaining;
  final int attemptNumber;
  final List<QuizQuestion> questions;
  final QuizProctoring proctoring;
}

/// Résultat renvoyé après correction serveur.
class QuizResult {
  const QuizResult({
    required this.expired,
    required this.scorePct,
    required this.passingScore,
    required this.passed,
    required this.earnedPoints,
    required this.totalPoints,
    required this.attemptNumber,
    this.remainingAttempts,
    required this.incidentCount,
    required this.severeIncidentCount,
    required this.alertTriggered,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      expired: json['expired'] == true,
      scorePct: _asInt(json['score_pct']),
      passingScore: _asInt(json['passing_score']),
      passed: json['passed'] == true,
      earnedPoints: _asInt(json['earned_points']),
      totalPoints: _asInt(json['total_points']),
      attemptNumber: _asInt(json['attempt_number']),
      remainingAttempts: _asIntOrNull(json['remaining_attempts']),
      incidentCount: _asInt(json['incident_count']),
      severeIncidentCount: _asInt(json['proctoring_severe_count']),
      alertTriggered: json['proctoring_alert_triggered'] == true,
    );
  }

  /// Temps écoulé : la tentative a été enregistrée à 0 par le serveur.
  final bool expired;
  final int scorePct;
  final int passingScore;
  final bool passed;
  final int earnedPoints;
  final int totalPoints;
  final int attemptNumber;
  final int? remainingAttempts;
  final int incidentCount;
  final int severeIncidentCount;

  /// La surveillance a franchi le seuil : l'employeur est notifié, et la
  /// tentative est invalidée si le quiz est en invalidation automatique.
  final bool alertTriggered;
}

/// Incidents de surveillance remontés au serveur. Les valeurs sont celles
/// acceptées par l'API (`HandlesQuizAttempts::allowedIncidentTypes`).
enum QuizIncidentType {
  appBackgrounded('app_backgrounded'),
  screenshot('screenshot'),
  splitScreen('split_screen'),
  copy('copy'),
  paste('paste');

  const QuizIncidentType(this.wire);

  final String wire;
}

int _asInt(dynamic value) {
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _asIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.round();
  return int.tryParse(value.toString());
}
