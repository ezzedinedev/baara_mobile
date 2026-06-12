import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_shapes.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/haptics.dart';

/// Champ de saisie de code à usage unique (OTP) en cases segmentées.
///
/// S'appuie sur le [controller] fourni (la logique de vérification lit
/// `controller.text`) : un unique [TextField] invisible capte la frappe et le
/// collage, et l'on peint [length] cases élégantes au-dessus. Case active mise
/// en valeur (bordure verte + halo doux), curseur clignotant simulé.
class AuthOtpField extends StatefulWidget {
  const AuthOtpField({
    super.key,
    required this.controller,
    this.length = 6,
    this.autofocus = true,
    this.onCompleted,
  });

  final TextEditingController controller;
  final int length;
  final bool autofocus;
  final ValueChanged<String>? onCompleted;

  @override
  State<AuthOtpField> createState() => _AuthOtpFieldState();
}

class _AuthOtpFieldState extends State<AuthOtpField> {
  final FocusNode _focusNode = FocusNode();
  int _lastLength = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() => setState(() {});

  void _onChanged() {
    final len = widget.controller.text.length;
    if (len != _lastLength) {
      if (len > _lastLength) AppHaptics.tap();
      _lastLength = len;
      if (len == widget.length) {
        widget.onCompleted?.call(widget.controller.text);
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasFocus = _focusNode.hasFocus;
    final text = widget.controller.text;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _focusNode.requestFocus(),
      child: Stack(
        children: [
          // Champ réel, invisible mais fonctionnel (frappe, collage, clavier).
          Opacity(
            opacity: 0,
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              keyboardType: TextInputType.number,
              maxLength: widget.length,
              showCursor: false,
              enableInteractiveSelection: false,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(widget.length),
              ],
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
              ),
            ),
          ),
          // Cases peintes par-dessus.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(widget.length, (i) {
              final filled = i < text.length;
              final isActive = hasFocus &&
                  (i == text.length ||
                      (text.length == widget.length && i == widget.length - 1));
              return _OtpCell(
                char: filled ? text[i] : '',
                isActive: isActive,
                isFilled: filled,
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _OtpCell extends StatelessWidget {
  const _OtpCell({
    required this.char,
    required this.isActive,
    required this.isFilled,
  });

  final String char;
  final bool isActive;
  final bool isFilled;

  @override
  Widget build(BuildContext context) {
    final borderColor = isActive
        ? AppColors.primaryAccent
        : isFilled
            ? AppColors.primaryAccent.withValues(alpha: 0.45)
            : AppColors.outlineVariant.withValues(alpha: 0.55);

    return AnimatedScale(
      duration: AppMotion.short,
      curve: AppMotion.springEmphasized,
      scale: isActive ? 1.06 : 1.0,
      child: AnimatedContainer(
        duration: AppMotion.short,
        curve: AppMotion.emphasizedDecelerate,
        width: 48,
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: AppShapes.squircleRadius(AppRadius.lg),
          border: Border.all(color: borderColor, width: isActive ? 1.6 : 1.0),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primaryAccent.withValues(alpha: 0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : AppColors.lightShadow,
        ),
        child: _cellContent(),
      ),
    );
  }

  Widget _cellContent() {
    return char.isNotEmpty
        ? Text(
            char,
            style: AppTextStyles.headlineLg.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.titleColor,
            ),
          )
        : (isActive
            ? Container(
                width: 2,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent,
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            : const SizedBox.shrink());
  }
}
