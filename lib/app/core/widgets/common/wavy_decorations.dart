import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class WaveClipper extends CustomClipper<Path> {
  const WaveClipper();

  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, size.height - 50)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height,
        size.width * 0.58,
        size.height - 30,
      )
      ..quadraticBezierTo(
        size.width * 0.86,
        size.height - 70,
        size.width,
        size.height - 10,
      )
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class TopoPainter extends CustomPainter {
  const TopoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.onPrimary.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    _drawBlob(canvas, paint, Offset(size.width * 0.25, size.height * 0.35), 90);
    _drawBlob(canvas, paint, Offset(size.width * 0.75, size.height * 0.55), 70);
    _drawBlob(canvas, paint, Offset(size.width * 0.55, size.height * 0.20), 50);
    _drawBlob(canvas, paint, Offset(size.width * 0.15, size.height * 0.70), 60);
  }

  void _drawBlob(Canvas canvas, Paint paint, Offset center, double baseRadius) {
    for (int i = 0; i < 5; i++) {
      final r = baseRadius - i * 12;
      if (r <= 0) break;
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WavyHeaderLeadingButton extends StatelessWidget {
  const WavyHeaderLeadingButton({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () => Navigator.of(context).maybePop(),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.onPrimary.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.onPrimary.withValues(alpha: 0.24),
            ),
          ),
          child: const Icon(
            Icons.chevron_left_rounded,
            color: AppColors.onPrimary,
            size: 26,
          ),
        ),
      ),
    );
  }
}

class WavyHeaderActionButton extends StatelessWidget {
  const WavyHeaderActionButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.badgeCount,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final int? badgeCount;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final core = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.onPrimary.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.onPrimary.withValues(alpha: 0.24),
                ),
              ),
              child: Icon(icon, color: AppColors.onPrimary, size: 22),
            ),
            if (badgeCount != null && badgeCount! > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.onPrimary, width: 1.4),
                  ),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    badgeCount! > 99 ? '99+' : '$badgeCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.onPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      return Tooltip(message: tooltip!, child: core);
    }
    return core;
  }
}
