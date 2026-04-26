import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/core/theme/app_colors.dart';
import '../app/core/theme/app_text_styles.dart';

class InputField extends StatefulWidget {
  const InputField({
    super.key,
    this.label,
    required this.hint,
    required this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.inputFormatters,
    this.prefixIcon,
    this.prefixIconData,
    this.suffixIcon,
    this.readOnly = false,
    this.maxLines = 1,
    this.helper,
    this.filled = true,
    this.borderRadius = 12.0,
  });

  final String? label;
  final String hint;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;
  final IconData? prefixIconData;
  final Widget? suffixIcon;
  final bool readOnly;
  final int maxLines;
  final String? helper;
  final bool filled;
  final double borderRadius;

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    final prefix = widget.prefixIcon ??
        (widget.prefixIconData != null
            ? Icon(widget.prefixIconData, size: 19, color: AppColors.hintColor)
            : null);

    InputDecoration decoration({Widget? suffixIcon}) {
      return InputDecoration(
        hintText: widget.hint,
        hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.hintColor),
        filled: widget.filled,
        fillColor: widget.filled ? AppColors.surfaceLow : null,
        prefixIcon: prefix,
        suffixIcon: suffixIcon ?? widget.suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.18),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      );
    }

    Widget field({Widget? suffix, bool obscureText = false}) {
      return TextFormField(
        controller: widget.controller,
        obscureText: obscureText,
        keyboardType: widget.keyboardType,
        readOnly: widget.readOnly,
        validator: widget.validator,
        inputFormatters: widget.inputFormatters,
        maxLines: widget.isPassword ? 1 : widget.maxLines,
        style: AppTextStyles.bodyMd.copyWith(color: AppColors.titleColor, fontSize: 15),
        decoration: decoration(suffixIcon: suffix),
      );
    }

    final labelWidget = widget.label != null
        ? Text(
            widget.label!.toUpperCase(),
            style: AppTextStyles.labelLg.copyWith(
              color: AppColors.bodyColor,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
            ),
          )
        : null;

    final helperWidget = widget.helper != null
        ? Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              widget.helper!,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.hintColor, fontSize: 10),
            ),
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelWidget != null) ...[labelWidget, const SizedBox(height: 8)],
        if (widget.isPassword)
          StatefulBuilder(builder: (context, setLocalState) {
            return field(
              suffix: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.hintColor,
                  size: 20,
                ),
                onPressed: () => setLocalState(() => _obscure = !_obscure),
              ),
              obscureText: _obscure,
            );
          })
        else
          field(),
        if (helperWidget != null) helperWidget,
      ],
    );
  }
}
