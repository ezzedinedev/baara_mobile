import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Champ de texte auth : label au-dessus, icône à gauche, underline discret,
/// suffix (pour œil masqué/visible par ex.). Style différent du `InputField`
/// existant qui a un fond rempli — celui-ci est plus épuré, comme les mockups
/// Welcome / Sign up.
///
/// **Toggle eye automatique** : si `obscureText: true` est passe et que
/// `suffix` n'est pas fourni, le widget rend automatiquement un bouton
/// œil ouvert/ferme qui bascule la visibilite du mot de passe. Cela
/// evite que chaque ecran qui a un champ password recode le toggle.
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
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: _obscured,
          validator: widget.validator,
          onChanged: widget.onChanged,
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.titleColor),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTextStyles.bodyMd.copyWith(
              color: AppColors.hintColor,
            ),
            prefixIcon:
                Icon(widget.icon, color: AppColors.hintColor, size: 20),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
            suffixIcon: effectiveSuffix,
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

  UnderlineInputBorder _underline(Color color, {double width = 1}) =>
      UnderlineInputBorder(borderSide: BorderSide(color: color, width: width));
}
