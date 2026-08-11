import 'package:flutter/material.dart';

import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_dimens.dart';

/// Indicateur "typing" : bulle reçue avec 3 points animés en cascade.
class ChatTypingBubble extends StatefulWidget {
  const ChatTypingBubble({super.key});

  @override
  State<ChatTypingBubble> createState() => _ChatTypingBubbleState();
}

class _ChatTypingBubbleState extends State<ChatTypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const SizedBox(width: 36),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.6),
                width: 1,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppRadius.lg * 1.7),
                topRight: Radius.circular(AppRadius.lg * 1.7),
                bottomLeft: Radius.circular(AppRadius.xs * 1.7),
                bottomRight: Radius.circular(AppRadius.lg * 1.7),
              ),
            ),
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final t = (_ctrl.value - i * 0.2) % 1.0;
                    final scale =
                        0.6 + 0.4 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
                    return Padding(
                      padding: EdgeInsets.only(right: i < 2 ? 5 : 0),
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: AppColors.primaryAccent
                                .withValues(alpha: 0.55 + 0.45 * scale),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
