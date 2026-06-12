import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/theme/app_theme_controller.dart';
import '../controllers/splash_controller.dart';

/// Splash sobre et performant : un seul [AnimationController] pour l'entrée
/// (fade + léger scale), pas de blur plein écran / particules / orbites pendant
/// le boot (le moment le plus sensible en perf). Logo centré, wordmark, tagline,
/// puis une barre de progression fine en bas. Tap n'importe où pour passer.
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
                        child: Text(
                          'Votre prochaine opportunité, à portée de main',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.titleColor.withValues(alpha: 0.72),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                            letterSpacing: 0.1,
                          ),
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
                        'Burkina Faso · Emploi · Formation',
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
        child: const _LogoMark(),
      ),
    );
  }
}

/// Logo de marque, affiché selon le thème : variante foncée sur fond clair,
/// variante blanche sur fond sombre (pour rester lisible dans les deux modes).
/// Repli sur une tuile-icône si les fichiers logo sont absents (aucun crash).
class _LogoMark extends StatelessWidget {
  const _LogoMark();

  // Texte foncé → fond clair ; texte blanc → fond sombre.
  static const String _logoDark = 'assets/images/logo/opportune_logo.png';
  static const String _logoLight =
      'assets/images/logo/opportune_logo_light.png';

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isRegistered<AppThemeController>() &&
        Get.find<AppThemeController>().isDarkMode.value;
    return SizedBox(
      width: 230,
      child: Image.asset(
        isDark ? _logoLight : _logoDark,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => _fallbackTile(),
      ),
    );
  }

  Widget _fallbackTile() {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.32),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Icon(IconlyLight.work, size: 52, color: AppColors.onPrimary),
    );
  }
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
                      RepaintBoundary(
                        child: AnimatedBuilder(
                          animation: _shimmer,
                          builder: (context, _) {
                            final pos =
                                _shimmer.value * (filledWidth + 60) - 60;
                            return Positioned(
                              left: pos,
                              top: 0,
                              bottom: 0,
                              width: 60,
                              child: DecoratedBox(
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
                            );
                          },
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
