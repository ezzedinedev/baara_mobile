import 'package:flutter/material.dart';

import '../../app/core/theme/app_colors.dart';
import '../../app/core/theme/app_text_styles.dart';

/// Champ de texte auth : label au-dessus, icône à gauche, underline discret,
/// suffix (pour œil masqué/visible par ex.). Style différent du `InputField`
/// existant qui a un fond rempli — celui-ci est plus épuré, comme les mockups
/// Welcome / Sign up.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.suffix,
    this.helper,
    this.onChanged,
  });

  final String label;
  final String? hint;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final String? helper;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.titleMd.copyWith(
            color: AppColors.titleColor,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          onChanged: onChanged,
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.titleColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMd.copyWith(
              color: AppColors.hintColor,
            ),
            prefixIcon: Icon(icon, color: AppColors.hintColor, size: 20),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
            suffixIcon: suffix,
            filled: false,
            // Le `hintColor` est dark-aware : gris-clair en mode clair,
            // gris-visible en mode sombre — underline toujours lisible.
            border: _underline(AppColors.hintColor.withValues(alpha: 0.4)),
            enabledBorder:
                _underline(AppColors.hintColor.withValues(alpha: 0.4)),
            focusedBorder: _underline(AppColors.primary, width: 1.8),
            errorBorder: _underline(AppColors.error),
            focusedErrorBorder: _underline(AppColors.error, width: 1.8),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            helperText: helper,
            helperStyle: AppTextStyles.bodySm.copyWith(
              color: AppColors.hintColor,
              fontSize: 11,
            ),
            errorStyle: AppTextStyles.bodySm.copyWith(
              color: AppColors.error,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  UnderlineInputBorder _underline(Color color, {double width = 1}) =>
      UnderlineInputBorder(borderSide: BorderSide(color: color, width: width));
}
