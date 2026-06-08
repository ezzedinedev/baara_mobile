import 'package:flutter/material.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/widgets/common/app_card.dart';
import 'package:opportune_bf/app/core/widgets/common/brand_avatar.dart';
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
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          BrandAvatar(
            seed: user.id,
            label: user.fullName,
            size: 46,
            imageUrl: user.avatarUrl,
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
                      const Icon(Icons.verified_rounded,
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
  }
}
