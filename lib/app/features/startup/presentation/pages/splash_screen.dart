import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:baara/app/core/theme/app_shapes.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/widgets/baara_mark.dart';
import '../controllers/splash_controller.dart';

/// Splash de marque : le personnage du logo fait un saut de joie.
///
/// Continuité avec le lancement natif : Android et iOS affichent déjà le
/// symbole (corps blanc, tête citron, [_markHeight] de haut) au centre d'un
/// fond vert forêt. Le premier frame Flutter le reprend à l'identique, puis
/// l'anime : il s'accroupit, saute bras levés, retombe en laissant une onde
/// au sol, remonte et laisse apparaître le mot « Baara ».
///
/// Un seul [AnimationController] pilote toute la séquence (Transform, Opacity
/// et un CustomPaint léger : aucun flou, rien de coûteux pendant le boot).
/// Animations réduites (réglage système) : on affiche directement l'état final.
/// Toucher l'écran passe l'introduction.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  /// Doit rester égal à la hauteur du symbole des écrans de lancement natifs
  /// (`splash_mark.png` Android, `LaunchImage` iOS) : 96 dp.
  static const double _markHeight = 96;

  /// Remontée finale du symbole pour faire place au mot « Baara ».
  static const double _settleShift = 54;

  static const double _wordmarkWidth = 132;

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_intro.isAnimating || _intro.isCompleted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
    } else {
      _intro.forward();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  /// Valeur 0 → 1 de [_intro] ramenée à l'intervalle [begin, end], avec courbe.
  double _seg(double begin, double end, [Curve curve = Curves.linear]) {
    final t = ((_intro.value - begin) / (end - begin)).clamp(0.0, 1.0);
    return curve.transform(t);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SplashController>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _SplashPalette.ground,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: BaaraMark.brandForest,
        body: Semantics(
          button: true,
          label: 'Baara. Chargement, touchez pour passer',
          onTap: controller.skip,
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: controller.skip,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.15),
                  radius: 1.05,
                  colors: [
                    _SplashPalette.light,
                    BaaraMark.brandForest,
                    _SplashPalette.ground,
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
              child: AnimatedBuilder(
                animation: _intro,
                builder: (context, _) => _buildScene(controller),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScene(SplashController controller) {
    // 1. Accroupi : les bras s'abaissent, le corps se tasse.
    final crouch = _seg(0.0, 0.16, Curves.easeOut);
    // 2. Saut : bras levés, le corps monte.
    final rise = _seg(0.16, 0.38, Curves.easeOutCubic);
    // 3. Chute puis réception.
    final fall = _seg(0.38, 0.56, Curves.easeInCubic);
    final land = _seg(0.56, 0.68, Curves.easeOutBack);
    // 4. Remontée finale et apparition du mot.
    final settle = _seg(0.62, 0.92, const Cubic(0.2, 0.0, 0.0, 1.0));
    final ripple = _seg(0.54, 0.98, Curves.easeOutCubic);
    final wordmark = _seg(0.70, 1.0, Curves.easeOutCubic);
    final tagline = _seg(0.82, 1.0, Curves.easeOut);
    final footer = _seg(0.60, 1.0, Curves.easeOut);

    double pose;
    if (rise == 0) {
      pose = -0.5 * crouch;
    } else if (fall == 0) {
      pose = -0.5 + 1.5 * rise;
    } else {
      pose = 1.0 - fall;
    }
    final jumpY = -26.0 * rise * (1 - fall);
    // Tassement à l'appel puis à la réception (ancré aux pieds).
    final squash = fall < 1 ? 0.07 * crouch * (1 - rise) : 0.05 * (1 - land);
    final markShift = -_settleShift * settle;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Onde au sol à la réception : une ellipse qui s'élargit et s'efface.
        Center(
          child: Transform.translate(
            offset: Offset(0, _markHeight / 2),
            child: CustomPaint(
              size: const Size(280, 80),
              painter: _RipplePainter(progress: ripple),
            ),
          ),
        ),
        Center(
          child: Transform.translate(
            offset: Offset(0, jumpY + markShift),
            child: Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.diagonal3Values(
                1 + squash * 0.6,
                1 - squash,
                1,
              ),
              child: RepaintBoundary(
                child: BaaraMark(
                  size: _markHeight,
                  color: Colors.white,
                  headColor: BaaraMark.brandLime,
                  pose: pose,
                ),
              ),
            ),
          ),
        ),
        // Mot « Baara » révélé par un balayage gauche → droite.
        Center(
          child: Transform.translate(
            offset: Offset(0, _markHeight / 2 + 46 - _settleShift * settle),
            child: Opacity(
              opacity: wordmark,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: wordmark,
                  child: Image.asset(
                    'assets/images/logo/baara_wordmark_light.png',
                    width: _wordmarkWidth,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) => Text(
                      'Baara',
                      style: AppTextStyles.logoGreen(size: 34)
                          .copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Center(
          child: Transform.translate(
            offset: Offset(
              0,
              _markHeight / 2 + 98 - _settleShift * settle + 8 * (1 - tagline),
            ),
            child: Opacity(
              opacity: tagline,
              child: Text(
                'Le travail commence ici.',
                style: AppTextStyles.bodyMd.copyWith(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Opacity(
              opacity: footer,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ProgressLine(controller: controller),
                    const SizedBox(height: 16),
                    Text(
                      'BURKINA FASO',
                      style: AppTextStyles.labelSm.copyWith(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Teintes dérivées du vert forêt, pour le fond du splash uniquement.
abstract final class _SplashPalette {
  /// Halo central, à peine plus clair que la forêt.
  static const Color light = Color(0xFF305A36);

  /// Bords, à peine plus sombres (et barre de navigation système).
  static const Color ground = Color(0xFF1C3620);
}

/// Onde elliptique « au sol » sous les pieds du personnage.
class _RipplePainter extends CustomPainter {
  const _RipplePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final center = size.center(Offset.zero);
    for (final lag in const [0.0, 0.18]) {
      final t = ((progress - lag) / (1 - lag)).clamp(0.0, 1.0);
      if (t <= 0) continue;
      final w = 40 + (size.width - 40) * t;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2 * (1 - t) + 0.4
        ..color = BaaraMark.brandLime.withValues(alpha: 0.55 * (1 - t));
      canvas.drawOval(
        Rect.fromCenter(center: center, width: w, height: w * 0.22),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) => old.progress != progress;
}

/// Fine ligne de progression, de la largeur du mot « Baara ». Seule cette
/// zone se reconstruit quand la progression avance.
class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.controller});

  final SplashController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _SplashScreenState._wordmarkWidth,
      height: 3,
      child: ClipRRect(
        borderRadius: AppShapes.pill,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: Colors.white.withValues(alpha: 0.12)),
            Obx(() {
              final fraction =
                  (controller.progress.value / 100).clamp(0.0, 1.0);
              return Semantics(
                liveRegion: true,
                value: controller.loadingMessage,
                child: AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.centerLeft,
                  widthFactor: fraction,
                  child: const ColoredBox(color: BaaraMark.brandLime),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
