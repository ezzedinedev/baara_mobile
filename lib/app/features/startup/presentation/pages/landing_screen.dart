import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:baara/app/core/constants/api_constants.dart';
import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_motion.dart';
import 'package:baara/app/core/theme/app_shapes.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/routes/app_routes.dart';
import 'package:baara/app/core/widgets/widgets.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  // Ken Burns : zoom + pan lents et continus du visuel d'accueil (cinéma).
  late final AnimationController _ken;

  @override
  void initState() {
    super.initState();
    _ken = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ken.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      body: Stack(
        children: [
          // Visuel hero animé (Ken Burns) — GPU pur (Transform), un seul
          // RepaintBoundary, pas de blur → fluide.
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _ken,
                builder: (context, child) {
                  final t = Curves.easeInOut.transform(_ken.value);
                  return Transform.scale(
                    scale: 1.05 + 0.12 * t,
                    alignment: Alignment(-0.25 + 0.5 * t, -0.35 + 0.2 * t),
                    child: child,
                  );
                },
                child: Image.asset(
                  'assets/images/landing/hero.jpg',
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: MediaQuery.sizeOf(context).height * 0.56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.primaryDark.withValues(alpha: 0.25),
                    AppColors.primaryDark.withValues(alpha: 0.60),
                    AppColors.primary.withValues(alpha: 0.92),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  28, 12, 28, 24 + (bottomInset > 0 ? 4 : 0)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  RevealOnMount(
                    child: Image.asset(
                      'assets/images/logo/baara_logo_light.png',
                      height: 34,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                  const Spacer(),
                  RevealOnMount(
                    child: Text(
                      'Bienvenue sur Baara.bf',
                      style: AppTextStyles.displayHero.copyWith(
                        fontSize: 38,
                        height: 1.05,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  RevealOnMount(
                    delay: const Duration(milliseconds: 80),
                    child: Container(
                      width: 52,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.onPrimary.withValues(alpha: 0.70),
                        borderRadius: AppShapes.pill,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  RevealOnMount(
                    delay: const Duration(milliseconds: 150),
                    child: Text(
                      'Application candidats : trouvez un emploi, suivez vos candidatures, formez-vous et développez votre réseau au Burkina Faso.',
                      style: AppTextStyles.bodyLg.copyWith(
                        color: AppColors.onPrimary.withValues(alpha: 0.90),
                        height: 1.5,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  RevealOnMount(
                    delay: const Duration(milliseconds: 240),
                    child: AuthCtaButton(
                      label: 'Créer un compte',
                      onPressed: () => Get.toNamed(AppRoutes.profileSelection),
                    ),
                  ),
                  const SizedBox(height: 12),
                  RevealOnMount(
                    delay: const Duration(milliseconds: 320),
                    child: _SecondaryButton(
                      label: 'Se connecter',
                      onPressed: () => Get.toNamed(AppRoutes.candidateLogin),
                    ),
                  ),
                  const SizedBox(height: 12),
                  RevealOnMount(
                    delay: const Duration(milliseconds: 400),
                    child: _SecondaryButton(
                      label: 'Je suis employeur',
                      onPressed: _openEmployerPortal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEmployerPortal() async {
    AppHaptics.tap();
    final uri = Uri.tryParse(ApiConstants.companyPortalWebUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _SecondaryButton extends StatefulWidget {
  const _SecondaryButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  State<_SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<_SecondaryButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
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
          height: 52,
          decoration: BoxDecoration(
            borderRadius: AppShapes.pill,
            border: Border.all(
              color: AppColors.onPrimary
                  .withValues(alpha: _isHovered ? 0.90 : 0.50),
              width: _isHovered ? 1.6 : 1.2,
            ),
            color: _isHovered
                ? AppColors.onPrimary.withValues(alpha: 0.10)
                : Colors.transparent,
          ),
          child: Center(
            child: Text(
              widget.label,
              style: AppTextStyles.buttonLg.copyWith(
                color: AppColors.onPrimary
                    .withValues(alpha: _isHovered ? 1.0 : 0.85),
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
