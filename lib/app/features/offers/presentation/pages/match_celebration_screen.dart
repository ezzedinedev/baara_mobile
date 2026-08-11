import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:get/get.dart';

import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_dimens.dart';
import 'package:baara/app/core/theme/app_motion.dart';
import 'package:baara/app/core/theme/app_shapes.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/app/core/widgets/widgets.dart';

class MatchCelebrationScreen extends StatefulWidget {
  const MatchCelebrationScreen({super.key});

  @override
  State<MatchCelebrationScreen> createState() => _MatchCelebrationScreenState();
}

class _MatchCelebrationScreenState extends State<MatchCelebrationScreen>
    with TickerProviderStateMixin {
  late final ConfettiController _confettiController;
  late final AnimationController _pulseController;
  late final AnimationController _contentController;
  late final Animation<double> _pulseAnim;
  late final Animation<double> _badgePop;
  late final Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 6));
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    // Apparition de l'anneau/badge en ressort prononcé (overshoot festif 2026).
    _badgePop = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: AppMotion.springEmphasized,
      ),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _contentController, curve: AppMotion.springEmphasized));

    _confettiController.play();
    _contentController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => AppHaptics.confirm());
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _pulseController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final title = args['offerTitle'] as String? ?? '';
    final company = args['company'] as String? ?? '';
    final score = args['score'] as int? ?? 85;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.heroAccueilGradient),
        child: Stack(
          children: [
            const Positioned.fill(child: CustomPaint(painter: TopoPainter())),
            // Halo mesh de marque en fond (profondeur hero festive 2026).
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: AppColors.meshBrandGlow),
                ),
              ),
            ),
            // Trois émetteurs : une pluie depuis chaque coin haut, dirigée vers
            // l'intérieur, plus un burst explosif calé sur le badge. Un unique
            // émetteur `topCenter` explosif envoyait la moitié des particules
            // hors cadre, au-dessus de l'écran.
            Align(
              alignment: Alignment.topLeft,
              child: _MatchConfetti(
                controller: _confettiController,
                blastDirection: math.pi / 3,
                particles: 18,
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: _MatchConfetti(
                controller: _confettiController,
                blastDirection: 2 * math.pi / 3,
                particles: 18,
              ),
            ),
            Align(
              alignment: const Alignment(0, -0.42),
              child: _MatchConfetti(
                controller: _confettiController,
                particles: 24,
              ),
            ),
            SafeArea(
              child: Center(
                // Scrollable : à fort `textScaleFactor` la colonne dépasse la
                // hauteur d'un petit écran et déclenche un RenderFlex overflow.
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: SlideTransition(
                    position: _contentSlide,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ScaleTransition(
                          scale: _badgePop,
                          child: ScaleTransition(
                            scale: _pulseAnim,
                            child: Container(
                              width: 124,
                              height: 124,
                              decoration: BoxDecoration(
                                color:
                                    AppColors.onPrimary.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.onPrimary
                                      .withValues(alpha: 0.28),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.onPrimary
                                        .withValues(alpha: 0.22),
                                    blurRadius: 36,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                color: AppColors.onPrimary,
                                size: 60,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl + AppSpacing.sm),
                        Text(
                          'VOUS AVEZ MATCHÉ !',
                          style: AppTextStyles.headlineLg.copyWith(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl),
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xxl,
                              vertical: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.onPrimary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color:
                                  AppColors.onPrimary.withValues(alpha: 0.24),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(AppIcons.heartFilled,
                                  color: AppColors.onPrimary, size: 22),
                              const SizedBox(width: 8),
                              // Flexible : sans lui le Text prend sa largeur
                              // intrinsèque et la pastille déborde de l'écran dès
                              // que la police grossit (réglage d'accessibilité).
                              Flexible(
                                child: Text(
                                  '$score% de correspondance',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.titleLg.copyWith(
                                    color: AppColors.onPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            title,
                            style: AppTextStyles.headlineMd.copyWith(
                              color: AppColors.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          company,
                          style: AppTextStyles.titleMd.copyWith(
                            color: AppColors.onPrimary.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 48),
                        SizedBox(
                          width: 240,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              AppHaptics.tap();
                              // Retour à l'écran d'origine (deck d'accueil ou
                              // détail de l'offre). L'ancien
                              // `offNamedUntil('/accueil', (_) => true)` ne
                              // retirait aucune route — la célébration restait
                              // sous l'accueil et réapparaissait au retour.
                              Get.back<void>();
                            },
                            icon:
                                const Icon(AppIcons.arrowRight, size: 20),
                            label: Text(
                              'Continuer',
                              style: AppTextStyles.buttonLg.copyWith(
                                color: AppColors.primaryAccent,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.onPrimary,
                              foregroundColor: AppColors.primaryAccent,
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.lg),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    AppShapes.squircleRadius(AppRadius.md),
                              ),
                              elevation: 6,
                              shadowColor:
                                  AppColors.onDark.withValues(alpha: 0.25),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Un émetteur de confetti de l'écran de match. [blastDirection] est en radians
/// (0 = vers la droite, pi/2 = vers le bas) ; s'il est nul le blast est
/// explosif (omnidirectionnel). Les émetteurs partagent le même
/// [ConfettiController].
class _MatchConfetti extends StatelessWidget {
  const _MatchConfetti({
    required this.controller,
    required this.particles,
    this.blastDirection,
  });

  final ConfettiController controller;
  final int particles;
  final double? blastDirection;

  @override
  Widget build(BuildContext context) {
    return ConfettiWidget(
      confettiController: controller,
      blastDirectionality: blastDirection == null
          ? BlastDirectionality.explosive
          : BlastDirectionality.directional,
      blastDirection: blastDirection ?? 0,
      shouldLoop: false,
      colors: AppColors.celebrationOnBrandConfetti,
      numberOfParticles: particles,
      maxBlastForce: 22,
      minBlastForce: 8,
      gravity: 0.18,
      emissionFrequency: 0.04,
    );
  }
}
