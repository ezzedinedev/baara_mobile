import 'network_user.dart';

/// Demande de connexion réseau entrante en attente (à accepter ou refuser).
class ConnectionRequest {
  final String connectionId;
  final NetworkUser user;

  const ConnectionRequest({
    required this.connectionId,
    required this.user,
  });
}
