import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_dimens.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/widgets/baara_mark.dart';
import '../controllers/splash_controller.dart';

/// Splash sobre et performant : un seul [AnimationController] pour l'entrée
/// (fade + léger scale), pas de blur plein écran / particules / orbites pendant
/// le boot (le moment le plus sensible en perf). Symbole de marque centré,
/// tagline, puis une barre de progression fine en bas. Tap n'importe où pour
/// passer.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  // Boucle douce et continue (respiration du logo + halo). Animations GPU
  // (Transform/Opacity) uniquement — pas de blur par frame → zéro jank.
  late final AnimationController _ambient;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _intro.dispose();
    _ambient.dispose();
    super.dispose();
  }

  /// Valeur 0→1 interpolée sur un intervalle de [_intro], avec courbe.
  double _seg(double begin, double end, Curve curve) {
    final t = ((_intro.value - begin) / (end - begin)).clamp(0.0, 1.0);
    return curve.transform(t);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SplashController>();

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: controller.skip,
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.splashBackground),
          child: SafeArea(
            child: AnimatedBuilder(
              animation: _intro,
              builder: (context, _) {
                final logoIn = _seg(0.0, 0.45, Curves.easeOut);
                final logoScale =
                    0.90 + 0.10 * _seg(0.0, 0.55, Curves.easeOutBack);
                final taglineIn = _seg(0.40, 0.80, Curves.easeOutCubic);
                final footerIn = _seg(0.55, 1.0, Curves.easeOut);

                return Column(
                  children: [
                    const Spacer(flex: 5),
                    Opacity(
                      opacity: logoIn,
                      child: Transform.scale(
                        scale: logoScale,
                        child: _BreathingLogo(ambient: _ambient),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _FadeSlide(
                      t: taglineIn,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 280),
                        child: Builder(
                          builder: (context) {
                            // Style commun : le mot animé doit couler dans la
                            // phrase sans décrochage de ligne de base.
                            final base = AppTextStyles.bodyMd.copyWith(
                              color:
                                  AppColors.titleColor.withValues(alpha: 0.72),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                              letterSpacing: 0.1,
                            );
                            return Text.rich(
                              TextSpan(
                                style: base,
                                children: [
                                  const TextSpan(text: 'Votre prochaine '),
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.baseline,
                                    baseline: TextBaseline.alphabetic,
                                    child: _ShimmerWord(
                                      'opportunité',
                                      // Même métrique que le reste : seul le
                                      // poids + le reflet changent.
                                      style: base.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const TextSpan(text: ', à portée de main'),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            );
                          },
                        ),
                      ),
                    ),
                    const Spacer(flex: 6),
                    Opacity(
                      opacity: footerIn,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: _ProgressBar(controller: controller),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Opacity(
                      opacity: footerIn,
                      child: Text(
                        'Baara.bf · Burkina Faso',
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.primaryMedium,
                          letterSpacing: 1.4,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo + halo lumineux qui respire doucement. Animations GPU pures
/// (Transform.scale + Opacity + dégradé radial), isolées dans un RepaintBoundary
/// → fluide même pendant le boot.
class _BreathingLogo extends StatelessWidget {
  const _BreathingLogo({required this.ambient});
  final Animation<double> ambient;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: ambient,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(ambient.value);
          final breath = 1.0 + 0.022 * t;
          // Halo doux, CIRCULAIRE et CENTRÉ (plus de rectangle désaxé qui
          // débordait à droite du wordmark = la « tache »). Lumière ambiante
          // discrète qui respire, pas un blob localisé.
          final glowOpacity = 0.10 + 0.16 * t;
          final glowScale = 0.94 + 0.12 * t;
          return SizedBox(
            width: 300,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: glowScale,
                  child: Opacity(
                    opacity: glowOpacity,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primaryMedium.withValues(alpha: 0.55),
                            AppColors.primaryMedium.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.72],
                        ),
                      ),
                    ),
                  ),
                ),
                Transform.scale(scale: breath, child: child),
              ],
            ),
          );
        },
        // Le lockup officiel (symbole + wordmark) : image PNG de marque
        // haute fidélité.
        child: const _LogoLockup(),
      ),
    );
  }
}

/// Affiche le logo complet (Pictogramme + Texte) de Baara.
class _LogoLockup extends StatelessWidget {
  const _LogoLockup();

  // Noms de fichiers en minuscules pour correspondre aux assets réels
  static const String _logoDark = 'assets/images/logo/baara_logo.png';
  static const String _logoLight = 'assets/images/logo/baara_logo_light.png';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: Image.asset(
        Get.isDarkMode ? _logoLight : _logoDark,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        // Repli sur le symbole vectoriel si le PNG est manquant.
        errorBuilder: (context, error, stackTrace) => const BaaraMark(size: 132),
      ),
    );
  }
}

/// Un mot mis en avant par un reflet lumineux qui le balaie en boucle.
///
/// Rendu via [ShaderMask] : un dégradé vert (accent → éclat → accent) dont la
/// bande claire glisse de gauche à droite. Le mot reste net et coule dans la
/// phrase (mêmes métriques que le texte porteur). Animation purement GPU,
/// isolée dans un [RepaintBoundary] → coût négligeable même pendant le boot.
class _ShimmerWord extends StatefulWidget {
  const _ShimmerWord(this.word, {required this.style});

  final String word;
  final TextStyle style;

  @override
  State<_ShimmerWord> createState() => _ShimmerWordState();
}

class _ShimmerWordState extends State<_ShimmerWord>
    with SingleTickerProviderStateMixin {
  // Contrôleur dédié, une seule direction : un reflet va-et-vient (reverse)
  // aurait l'air d'un balancier, pas d'une brillance qui passe.
  late final _shine = _RepeatingTicker(this);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _shine.controller,
        builder: (context, child) {
          final v = _shine.controller.value;
          // Position de la bande d'éclat, débordant des deux côtés pour qu'elle
          // entre et sorte complètement du mot à chaque passage.
          final p = -0.3 + 1.6 * v;
          return ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: const [
                  AppColors.primaryDark, // accent lisible sur fond clair
                  AppColors.primaryLight, // l'éclat qui passe
                  AppColors.primaryDark,
                ],
                stops: [
                  (p - 0.3).clamp(0.0, 1.0),
                  p.clamp(0.0, 1.0),
                  (p + 0.3).clamp(0.0, 1.0),
                ],
              ).createShader(bounds);
            },
            child: child,
          );
        },
        child: Text(widget.word, style: widget.style),
      ),
    );
  }

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }
}

/// Petit ticker répétitif encapsulé, pour ne pas alourdir l'état de l'écran.
class _RepeatingTicker {
  _RepeatingTicker(TickerProvider vsync)
      : controller = AnimationController(
          vsync: vsync,
          duration: const Duration(milliseconds: 2200),
        )..repeat();

  final AnimationController controller;

  void dispose() => controller.dispose();
}

/// Fade + léger glissement vers le haut, piloté par une valeur 0→1.
class _FadeSlide extends StatelessWidget {
  const _FadeSlide({required this.t, required this.child});
  final double t;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, (1 - t) * 14),
        child: child,
      ),
    );
  }
}

/// Barre de progression fine + message + pourcentage, avec un reflet (shimmer)
/// qui balaie la portion remplie. Seule cette zone se reconstruit (Obx + le
/// shimmer isolé en RepaintBoundary) → coût négligeable.
class _ProgressBar extends StatefulWidget {
  const _ProgressBar({required this.controller});
  final SplashController controller;

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final pct = widget.controller.progress.value;
      final fraction = (pct / 100).clamp(0.0, 1.0);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: Text(
                  widget.controller.loadingMessage,
                  key: ValueKey(widget.controller.loadingMessage),
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.bodyColor,
                    fontSize: 11,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Text('$pct%', style: AppTextStyles.splashPercent),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: SizedBox(
              height: 5,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final filledWidth = constraints.maxWidth * fraction;
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: ColoredBox(color: AppColors.surfaceHighest),
                      ),
                      AnimatedFractionallySizedBox(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        widthFactor: fraction,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient),
                        ),
                      ),
                      // Reflet qui balaie la partie remplie.
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: filledWidth,
                        child: ClipRect(
                          child: AnimatedBuilder(
                            animation: _shimmer,
                            builder: (context, _) {
                              final pos =
                                  _shimmer.value * (filledWidth + 60) - 60;
                              return Transform.translate(
                                offset: Offset(pos, 0),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    width: 60,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.onPrimary
                                              .withValues(alpha: 0.0),
                                          AppColors.onPrimary
                                              .withValues(alpha: 0.45),
                                          AppColors.onPrimary
                                              .withValues(alpha: 0.0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
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
