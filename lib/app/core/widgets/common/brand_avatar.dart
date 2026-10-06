import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../constants/api_constants.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

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
    final resolved = ApiConstants.resolveMediaUrl(imageUrl);
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
        child: resolved != null && resolved.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: resolved,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _initialsLayer(),
              )
            : _initialsLayer(),
      ),
    );
  }

  Widget _initialsLayer() => Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _initials,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleMd.copyWith(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.w800,
              fontSize: fontSize ?? size * 0.42,
              height: 1.0,
            ),
          ),
        ),
      );
}
