import 'package:flutter/material.dart';
import 'package:baara/app/core/theme/app_icons.dart';

import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_dimens.dart';
import 'package:baara/app/core/theme/app_shapes.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/widgets/common/brand_avatar.dart';
import 'package:baara/app/core/widgets/common/press_scale.dart';
import '../../domain/entities/network_user.dart';

/// Tuile membre réutilisable (résultats de recherche, demandes de connexion,
/// suggestions). Avatar + nom + rôle, action(s) à droite via [trailing].
class NetworkUserTile extends StatelessWidget {
  const NetworkUserTile({
    super.key,
    required this.user,
    this.onTap,
    this.trailing,
  });

  final NetworkUser user;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppShapes.cardRadius,
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          ...AppColors.ambientShadow,
          ...AppColors.lightShadow,
        ],
      ),
      child: Row(
        children: [
          // Hero lié vers l'avatar du profil public communautaire. La tuile
          // n'apparaît qu'une fois par utilisateur dans une liste donnée
          // (recherche, connexions, suggestions) → pas de collision de tag.
          Hero(
            tag: 'community-avatar-${user.id}',
            child: BrandAvatar(
              seed: user.id,
              label: user.fullName,
              size: 46,
              imageUrl: user.avatarUrl,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleMd.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.titleColor,
                        ),
                      ),
                    ),
                    if (user.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(AppIcons.shieldDone,
                          size: 14, color: AppColors.verified),
                    ],
                  ],
                ),
                if (user.role.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    user.role,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySm
                        .copyWith(color: AppColors.hintColor),
                  ),
                ],
                // Raison de la suggestion (IA / signaux réseau) — discrète,
                // optionnelle : présente uniquement sur les tuiles de
                // suggestion, jamais en recherche/connexions.
                if (user.hasReason) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        AppIcons.networkFilled,
                        size: 13,
                        color: AppColors.primaryAccent,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          user.reason!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelMd.copyWith(
                            color: AppColors.primaryAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                // Accroche IA (#3) — discrète, en italique, sous la reason.
                // Apparaît seulement après l'arrivée des insights (non bloquant).
                if (user.hasInsight) ...[
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 13,
                        color: AppColors.primaryAccent,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          user.insight!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.primaryAccent,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap == null) return card;
    return PressScale(onTap: onTap, child: card);
  }
}

/// Bouton « Suivre / Suivi » en pastille — cohérent avec le design system,
/// utilisé comme [NetworkUserTile.trailing] dans la recherche et les
/// suggestions. État suivi = fond tonal vert ; à suivre = contour neutre.
class FollowPillButton extends StatelessWidget {
  const FollowPillButton({
    super.key,
    required this.following,
    required this.onTap,
  });

  final bool following;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.primaryAccent;
    return PressScale(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 7),
        decoration: BoxDecoration(
          color:
              following ? accent.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: AppShapes.pill,
          border: Border.all(
            color: following
                ? accent.withValues(alpha: 0.4)
                : AppColors.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              following ? AppIcons.tickSquare : AppIcons.add,
              size: 15,
              color: following ? accent : AppColors.bodyColor,
            ),
            const SizedBox(width: 4),
            Text(
              following ? 'Suivi' : 'Suivre',
              style: AppTextStyles.labelMd.copyWith(
                color: following ? accent : AppColors.bodyColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
