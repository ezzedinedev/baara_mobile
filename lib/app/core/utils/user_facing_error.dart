import '../network/api_provider.dart';
import 'candidate_access.dart';

const String _genericError =
    'Une erreur est survenue. Réessayez dans un instant.';
const String _networkError =
    'Connexion impossible. Vérifiez votre réseau ou réessayez dans un instant.';
const String _serverError = 'Le serveur est indisponible. Réessayez plus tard.';

/// Détecte un contenu technique/sensible (SQL, stack trace, chemins, classes
/// internes, HTML d'erreur…) qui ne doit JAMAIS s'afficher à l'utilisateur —
/// surface d'info exploitable par un attaquant.
bool _looksTechnical(String s) {
  final l = s.toLowerCase();
  const markers = [
    'sqlstate',
    'sql:',
    'queryexception',
    'pdoexception',
    'unknown column',
    'integrity constraint',
    'foreign key',
    'stack trace',
    '#0 ',
    'errno',
    'vendor\\',
    'vendor/',
    'illuminate\\',
    'symfony',
    'whoops',
    'typeerror',
    'is not a subtype',
    'nosuchmethoderror',
    'rangeerror',
    '<!doctype',
    '<html',
    '<br',
    'fatal error',
    'undefined ',
    '.php',
    'at line',
    'call to ',
  ];
  if (markers.any(l.contains)) return true;
  // Un message anormalement long est presque toujours un dump technique.
  if (s.length > 180) return true;
  return false;
}

/// Nettoie un message backend : le renvoie s'il est « présentable », sinon un
/// message générique sûr.
String _safe(String message, {required String fallback}) {
  final cleaned = message
      .replaceFirst(RegExp(r'^ApiException:\s*'), '')
      .replaceFirst(RegExp(r'^Exception:\s*'), '')
      .replaceFirst(RegExp(r'\s*\(status:.*\)$'), '')
      .trim();
  if (cleaned.isEmpty || _looksTechnical(cleaned)) return fallback;
  return cleaned;
}

/// Convertit n'importe quelle erreur en message affichable et **non sensible**.
String userFacingError(Object error) {
  // Erreur de validation : les messages par champ sont déjà rédigés côté
  // serveur (français) et présentables tels quels.
  if (error is ApiValidationException) {
    return error.message;
  }
  if (error is CandidateAccessDeniedException) {
    return CandidateAccess.blockedMessage;
  }
  if (error is ApiException) {
    final code = error.statusCode;
    final raw = error.message.toLowerCase();

    if (raw.contains('unable to connect') ||
        raw.contains('connection refused') ||
        raw.contains('failed host lookup') ||
        raw.contains('network is unreachable') ||
        code == null) {
      return _networkError;
    }
    if (code == 401 || code == 403) {
      // 403 peut porter une règle métier présentable (ex. demande de message) ;
      // sinon message d'auth générique.
      return _safe(error.message, fallback: 'Action non autorisée.');
    }
    if (code == 422 || code == 400) {
      return _safe(error.message,
          fallback: 'Vérifiez les informations saisies.');
    }
    if (code >= 500) {
      // Jamais le détail d'un 500 (peut contenir du SQL en debug serveur).
      return _serverError;
    }
    return _safe(error.message, fallback: _genericError);
  }

  final text = error.toString();
  if (text.contains('SocketException') ||
      text.contains('ClientException') ||
      text.contains('HandshakeException') ||
      text.contains('Failed to fetch')) {
    return _networkError;
  }

  if (error is Error) {
    // Les `Error` Dart (TypeError…) sont des bugs internes : jamais affichés.
    return _genericError;
  }

  return _safe(text, fallback: _genericError);
}
