import "package:flutter/material.dart";
import '../../theme/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_shapes.dart';
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
    this.maxLines = 1,
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

  /// Nombre de lignes (1 = champ simple). > 1 → champ multiligne (ex. bio).
  final int maxLines;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _obscured;
  final FocusNode _focusNode = FocusNode();
  final _fieldKey = GlobalKey<FormFieldState<String>>();
  bool _focused = false;

  /// Un champ déjà en erreur se revalide à chaque frappe : le message
  /// disparaît dès que la saisie est correcte. Les autres champs ne sont pas
  /// vérifiés pendant la frappe (ce serait agaçant), seulement à l'envoi.
  void _onChanged(String value) {
    final field = _fieldKey.currentState;
    if (field != null && field.hasError) field.validate();
    widget.onChanged?.call(value);
  }

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus != _focused) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
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
                  _obscured ? AppIcons.show : AppIcons.hide,
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
        AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.emphasizedDecelerate,
          decoration: BoxDecoration(
            borderRadius: AppShapes.squircleRadius(AppRadius.lg),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: AppColors.primaryAccent.withValues(alpha: 0.18),
                      blurRadius: 22,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : const [],
          ),
          child: TextFormField(
            key: _fieldKey,
            controller: widget.controller,
            focusNode: _focusNode,
            keyboardType: widget.maxLines > 1
                ? TextInputType.multiline
                : widget.keyboardType,
            obscureText: _obscured,
            // Le toggle eye n'a de sens qu'en mono-ligne (password).
            maxLines: _obscured ? 1 : widget.maxLines,
            textAlignVertical: TextAlignVertical.top,
            validator: widget.validator,
            onChanged: _onChanged,
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
                child: AnimatedScale(
                  duration: AppMotion.short,
                  curve: AppMotion.spring,
                  scale: _focused ? 1.12 : 1.0,
                  child: Icon(
                    widget.icon,
                    color: _focused
                        ? AppColors.primaryAccent
                        : AppColors.primaryAccent.withValues(alpha: 0.85),
                    size: 20,
                  ),
                ),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 46, minHeight: 46),
              suffixIcon: effectiveSuffix,
              filled: true,
              fillColor: _focused ? AppColors.inputFill : AppColors.surfaceCard,
              border:
                  _outline(AppColors.outlineVariant.withValues(alpha: 0.55)),
              enabledBorder:
                  _outline(AppColors.outlineVariant.withValues(alpha: 0.55)),
              focusedBorder: _outline(AppColors.primaryAccent, width: 1.5),
              errorBorder: _outline(AppColors.errorAccent),
              focusedErrorBorder: _outline(AppColors.errorAccent, width: 1.5),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              helperText: widget.helper,
              helperStyle: AppTextStyles.bodySm.copyWith(
                color: AppColors.hintColor,
                fontSize: 11,
              ),
              errorStyle: AppTextStyles.bodySm.copyWith(
                color: AppColors.errorAccent,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _outline(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: AppShapes.squircleRadius(AppRadius.lg),
        borderSide: BorderSide(color: color, width: width),
      );
}
