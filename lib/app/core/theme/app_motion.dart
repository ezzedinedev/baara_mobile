import 'package:flutter/animation.dart' show Curve, Curves, Cubic;

/// Langage de motion 2026-2027 : synthèse Material 3 Expressive
/// (courbes « emphasized » + ressorts) pour des transitions vivantes mais
/// calmes. Les anciens tokens (fast/base/slow/enter/exit/standard) sont
/// conservés tels quels pour ne casser aucun usage existant.
class AppMotion {
  AppMotion._();

  // ── Durées historiques (conservées) ──────────────────────────────────────
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration base = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 360);
  static const Duration stagger = Duration(milliseconds: 40);

  // ── Durées standard Material 3 (nouvelles, additives) ─────────────────────
  /// 200 ms — micro-interactions (états de press, petites bascules).
  static const Duration short = Duration(milliseconds: 200);

  /// 350 ms — transitions de composant (cards, sheets, indicateurs nav).
  static const Duration medium = Duration(milliseconds: 350);

  /// 500 ms — transitions expressives marquantes (hero, reveals en cascade).
  static const Duration long = Duration(milliseconds: 500);

  // ── Courbes historiques (conservées) ──────────────────────────────────────
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve standard = Curves.easeInOutCubic;

  // ── Courbes « emphasized » Material 3 Expressive (nouvelles) ──────────────
  /// Courbe emphasized symétrique — déplacement standard expressif.
  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);

  /// Entrée / ouverture (objet qui décélère vers sa place).
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);

  /// Sortie / fermeture (objet qui accélère hors de l'écran).
  static const Curve emphasizedAccelerate = Cubic(0.3, 0.0, 0.8, 0.15);

  /// Ressort expressif léger (overshoot doux) — sélection nav, press release,
  /// apparition d'un label. Sensation « élastique » sans rebond excessif.
  static const Curve spring = Curves.easeOutBack;

  /// Ressort plus prononcé pour les éléments hero (count-up, badges).
  static const Curve springEmphasized = Cubic(0.34, 1.56, 0.64, 1.0);

  static const double listSlideOffset = 18;
}
