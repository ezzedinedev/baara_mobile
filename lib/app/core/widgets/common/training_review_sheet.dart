import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_text_styles.dart';

/// Feuille d'avis formation (remplace l'AlertDialog legacy).
Future<({int rating, String comment})?> showTrainingReviewSheet({
  required BuildContext context,
}) {
  var rating = 5;
  final commentCtrl = TextEditingController();

  return showModalBottomSheet<({int rating, String comment})?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetCtx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              20 + MediaQuery.of(sheetCtx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHighest,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Votre avis',
                  style: AppTextStyles.titleLg.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 1; i <= 5; i++)
                      IconButton(
                        onPressed: () => setState(() => rating = i),
                        icon: Icon(
                          i <= rating ? AppIcons.starFilled : AppIcons.star,
                          color: AppColors.warningAccent,
                        ),
                      ),
                  ],
                ),
                TextField(
                  controller: commentCtrl,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Commentaire optionnel',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(sheetCtx).pop(null),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(sheetCtx).pop(
                          (rating: rating, comment: commentCtrl.text),
                        ),
                        child: const Text('Envoyer'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  ).whenComplete(commentCtrl.dispose);
}
