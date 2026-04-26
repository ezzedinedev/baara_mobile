import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/core/theme/app_colors.dart';
import '../../app/core/theme/app_text_styles.dart';
import '../../app/modules/auth/register/register_controller.dart';

class RegisterCountryDropdown extends StatelessWidget {
  const RegisterCountryDropdown({
    super.key,
    required this.controller,
  });

  final RegisterController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedIso = controller.selectedCountryIso.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pays',
            style: AppTextStyles.titleMd.copyWith(
              color: AppColors.bodyColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey<String>('country_$selectedIso'),
            initialValue: selectedIso,
            isExpanded: true,
            menuMaxHeight: 320,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.titleColor,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceLow,
              prefixIcon: Icon(
                Icons.public_rounded,
                size: 19,
                color: AppColors.hintColor,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.18),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.4,
                ),
              ),
            ),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.hintColor,
            ),
            items: controller.countries.map((country) {
              return DropdownMenuItem<String>(
                value: country.isoCode,
                child: Text(
                  '${country.flag}  ${country.name}',
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.titleColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              controller.selectCountry(value);
            },
            validator: (_) =>
                controller.validateCountry(controller.countryCtrl.text),
          ),
        ],
      );
    });
  }
}
