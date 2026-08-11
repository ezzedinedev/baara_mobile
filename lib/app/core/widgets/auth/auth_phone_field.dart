import 'package:flutter/material.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_shapes.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/haptics.dart';
import 'phone_country.dart';

/// Champ « Téléphone » avec sélecteur de pays intégré : un appui sur le drapeau
/// ouvre une feuille de choix (pays UEMOA) qui fixe l'indicatif (+226, +223…).
/// Le [controller] ne porte que la partie locale du numéro ; l'indicatif vit
/// dans [country]. Visuellement aligné sur [AuthTextField] (glow au focus,
/// squircle, mêmes couleurs) pour rester cohérent dans le parcours d'auth.
class AuthPhoneField extends StatefulWidget {
  const AuthPhoneField({
    super.key,
    required this.controller,
    required this.country,
    required this.onCountryChanged,
    this.label = 'Téléphone',
    this.hint = '70 00 00 00',
    this.validator,
  });

  /// Partie locale du numéro (sans indicatif).
  final TextEditingController controller;

  /// Pays / indicatif actuellement sélectionné.
  final PhoneCountry country;

  /// Notifié quand l'utilisateur choisit un autre pays.
  final ValueChanged<PhoneCountry> onCountryChanged;

  final String label;
  final String? hint;
  final String? Function(String?)? validator;

  @override
  State<AuthPhoneField> createState() => _AuthPhoneFieldState();
}

class _AuthPhoneFieldState extends State<AuthPhoneField> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
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

  Future<void> _openPicker() async {
    AppHaptics.tap();
    FocusScope.of(context).unfocus();
    final picked = await showCountryPickerSheet(
      context: context,
      selected: widget.country,
    );
    if (picked != null && picked.isoCode != widget.country.isoCode) {
      AppHaptics.success();
      widget.onCountryChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            controller: widget.controller,
            focusNode: _focusNode,
            keyboardType: TextInputType.phone,
            validator: widget.validator,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
              LengthLimitingTextInputFormatter(14),
            ],
            style: AppTextStyles.bodyLg.copyWith(
              color: AppColors.titleColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppTextStyles.bodyMd.copyWith(
                color: AppColors.hintColor,
              ),
              prefixIcon: _CountryPrefix(
                country: widget.country,
                focused: _focused,
                onTap: _openPicker,
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 96, minHeight: 46),
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
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
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

/// Zone tappable en tête du champ : drapeau + indicatif + chevron, suivie d'un
/// séparateur vertical. Sert de `prefixIcon` au [TextFormField].
class _CountryPrefix extends StatelessWidget {
  const _CountryPrefix({
    required this.country,
    required this.focused,
    required this.onTap,
  });

  final PhoneCountry country;
  final bool focused;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppShapes.squircleRadius(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.only(left: 12, right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(country.flag, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 6),
              Text(
                country.dialCode,
                style: AppTextStyles.bodyLg.copyWith(
                  color: AppColors.titleColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                AppIcons.chevronDown,
                size: 16,
                color: focused ? AppColors.primaryAccent : AppColors.hintColor,
              ),
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: 24,
                color: AppColors.outlineVariant.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ouvre la feuille de sélection de pays et renvoie le pays choisi (ou `null`).
Future<PhoneCountry?> showCountryPickerSheet({
  required BuildContext context,
  required PhoneCountry selected,
}) {
  return showModalBottomSheet<PhoneCountry>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetCtx) => _CountryPickerSheet(selected: selected),
  );
}

class _CountryPickerSheet extends StatelessWidget {
  const _CountryPickerSheet({required this.selected});

  final PhoneCountry selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Indicatif du pays',
                style: AppTextStyles.titleLg.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 12),
            for (final country in PhoneCountry.uemoa)
              _CountryTile(
                country: country,
                selected: country.isoCode == selected.isoCode,
                onTap: () {
                  AppHaptics.tap();
                  Navigator.of(context).pop(country);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _CountryTile extends StatelessWidget {
  const _CountryTile({
    required this.country,
    required this.selected,
    required this.onTap,
  });

  final PhoneCountry country;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppShapes.squircleRadius(AppRadius.md),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.surfaceSelected : Colors.transparent,
            borderRadius: AppShapes.squircleRadius(AppRadius.md),
            border: Border.all(
              color: selected
                  ? AppColors.primaryAccent.withValues(alpha: 0.45)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Text(country.flag, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  country.name,
                  style: AppTextStyles.bodyLg.copyWith(
                    color: AppColors.titleColor,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
              Text(
                country.dialCode,
                style: AppTextStyles.bodyMd.copyWith(
                  color: selected ? AppColors.primaryAccent : AppColors.bodyColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 10),
                Icon(AppIcons.tickSquare,
                    size: 20, color: AppColors.primaryAccent),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
