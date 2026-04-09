import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../../widgets/opportune_logo.dart';
import 'splash_controller.dart';

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.splashBackground),
          ),
          Positioned(
            top: size.height * 0.085,
            left: size.width * 0.155,
            child: const _DecorativeDot(size: 8, opacity: 0.85),
          ),
          Positioned(
            top: size.height * 0.13,
            right: size.width * 0.18,
            child: const _DecorativeDot(size: 5, opacity: 0.35),
          ),
          Positioned(
            top: size.height * 0.38,
            left: size.width * 0.08,
            child: const _DecorativeDot(size: 4, opacity: 0.20),
          ),
          Positioned(
            bottom: size.height * 0.065,
            right: size.width * 0.08,
            child: const _DecorativeDot(size: 8, opacity: 0.80),
          ),
          Positioned(
            bottom: size.height * 0.12,
            left: size.width * 0.12,
            child: const _DecorativeDot(size: 4, opacity: 0.25),
          ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: size.height * 0.12),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primaryLight.withValues(alpha: 0.14),
                            AppColors.primaryLight.withValues(alpha: 0.06),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                    Container(
                      width: 132,
                      height: 132,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(34),
                        boxShadow: AppColors.glowShadow,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.work_rounded,
                          size: 62,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 38),
                const OpportuneLogo(
                  iconSize: 0,
                  fontSize: 36,
                  showIcon: false,
                  centerAlign: true,
                ),
                const SizedBox(height: 10),
                Text(
                  'Votre carrière commence ici',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.hintColor,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 56),
                  child: Obx(
                    () {
                      final pct = controller.progress.value;
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                controller.loadingMessage,
                                style: AppTextStyles.labelMd.copyWith(
                                  color: AppColors.bodyColor,
                                  letterSpacing: 0.3,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                '$pct%',
                                style: AppTextStyles.splashPercent,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: SizedBox(
                              height: 3,
                              child: Stack(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    color: AppColors.surfaceHighest,
                                  ),
                                  AnimatedFractionallySizedBox(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeOut,
                                    widthFactor: pct / 100,
                                    child: const DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: AppColors.primaryGradient,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _DecorativeDot(size: 6, opacity: 0.9),
                    const SizedBox(width: 10),
                    Text(
                      'Burkina Faso  ·  Emploi  ·  Formation',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.primaryMedium,
                        letterSpacing: 1.5,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const _DecorativeDot(size: 6, opacity: 0.9),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DecorativeDot extends StatelessWidget {
  const _DecorativeDot({
    required this.size,
    this.opacity = 1,
  });

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryLight.withValues(alpha: opacity),
      ),
    );
  }
}
