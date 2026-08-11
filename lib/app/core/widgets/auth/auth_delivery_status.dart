import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_shapes.dart';
import '../../theme/app_text_styles.dart';
import '../common/app_animations.dart';

/// Statut d'envoi d'un code (OTP, reset…) — feedback visuel fluide.
enum AuthDeliveryPhase { idle, sending, sent, failed }

/// Bandeau animé : envoi en cours → code envoyé (ou erreur).
class AuthDeliveryStatus extends StatelessWidget {
  const AuthDeliveryStatus({
    super.key,
    required this.phase,
    this.destination = '',
    this.errorMessage = '',
  });

  final AuthDeliveryPhase phase;
  final String destination;
  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    if (phase == AuthDeliveryPhase.idle) return const SizedBox.shrink();

    final (icon, label, color, bg) = switch (phase) {
      AuthDeliveryPhase.sending => (
          null,
          destination.isNotEmpty
              ? 'Envoi du code à $destination…'
              : 'Envoi du code en cours…',
          AppColors.primaryAccent,
          AppColors.primaryAccent.withValues(alpha: 0.08),
        ),
      AuthDeliveryPhase.sent => (
          Icons.check_circle_rounded,
          destination.isNotEmpty
              ? 'Code envoyé à $destination'
              : 'Code envoyé',
          AppColors.primaryDark,
          AppColors.primaryDark.withValues(alpha: 0.08),
        ),
      AuthDeliveryPhase.failed => (
          Icons.error_outline_rounded,
          errorMessage.isNotEmpty ? errorMessage : 'Échec de l\'envoi',
          AppColors.error,
          AppColors.error.withValues(alpha: 0.08),
        ),
      AuthDeliveryPhase.idle => (null, '', AppColors.hintColor, Colors.transparent),
    };

    return RevealOnMount(
      child: AnimatedContainer(
        duration: AppMotion.medium,
        curve: AppMotion.emphasizedDecelerate,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppShapes.squircleRadius(AppRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            if (phase == AuthDeliveryPhase.sending)
              PulsingDot(color: AppColors.primaryAccent, size: 8)
            else if (icon != null)
              Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: AnimatedSwitcher(
                duration: AppMotion.short,
                child: Text(
                  label,
                  key: ValueKey(label),
                  style: AppTextStyles.bodySm.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
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
