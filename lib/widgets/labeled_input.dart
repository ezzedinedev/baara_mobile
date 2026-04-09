import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../app/core/theme/app_colors.dart';
import '../app/core/theme/app_text_styles.dart';

class LabeledInput extends StatefulWidget {
  const LabeledInput({
    super.key,
    required this.label,
    required this.placeholder,
    required this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.inputFormatters,
    this.prefixIcon,
    this.readOnly = false,
    this.maxLines = 1,
  });

  final String label;
  final String placeholder;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;
  final bool readOnly;
  final int maxLines;

  @override
  State<LabeledInput> createState() => _LabeledInputState();
}

class _LabeledInputState extends State<LabeledInput> {
  final RxBool _obscure = true.obs;

  @override
  void dispose() {
    _obscure.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration decoration({Widget? suffixIcon}) {
      return InputDecoration(
        hintText: widget.placeholder,
        hintStyle: AppTextStyles.bodyMd.copyWith(
          color: AppColors.hintColor,
        ),
        prefixIcon: widget.prefixIcon,
        suffixIcon: suffixIcon,
      );
    }

    TextFormField buildField({Widget? suffixIcon, bool obscureText = false}) {
      return TextFormField(
        controller: widget.controller,
        obscureText: obscureText,
        keyboardType: widget.keyboardType,
        readOnly: widget.readOnly,
        validator: widget.validator,
        inputFormatters: widget.inputFormatters,
        maxLines: widget.isPassword ? 1 : widget.maxLines,
        style: AppTextStyles.bodyMd.copyWith(
          color: AppColors.titleColor,
          fontSize: 15,
        ),
        decoration: decoration(suffixIcon: suffixIcon),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label.toUpperCase(),
          style: AppTextStyles.labelLg.copyWith(
            color: AppColors.bodyColor,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (widget.isPassword)
          Obx(
            () => buildField(
              obscureText: _obscure.value,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure.value
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.hintColor,
                  size: 20,
                ),
                onPressed: _obscure.toggle,
              ),
            ),
          )
        else
          buildField(),
      ],
    );
  }
}
