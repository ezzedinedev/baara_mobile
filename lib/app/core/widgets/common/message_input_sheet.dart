import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Feuille de saisie de message (remplace les AlertDialog de formulaire).
Future<String?> showMessageInputSheet({
  required BuildContext context,
  required String title,
  required String hint,
  bool required = false,
  String confirmLabel = 'Envoyer',
}) {
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();

  return showModalBottomSheet<String?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetCtx) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          20 + MediaQuery.of(sheetCtx).viewInsets.bottom,
        ),
        child: Form(
          key: formKey,
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
                title,
                style: AppTextStyles.titleLg.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller,
                autofocus: true,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(hintText: hint),
                validator: (value) =>
                    required && (value == null || value.trim().isEmpty)
                        ? 'Message requis'
                        : null,
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
                      onPressed: () {
                        if (formKey.currentState?.validate() != true) return;
                        Navigator.of(sheetCtx).pop(controller.text.trim());
                      },
                      child: Text(confirmLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
