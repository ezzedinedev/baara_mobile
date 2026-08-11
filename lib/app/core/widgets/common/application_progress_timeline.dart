import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_shapes.dart';
import '../../theme/app_text_styles.dart';
import '../../../features/offers/data/models/application_model.dart';

/// Timeline horizontale de suivi candidature (4 étapes).
class ApplicationProgressTimeline extends StatelessWidget {
  const ApplicationProgressTimeline({
    super.key,
    required this.status,
    this.compact = false,
  });

  final ApplicationStatus status;
  final bool compact;

  static const _steps = ['Envoyée', 'Présélection', 'Entretien', 'Décision'];

  int get _activeIndex => switch (status) {
        ApplicationStatus.newApp => 0,
        ApplicationStatus.shortlisted => 1,
        ApplicationStatus.interview => 2,
        ApplicationStatus.rejected => 3,
      };

  @override
  Widget build(BuildContext context) {
    final active = _activeIndex;
    final rejected = status == ApplicationStatus.rejected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < _steps.length; i++) ...[
              if (i > 0)
                Expanded(
                  child: AnimatedContainer(
                    duration: AppMotion.short,
                    height: compact ? 2 : 3,
                    margin: EdgeInsets.only(bottom: compact ? 0 : 2),
                    decoration: BoxDecoration(
                      color: i <= active
                          ? (rejected && i == 3
                              ? AppColors.errorAccent
                              : AppColors.primaryAccent)
                          : AppColors.outlineVariant.withValues(alpha: 0.45),
                      borderRadius: AppShapes.pill,
                    ),
                  ),
                ),
              _StepDot(
                label: _steps[i],
                filled: i <= active,
                active: i == active,
                error: rejected && i == 3,
                compact: compact,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.label,
    required this.filled,
    required this.active,
    required this.error,
    required this.compact,
  });

  final String label;
  final bool filled;
  final bool active;
  final bool error;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = error
        ? AppColors.errorAccent
        : filled
            ? AppColors.primaryAccent
            : AppColors.outlineVariant;

    return Column(
      children: [
        AnimatedContainer(
          duration: AppMotion.short,
          width: active ? (compact ? 10 : 12) : (compact ? 8 : 10),
          height: active ? (compact ? 10 : 12) : (compact ? 8 : 10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? color : Colors.transparent,
            border: Border.all(color: color, width: active ? 2 : 1.4),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 6),
          SizedBox(
            width: 58,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSm.copyWith(
                fontSize: 9,
                color: active ? AppColors.titleColor : AppColors.hintColor,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
