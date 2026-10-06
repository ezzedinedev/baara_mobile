import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:baara/app/core/theme/app_motion.dart';
import 'package:baara/app/core/theme/app_shapes.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/routes/app_routes.dart';
import 'package:baara/app/core/widgets/widgets.dart';

/// Écran d'accueil des visiteurs non connectés.
///
/// Composition : une photo plein écran (lent zoom « Ken Burns »), deux cartes
/// flottantes qui montrent l'app en action (une offre, une candidature
/// envoyée), puis le message et les actions dans la zone du pouce. L'app est
/// réservée aux candidats : aucun accès employeur ici. Le tout défile si la
/// taille de texte système est grande ; les animations s'arrêtent si l'utilisateur a
/// réduit les animations.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ken = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );
  // Flottement des cartes : une seule horloge, déphasée par carte.
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _ken.stop();
      _float.stop();
    } else {
      if (!_ken.isAnimating) _ken.repeat(reverse: true);
      if (!_float.isAnimating) _float.repeat();
    }
  }

  @override
  void dispose() {
    _ken.dispose();
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    // Petits écrans : on garde le message et les actions, pas les cartes.
    final showGlimpses = screenHeight >= 680;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: BaaraMark.brandForest,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: BaaraMark.brandForest,
        body: Stack(
          children: [
            Positioned.fill(child: _HeroPhoto(ken: _ken)),
            const Positioned.fill(child: _Scrim()),
            SafeArea(
              child: CustomScrollView(
                physics: const ClampingScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _TopBar(),
                          Expanded(
                            child: showGlimpses
                                ? _Glimpses(float: _float)
                                : const SizedBox(height: 24),
                          ),
                          const _Pitch(),
                          const SizedBox(height: 28),
                          RevealOnMount(
                            delay: const Duration(milliseconds: 320),
                            child: AuthCtaButton(
                              label: 'Créer mon compte',
                              backgroundColor: BaaraMark.brandLime,
                              foregroundColor: BaaraMark.brandForest,
                              onPressed: () =>
                                  Get.toNamed(AppRoutes.profileSelection),
                            ),
                          ),
                          const SizedBox(height: 12),
                          RevealOnMount(
                            delay: const Duration(milliseconds: 400),
                            child: _OutlineButton(
                              label: 'Se connecter',
                              onPressed: () =>
                                  Get.toNamed(AppRoutes.candidateLogin),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

/// Photo d'accueil avec un zoom lent et continu, cadrée sur le visage.
class _HeroPhoto extends StatelessWidget {
  const _HeroPhoto({required this.ken});

  final Animation<double> ken;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: ken,
          builder: (context, child) {
            final t = Curves.easeInOut.transform(ken.value);
            return Transform.scale(
              scale: 1.04 + 0.08 * t,
              alignment: Alignment(-0.1 + 0.2 * t, -0.55),
              child: child,
            );
          },
          child: Image.asset(
            'assets/images/landing/hero.jpg',
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.4),
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }
}

/// Voiles de lisibilité : léger en haut (barre d'état, logo), profond en bas
/// où se fond la photo dans le vert forêt qui porte le texte.
class _Scrim extends StatelessWidget {
  const _Scrim();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.38),
            Colors.black.withValues(alpha: 0.0),
            BaaraMark.brandForest.withValues(alpha: 0.0),
            BaaraMark.brandForest.withValues(alpha: 0.82),
            BaaraMark.brandForest,
          ],
          stops: const [0.0, 0.18, 0.40, 0.62, 0.80],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return RevealOnMount(
      offsetY: 0,
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            Semantics(
              label: 'Baara',
              image: true,
              child: Image.asset(
                'assets/images/logo/baara_logo_light.png',
                height: 30,
                filterQuality: FilterQuality.high,
                excludeFromSemantics: true,
                errorBuilder: (_, __, ___) => const BaaraMark(
                  size: 30,
                  color: Colors.white,
                  headColor: BaaraMark.brandLime,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Deux aperçus de l'app posés sur la photo, qui flottent doucement.
class _Glimpses extends StatelessWidget {
  const _Glimpses({required this.float});

  final Animation<double> float;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Stack(
        children: [
          Align(
            alignment: const Alignment(-1, -0.55),
            child: RevealOnMount(
              delay: const Duration(milliseconds: 420),
              offsetY: 18,
              child: _Floating(
                float: float,
                phase: 0,
                child: const _GlimpseCard(
                  icon: AppIcons.workFilled,
                  tint: BaaraMark.brandLime,
                  iconColor: BaaraMark.brandForest,
                  overline: 'Nouvelle offre',
                  title: 'Comptable junior',
                  subtitle: 'Ouagadougou · CDI',
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(1, 0.78),
            child: RevealOnMount(
              delay: const Duration(milliseconds: 560),
              offsetY: 18,
              child: _Floating(
                float: float,
                phase: 0.45,
                child: const _GlimpseCard(
                  icon: AppIcons.checkCircle,
                  tint: BaaraMark.brandForest,
                  iconColor: BaaraMark.brandLime,
                  overline: 'Candidature',
                  title: 'Envoyée au recruteur',
                  subtitle: 'Suivi en temps réel',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Floating extends StatelessWidget {
  const _Floating({
    required this.float,
    required this.phase,
    required this.child,
  });

  final Animation<double> float;
  final double phase;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: float,
        builder: (context, child) {
          final dy = math.sin((float.value + phase) * 2 * math.pi) * 5;
          return Transform.translate(offset: Offset(0, dy), child: child);
        },
        child: child,
      ),
    );
  }
}

/// Carte d'aperçu : toujours claire, quel que soit le thème, car elle est
/// posée sur une photo.
class _GlimpseCard extends StatelessWidget {
  const _GlimpseCard({
    required this.icon,
    required this.tint,
    required this.iconColor,
    required this.overline,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color tint;
  final Color iconColor;
  final String overline;
  final String title;
  final String subtitle;

  static const Color _ink = Color(0xFF14201A);
  static const Color _muted = Color(0xFF5B6B62);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 236),
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  overline.toUpperCase(),
                  style: AppTextStyles.labelSm.copyWith(
                    color: _muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMd.copyWith(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySm.copyWith(
                    color: _muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Le message : promesse et preuves.
class _Pitch extends StatelessWidget {
  const _Pitch();

  @override
  Widget build(BuildContext context) {
    final headline = AppTextStyles.displayHero.copyWith(
      fontSize: 34,
      height: 1.08,
      letterSpacing: -0.6,
      color: Colors.white,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RevealOnMount(
          delay: const Duration(milliseconds: 160),
          child: Semantics(
            header: true,
            child: Text.rich(
              TextSpan(
                style: headline,
                children: const [
                  TextSpan(text: 'Trouvez le '),
                  TextSpan(
                    text: 'travail',
                    style: TextStyle(color: BaaraMark.brandLime),
                  ),
                  TextSpan(text: '\nqui vous ressemble.'),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        RevealOnMount(
          delay: const Duration(milliseconds: 240),
          child: Text(
            'Offres vérifiées, CV gratuit et formations pour avancer '
            'au Burkina Faso.',
            style: AppTextStyles.bodyLg.copyWith(
              color: Colors.white.withValues(alpha: 0.80),
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _OutlineButton extends StatefulWidget {
  const _OutlineButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  State<_OutlineButton> createState() => _OutlineButtonState();
}

class _OutlineButtonState extends State<_OutlineButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: PressScale(
          curve: AppMotion.springEmphasized,
          onTap: () {
            AppHaptics.tap();
            widget.onPressed();
          },
          child: AnimatedContainer(
            duration: AppMotion.short,
            curve: AppMotion.emphasized,
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: AppShapes.pill,
              border: Border.all(
                color: Colors.white.withValues(alpha: _isHovered ? 0.9 : 0.42),
                width: 1.4,
              ),
              color: Colors.white.withValues(alpha: _isHovered ? 0.12 : 0.04),
            ),
            child: Center(
              child: Text(
                widget.label,
                style: AppTextStyles.buttonLg.copyWith(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
