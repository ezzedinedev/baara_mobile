/// Interrupteurs de fonctionnalités, fixés à la compilation
/// (`--dart-define=NOM=true`). Par défaut : la version publiée sur les stores.
abstract final class AppFeatures {
  /// Achat de contenu numérique dans l'app (formations payantes,
  /// abonnement). Désactivé : Google Play et l'App Store imposent leur propre
  /// système de paiement pour le contenu numérique consommé dans l'app, alors
  /// que Baara encaisse par mobile money. Les formations gratuites et celles
  /// déjà achetées restent accessibles.
  static const bool inAppPurchases =
      bool.fromEnvironment('IN_APP_PURCHASES', defaultValue: false);

  /// « Continuer avec Google ». À activer une fois le client OAuth Android
  /// (et iOS) créé dans Google Cloud et la connexion testée : un bouton qui
  /// échoue devant le testeur Google est un motif de refus.
  static const bool googleSignIn =
      bool.fromEnvironment('GOOGLE_SIGNIN', defaultValue: false);
}
