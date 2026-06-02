import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/haptics.dart';

/// Dialogue de confirmation "Settings Updated!" style UI 2026.
/// Design ultra-moderne, sombre, avec illustration circulaire et bouton large.
class SettingsUpdatedDialog extends StatefulWidget {
  const SettingsUpdatedDialog({super.key});

  static Future<void> show() async {
    await Get.bottomSheet(
      const SettingsUpdatedDialog(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enterBottomSheetDuration: const Duration(milliseconds: 500),
      exitBottomSheetDuration: const Duration(milliseconds: 300),
    );
  }

  @override
  State<SettingsUpdatedDialog> createState() => _SettingsUpdatedDialogState();
}

class _SettingsUpdatedDialogState extends State<SettingsUpdatedDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C2E), // Fond encore plus profond
        borderRadius: const BorderRadius.vertical(top: Radius.circular(42)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Illustration circulaire avec animation de scale
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.settings_outlined,
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  Positioned(
                    bottom: 24,
                    right: 24,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Titre avec animation d'entrée
          FadeInAnimation(
            duration: const Duration(milliseconds: 600),
            child: Text(
              'Préférences enregistrées',
              style: AppTextStyles.displayMd.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 30,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Description
          FadeInAnimation(
            duration: const Duration(milliseconds: 800),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Vos changements sont appliqués immédiatement. Vous pourrez les ajuster à tout moment.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd.copyWith(
                  color: Colors.white.withValues(alpha: 0.6),
                  height: 1.5,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),
          // Bouton Confirm
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 22),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
                ),
              ),
              onPressed: () {
                AppHaptics.tap();
                Get.back();
              },
              child: Text(
                'Terminé',
                style: AppTextStyles.titleLg.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
