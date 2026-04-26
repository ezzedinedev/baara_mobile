/// Tokens de dimensions (rayons, espacements). Centralisés ici pour éviter
/// la prolifération de `BorderRadius.circular(N)` magiques. Conventions :
///   xs=8, sm=12, md=16, lg=20, xl=24, xxl=32, pill=999.
///
/// Pour un cas qui sort de l'échelle, garder le nombre brut local — mais ≥3
/// occurrences dans un même fichier signalent qu'il faut un token dédié.
class AppRadius {
  AppRadius._();

  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double pill = 999;
}

/// Espacements horizontaux/verticaux récurrents.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  /// Marge horizontale standard d'une page (sides).
  static const double pageH = 16;
}
