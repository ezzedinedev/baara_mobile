import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_text_styles.dart';

/// Libellé de section discret (uppercase, hint, lettré) posé au-dessus d'un
/// groupe de réglages ou d'une carte. Partagé entre Profil et Paramètres.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, AppSpacing.sm),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.labelSm.copyWith(
          color: AppColors.hintColor,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
