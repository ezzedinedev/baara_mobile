import 'package:flutter/material.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';

/// Indicateur de pull-to-refresh de marque (Option A : wrapper sûr autour de
/// [RefreshIndicator]). Couleurs charte dark-aware ([primaryAccent] sur
/// [surfaceCard]), `displacement` premium et `strokeWidth` affiné. Remplaçant
/// direct de [RefreshIndicator] : même API `onRefresh`/`child`, aucune
/// modification de la logique de rafraîchissement.
///
/// Les overrides ([color], [backgroundColor], [strokeWidth], [edgeOffset],
/// [displacement]) sont optionnels : par défaut on applique le look de marque,
/// ce qui rend le remplacement de [RefreshIndicator] purement mécanique.
class AppRefreshIndicator extends StatelessWidget {
  const AppRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color,
    this.backgroundColor,
    this.strokeWidth = 2.6,
    this.edgeOffset = 0,
    this.displacement = 52,
  });

  final RefreshCallback onRefresh;
  final Widget child;

  /// Couleur de l'anneau. Par défaut [AppColors.primaryAccent] (dark-aware).
  final Color? color;

  /// Fond du disque. Par défaut [AppColors.surfaceCard] (dark-aware).
  final Color? backgroundColor;

  final double strokeWidth;

  /// Décalage du bord supérieur (utile sous une app bar / hero sticky).
  final double edgeOffset;

  /// Distance d'apparition de l'anneau depuis le bord.
  final double displacement;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      edgeOffset: edgeOffset,
      displacement: displacement,
      color: color ?? AppColors.primaryAccent,
      backgroundColor: backgroundColor ?? AppColors.surfaceCard,
      strokeWidth: strokeWidth,
      child: child,
    );
  }
}
