import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_text_styles.dart';
import '../baara_mark.dart';
import 'app_back_button.dart';

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
    // Material à la racine : fournit l'ancêtre requis par les InkWell/TextField
    // des contenus (cet écran est poussé en route, sans Scaffold au-dessus).
    return Material(
      color: AppColors.background,
      child: Column(
        children: [
          ColoredBox(
            color: AppColors.primary,
            child: SafeArea(
              bottom: false,
              child: Padding(
                // Le bas doit dépasser `sheetOverlap` (la feuille remonte par-
                // dessus le bandeau) sinon les boutons se collent à la feuille.
                padding: EdgeInsets.fromLTRB(8, 8, 8, sheetOverlap + 16),
                child: Row(
                  children: [
                    if (showBack)
                      AppBackButton(onDark: true, onTap: onBack)
                    else
                      const SizedBox(width: 42),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (titleIcon != null) ...[
                            Icon(titleIcon,
                                color: AppColors.onPrimary, size: 18),
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

/// Onglet principal, dans le langage du splash et des écrans de connexion :
/// bandeau vert forêt aux coins bas arrondis, halo citron, personnage Baara en
/// filigrane, grand titre blanc. Les actions et le [headerChild] (recherche,
/// sélecteur) sont posés sur le bandeau ; le contenu défile dessous sur le
/// fond clair.
class SankTabShell extends StatelessWidget {
  const SankTabShell({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.headerActions = const [],
    this.headerChild,
    this.headerVisible = true,
  });

  final String title;
  final String? subtitle;
  final List<Widget> headerActions;
  final Widget? headerChild;
  final Widget body;

  /// Quand false, le header se rétracte vers le haut avec une animation.
  final bool headerVisible;

  static const double _radius = 28;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Material(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light
                .copyWith(statusBarColor: Colors.transparent),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(_radius),
              ),
              child: ColoredBox(
                color: BaaraMark.brandForest,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(1.1, -1.3),
                            radius: 1.4,
                            colors: [
                              BaaraMark.brandLime.withValues(alpha: 0.20),
                              BaaraMark.brandLime.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -28,
                      bottom: -40,
                      child: ExcludeSemantics(
                        child: BaaraMark(
                          size: 150,
                          color: Colors.white.withValues(alpha: 0.05),
                          headColor:
                              BaaraMark.brandLime.withValues(alpha: 0.09),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: topInset),
                      child: _header(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _header() {
    return ClipRect(
      child: AnimatedAlign(
        alignment: Alignment.topCenter,
        heightFactor: headerVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
        child: AnimatedOpacity(
          opacity: headerVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageH,
              AppSpacing.md,
              AppSpacing.pageH,
              AppSpacing.lg + 4,
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
                          Semantics(
                            header: true,
                            child: Text(
                              title,
                              style: AppTextStyles.displayMd.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.6,
                              ),
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              subtitle!,
                              style: AppTextStyles.bodyMd.copyWith(
                                color: Colors.white.withValues(alpha: 0.74),
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
      ),
    );
  }
}
