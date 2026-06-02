import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import '../controllers/splash_controller.dart';

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: const _SplashBody(),
    );
  }
}

class _SplashBody extends StatefulWidget {
  const _SplashBody();

  @override
  State<_SplashBody> createState() => _SplashBodyState();
}

class _SplashBodyState extends State<_SplashBody> with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _ambient;
  late final AnimationController _orbit;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _haloPulse;
  late final Animation<double> _breath;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _logoScale = CurvedAnimation(parent: _intro, curve: const Interval(0.0, 0.55, curve: Curves.elasticOut));
    _logoOpacity = CurvedAnimation(parent: _intro, curve: const Interval(0.0, 0.30, curve: Curves.easeOut));
    _intro.forward();

    _ambient = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat(reverse: true);
    _haloPulse = Tween<double>(begin: 0.85, end: 1.15).animate(CurvedAnimation(parent: _ambient, curve: Curves.easeInOut));
    _breath = Tween<double>(begin: 1.0, end: 1.04).animate(CurvedAnimation(parent: _ambient, curve: Curves.easeInOut));
    _orbit = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat();
  }

  @override
  void dispose() {
    _intro.dispose();
    _ambient.dispose();
    _orbit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SplashController>();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: controller.skip,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(decoration: BoxDecoration(gradient: AppColors.splashBackground)),
          const _GradientMesh(),
          const _FloatingParticles(),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 5),
                _LogoMark(
                  introScale: _logoScale,
                  introOpacity: _logoOpacity,
                  haloPulse: _haloPulse,
                  breath: _breath,
                  orbit: _orbit,
                  intro: _intro,
                ),
                const SizedBox(height: 28),
                _BrandWordmark(intro: _intro),
                const SizedBox(height: 10),
                _Tagline(intro: _intro),
                const Spacer(flex: 7),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 56),
                  child: _ModernProgress(controller: controller),
                ),
                const SizedBox(height: 30),
                const _BottomTag(),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark({
    required this.introScale,
    required this.introOpacity,
    required this.haloPulse,
    required this.breath,
    required this.orbit,
    required this.intro,
  });

  final Animation<double> introScale;
  final Animation<double> introOpacity;
  final Animation<double> haloPulse;
  final Animation<double> breath;
  final Animation<double> orbit;
  final Animation<double> intro;

  static const List<({IconData icon, double radius, double speed, double phase})> _satellites = [
    (icon: IconlyBold.send, radius: 102, speed: 1.0, phase: 0.0),
    (icon: IconlyBold.document, radius: 110, speed: 0.7, phase: 0.33),
    (icon: IconlyBold.star, radius: 96, speed: 1.25, phase: 0.66),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([introScale, haloPulse, breath, orbit, intro]),
      builder: (_, __) {
        final introS = introScale.value.clamp(0.0, 1.5);
        final s = introS * breath.value;
        final satFade = ((intro.value - 0.55) / 0.30).clamp(0.0, 1.0);
        final satEased = Curves.easeOutCubic.transform(satFade);

        return Opacity(
          opacity: introOpacity.value.clamp(0.0, 1.0),
          child: SizedBox(
            width: 260,
            height: 260,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: haloPulse.value,
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primaryLight.withValues(alpha: 0.18),
                          AppColors.primaryLight.withValues(alpha: 0.06),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                ),
                Transform.scale(
                  scale: 0.7 * haloPulse.value,
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryLight.withValues(alpha: 0.10),
                    ),
                  ),
                ),
                Opacity(
                  opacity: 0.20 * satEased,
                  child: CustomPaint(
                    size: const Size(220, 220),
                    painter: _DashedRingPainter(color: AppColors.primaryLight, radius: 100),
                  ),
                ),
                CustomPaint(
                  size: const Size(260, 260),
                  painter: _ConnectionLinesPainter(
                    satellites: _satellites.map((s) => (radius: s.radius, speed: s.speed, phase: s.phase)).toList(growable: false),
                    orbitValue: orbit.value,
                    color: AppColors.primaryLight,
                    fade: satEased,
                  ),
                ),
                for (final sat in _satellites)
                  _OrbitingSatellite(orbit: orbit, icon: sat.icon, radius: sat.radius, speed: sat.speed, phase: sat.phase, fade: satEased),
                Transform.scale(
                  scale: s,
                  child: Container(
                    width: 124,
                    height: 124,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(AppRadius.xxl),
                      border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.28), width: 1.2),
                      boxShadow: [
                        BoxShadow(color: AppColors.primaryLight.withValues(alpha: 0.35), blurRadius: 38, spreadRadius: 2, offset: const Offset(0, 8)),
                        BoxShadow(color: AppColors.primaryDark.withValues(alpha: 0.18), blurRadius: 22, offset: const Offset(0, 14)),
                      ],
                    ),
                    child: Center(
                      child: ShaderMask(
                        shaderCallback: (rect) => AppColors.primaryGradient.createShader(rect),
                        child: const Icon(IconlyBold.work, size: 60, color: AppColors.onPrimary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OrbitingSatellite extends StatelessWidget {
  const _OrbitingSatellite({
    required this.orbit,
    required this.icon,
    required this.radius,
    required this.speed,
    required this.phase,
    required this.fade,
  });

  final Animation<double> orbit;
  final IconData icon;
  final double radius;
  final double speed;
  final double phase;
  final double fade;

  @override
  Widget build(BuildContext context) {
    final t = (orbit.value * speed + phase) % 1.0;
    final angle = t * 2 * math.pi;
    final dx = math.cos(angle) * radius;
    final dy = math.sin(angle) * radius;

    final depthFactor = (math.sin(angle - math.pi / 2) + 1) / 2;
    final scale = 0.85 + 0.30 * depthFactor;
    final visibility = (0.65 + 0.35 * depthFactor).clamp(0.0, 1.0);
    final opacity = (fade * visibility).clamp(0.0, 1.0);

    return Transform.translate(
      offset: Offset(dx, dy),
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceCard.withValues(alpha: 0.96),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.primaryLight.withValues(alpha: 0.30), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  _DashedRingPainter({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.0;
    const dashCount = 64;
    const dashLengthRatio = 0.55;
    const step = (2 * math.pi) / dashCount;
    for (int i = 0; i < dashCount; i++) {
      final start = i * step;
      final end = start + step * dashLengthRatio;
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(rect, start, end - start, false, paint);
    }
  }
  @override
  bool shouldRepaint(covariant _DashedRingPainter oldDelegate) => oldDelegate.color != color || oldDelegate.radius != radius;
}

class _GradientMesh extends StatefulWidget {
  const _GradientMesh();
  @override
  State<_GradientMesh> createState() => _GradientMeshState();
}

class _GradientMeshState extends State<_GradientMesh> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();
  }
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      // RepaintBoundary : isole le repaint plein écran du mesh animé du reste
      // de l'arbre (sinon chaque frame invalide tout le splash → jank au boot).
      child: RepaintBoundary(
        child: AnimatedBuilder(animation: _ctrl, builder: (_, __) => CustomPaint(painter: _MeshPainter(t: _ctrl.value), size: Size.infinite)),
      ),
    );
  }
}

class _MeshPainter extends CustomPainter {
  _MeshPainter({required this.t});
  final double t;
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()..color = AppColors.primaryLight.withValues(alpha: 0.16)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70);
    final paint2 = Paint()..color = AppColors.primary.withValues(alpha: 0.12)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
    final w = size.width; final h = size.height;
    final c1 = Offset(w * (0.30 + 0.18 * math.cos(t * 2 * math.pi * 0.7)), h * (0.28 + 0.10 * math.sin(t * 2 * math.pi * 1.1)));
    final c2 = Offset(w * (0.78 - 0.20 * math.cos(t * 2 * math.pi * 0.9)), h * (0.72 + 0.12 * math.sin(t * 2 * math.pi * 0.6)));
    canvas.drawCircle(c1, w * 0.45, paint1); canvas.drawCircle(c2, w * 0.50, paint2);
  }
  @override
  bool shouldRepaint(covariant _MeshPainter oldDelegate) => oldDelegate.t != t;
}

class _ConnectionLinesPainter extends CustomPainter {
  _ConnectionLinesPainter({required this.satellites, required this.orbitValue, required this.color, required this.fade});
  final List<({double radius, double speed, double phase})> satellites;
  final double orbitValue; final Color color; final double fade;
  @override
  void paint(Canvas canvas, Size size) {
    if (fade <= 0.001) return;
    final center = Offset(size.width / 2, size.height / 2);
    for (final sat in satellites) {
      final t = (orbitValue * sat.speed + sat.phase) % 1.0;
      final angle = t * 2 * math.pi;
      final dx = math.cos(angle) * sat.radius;
      final dy = math.sin(angle) * sat.radius;
      final depthFactor = (math.sin(angle - math.pi / 2) + 1) / 2;
      final lineOpacity = (fade * (0.05 + 0.30 * depthFactor)).clamp(0.0, 1.0);
      final paint = Paint()..color = color.withValues(alpha: lineOpacity)..strokeWidth = 1.0..strokeCap = StrokeCap.round;
      final startOffsetRatio = 32 / sat.radius;
      final start = Offset(center.dx + dx * startOffsetRatio, center.dy + dy * startOffsetRatio);
      final end = Offset(center.dx + dx, center.dy + dy);
      canvas.drawLine(start, end, paint);
    }
  }
  @override
  bool shouldRepaint(covariant _ConnectionLinesPainter oldDelegate) => oldDelegate.orbitValue != orbitValue || oldDelegate.fade != fade || oldDelegate.color != color;
}

class _BrandWordmark extends StatelessWidget {
  const _BrandWordmark({required this.intro});
  final Animation<double> intro;
  static const String _brand = 'OpporTune';
  static const String _suffix = ' BF';
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: intro,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < _brand.length; i++) _StaggerChar(char: _brand[i], delay: 0.30 + (i * 0.025), color: AppColors.titleColor, intro: intro),
            for (int i = 0; i < _suffix.length; i++) _StaggerChar(char: _suffix[i], delay: 0.30 + ((_brand.length + i) * 0.025), color: AppColors.primary, intro: intro),
          ],
        );
      },
    );
  }
}

class _StaggerChar extends StatelessWidget {
  const _StaggerChar({required this.char, required this.delay, required this.color, required this.intro});
  final String char; final double delay; final Color color; final Animation<double> intro;
  @override
  Widget build(BuildContext context) {
    final t = ((intro.value - delay) / 0.18).clamp(0.0, 1.0);
    final eased = Curves.easeOutCubic.transform(t);
    return Opacity(
      opacity: eased,
      child: Transform.translate(
        offset: Offset(0, (1 - eased) * 18),
        child: Text(char, style: AppTextStyles.displayMd.copyWith(fontSize: 32, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.5, height: 1.0)),
      ),
    );
  }
}

class _Tagline extends StatelessWidget {
  const _Tagline({required this.intro});
  final Animation<double> intro;
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: intro,
      builder: (_, __) {
        final t = ((intro.value - 0.65) / 0.25).clamp(0.0, 1.0);
        final eased = Curves.easeOutCubic.transform(t);
        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(0, (1 - eased) * 12),
            child: Text('Votre prochaine opportunité, à portée de main', style: AppTextStyles.bodyMd.copyWith(color: AppColors.bodyColor, letterSpacing: 0.4, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        );
      },
    );
  }
}

class _ModernProgress extends StatefulWidget {
  const _ModernProgress({required this.controller});
  final SplashController controller;
  @override
  State<_ModernProgress> createState() => _ModernProgressState();
}

class _ModernProgressState extends State<_ModernProgress> with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;
  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  }
  @override
  void dispose() { _shimmer.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final pct = widget.controller.progress.value;
      final fraction = (pct / 100).clamp(0.0, 1.0);
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                child: Text(widget.controller.loadingMessage, key: ValueKey(widget.controller.loadingMessage), style: AppTextStyles.labelMd.copyWith(color: AppColors.bodyColor, letterSpacing: 0.3, fontSize: 11)),
              ),
              Text('$pct%', style: AppTextStyles.splashPercent),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 5,
              child: LayoutBuilder(
                builder: (_, constraints) {
                  return Stack(
                    children: [
                      Container(width: double.infinity, color: AppColors.surfaceHighest),
                      AnimatedFractionallySizedBox(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        widthFactor: fraction,
                        child: Stack(
                          children: [
                            DecoratedBox(decoration: BoxDecoration(gradient: AppColors.primaryGradient)),
                            AnimatedBuilder(
                              animation: _shimmer,
                              builder: (_, __) {
                                final w = constraints.maxWidth * fraction;
                                final pos = _shimmer.value * (w + 60) - 60;
                                return Positioned(left: pos, top: 0, bottom: 0, width: 60, child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [AppColors.onPrimary.withValues(alpha: 0.0), AppColors.onPrimary.withValues(alpha: 0.45), AppColors.onPrimary.withValues(alpha: 0.0)]))));
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _BottomTag extends StatefulWidget {
  const _BottomTag();
  @override
  State<_BottomTag> createState() => _BottomTagState();
}

class _BottomTagState extends State<_BottomTag> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = Curves.easeInOut.transform(_ctrl.value);
        final size = 5 + t * 2; final opacity = 0.5 + t * 0.45;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PulseDot(size: size, opacity: opacity), const SizedBox(width: 12),
            Text('Burkina Faso  ·  Emploi  ·  Formation', style: AppTextStyles.labelSm.copyWith(color: AppColors.primaryMedium, letterSpacing: 1.6, fontSize: 10, fontWeight: FontWeight.w700)),
            const SizedBox(width: 12), _PulseDot(size: size, opacity: opacity),
          ],
        );
      },
    );
  }
}

class _PulseDot extends StatelessWidget {
  const _PulseDot({required this.size, required this.opacity});
  final double size; final double opacity;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryLight.withValues(alpha: opacity), boxShadow: [BoxShadow(color: AppColors.primaryLight.withValues(alpha: 0.45 * opacity), blurRadius: 6)]),
    );
  }
}

class _FloatingParticles extends StatefulWidget {
  const _FloatingParticles();
  @override
  State<_FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<_FloatingParticles> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final List<_ParticleSeed> _seeds = List.generate(10, (i) {
    final r = math.Random(i * 17 + 3);
    return _ParticleSeed(x: r.nextDouble(), size: 2.5 + r.nextDouble() * 6, speed: 0.6 + r.nextDouble() * 0.8, phase: r.nextDouble(), opacity: 0.10 + r.nextDouble() * 0.40);
  });
  @override
  void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat(); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(painter: _ParticlesPainter(seeds: _seeds, t: _ctrl.value, color: AppColors.primaryLight), size: Size.infinite),
      ),
    );
  }
}

class _ParticleSeed {
  const _ParticleSeed({required this.x, required this.size, required this.speed, required this.phase, required this.opacity});
  final double x; final double size; final double speed; final double phase; final double opacity;
}

class _ParticlesPainter extends CustomPainter {
  _ParticlesPainter({required this.seeds, required this.t, required this.color});
  final List<_ParticleSeed> seeds; final double t; final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    for (final seed in seeds) {
      final localT = (t * seed.speed + seed.phase) % 1.0;
      final y = (1.0 - localT) * size.height;
      final slalom = math.sin(localT * 2 * math.pi) * 18;
      final x = seed.x * size.width + slalom;
      double a = seed.opacity;
      if (localT < 0.1) a *= localT / 0.1;
      if (localT > 0.9) a *= (1 - localT) / 0.1;
      final paint = Paint()..color = color.withValues(alpha: a);
      canvas.drawCircle(Offset(x, y), seed.size / 2, paint);
    }
  }
  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) => oldDelegate.t != t;
}
