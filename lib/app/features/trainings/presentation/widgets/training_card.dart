import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_motion.dart';
import 'package:opportune_bf/app/core/theme/app_shapes.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';

import '../../domain/entities/training.dart';

/// Carte formation (design d'origine restauré, avril 2026) : image de
/// couverture plein cadre + voile dégradé pour la lisibilité, badge niveau
/// en haut à gauche, titre blanc, stats (leçons / durée), et CTA passif.
///
/// Améliorations :
///  - Image cassée → fallback gracieux (pattern de marque) via
///    [CachedNetworkImage]. Jamais de X rouge ni de "HTTP request failed".
///  - Pas de badge "Publiée" (statut interne sans intérêt candidat). On
///    garde le badge niveau ; un badge "Gratuite" s'affiche si pertinent.
class TrainingCard extends StatelessWidget {
  const TrainingCard({
    super.key,
    required this.training,
    this.compact = false,
    this.onTap,
  });

  final Training training;
  final bool compact;
  final VoidCallback? onTap;

  bool get _isFree {
    final p = training.price;
    if (p != null) return p <= 0;
    final label = training.priceLabel.toLowerCase();
    return label.contains('gratuit');
  }

  @override
  Widget build(BuildContext context) {
    final hasCover = training.coverUrl.trim().isNotEmpty;
    final cardHeight = compact ? 224.0 : 280.0;

    final lessonsLabel = training.lessons > 0
        ? '${training.lessons} ${training.lessons > 1 ? "leçons" : "leçon"}'
        : 'Leçons à venir';

    final cardRadius = AppShapes.squircleRadius(AppRadius.xl);
    return PressScale(
      curve: AppMotion.spring,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.onDark,
          borderRadius: cardRadius,
          // Ombres en couches (profondeur 2026) : portée large + contact net.
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.22),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.10),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: cardRadius,
          child: SizedBox(
            height: cardHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Fond : couverture serveur avec fallback gracieux, ou pattern
                // de marque directement quand aucune URL n'est fournie.
                Hero(
                  tag: 'training-cover-${training.id}',
                  child: hasCover
                      ? CachedNetworkImage(
                          imageUrl: training.coverUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              const _BrandFallback(light: true),
                          errorWidget: (_, __, ___) => const _BrandFallback(),
                        )
                      : const _BrandFallback(),
                ),

                // Voile dégradé : assombrit haut + bas pour la lisibilité du
                // badge, du titre et des stats quelle que soit l'image.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.34),
                        Colors.black.withValues(alpha: 0.10),
                        Colors.black.withValues(alpha: 0.46),
                        Colors.black.withValues(alpha: 0.78),
                      ],
                      stops: const [0.0, 0.32, 0.68, 1.0],
                    ),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.all(compact ? 14 : 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (training.level.isNotEmpty)
                            _LevelBadge(text: training.level),
                          const Spacer(),
                          if (_isFree) const _FreeBadge(),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        training.title,
                        style: AppTextStyles.headlineSm.copyWith(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: compact ? 20 : 24,
                          height: 1.18,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (training.providerName.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          training.providerName,
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.onPrimary.withValues(alpha: 0.82),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const Spacer(),
                      // Flexible : les stats se compriment au lieu de déborder
                      // latéralement sur les écrans étroits (~360px).
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: _CardStat(
                              icon: Icons.menu_book_rounded,
                              label: lessonsLabel,
                            ),
                          ),
                          if (training.durationLabel.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Flexible(
                              child: _CardStat(
                                icon: Icons.access_time_rounded,
                                label: training.durationLabel,
                              ),
                            ),
                          ],
                          if (training.rating > 0) ...[
                            const SizedBox(width: 12),
                            _CardStat(
                              icon: IconlyBold.star,
                              label: training.rating.toStringAsFixed(1),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _StatusPill(isEnrolled: training.isEnrolled),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fallback de marque : pattern dégradé/courbe utilisé quand l'image serveur
/// est absente, en cours de chargement ([light]), ou en échec. Évite tout
/// affichage d'erreur réseau.
class _BrandFallback extends StatelessWidget {
  const _BrandFallback({this.light = false});

  final bool light;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: AppColors.heroTrainingsGradient),
      child: light
          ? const SizedBox.expand()
          : CustomPaint(painter: _ChartPatternPainter()),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSm.copyWith(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _FreeBadge extends StatelessWidget {
  const _FreeBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        'Gratuite',
        style: AppTextStyles.labelSm.copyWith(
          color: AppColors.onPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _CardStat extends StatelessWidget {
  const _CardStat({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.onPrimary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

/// Pastille de statut passive : "Inscrit" si l'utilisateur suit déjà la
/// formation, sinon "Découvrir". Le tap sur la carte ouvre le détail.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isEnrolled});

  final bool isEnrolled;

  @override
  Widget build(BuildContext context) {
    if (isEnrolled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.successSoft,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: AppColors.success.withValues(alpha: 0.30),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              IconlyBold.tick_square,
              size: 13,
              color: AppColors.successAccent,
            ),
            const SizedBox(width: 5),
            Text(
              'Inscrit',
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.successAccent,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(IconlyLight.arrow_right_2,
              size: 14, color: AppColors.primaryAccent),
          const SizedBox(width: 6),
          Text(
            'Découvrir',
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pattern de marque (grille + courbe + chandelles) peint en fallback image.
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
