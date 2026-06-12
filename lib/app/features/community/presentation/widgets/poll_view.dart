import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_motion.dart';
import 'package:opportune_bf/app/core/theme/app_shapes.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/relative_time.dart';
import 'package:opportune_bf/app/core/widgets/common/press_scale.dart';
import '../../domain/entities/post.dart';

/// Widget de vote/résultats d'un sondage attaché à une publication.
///
/// - Avant vote (et tant que le sondage est ouvert) : chaque option est une
///   ligne tappable.
/// - Après vote OU une fois clôturé : barres avec remplissage animé montrant le
///   pourcentage, total des votes, coche sur mes choix.
class PollView extends StatelessWidget {
  const PollView({super.key, required this.poll, this.onVote});

  final PostPoll poll;
  final void Function(String optionId)? onVote;

  @override
  Widget build(BuildContext context) {
    final showResults = poll.showResults;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: AppShapes.squircleRadius(AppRadius.sm),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((poll.question ?? '').trim().isNotEmpty) ...[
            Text(
              poll.question!.trim(),
              style: AppTextStyles.labelLg.copyWith(
                color: AppColors.titleColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          for (var i = 0; i < poll.options.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            _PollOptionRow(
              option: poll.options[i],
              fraction: poll.fractionFor(poll.options[i]),
              showResults: showResults,
              canVote: !poll.isClosed && onVote != null,
              onTap: (!poll.isClosed && onVote != null)
                  ? () => onVote!(poll.options[i].id)
                  : null,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          _footer(),
        ],
      ),
    );
  }

  Widget _footer() {
    final parts = <String>[
      '${poll.totalVotes} vote${poll.totalVotes > 1 ? 's' : ''}',
      if (poll.multiple) 'Choix multiples',
    ];
    final closeText = poll.isClosed
        ? 'Sondage terminé'
        : (poll.closesAt != null
            ? 'Se termine ${relativeTimeFr(poll.closesAt!)}'
            : null);
    return Row(
      children: [
        Icon(
          poll.isClosed ? IconlyLight.lock : IconlyLight.chart,
          size: 13,
          color: AppColors.hintColor,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            parts.join('  ·  '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.hintColor,
              fontSize: 12,
            ),
          ),
        ),
        if (closeText != null)
          Text(
            closeText,
            style: AppTextStyles.bodySm.copyWith(
              color:
                  poll.isClosed ? AppColors.primaryAccent : AppColors.hintColor,
              fontSize: 12,
              fontWeight: poll.isClosed ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
      ],
    );
  }
}

/// Une ligne d'option : bascule animée entre l'état « tappable » et l'état
/// « barre de résultat » (remplissage animé + %).
class _PollOptionRow extends StatelessWidget {
  const _PollOptionRow({
    required this.option,
    required this.fraction,
    required this.showResults,
    required this.canVote,
    this.onTap,
  });

  final PollOption option;
  final double fraction;
  final bool showResults;
  final bool canVote;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final mine = option.votedByMe;
    final percent = (fraction * 100).round();

    final content = ClipRRect(
      borderRadius: AppShapes.squircleRadius(AppRadius.xs),
      child: Stack(
        children: [
          // Fond de la barre.
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: AppShapes.squircleRadius(AppRadius.xs),
              border: Border.all(
                color:
                    mine ? AppColors.primaryAccent : AppColors.outlineVariant,
                width: mine ? 1.5 : 1,
              ),
            ),
          ),
          // Remplissage animé proportionnel (résultats uniquement).
          if (showResults)
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: fraction),
                duration: AppMotion.slow,
                curve: AppMotion.standard,
                builder: (context, value, _) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          (mine ? AppColors.primaryAccent : AppColors.primary)
                              .withValues(alpha: mine ? 0.22 : 0.12),
                      borderRadius: AppShapes.squircleRadius(AppRadius.xs),
                    ),
                  ),
                ),
              ),
            ),
          // Libellé + (coche) + %.
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  if (mine) ...[
                    Icon(IconlyBold.tick_square,
                        size: 16, color: AppColors.primaryAccent),
                    const SizedBox(width: 7),
                  ],
                  Expanded(
                    child: Text(
                      option.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.titleColor,
                        fontWeight: mine ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                  if (showResults) ...[
                    const SizedBox(width: 8),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: percent.toDouble()),
                      duration: AppMotion.slow,
                      curve: AppMotion.standard,
                      builder: (context, value, _) => Text(
                        '${value.round()}%',
                        style: AppTextStyles.labelMd.copyWith(
                          color: mine
                              ? AppColors.primaryAccent
                              : AppColors.bodyColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (!canVote) return content;
    return PressScale(onTap: onTap, child: content);
  }
}
