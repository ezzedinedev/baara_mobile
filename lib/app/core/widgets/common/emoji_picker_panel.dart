import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Banque d'emojis (package `emoji_picker_flutter`) habillée à la charte
/// (dark-aware). Liée à un [TextEditingController] : l'emoji choisi est inséré
/// au curseur et le backspace efface le dernier caractère automatiquement.
class EmojiPickerPanel extends StatelessWidget {
  const EmojiPickerPanel({
    super.key,
    required this.controller,
    this.height = 300,
    this.onBackspace,
  });

  final TextEditingController controller;
  final double height;
  final VoidCallback? onBackspace;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: EmojiPicker(
        textEditingController: controller,
        onBackspacePressed: onBackspace,
        config: Config(
          height: height,
          locale: const Locale('fr'),
          emojiTextStyle: AppTextStyles.bodyLg,
          emojiViewConfig: EmojiViewConfig(
            backgroundColor: AppColors.surfaceCard,
            columns: 8,
            emojiSizeMax: 28,
            gridPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            buttonMode: ButtonMode.MATERIAL,
          ),
          categoryViewConfig: CategoryViewConfig(
            backgroundColor: AppColors.surfaceLow,
            indicatorColor: AppColors.primaryAccent,
            iconColor: AppColors.hintColor,
            iconColorSelected: AppColors.primaryAccent,
            backspaceColor: AppColors.primaryAccent,
            dividerColor: AppColors.outlineVariant,
          ),
          bottomActionBarConfig: BottomActionBarConfig(
            backgroundColor: AppColors.surfaceLow,
            buttonColor: AppColors.surfaceLow,
            buttonIconColor: AppColors.primaryAccent,
          ),
          searchViewConfig: SearchViewConfig(
            backgroundColor: AppColors.surfaceCard,
            buttonIconColor: AppColors.primaryAccent,
            hintText: 'Rechercher',
            hintTextStyle:
                AppTextStyles.bodyMd.copyWith(color: AppColors.hintColor),
          ),
        ),
      ),
    );
  }
}
