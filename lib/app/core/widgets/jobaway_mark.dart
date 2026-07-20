import 'package:flutter/material.dart';

/// Symbole officiel JobAway (le pictogramme seul, sans le mot « JobAway »).
///
/// Tracé vectoriel de l'artwork officiel : reste net à n'importe quelle taille,
/// là où le PNG de marque (173x44) pixellise dès qu'on le grossit. Utiliser
/// [JobAwayLogo] quand le lockup complet (symbole + wordmark) est attendu.
///
/// Le vecteur a été tracé depuis `logo-icon-2.png` du kit de marque (fidélité
/// mesurée : 98,9 % du pixel d'origine).
class JobAwayMark extends StatelessWidget {
  const JobAwayMark({super.key, this.size = 96, this.color});

  /// Largeur du symbole. La hauteur suit le ratio de l'artwork officiel.
  final double size;

  /// Teinte du symbole. Par défaut : le vert officiel de la marque.
  final Color? color;

  /// Vert officiel du logo — volontairement figé, il ne suit pas le thème
  /// (ce n'est pas un token d'UI mais une couleur de marque).
  static const Color brandGreen = Color(0xFF45A735);

  /// Boîte de l'artwork d'origine, qui définit le ratio du symbole.
  static const double _viewW = 60;
  static const double _viewH = 52;
  static const double aspectRatio = _viewW / _viewH;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size / aspectRatio,
      child: CustomPaint(
        painter: _JobAwayMarkPainter(color ?? brandGreen),
        isComplex: true,
        willChange: false,
      ),
    );
  }
}

class _JobAwayMarkPainter extends CustomPainter {
  const _JobAwayMarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(
      size.width / JobAwayMark._viewW,
      size.height / JobAwayMark._viewH,
    );
    canvas.drawPath(_path, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_JobAwayMarkPainter old) => old.color != color;

  /// Contours de l'artwork officiel, dans la boîte 60x52.
  /// Trois contours : le disque (avec l'élan qui s'échappe en haut à droite),
  /// la coche en réserve, puis la tête. Le remplissage pair-impair creuse les
  /// deux derniers.
  static final Path _path = Path()
    ..fillType = PathFillType.evenOdd
    ..moveTo(22.9, 51.74)
    ..cubicTo(22.42, 51.4, 21.53, 51.14, 20.35, 51.0)
    ..cubicTo(19.2, 50.87, 18.44, 50.68, 17.98, 50.4)
    ..cubicTo(17.8, 50.3, 17.3, 50.13, 16.88, 50.02)
    ..cubicTo(16.45, 49.91, 15.9, 49.68, 15.64, 49.52)
    ..cubicTo(15.39, 49.35, 14.89, 49.12, 14.52, 49.0)
    ..cubicTo(14.16, 48.88, 13.69, 48.65, 13.49, 48.49)
    ..cubicTo(13.28, 48.33, 12.88, 48.08, 12.58, 47.95)
    ..cubicTo(12.05, 47.69, 11.64, 47.41, 10.67, 46.62)
    ..cubicTo(10.38, 46.39, 9.97, 46.12, 9.75, 46.01)
    ..cubicTo(9.31, 45.81, 6.66, 43.23, 5.98, 42.34)
    ..cubicTo(4.57, 40.51, 4.28, 40.1, 4.01, 39.59)
    ..cubicTo(3.85, 39.29, 3.64, 38.97, 3.54, 38.89)
    ..cubicTo(3.45, 38.81, 3.2, 38.39, 2.99, 37.95)
    ..cubicTo(2.79, 37.51, 2.51, 37.0, 2.37, 36.82)
    ..cubicTo(2.2, 36.6, 2.07, 36.24, 2.0, 35.8)
    ..cubicTo(1.93, 35.38, 1.78, 34.94, 1.61, 34.68)
    ..cubicTo(1.25, 34.11, 1.13, 33.74, 1.0, 32.72)
    ..cubicTo(0.87, 31.73, 0.7, 31.23, 0.3, 30.64)
    ..lineTo(0.0, 30.19)
    ..lineTo(0.0, 25.61)
    ..lineTo(0.0, 21.03)
    ..lineTo(0.26, 20.9)
    ..cubicTo(0.64, 20.69, 0.79, 20.31, 1.05, 18.9)
    ..cubicTo(1.19, 18.15, 1.38, 17.43, 1.53, 17.14)
    ..cubicTo(1.67, 16.87, 1.87, 16.33, 1.99, 15.94)
    ..cubicTo(2.1, 15.56, 2.33, 15.04, 2.49, 14.79)
    ..cubicTo(2.65, 14.55, 2.88, 14.09, 3.0, 13.77)
    ..cubicTo(3.13, 13.43, 3.32, 13.13, 3.46, 13.03)
    ..cubicTo(3.6, 12.94, 3.83, 12.64, 3.97, 12.36)
    ..cubicTo(4.11, 12.08, 4.34, 11.72, 4.47, 11.56)
    ..cubicTo(4.6, 11.4, 4.82, 11.06, 4.95, 10.79)
    ..cubicTo(5.41, 9.88, 10.3, 5.0, 10.75, 5.0)
    ..cubicTo(10.83, 5.0, 11.13, 4.8, 11.42, 4.57)
    ..cubicTo(11.72, 4.33, 12.16, 4.05, 12.41, 3.96)
    ..cubicTo(12.67, 3.86, 13.01, 3.64, 13.17, 3.46)
    ..cubicTo(13.36, 3.26, 13.69, 3.08, 14.06, 2.96)
    ..cubicTo(14.38, 2.86, 14.84, 2.63, 15.07, 2.45)
    ..cubicTo(15.38, 2.21, 15.69, 2.09, 16.17, 2.0)
    ..cubicTo(16.58, 1.93, 17.09, 1.75, 17.47, 1.54)
    ..cubicTo(17.95, 1.26, 18.31, 1.15, 19.07, 1.04)
    ..cubicTo(20.29, 0.86, 20.87, 0.67, 21.39, 0.29)
    ..lineTo(21.8, -0.0)
    ..lineTo(26.45, 0.0)
    ..cubicTo(31.06, 0.0, 31.09, 0.0, 31.21, 0.21)
    ..cubicTo(31.39, 0.55, 32.26, 0.88, 33.26, 1.0)
    ..cubicTo(34.23, 1.11, 34.68, 1.23, 35.46, 1.63)
    ..cubicTo(35.73, 1.76, 36.22, 1.93, 36.55, 2.0)
    ..cubicTo(37.23, 2.14, 37.4, 2.22, 37.9, 2.6)
    ..cubicTo(38.09, 2.75, 38.37, 2.9, 38.51, 2.94)
    ..cubicTo(38.66, 2.97, 38.99, 3.15, 39.26, 3.35)
    ..cubicTo(39.53, 3.54, 40.02, 3.83, 40.35, 4.0)
    ..cubicTo(40.93, 4.29, 41.24, 4.51, 42.38, 5.42)
    ..cubicTo(42.67, 5.66, 43.05, 5.93, 43.23, 6.02)
    ..cubicTo(43.84, 6.34, 46.44, 9.03, 47.12, 10.04)
    ..cubicTo(47.61, 10.77, 47.42, 11.26, 46.24, 12.35)
    ..cubicTo(45.55, 12.99, 44.13, 14.35, 43.0, 15.44)
    ..cubicTo(42.75, 15.68, 42.44, 15.93, 42.31, 16.0)
    ..cubicTo(42.09, 16.11, 40.75, 17.29, 39.65, 18.34)
    ..cubicTo(38.94, 19.01, 38.07, 19.75, 37.75, 19.95)
    ..cubicTo(37.59, 20.06, 37.22, 20.37, 36.95, 20.65)
    ..cubicTo(36.67, 20.92, 35.57, 21.98, 34.5, 23.0)
    ..cubicTo(33.43, 24.02, 32.34, 25.07, 32.07, 25.35)
    ..cubicTo(31.8, 25.62, 31.46, 25.92, 31.33, 26.01)
    ..cubicTo(30.48, 26.57, 28.9, 28.22, 28.9, 28.55)
    ..cubicTo(28.9, 28.94, 30.59, 30.71, 33.57, 33.42)
    ..cubicTo(35.6, 35.29, 35.4, 35.27, 36.85, 33.73)
    ..cubicTo(37.45, 33.09, 40.2, 30.3, 42.95, 27.54)
    ..cubicTo(49.62, 20.83, 52.76, 17.62, 53.05, 17.21)
    ..cubicTo(53.36, 16.77, 56.07, 14.0, 56.46, 13.73)
    ..cubicTo(56.63, 13.61, 56.88, 13.35, 57.01, 13.15)
    ..cubicTo(57.21, 12.85, 57.83, 12.4, 58.05, 12.4)
    ..cubicTo(58.27, 12.4, 57.83, 13.5, 57.45, 13.9)
    ..cubicTo(57.32, 14.04, 57.14, 14.32, 57.06, 14.52)
    ..cubicTo(56.97, 14.73, 56.76, 15.06, 56.58, 15.26)
    ..cubicTo(56.41, 15.46, 56.15, 15.79, 56.01, 16.0)
    ..cubicTo(51.99, 21.93, 52.21, 21.5, 52.47, 22.74)
    ..cubicTo(52.79, 24.36, 52.65, 29.56, 52.26, 30.19)
    ..cubicTo(52.23, 30.24, 52.16, 30.61, 52.1, 31.01)
    ..cubicTo(51.95, 32.13, 51.7, 33.09, 51.42, 33.65)
    ..cubicTo(51.28, 33.92, 51.09, 34.48, 50.98, 34.89)
    ..cubicTo(50.88, 35.3, 50.65, 35.91, 50.46, 36.24)
    ..cubicTo(50.28, 36.58, 50.05, 37.08, 49.96, 37.35)
    ..cubicTo(49.87, 37.62, 49.64, 38.08, 49.44, 38.35)
    ..cubicTo(49.25, 38.62, 49.03, 38.99, 48.95, 39.16)
    ..cubicTo(48.88, 39.34, 48.67, 39.65, 48.48, 39.86)
    ..cubicTo(48.29, 40.08, 48.02, 40.45, 47.88, 40.7)
    ..cubicTo(47.25, 41.77, 44.06, 45.19, 43.06, 45.87)
    ..cubicTo(42.84, 46.02, 42.46, 46.31, 42.23, 46.51)
    ..cubicTo(42.01, 46.72, 41.65, 46.98, 41.43, 47.09)
    ..cubicTo(41.22, 47.2, 40.93, 47.41, 40.79, 47.57)
    ..cubicTo(40.63, 47.74, 40.29, 47.93, 39.94, 48.04)
    ..cubicTo(39.61, 48.14, 39.19, 48.35, 39.0, 48.5)
    ..cubicTo(38.81, 48.65, 38.36, 48.87, 38.0, 49.0)
    ..cubicTo(37.64, 49.13, 37.18, 49.36, 36.97, 49.53)
    ..cubicTo(36.72, 49.72, 36.32, 49.89, 35.86, 50.0)
    ..cubicTo(35.46, 50.1, 34.95, 50.27, 34.72, 50.39)
    ..cubicTo(34.24, 50.63, 32.94, 50.95, 32.0, 51.04)
    ..cubicTo(31.13, 51.13, 30.7, 51.25, 29.77, 51.66)
    ..lineTo(28.99, 52.0)
    ..lineTo(26.12, 52.0)
    ..lineTo(23.25, 51.99)
    ..lineTo(22.9, 51.74)
    ..close()
    ..moveTo(29.53, 40.98)
    ..cubicTo(31.11, 39.42, 32.53, 38.03, 32.71, 37.88)
    ..cubicTo(32.97, 37.65, 33.01, 37.56, 32.96, 37.33)
    ..cubicTo(32.88, 37.02, 31.58, 35.64, 30.95, 35.19)
    ..cubicTo(30.51, 34.88, 29.04, 33.47, 24.46, 28.95)
    ..cubicTo(18.92, 23.48, 17.53, 22.19, 16.88, 21.9)
    ..cubicTo(16.34, 21.66, 4.42, 21.57, 4.14, 21.81)
    ..cubicTo(3.91, 22.0, 3.97, 22.58, 4.25, 22.83)
    ..cubicTo(4.66, 23.2, 7.53, 25.97, 9.03, 27.45)
    ..cubicTo(9.81, 28.22, 10.58, 28.94, 10.75, 29.04)
    ..cubicTo(11.1, 29.27, 13.8, 31.86, 17.9, 35.9)
    ..cubicTo(21.73, 39.68, 23.88, 41.73, 24.25, 41.96)
    ..cubicTo(24.41, 42.06, 24.93, 42.52, 25.38, 42.97)
    ..cubicTo(25.94, 43.53, 26.29, 43.8, 26.45, 43.8)
    ..cubicTo(26.61, 43.8, 27.46, 43.02, 29.53, 40.98)
    ..close()
    ..moveTo(28.75, 24.3)
    ..cubicTo(29.75, 23.82, 30.8, 22.96, 31.1, 22.39)
    ..cubicTo(31.2, 22.2, 31.36, 21.98, 31.45, 21.9)
    ..cubicTo(32.36, 21.14, 32.53, 17.23, 31.7, 16.2)
    ..cubicTo(31.58, 16.06, 31.37, 15.75, 31.22, 15.51)
    ..cubicTo(30.72, 14.69, 30.12, 14.12, 29.59, 13.95)
    ..cubicTo(29.32, 13.86, 28.97, 13.68, 28.82, 13.56)
    ..cubicTo(28.28, 13.11, 28.09, 13.06, 26.67, 13.02)
    ..cubicTo(25.0, 12.97, 24.67, 13.04, 23.35, 13.76)
    ..cubicTo(22.62, 14.16, 22.25, 14.44, 22.0, 14.76)
    ..cubicTo(21.81, 15.01, 21.53, 15.37, 21.38, 15.56)
    ..cubicTo(21.23, 15.76, 21.04, 16.14, 20.94, 16.42)
    ..cubicTo(20.85, 16.7, 20.64, 17.15, 20.47, 17.41)
    ..cubicTo(20.11, 17.99, 20.12, 19.11, 20.48, 20.1)
    ..cubicTo(20.59, 20.4, 20.79, 20.96, 20.93, 21.33)
    ..cubicTo(21.33, 22.41, 22.61, 23.81, 23.41, 24.05)
    ..cubicTo(23.69, 24.13, 24.04, 24.28, 24.19, 24.39)
    ..cubicTo(24.71, 24.76, 24.93, 24.8, 26.4, 24.77)
    ..lineTo(27.85, 24.74)
    ..lineTo(28.75, 24.3)
    ..close();
}
