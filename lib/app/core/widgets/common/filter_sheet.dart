import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/haptics.dart';

/// Un groupe de filtres mono-sélection (ex: « Type de contrat »). `null` dans
/// la sélection = « Tous ».
class FilterGroup {
  final String key;
  final String label;
  final List<String> options;

  const FilterGroup({
    required this.key,
    required this.label,
    required this.options,
  });
}

/// Affiche une feuille de filtres moderne (poignée, chips, Réinitialiser /
/// Appliquer) et renvoie la nouvelle sélection (`{key: valeur|null}`), ou
/// `null` si l'utilisateur ferme sans appliquer.
Future<Map<String, String?>?> showFilterSheet({
  required BuildContext context,
  required List<FilterGroup> groups,
  required Map<String, String?> selected,
}) {
  final draft = Map<String, String?>.from(selected);
  return showModalBottomSheet<Map<String, String?>>(
    context: context,
    backgroundColor: AppColors.surfaceCard,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Filtres',
                  style: AppTextStyles.titleLg
                      .copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: AppSpacing.md),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final group in groups) ...[
                        Text(
                          group.label,
                          style: AppTextStyles.labelLg
                              .copyWith(color: AppColors.bodyColor),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            for (final option in group.options)
                              _Chip(
                                label: option,
                                selected: draft[group.key] == option,
                                onTap: () {
                                  AppHaptics.tap();
                                  setSheet(() {
                                    draft[group.key] =
                                        draft[group.key] == option
                                            ? null
                                            : option;
                                  });
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      AppHaptics.tap();
                      setSheet(() {
                        for (final g in groups) {
                          draft[g.key] = null;
                        }
                      });
                    },
                    child: Text('Réinitialiser',
                        style: AppTextStyles.labelLg
                            .copyWith(color: AppColors.bodyColor)),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      AppHaptics.tap();
                      Navigator.pop(ctx, draft);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xxl, vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: Text('Appliquer',
                        style: AppTextStyles.buttonMd
                            .copyWith(color: AppColors.onPrimary)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryAccent.withValues(alpha: 0.14)
              : AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color:
                selected ? AppColors.primaryAccent : AppColors.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMd.copyWith(
            color: selected ? AppColors.primaryDark : AppColors.bodyColor,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
