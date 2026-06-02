import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/haptics.dart';
import 'app_icon_button.dart';

/// Sous-page (paramètres, édition profil…) : bandeau vert uni + feuille blanche.
class SankSheetScaffold extends StatelessWidget {
  const SankSheetScaffold({
    super.key,
    required this.title,
    required this.body,
    this.titleIcon,
    this.actions = const [],
    this.showBack = true,
    this.onBack,
    this.sheetOverlap = 22,
  });

  final String title;
  final Widget body;
  final IconData? titleIcon;
  final List<Widget> actions;
  final bool showBack;
  final VoidCallback? onBack;
  final double sheetOverlap;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: Column(
        children: [
          ColoredBox(
            color: AppColors.primary,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 20),
                child: Row(
                  children: [
                    if (showBack)
                      AppIconButton(
                        onBrandHeader: true,
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: onBack ??
                            () {
                              AppHaptics.tap();
                              Navigator.of(context).maybePop();
                            },
                      )
                    else
                      const SizedBox(width: 42),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (titleIcon != null) ...[
                            Icon(titleIcon, color: AppColors.onPrimary, size: 18),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              title,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.headlineSm.copyWith(
                                color: AppColors.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions.isEmpty
                          ? [const SizedBox(width: 42)]
                          : actions,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Transform.translate(
              offset: Offset(0, -sheetOverlap),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.sheetTop),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: AppColors.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.sheetTop),
                  ),
                  child: body,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Onglet principal : titre sur fond clair, contenu continu (pas de dégradé).
class SankTabShell extends StatelessWidget {
  const SankTabShell({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.headerActions = const [],
    this.headerChild,
  });

  final String title;
  final String? subtitle;
  final List<Widget> headerActions;
  final Widget? headerChild;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageH,
                AppSpacing.md,
                AppSpacing.pageH,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: AppTextStyles.displayMd.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                subtitle!,
                                style: AppTextStyles.bodyMd.copyWith(
                                  color: AppColors.bodyColor,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      ...headerActions,
                    ],
                  ),
                  if (headerChild != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    headerChild!,
                  ],
                ],
              ),
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
