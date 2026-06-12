import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_motion.dart';
import 'package:opportune_bf/app/core/theme/app_shapes.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';

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
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  AppColors.onPrimary,
                  AppColors.celebrationGold,
                  AppColors.secondary,
                  AppColors.celebrationGreen,
                ],
                numberOfParticles: 30,
                maxBlastForce: 20,
                minBlastForce: 5,
                gravity: 0.15,
              ),
            ),
            SafeArea(
              child: Center(
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
                                color:
                                    AppColors.onPrimary.withValues(alpha: 0.28),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xxl,
                            vertical: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.onPrimary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: AppColors.onPrimary.withValues(alpha: 0.24),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(IconlyBold.heart,
                                color: AppColors.onPrimary, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              '$score% de correspondance',
                              style: AppTextStyles.titleLg.copyWith(
                                color: AppColors.onPrimary,
                                fontWeight: FontWeight.w700,
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
                            Get.offNamedUntil('/accueil', (_) => true);
                          },
                          icon: const Icon(IconlyLight.arrow_right_2, size: 20),
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
          ],
        ),
      ),
    );
  }
}
