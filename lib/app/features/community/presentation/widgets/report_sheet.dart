import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/common/app_toast.dart';
import '../controllers/community_controller.dart';

/// Feuille de signalement d'une publication : choix du motif (aligné sur les
/// valeurs acceptées par le backend) → POST report.
Future<void> showReportSheet(
  BuildContext context,
  CommunityController controller,
  String postId,
) {
  const reasons = <String, String>{
    'spam': 'Spam ou publicité',
    'harassment': 'Harcèlement',
    'inappropriate': 'Contenu inapproprié',
    'false_information': 'Fausse information',
  };

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Signaler la publication',
                style: AppTextStyles.titleLg
                    .copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Pourquoi signalez-vous ce contenu ?',
                style:
                    AppTextStyles.bodySm.copyWith(color: AppColors.hintColor)),
            const SizedBox(height: AppSpacing.md),
            for (final entry in reasons.entries)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(IconlyLight.danger, color: AppColors.hintColor),
                title: Text(entry.value, style: AppTextStyles.titleMd),
                onTap: () async {
                  AppHaptics.tap();
                  Navigator.of(ctx).pop();
                  final ok = await controller.reportPost(postId, entry.key);
                  if (ok) {
                    AppToast.success('Merci',
                        'Le signalement a été transmis à la modération.');
                  } else {
                    AppToast.error(
                        'Échec', 'Le signalement n\'a pas pu être envoyé.');
                  }
                },
              ),
          ],
        ),
      ),
    ),
  );
}
