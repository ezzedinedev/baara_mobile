import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';


class AuthTextField extends StatefulWidget {
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
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
  }

  void _toggleObscure() {
    setState(() => _obscured = !_obscured);
  }

  @override
  Widget build(BuildContext context) {
    // Si le champ est masque (password) et qu'aucun suffix custom n'est
    // fourni, on ajoute automatiquement le toggle eye.
    final Widget? effectiveSuffix = widget.suffix ??
        (widget.obscureText
            ? IconButton(
                tooltip: _obscured ? 'Afficher' : 'Masquer',
                onPressed: _toggleObscure,
                splashRadius: 18,
                icon: Icon(
                  _obscured ? IconlyLight.show : IconlyLight.hide,
                  size: 20,
                  color: AppColors.hintColor,
                ),
              )
            : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTextStyles.titleMd.copyWith(
            color: AppColors.titleColor,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: _obscured,
          validator: widget.validator,
          onChanged: widget.onChanged,
          style: AppTextStyles.bodyLg.copyWith(
            color: AppColors.titleColor,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTextStyles.bodyMd.copyWith(
              color: AppColors.hintColor,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(widget.icon, color: AppColors.primary, size: 20),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 46, minHeight: 46),
            suffixIcon: effectiveSuffix,
            filled: true,
            fillColor: AppColors.surfaceCard,
            border: _outline(AppColors.outlineVariant.withValues(alpha: 0.55)),
            enabledBorder:
                _outline(AppColors.outlineVariant.withValues(alpha: 0.55)),
            focusedBorder: _outline(AppColors.primary, width: 1.5),
            errorBorder: _outline(AppColors.error),
            focusedErrorBorder: _outline(AppColors.error, width: 1.5),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            helperText: widget.helper,
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

  OutlineInputBorder _outline(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );
}
