import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// État vide moderne : icône avec halo pulsé, titre, sous-titre, CTA optionnel.
class EmptyState extends StatefulWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? accent;

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent ?? AppColors.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                final t = Curves.easeInOut.transform(_ctrl.value);
                return SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 140 - 30 * t,
                        height: 140 - 30 * t,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.05 + 0.05 * t),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 110 - 18 * t,
                        height: 110 - 18 * t,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.08 + 0.06 * t),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.18 + 0.10 * t),
                              blurRadius: 18 + 12 * t,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(widget.icon, size: 36, color: accent),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 22),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleLg.copyWith(
                color: AppColors.titleColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.bodyColor,
                height: 1.45,
              ),
            ),
            if (widget.actionLabel != null && widget.onAction != null) ...[
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: widget.onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  widget.actionLabel!,
                  style: AppTextStyles.titleMd.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
