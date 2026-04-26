part of '../home_screen.dart';


void _showFormationDetails(
  BuildContext context,
  HomeFormationPreview formation,
) {
  openFormationDetail(context, Get.find<HomeController>(), formation);
}

class _FormationDarkCard extends StatelessWidget {
  const _FormationDarkCard({
    required this.formation,
    this.compact = false,
    this.onTap,
  });

  final HomeFormationPreview formation;
  final bool compact;
  final VoidCallback? onTap;

  bool get _isFree => formation.priceAmount == 0;

  @override
  Widget build(BuildContext context) {
    const textPrimary = AppColors.onPrimary;
    final textSecondary = AppColors.onPrimary.withValues(alpha: 0.78);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryDark, AppColors.onDark],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.primaryLight.withValues(alpha: 0.14),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.30),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FormationMedia(formation: formation, compact: compact),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 12 : 14,
                  compact ? 10 : 12,
                  compact ? 12 : 14,
                  compact ? 12 : 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (formation.sector.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          formation.sector.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    Text(
                      formation.title,
                      style: AppTextStyles.titleLg.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: compact ? 15 : 17,
                        height: 1.2,
                      ),
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formation.providerName,
                      style: AppTextStyles.bodySm.copyWith(
                        color: textSecondary,
                        fontSize: compact ? 11 : 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: compact ? 10 : 12),
                    Row(
                      children: [
                        _DarkStat(
                          icon: Icons.menu_book_rounded,
                          label: '${formation.lessons}',
                          color: AppColors.categoryBlueLight,
                          compact: compact,
                        ),
                        const SizedBox(width: 12),
                        _DarkStat(
                          icon: Icons.cast_for_education_rounded,
                          label: formation.formatLabel,
                          color: AppColors.primaryLight,
                          compact: compact,
                          isText: true,
                        ),
                        const Spacer(),
                        _DarkStat(
                          icon: Icons.groups_rounded,
                          label: '${formation.enrolledCount}',
                          color: AppColors.categoryOrange,
                          compact: compact,
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 10 : 12),
                    // Bandeau prix bas (vert si gratuit, accent si payant).
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(
                        compact ? 10 : 12,
                        compact ? 7 : 8,
                        compact ? 10 : 12,
                        compact ? 7 : 8,
                      ),
                      decoration: BoxDecoration(
                        color: _isFree
                            ? AppColors.primaryLight.withValues(alpha: 0.20)
                            : AppColors.categoryYellow.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                          color: _isFree
                              ? AppColors.primaryLight.withValues(alpha: 0.40)
                              : AppColors.categoryYellow
                                  .withValues(alpha: 0.40),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isFree
                                ? Icons.verified_rounded
                                : Icons.payments_rounded,
                            size: compact ? 13 : 15,
                            color: _isFree
                                ? AppColors.primaryLight
                                : AppColors.categoryYellow,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              formation.priceLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.titleMd.copyWith(
                                color: _isFree
                                    ? AppColors.primaryLight
                                    : AppColors.categoryYellow,
                                fontWeight: FontWeight.w800,
                                fontSize: compact ? 11 : 12,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: compact ? 13 : 15,
                            color: AppColors.onPrimary
                                .withValues(alpha: 0.85),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DarkStat extends StatelessWidget {
  const _DarkStat({
    required this.icon,
    required this.label,
    required this.color,
    required this.compact,
    this.isText = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool compact;
  final bool isText;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 22 : 26,
          height: compact ? 22 : 26,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: compact ? 12 : 14, color: color),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onPrimary,
              fontWeight: isText ? FontWeight.w700 : FontWeight.w800,
              fontSize: compact ? 10 : 11,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _FormationMedia extends StatelessWidget {
  const _FormationMedia({
    required this.formation,
    required this.compact,
  });

  final HomeFormationPreview formation;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hasCover = formation.coverUrl.trim().isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        height: compact ? 94 : 122,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.onDark, AppColors.primaryDark],
          ),
          border: Border.all(
            color: AppColors.primaryLight.withValues(alpha: 0.24),
          ),
        ),
        child: Stack(
          children: [
            if (hasCover)
              Positioned.fill(
                child: KenBurnsImage(
                  image: CachedNetworkImageProvider(formation.coverUrl),
                ),
              )
            else
              Positioned.fill(
                child: CustomPaint(
                  painter: _ChartPatternPainter(),
                ),
              ),
            // Voile gradient concentre dans le bas (stops 0.55+) : laisse
            // les 2/3 du haut clairs pour que l'image reste lisible, n'assombrit
            // que la zone des badges en bas.
            if (hasCover)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: AppColors.imageScrim,
                      stops: AppColors.imageScrimStops,
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 8,
              top: 8,
              child: _FormationBadge(
                text: formation.level,
                background: AppColors.surfaceIconSoft.withValues(alpha: 0.95),
                textColor: AppColors.primaryDark,
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: _FormationBadge(
                text: formation.status,
                background: AppColors.primary,
                textColor: AppColors.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormationBadge extends StatelessWidget {
  const _FormationBadge({
    required this.text,
    required this.background,
    required this.textColor,
  });

  final String text;
  final Color background;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodySm.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 9,
        ),
      ),
    );
  }
}

class _ChartPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.onPrimary.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (double x = 0; x <= size.width; x += size.width / 6) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }

    for (double y = 0; y <= size.height; y += size.height / 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final curve = Paint()
      ..color = AppColors.primaryLight.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height * 0.66)
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height * 0.38,
        size.width * 0.36,
        size.height * 0.56,
      )
      ..quadraticBezierTo(
        size.width * 0.54,
        size.height * 0.74,
        size.width * 0.72,
        size.height * 0.50,
      )
      ..quadraticBezierTo(
        size.width * 0.84,
        size.height * 0.34,
        size.width,
        size.height * 0.58,
      );
    canvas.drawPath(path, curve);

    final candle = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.70)
      ..strokeWidth = 2;
    for (double i = 0; i < 7; i++) {
      final dx = (size.width / 7) * i + 6;
      final top = size.height * (0.22 + (i % 3) * 0.12);
      final bottom = size.height * (0.74 - (i % 2) * 0.10);
      canvas.drawLine(Offset(dx, top), Offset(dx, bottom), candle);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

