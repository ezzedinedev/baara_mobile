import 'package:google_sign_in/google_sign_in.dart';

/// Résultat d'une tentative de sign-in Google.
class GoogleAuthResult {
  const GoogleAuthResult._({this.idToken, this.email, this.displayName,
      this.avatarUrl, this.cancelled = false, this.error});

  final String? idToken;
  final String? email;
  final String? displayName;
  final String? avatarUrl;

  /// `true` si l'utilisateur a fermé la feuille Google sans valider.
  final bool cancelled;

  /// Message d'erreur technique si le flow a échoué (réseau, config, …).
  final String? error;

  bool get isSuccess => idToken != null && idToken!.isNotEmpty;

  factory GoogleAuthResult.success({
    required String idToken,
    String? email,
    String? displayName,
    String? avatarUrl,
  }) =>
      GoogleAuthResult._(
        idToken: idToken,
        email: email,
        displayName: displayName,
        avatarUrl: avatarUrl,
      );

  factory GoogleAuthResult.cancelled() =>
      const GoogleAuthResult._(cancelled: true);

  factory GoogleAuthResult.failure(String error) =>
      GoogleAuthResult._(error: error);
}

/// Wrapper autour de `google_sign_in` pour centraliser :
/// - la configuration (scopes demandés)
/// - la récupération du `id_token` (ce qui sera envoyé au backend)
/// - la déconnexion lors du logout
///
/// Le backend Laravel devra exposer `POST /api/v1/auth/google` qui prend
/// `id_token` + `user_type` + `device_name` et retourne un token Sanctum.
class GoogleAuthService {
  GoogleAuthService({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const ['email', 'profile'],
            );

  final GoogleSignIn _googleSignIn;

  /// Ouvre la feuille Google et récupère un `id_token` signé.
  Future<GoogleAuthResult> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return GoogleAuthResult.cancelled();
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        return GoogleAuthResult.failure(
          'Impossible d\'obtenir le jeton Google.',
        );
      }

      return GoogleAuthResult.success(
        idToken: idToken,
        email: account.email,
        displayName: account.displayName,
        avatarUrl: account.photoUrl,
      );
    } catch (e) {
      return GoogleAuthResult.failure(
        'Connexion Google échouée : ${e.toString()}',
      );
    }
  }

  /// À appeler lors d'un logout applicatif pour nettoyer la session Google
  /// côté device (évite qu'une re-connexion reprenne le même compte sans
  /// laisser le choix à l'utilisateur).
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // silencieux — nettoyage best-effort
    }
  }

  Future<bool> isSignedIn() => _googleSignIn.isSignedIn();
}
