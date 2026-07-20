import 'package:flutter/material.dart';

import 'package:jobaway/app/core/theme/app_colors.dart';
import 'package:jobaway/app/core/theme/app_motion.dart';
import 'package:jobaway/app/core/theme/app_shapes.dart';
import 'package:jobaway/app/core/theme/app_text_styles.dart';
import 'package:jobaway/app/core/widgets/widgets.dart';

/// Rangée de réponses suggérées (IA) au-dessus du composer. Apparition animée
/// (fade + slide), une puce par suggestion, préfixée d'une étincelle IA.
class ChatSmartRepliesBar extends StatelessWidget {
  const ChatSmartRepliesBar({
    super.key,
    required this.suggestions,
    required this.loading,
    required this.onTap,
  });

  final List<String> suggestions;
  final bool loading;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final visible = suggestions.isNotEmpty;
    return AnimatedSwitcher(
      duration: AppMotion.base,
      switchInCurve: AppMotion.enter,
      switchOutCurve: AppMotion.exit,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SizeTransition(
          sizeFactor: anim,
          child: child,
        ),
      ),
      child: !visible
          ? const SizedBox(width: double.infinity)
          : Container(
              key: const ValueKey('smart-replies'),
              width: double.infinity,
              color: AppColors.background,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  // Étiquette « IA » (étincelle + libellé) — identité visuelle
                  // commune, signale que les réponses sont suggérées par l'IA.
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.10),
                      borderRadius: AppShapes.pill,
                      border: Border.all(
                        color: AppColors.primaryAccent.withValues(alpha: 0.30),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            size: 13, color: AppColors.primaryAccent),
                        const SizedBox(width: 4),
                        Text(
                          'IA',
                          style: AppTextStyles.labelMd.copyWith(
                            color: AppColors.primaryAccent,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: suggestions.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final s = suggestions[i];
                          return Center(
                            child: PressScale(
                              onTap: () => onTap(s),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryAccent
                                      .withValues(alpha: 0.10),
                                  borderRadius: AppShapes.pill,
                                  border: Border.all(
                                    color: AppColors.primaryAccent
                                        .withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Text(
                                  s,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.labelMd.copyWith(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
