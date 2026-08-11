/// Politique d'accès mobile : l'application est **strictement réservée aux
/// candidats**. Les employeurs / recruteurs utilisent la plateforme web.
abstract final class CandidateAccess {
  static const allowedUserTypes = {'candidate'};

  static bool isAllowed(String? userType) {
    final normalized = (userType ?? '').trim().toLowerCase();
    return allowedUserTypes.contains(normalized);
  }

  static const blockedMessage =
      'Cette application est réservée aux candidats. '
      'Les employeurs et recruteurs doivent se connecter sur la plateforme web Baara.bf.';
}

/// Levée quand un compte employeur / recruteur tente d'accéder à l'app mobile.
class CandidateAccessDeniedException implements Exception {
  const CandidateAccessDeniedException();

  @override
  String toString() => CandidateAccess.blockedMessage;
}
