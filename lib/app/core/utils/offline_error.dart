import 'dart:async';
import 'dart:io';

import '../network/api_provider.dart';

/// Détecte si une erreur signale une absence de réseau (device hors-ligne,
/// serveur injoignable) — par opposition à un rejet applicatif du serveur
/// (4xx/5xx, validation…). Sert à décider si une action doit être mise en
/// file d'attente hors-ligne plutôt qu'affichée comme un échec définitif.
///
/// Aligné sur [ApiProvider] : une panne réseau y remonte sous forme d'une
/// [ApiException] sans `statusCode` (la requête n'a jamais atteint le serveur),
/// dont la cause (`previous`) est un [SocketException] / [TimeoutException] /
/// [HandshakeException].
bool isOfflineError(Object error) {
  if (error is ApiException) {
    // Jamais atteint le serveur → pas de code HTTP.
    if (error.statusCode == null) return true;
    final prev = error.previous;
    if (prev != null && _isNetworkThrowable(prev)) return true;
    return _hasNetworkMarker(error.message);
  }
  return _isNetworkThrowable(error) || _hasNetworkMarker(error.toString());
}

bool _isNetworkThrowable(Object e) {
  return e is SocketException ||
      e is TimeoutException ||
      e is HandshakeException ||
      e is HttpException;
}

bool _hasNetworkMarker(String message) {
  final l = message.toLowerCase();
  return l.contains('socketexception') ||
      l.contains('handshakeexception') ||
      l.contains('clientexception') ||
      l.contains('timeoutexception') ||
      l.contains('unable to connect') ||
      l.contains('connection refused') ||
      l.contains('connection closed') ||
      l.contains('failed host lookup') ||
      l.contains('network is unreachable') ||
      l.contains('failed to fetch');
}
