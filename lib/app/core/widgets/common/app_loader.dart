import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Indicateur de chargement adaptatif de la charte.
///
/// Rend un spinner Cupertino sur iOS / macOS (HIG) et un
/// [CircularProgressIndicator] Material sur Android (MD3), via
/// [CircularProgressIndicator.adaptive].
///
/// Le constructeur `.adaptive` n'expose PAS de paramètre `color` : la teinte
/// doit être donnée à la fois via `valueColor` (anneau Material) et
/// `backgroundColor` (teinte du spinner Cupertino). Ce widget centralise ce
/// mapping pour que la couleur de marque soit respectée sur les deux
/// plateformes — à utiliser pour TOUT loader générique (pages, sections,
/// listes). Pour un anneau de progression déterminé (`value != null`) ou un
/// spinner inline sur fond coloré, garder un [CircularProgressIndicator]
/// classique.
class AppLoader extends StatelessWidget {
  const AppLoader({
    super.key,
    this.color,
    this.size,
    this.strokeWidth = 2.4,
  });

  /// Teinte du loader. Par défaut [AppColors.primaryAccent].
  final Color? color;

  /// Taille carrée optionnelle (sinon taille naturelle de l'indicateur).
  final double? size;

  /// Épaisseur de l'anneau Material (ignorée par le spinner Cupertino).
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? AppColors.primaryAccent;
    final indicator = CircularProgressIndicator.adaptive(
      strokeWidth: strokeWidth,
      // Material : couleur de l'anneau. Cupertino : teinte du spinner.
      valueColor: AlwaysStoppedAnimation<Color>(resolved),
      backgroundColor: resolved,
    );
    if (size == null) return indicator;
    return SizedBox(width: size, height: size, child: indicator);
  }
}
