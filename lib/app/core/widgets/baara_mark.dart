import 'package:flutter/material.dart';

/// Symbole officiel Baara (le pictogramme seul, sans le mot « Baara ») :
/// un personnage bras levés, dont le corps forme un X, surmonté d'une tête.
///
/// Tracé vectoriel : reste net à n'importe quelle taille. Utiliser
/// [BaaraLogo] quand le lockup complet (symbole + wordmark) est attendu.
///
/// Géométrie mesurée sur `logo.png` du site (ajustement à 99,8 % des pixels) :
/// quatre membres arrondis de même épaisseur partant d'un centre commun, et un
/// disque pour la tête.
class BaaraMark extends StatelessWidget {
  const BaaraMark({
    super.key,
    this.size = 96,
    this.color,
    this.headColor,
    this.pose = 0,
  });

  /// Hauteur du symbole. La largeur suit le ratio de l'artwork officiel.
  final double size;

  /// Teinte du corps (le X). Par défaut : le vert forêt de la marque.
  final Color? color;

  /// Teinte de la tête. Par défaut : le vert feuille de la marque.
  final Color? headColor;

  /// Posture du personnage, pour l'animer : 0 = pose officielle, 1 = saut
  /// (bras plus hauts, jambes resserrées, tête soulevée), valeurs négatives =
  /// accroupi (bras plus bas). Rester dans [-1, 1].
  final double pose;

  /// Couleurs officielles du logo, volontairement figées : elles ne suivent
  /// pas le thème (ce ne sont pas des tokens d'UI mais la charte).
  static const Color brandForest = Color(0xFF26472B);
  static const Color brandGreen = Color(0xFF45A735);
  static const Color brandLime = Color(0xFF78EB54);

  /// Boîte de l'artwork d'origine, qui définit le ratio du symbole.
  static const double _viewW = 175.54;
  static const double _viewH = 204.0;
  static const double aspectRatio = _viewW / _viewH;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * aspectRatio,
      height: size,
      child: CustomPaint(
        painter: _BaaraMarkPainter(
          color ?? brandForest,
          headColor ?? brandGreen,
          pose,
        ),
        willChange: false,
      ),
    );
  }
}

class _BaaraMarkPainter extends CustomPainter {
  const _BaaraMarkPainter(this.body, this.head, this.pose);

  final Color body;
  final Color head;
  final double pose;

  // Amplitude de la posture : rotation des membres vers la verticale (rad)
  // et levée de la tête (unités de la boîte) pour pose = 1.
  static const double _armSwing = 0.12;
  static const double _legSwing = 0.12;
  static const double _headLift = 11;

  /// Fait pivoter un membre autour de la hanche vers la verticale (delta > 0)
  /// ou vers l'horizontale (delta < 0), longueur conservée.
  static Offset _swing(Offset end, double delta) {
    if (delta == 0) return end;
    final v = end - _hip;
    final towardVertical = (v.dx < 0) == (v.dy < 0) ? 1.0 : -1.0;
    final angle = v.direction + towardVertical * delta;
    return _hip + Offset.fromDirection(angle, v.distance);
  }

  // Coordonnées dans la boîte 175.54 x 204 (origine en haut à gauche).
  static const double _cx = 87.77;
  static const Offset _hip = Offset(_cx, 116.28);
  static const List<Offset> _limbs = [
    Offset(_cx - 69.22, 42.15),
    Offset(_cx + 69.22, 42.15),
    Offset(_cx - 44.45, 185.4),
    Offset(_cx + 44.45, 185.4),
  ];
  static const double _stroke = 37.1;
  static const Offset _headCenter = Offset(_cx, 27.2);
  static const double _headRadius = 27.2;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(
      size.width / BaaraMark._viewW,
      size.height / BaaraMark._viewH,
    );
    final limb = Paint()
      ..color = body
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    for (var i = 0; i < _limbs.length; i++) {
      final isArm = i < 2;
      final end = _swing(_limbs[i], pose * (isArm ? _armSwing : _legSwing));
      canvas.drawLine(_hip, end, limb);
    }
    canvas.drawCircle(
      _headCenter.translate(0, -pose * _headLift),
      _headRadius,
      Paint()..color = head,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BaaraMarkPainter old) =>
      old.body != body || old.head != head || old.pose != pose;
}
