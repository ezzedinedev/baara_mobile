import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';

/// Card de surface standard de l'app : fond `surfaceCard`, bord
/// `outlineVariant` discret, radius par defaut `lg`, ombre `lightShadow`.
///
/// Wrapper sur `Container` qui couvre 80% des "cards" repetees dans le
/// projet. Si [onTap] est fourni, la card devient pressable avec ripple
/// `InkWell` (et le clipping est fait au bon endroit pour preserver
/// l'effet ripple).
///
/// Variantes :
///   - [radius]      : par defaut `AppRadius.lg`. Mettre `AppRadius.xl` ou
///                     `AppRadius.pill` selon le besoin.
///   - [padding]     : par defaut `EdgeInsets.all(14)`. Override pour cards
///                     plus aerees.
///   - [borderColor] : override de la couleur de bordure (par defaut
///                     `outlineVariant.withAlpha(0.16)`).
///   - [shadow]      : `light` (defaut), `ambient` (plus marquee, pour
///                     unread/selected), `none`.
///
/// Exemple :
/// ```dart
/// BrandCard(
///   onTap: () => print('tap'),
///   child: const Text('Hello'),
/// )
/// ```
class BrandCard extends StatelessWidget {
  const BrandCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = AppRadius.lg,
    this.borderColor,
    this.shadow = BrandCardShadow.none,
    this.color,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? borderColor;
  final BrandCardShadow shadow;
  /// Override de la couleur de fond. `null` = `AppColors.surfaceCard`.
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final resolvedBorderColor =
        borderColor ?? AppColors.outlineVariant.withValues(alpha: 0.4);
    final boxShadow = switch (shadow) {
      BrandCardShadow.none => null,
      BrandCardShadow.light => AppColors.lightShadow,
      BrandCardShadow.ambient => AppColors.ambientShadow,
    };

    final decoration = BoxDecoration(
      color: color ?? AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: resolvedBorderColor),
      boxShadow: boxShadow,
    );

    if (onTap == null) {
      return Container(
        decoration: decoration,
        padding: padding,
        child: child,
      );
    }
    // Avec onTap : clip pour que le ripple respecte le radius.
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: Ink(
        decoration: decoration,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Niveau d'ombre porte par [BrandCard].
enum BrandCardShadow { none, light, ambient }
