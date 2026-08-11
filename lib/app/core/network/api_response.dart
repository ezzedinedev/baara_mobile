import 'api_provider.dart';

/// Utilitaires partagés pour interpréter les réponses JSON de l'API Laravel.
class ApiResponse {
  ApiResponse._();

  /// Lance [ApiValidationException] ou [ApiException] si la réponse indique un échec.
  ///
  /// Tous les endpoints ne posent pas le champ `success` : ceux qui n'héritent
  /// pas de l'enveloppe `ApiController::success()` côté Laravel répondent en
  /// `{'data': ...}` nu avec un HTTP 200 (entretiens, offres d'emploi…). Un
  /// `success` absent est donc arbitré par le code HTTP, jamais traité comme un
  /// échec — sinon ces routes échoueraient alors qu'elles ont réussi.
  /// Seul un `success: false` explicite, ou un statut >= 400, est un échec.
  static void ensureSuccess(
    Map<String, dynamic> response, {
    String fallback = 'Requête impossible.',
  }) {
    final statusCode = response['statusCode'] as int?;
    if (statusCode != null && statusCode >= 400) {
      throw _failure(response, statusCode, fallback);
    }
    final success = response['success'] as bool? ??
        (statusCode != null && statusCode < 400);
    if (!success) {
      throw _failure(response, statusCode, fallback);
    }
  }

  static Exception _failure(
    Map<String, dynamic> response,
    int? statusCode,
    String fallback,
  ) {
    final validation = ApiValidationException.tryFrom(response);
    if (validation != null) return validation;
    return ApiException(
      message: response['message']?.toString() ?? fallback,
      statusCode: statusCode,
    );
  }

  static List<dynamic> extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      if (data['items'] is List) return data['items'] as List;
      if (data['data'] is List) return data['data'] as List;
    }
    return const [];
  }

  static Map<String, dynamic>? extractItem(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['item'] is Map<String, dynamic>) {
        return data['item'] as Map<String, dynamic>;
      }
      return data;
    }
    return null;
  }

  /// `data` sous forme d'objet. Tolérant par défaut : un `data` absent, nul ou
  /// d'une autre forme (liste, scalaire) rend une map vide plutôt que de lever
  /// un `TypeError` de cast — l'échec réel est déjà arbitré par [ensureSuccess].
  static Map<String, dynamic> dataMap(Map<String, dynamic> response) {
    final data = response['data'];
    return data is Map<String, dynamic> ? data : const {};
  }

  /// Déduit `hasMore` depuis l'enveloppe paginée Laravel (`items`, `has_more`,
  /// `current_page`, `last_page`) ou, à défaut, depuis la taille de la page.
  static bool hasMorePages(
    dynamic data, {
    required int pageSize,
    required int itemCount,
  }) {
    if (data is Map<String, dynamic>) {
      if (data['has_more'] == true) return true;
      if (data['has_more'] == false) return false;
      final current = (data['current_page'] as num?)?.toInt();
      final last = (data['last_page'] as num?)?.toInt();
      if (current != null && last != null) return current < last;
    }
    return itemCount >= pageSize;
  }

  static int currentPage(dynamic data, {required int fallback}) {
    if (data is Map<String, dynamic>) {
      return (data['current_page'] as num?)?.toInt() ?? fallback;
    }
    return fallback;
  }
}
