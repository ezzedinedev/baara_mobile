import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_text_styles.dart';
import 'app_back_button.dart';

/// En-tête de sous-page unifié : bouton retour + titre (+ sous-titre optionnel)
/// aligné à gauche, sur fond clair. Utilisé par Paramètres, Mes documents, etc.
/// pour garantir un en-tête cohérent d'un écran à l'autre.
class AppSubHeader extends StatelessWidget {
  const AppSubHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            8, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
        child: Row(
          children: [
            AppBackButton(onTap: onBack),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleLg
                        .copyWith(fontWeight: FontWeight.w800),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.hintColor),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
