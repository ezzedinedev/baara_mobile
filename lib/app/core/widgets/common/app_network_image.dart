import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../constants/api_constants.dart';
import '../../theme/app_colors.dart';

/// Image réseau avec cache disque/mémoire et placeholder cohérent.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.errorWidget,
  });

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    final resolved = ApiConstants.resolveMediaUrl(url);
    if (resolved == null || resolved.isEmpty) {
      return errorWidget ?? _placeholder();
    }

    Widget image = CachedNetworkImage(
      imageUrl: resolved,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, __) => _placeholder(),
      errorWidget: (_, __, ___) => errorWidget ?? _placeholder(),
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }

  Widget _placeholder() => Container(
        width: width,
        height: height,
        color: AppColors.surfaceContainer,
        alignment: Alignment.center,
        child: Icon(Icons.image_outlined,
            size: (width != null && height != null)
                ? (width! < height! ? width! : height!) * 0.35
                : 24,
            color: AppColors.hintColor),
      );
}
