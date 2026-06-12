import 'package:flutter/widgets.dart';

import 'app_dimens.dart';

/// Formes « squircle » (coins continus, look iOS / Apple) du langage de design
/// 2026. On s'appuie sur [ContinuousRectangleBorder] pour la courbure continue
/// (G2), nettement plus douce qu'un simple [BorderRadius] circulaire.
///
/// Les rayons restent pilotés par [AppRadius] — aucun nombre magique ici hors
/// facteur de conversion. Pour un effet squircle visuellement équivalent à un
/// rayon circulaire donné, [ContinuousRectangleBorder] demande un rayon plus
/// large (~1.7x) ; on applique ce facteur dans les helpers.
class AppShapes {
  AppShapes._();

  /// Facteur de conversion rayon circulaire → rayon continu équivalent.
  static const double _continuousFactor = 1.7;

  /// [ShapeBorder] squircle pour un [radius] « perçu » donné.
  /// Ex : `AppShapes.squircle(AppRadius.xl)` pour une card.
  static ShapeBorder squircle(double radius, {Color? side, double width = 0}) {
    return ContinuousRectangleBorder(
      borderRadius: squircleRadius(radius),
      side: side == null
          ? BorderSide.none
          : BorderSide(color: side, width: width),
    );
  }

  /// [BorderRadius] continu équivalent — pour les `Container`/`ClipRRect` qui
  /// ne prennent pas de [ShapeBorder] mais un `borderRadius`.
  static BorderRadius squircleRadius(double radius) {
    return BorderRadius.circular(radius * _continuousFactor);
  }

  // ── Raccourcis charte (rayons depuis AppRadius) ───────────────────────────

  /// Squircle de card (rayon perçu 24).
  static ShapeBorder get card => squircle(AppRadius.xl);

  /// Squircle de card avec bordure hairline.
  static ShapeBorder cardBordered(Color color, {double width = 1}) =>
      squircle(AppRadius.xl, side: color, width: width);

  /// Squircle de sheet (rayon perçu 32, coins hauts surtout).
  static ShapeBorder get sheet => squircle(AppRadius.xxl);

  /// BorderRadius squircle de card (pour Container/ClipRRect).
  static BorderRadius get cardRadius => squircleRadius(AppRadius.xl);

  /// BorderRadius squircle de tuile bento (rayon perçu 20).
  static BorderRadius get bentoRadius => squircleRadius(AppRadius.lg);

  /// Pill (capsule) — reste un rayon circulaire plein (999), pas de squircle.
  static const BorderRadius pill =
      BorderRadius.all(Radius.circular(AppRadius.pill));
}
