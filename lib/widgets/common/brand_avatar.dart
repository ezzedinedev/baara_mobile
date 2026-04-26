import 'package:flutter/material.dart';

import '../../app/core/theme/app_colors.dart';
import '../../app/core/theme/app_text_styles.dart';

/// Avatar circulaire avec gradient stable basé sur un `seed`. Affiche les
/// initiales de `label` en fallback. Si `imageUrl` est fourni, tente de le
/// charger ; en cas d'échec, retombe sur le gradient + initiales.
class BrandAvatar extends StatelessWidget {
  const BrandAvatar({
    super.key,
    required this.seed,
    required this.label,
    this.size = 44,
    this.imageUrl,
    this.fontSize,
  });

  final String seed;
  final String label;
  final double size;
  final String? imageUrl;
  final double? fontSize;

  String get _initials {
    final parts = label.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.avatarGradientForSeed(seed);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? ClipOval(
              child: Image.network(
                imageUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initialsText(),
              ),
            )
          : _initialsText(),
    );
  }

  Widget _initialsText() => Text(
        _initials,
        style: AppTextStyles.titleMd.copyWith(
          color: AppColors.onPrimary,
          fontWeight: FontWeight.w800,
          fontSize: fontSize ?? size * 0.42,
        ),
      );
}
