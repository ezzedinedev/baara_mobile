import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../constants/api_constants.dart';

/// Résultat d'une tentative de sign-in Google.
class GoogleAuthResult {
  const GoogleAuthResult._(
      {this.idToken,
      this.email,
      this.displayName,
      this.avatarUrl,
      this.cancelled = false,
      this.error});

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

class GoogleAuthService {
  GoogleAuthService({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final GoogleSignIn _googleSignIn;

  /// `initialize` ne doit être appelé qu'une fois par processus.
  static Future<void>? _initialized;

  Future<GoogleAuthResult> signIn() async {
    try {
      // serverClientId = client OAuth « Web » du site : le jeton obtenu porte
      // cet identifiant en audience, celui que l'API vérifie (GOOGLE_CLIENT_ID).
      // Sur iOS, le client iOS est requis en plus ; sur Android, c'est le
      // couple package + SHA-1 déclaré dans Google Cloud qui identifie l'app.
      await (_initialized ??= _googleSignIn.initialize(
        clientId: defaultTargetPlatform == TargetPlatform.iOS
            ? ApiConstants.googleIosClientId
            : null,
        serverClientId: ApiConstants.googleServerClientId,
      ));
      final account = await _googleSignIn.authenticate();
      final auth = account.authentication;
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
      if (e is GoogleSignInException &&
          e.code == GoogleSignInExceptionCode.canceled) {
        return GoogleAuthResult.cancelled();
      }
      return GoogleAuthResult.failure(
        'Connexion Google échouée : ${e.toString()}',
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // silencieux — nettoyage best-effort
    }
  }

  Future<bool> isSignedIn() async {
    final account = await _googleSignIn.attemptLightweightAuthentication();
    return account != null;
  }
}
