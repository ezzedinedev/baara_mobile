part of '../home_screen.dart';


void _showFormationDetails(
  BuildContext context,
  HomeFormationPreview formation,
) {
  openFormationDetail(context, Get.find<HomeController>(), formation);
}

/// Carte formation refondue (avril 2026) : background image plein cadre,
/// voile gradient pour la lisibilite, badge niveau en haut a gauche, titre
/// blanc, stats en bas (lecons, duree, %) et barre de progression. Pas de
/// bouton play : la lecture se fait depuis le detail formation.
class _FormationDarkCard extends StatelessWidget {
  const _FormationDarkCard({
    required this.formation,
    this.compact = false,
    this.onTap,
  });

  final HomeFormationPreview formation;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasCover = formation.coverUrl.trim().isNotEmpty;
    final cardHeight = compact ? 224.0 : 280.0;
    final progress = formation.progressRatio.clamp(0.0, 1.0);
    final progressPct = formation.progressPercent;

    final lessonsLabel = formation.lessons > 0
        ? '${formation.lessons} ${formation.lessons > 1 ? "leçons" : "leçon"}'
        : 'Leçons à venir';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.onDark,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.22),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: cardHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Fond : photo de couverture (Ken Burns subtil) ou pattern
                // de fallback quand le serveur n'a pas encore d'image.
                if (hasCover)
                  KenBurnsImage(
                    image: CachedNetworkImageProvider(formation.coverUrl),
                  )
                else
                  CustomPaint(painter: _ChartPatternPainter()),

                // Voile gradient : assombrit haut + bas pour que le badge,
                // le titre, les stats et la progress bar restent lisibles
                // quelle que soit l'image du serveur.
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
                      if (formation.level.isNotEmpty)
                        _LevelBadge(text: formation.level),
                      const SizedBox(height: 14),
                      Text(
                        formation.title,
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
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _CardStat(
                            icon: Icons.menu_book_rounded,
                            label: lessonsLabel,
                          ),
                          const Spacer(),
                          if (formation.durationLabel.isNotEmpty) ...[
                            _CardStat(
                              icon: Icons.access_time_rounded,
                              label: formation.durationLabel,
                            ),
                            // Le pourcentage n'apparait qu'a partir du moment
                            // ou l'utilisateur a vraiment commence la formation
                            // (au moins une lecon completee). Avant ca, "0 %"
                            // affiche cote utilisateur fait croire qu'il est
                            // deja inscrit, ce qui est trompeur — on prefere
                            // un CTA explicite (Suivre / Commencer).
                            if (progressPct > 0) const SizedBox(width: 14),
                          ],
                          if (progressPct > 0)
                            Text(
                              '$progressPct%',
                              style: AppTextStyles.titleMd.copyWith(
                                color: AppColors.onPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: compact ? 13 : 15,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (progressPct > 0)
                        _ProgressTrack(progress: progress, compact: compact)
                      else
                        Align(
                          alignment: Alignment.centerRight,
                          child: _FormationCta(formation: formation),
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

class _ProgressTrack extends StatelessWidget {
  const _ProgressTrack({required this.progress, required this.compact});

  final double progress;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progression',
          style: AppTextStyles.labelSm.copyWith(
            color: AppColors.onPrimary.withValues(alpha: 0.86),
            fontSize: compact ? 10 : 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: compact ? 4 : 5,
            backgroundColor: AppColors.onPrimary.withValues(alpha: 0.22),
            valueColor: const AlwaysStoppedAnimation(AppColors.onPrimary),
          ),
        ),
      ],
    );
  }
}

/// CTA compact affiche en bas de la carte quand l'utilisateur n'a pas encore
/// commence la formation. "Suivre" si pas inscrit (declenche enrollment),
/// "Commencer" si inscrit mais 0 lecon completee (ouvre le detail).
class _FormationCta extends StatelessWidget {
  const _FormationCta({required this.formation});

  final HomeFormationPreview formation;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Obx(() {
      final isEnrolling =
          controller.enrollingFormationId.value == formation.id;
      final isEnrolled = formation.isEnrolled;

      // Deja inscrit : pas de CTA d'action — un badge "Inscrit" passif
      // suffit. Le card lui-meme ouvre le detail au tap, donc le bouton
      // "Commencer" en doublon embrouillait l'utilisateur ("pourquoi je
      // dois encore cliquer Suivre alors que je suis inscrit ?").
      if (isEnrolled) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.successSoft,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: AppColors.successDark.withValues(alpha: 0.30),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 13,
                color: AppColors.successStrong,
              ),
              const SizedBox(width: 5),
              Text(
                'Inscrit',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.successStrong,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        );
      }

      // Pas encore inscrit : pill "Suivre" qui declenche enrollInFormation.
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(99),
          onTap: isEnrolling
              ? null
              : () {
                  AppHaptics.tap();
                  controller.enrollInFormation(formation);
                },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(99),
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
                if (isEnrolling)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  )
                else
                  const Icon(Icons.add_rounded,
                      size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'Suivre',
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
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
