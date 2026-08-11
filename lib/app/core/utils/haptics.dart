import 'package:flutter/services.dart';

/// Feedback haptique centralisé pour Baara.
/// Éviter d'appeler directement `HapticFeedback` ailleurs : tout passe par ces helpers
/// pour garder une sensation cohérente dans l'app.
class AppHaptics {
  AppHaptics._();

  /// Sélection / changement d'onglet / toggle / ouverture de picker.
  static void tap() => HapticFeedback.selectionClick();

  /// Action validée avec succès (sauvegarde, like, envoi court).
  static void success() => HapticFeedback.lightImpact();

  /// Confirmation importante (paiement, suppression confirmée).
  static void confirm() => HapticFeedback.mediumImpact();

  /// Erreur utilisateur-critique / action bloquée.
  static void error() => HapticFeedback.heavyImpact();
}
