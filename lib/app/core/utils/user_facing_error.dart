import '../network/api_provider.dart';

String userFacingError(Object error) {
  if (error is ApiException) {
    final code = error.statusCode;
    final raw = error.message.toLowerCase();

    if (raw.contains('unable to connect') ||
        raw.contains('connection refused') ||
        raw.contains('failed host lookup') ||
        raw.contains('network is unreachable') ||
        code == null) {
      return 'Connexion impossible. Vérifiez votre réseau ou réessayez dans un instant.';
    }
    if (code == 401 || code == 403) {
      return 'Email ou mot de passe incorrect.';
    }
    if (code == 422 || code == 400) {
      return error.message.isNotEmpty
          ? error.message
          : 'Vérifiez les informations saisies.';
    }
    if (code >= 500) {
      return 'Le serveur est indisponible. Réessayez plus tard.';
    }
    return error.message;
  }

  final text = error.toString();
  if (text.contains('SocketException') ||
      text.contains('ClientException') ||
      text.contains('HandshakeException') ||
      text.contains('Failed to fetch')) {
    return 'Connexion impossible. Vérifiez votre réseau ou réessayez dans un instant.';
  }


  if (error is Error) {
    return 'Une erreur inattendue est survenue. Réessayez dans un instant.';
  }

  final cleaned = text
      .replaceFirst(RegExp(r'^ApiException:\s*'), '')
      .replaceFirst(RegExp(r'^Exception:\s*'), '')
      .replaceFirst(RegExp(r'\s*\(status:.*\)$'), '')
      .trim();

  // Garde-fou : si le message ressemble encore à un dump technique, message générique.
  if (cleaned.isEmpty || cleaned.contains('TypeError') || cleaned.contains("is not a subtype")) {
    return 'Une erreur inattendue est survenue. Réessayez dans un instant.';
  }
  return cleaned;
}
