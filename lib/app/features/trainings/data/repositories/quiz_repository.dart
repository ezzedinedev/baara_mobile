import 'package:jobaway/app/core/constants/api_constants.dart';
import 'package:jobaway/app/core/network/api_provider.dart';

import '../../domain/entities/quiz.dart';

/// Accès aux quiz. Toute la logique de notation est côté serveur : ici on ne
/// fait que transporter l'épreuve et les réponses.
/// cf. QuizApiController (index / start / submit / incident).
class QuizRepository {
  const QuizRepository({required ApiProvider apiProvider})
      : _apiProvider = apiProvider;

  final ApiProvider _apiProvider;

  /// Quiz d'un module, tels que servis à cet apprenant (variante A/B comprise).
  Future<List<QuizSummary>> quizzesOfModule(String moduleId) async {
    final data = _unwrap(
      await _apiProvider.getJson(ApiConstants.quizzesOfModule(moduleId)),
    );
    final raw = data['quizzes'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => QuizSummary.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  /// Démarre (ou reprend) une tentative. Le serveur tire les questions et pose
  /// l'échéance : relancer l'app ne redonne ni un nouveau tirage ni du temps.
  Future<QuizAttempt> start(String quizId) async {
    final data = _unwrap(
      await _apiProvider.postJson(ApiConstants.quizStart(quizId), const {}),
    );
    return QuizAttempt.fromJson(data);
  }

  /// Envoie les réponses (identifiants d'options) et récupère la correction.
  Future<QuizResult> submit(
    String quizId, {
    required Map<String, String> answers,
  }) async {
    final data = _unwrap(
      await _apiProvider.postJson(
        ApiConstants.quizSubmit(quizId),
        {'answers': answers},
      ),
    );
    return QuizResult.fromJson(data);
  }

  /// Journalise un incident de surveillance. Volontairement tolérant : un
  /// incident qui n'arrive pas à partir ne doit pas casser l'épreuve en cours.
  Future<void> reportIncident(
    String quizId, {
    required QuizIncidentType type,
    String? context,
  }) async {
    try {
      await _apiProvider.postJson(
        ApiConstants.quizIncident(quizId),
        {
          'type': type.wire,
          if (context != null && context.isNotEmpty) 'context': context,
        },
      );
    } catch (_) {
      // Silencieux : l'incident est perdu, la tentative continue.
    }
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic> response) {
    final statusCode = response['statusCode'] as int?;
    final success = response['success'] as bool? ??
        (statusCode != null && statusCode < 400);
    if (!success) {
      throw ApiException(
        message: response['message']?.toString() ?? 'Quiz indisponible.',
        statusCode: statusCode,
      );
    }
    final data = response['data'];
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }
}
