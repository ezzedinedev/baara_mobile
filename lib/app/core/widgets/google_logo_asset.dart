import 'package:flutter/material.dart';

class GoogleLogoAsset extends StatelessWidget {
  const GoogleLogoAsset({
    super.key,
    this.size = 22,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.2),
      child: Image.asset(
        'assets/images/logo/google.jpg',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
