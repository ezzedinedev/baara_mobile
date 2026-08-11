import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:baara/app/core/theme/app_icons.dart';

import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_dimens.dart';
import 'package:baara/app/core/theme/app_shapes.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/widgets/widgets.dart';

import '../../domain/entities/training.dart';

/// Carte formation — refonte « carte blanche » inspirée d'Edomatch (juin 2026) :
/// image de couverture en haut (coins arrondis), corps blanc avec le **prix**
/// mis en avant en vert, une ligne méta (langue · leçons · inscrits) et des
/// **chips de catégories** (secteur, niveau).
///
/// Robustesse conservée de la version précédente :
///  - Image cassée/absente → fallback de marque gracieux ([CachedNetworkImage]),
///    jamais de X rouge ni de message d'erreur réseau.
///  - Le prix réel est affiché tel quel (pas de fausse remise barrée : le
///    backend n'expose pas de prix d'origine distinct).
class TrainingCard extends StatelessWidget {
  const TrainingCard({
    super.key,
    required this.training,
    this.compact = false,
    this.onTap,
    this.heroTag,
  });

  final Training training;
  final bool compact;
  final VoidCallback? onTap;

  /// Tag du Hero de couverture (morphing carte → détail). Par défaut
  /// `training-cover-<id>` (matche l'écran détail). À surcharger avec un tag
  /// UNIQUE quand la même formation peut être affichée simultanément ailleurs
  /// (ex. rail d'accueil + onglet Formations) pour éviter les Hero en doublon.
  final String? heroTag;

  bool get _isFree {
    final p = training.price;
    if (p != null) return p <= 0;
    return training.priceLabel.toLowerCase().contains('gratuit');
  }

  @override
  Widget build(BuildContext context) {
    final hasCover = training.coverUrl.trim().isNotEmpty;
    final coverHeight = compact ? 120.0 : 150.0;
    final cardRadius = AppShapes.squircleRadius(AppRadius.xl);

    final lessonsLabel = training.lessons > 0
        ? '${training.lessons} ${training.lessons > 1 ? "leçons" : "leçon"}'
        : 'Leçons à venir';

    final chips = <String>[
      if (training.sector.trim().isNotEmpty) training.sector.trim(),
      if (training.level.trim().isNotEmpty) training.level.trim(),
    ];

    return TouchBloom(
      onTap: onTap,
      borderRadius: cardRadius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: cardRadius,
          border: Border.all(color: AppColors.outlineVariant),
          boxShadow: [...AppColors.lightShadow, ...AppColors.ambientShadow],
        ),
        child: ClipRRect(
          borderRadius: cardRadius,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Couverture ──────────────────────────────────────────────
              SizedBox(
                height: coverHeight,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: heroTag ?? 'training-cover-${training.id}',
                      child: _ParallaxCover(
                        height: coverHeight,
                        child: hasCover
                            ? CachedNetworkImage(
                                imageUrl: training.coverUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                placeholder: (_, __) =>
                                    const _BrandFallback(light: true),
                                errorWidget: (_, __, ___) =>
                                    const _BrandFallback(),
                              )
                            : const _BrandFallback(),
                      ),
                    ),
                    if (training.level.trim().isNotEmpty)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: _LevelBadge(text: training.level),
                      ),
                    if (training.isEnrolled)
                      const Positioned(
                        top: 12,
                        right: 12,
                        child: _EnrolledBadge(),
                      ),
                  ],
                ),
              ),

              // ── Corps ───────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.all(compact ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            training.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleMd.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: compact ? 15 : 17,
                              height: 1.2,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _PriceTag(label: training.priceLabel, isFree: _isFree),
                      ],
                    ),
                    if (training.providerName.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        training.providerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.hintColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    // Méta : langue · leçons · inscrits (icônes discrètes).
                    Wrap(
                      spacing: 14,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _MetaStat(
                          icon: Icons.volume_up_rounded,
                          label: training.languageLabel,
                        ),
                        _MetaStat(
                          icon: Icons.play_circle_outline_rounded,
                          label: lessonsLabel,
                        ),
                        if (training.enrolledCount > 0)
                          _MetaStat(
                            icon: Icons.people_alt_outlined,
                            label: '${training.enrolledCount} inscrit'
                                '${training.enrolledCount > 1 ? "s" : ""}',
                          ),
                        if (training.rating > 0)
                          _MetaStat(
                            icon: AppIcons.starFilled,
                            label: training.rating.toStringAsFixed(1),
                            iconColor: AppColors.warningAccent,
                          ),
                      ],
                    ),
                    if (chips.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final c in chips) _CategoryChip(label: c)
                        ],
                      ),
                    ],
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

/// Prix mis en avant en vert (ou pastille « Gratuite »).
class _PriceTag extends StatelessWidget {
  const _PriceTag({required this.label, required this.isFree});
  final String label;
  final bool isFree;

  @override
  Widget build(BuildContext context) {
    if (isFree) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.successSoft,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          'Gratuite',
          style: AppTextStyles.labelSm.copyWith(
            color: AppColors.successAccent,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      );
    }
    return Text(
      label,
      style: AppTextStyles.titleMd.copyWith(
        color: AppColors.primaryAccent,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.2,
      ),
    );
  }
}

/// Couverture par défaut « premium » quand aucune image n'est fournie, pendant
/// le chargement ([light]) ou en cas d'échec : dégradé de marque + cercles
/// translucides (profondeur douce) + pastille avec icône formation. Jamais
/// d'affichage d'erreur réseau, jamais de vide terne.
class _BrandFallback extends StatelessWidget {
  const _BrandFallback({this.light = false});
  final bool light;

  Widget _softCircle(double size, double alpha) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.onPrimary.withValues(alpha: alpha),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: AppColors.heroTrainingsGradient),
      // Pendant le chargement on évite l'icône (qui clignoterait sous l'image) ;
      // on garde juste le dégradé.
      child: light
          ? const SizedBox.expand()
          : Stack(
              fit: StackFit.expand,
              children: [
                Positioned(top: -30, right: -22, child: _softCircle(100, 0.14)),
                Positioned(
                    bottom: -36, left: -26, child: _softCircle(128, 0.10)),
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.onPrimary.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.onPrimary.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(Icons.school_rounded,
                        color: AppColors.onPrimary, size: 28),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Couverture en **parallax** : l'image se déplace verticalement à un rythme
/// différent du défilement quand la carte traverse le viewport (recette Flutter
/// basée sur [Flow], repaint piloté par la position de scroll — pas de setState).
/// Hors d'un [Scrollable] (ou en « réduire les animations »), repli statique.
class _ParallaxCover extends StatefulWidget {
  const _ParallaxCover({required this.height, required this.child});
  final double height;
  final Widget child;

  @override
  State<_ParallaxCover> createState() => _ParallaxCoverState();
}

class _ParallaxCoverState extends State<_ParallaxCover> {
  final _bgKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.maybeOf(context);
    final reduceMotion =
        mq?.disableAnimations == true || mq?.accessibleNavigation == true;
    final scrollable = Scrollable.maybeOf(context);

    // Repli : image plein cadre (cover) sans parallax.
    if (scrollable == null || reduceMotion) {
      return SizedBox(
        height: widget.height,
        width: double.infinity,
        child: widget.child,
      );
    }

    // L'image est rendue plus haute que la zone visible (marge de débordement)
    // pour avoir de la course de translation, puis clippée à [height].
    return ClipRect(
      child: Flow(
        delegate: _ParallaxFlowDelegate(
          scrollable: scrollable,
          itemContext: context,
          bgKey: _bgKey,
        ),
        children: [
          SizedBox(
            key: _bgKey,
            height: widget.height * 1.35,
            width: double.infinity,
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

class _ParallaxFlowDelegate extends FlowDelegate {
  _ParallaxFlowDelegate({
    required this.scrollable,
    required this.itemContext,
    required this.bgKey,
  }) : super(repaint: scrollable.position);

  final ScrollableState scrollable;
  final BuildContext itemContext;
  final GlobalKey bgKey;

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) =>
      BoxConstraints.tightFor(width: constraints.maxWidth);

  @override
  void paintChildren(FlowPaintingContext context) {
    final scrollBox = scrollable.context.findRenderObject() as RenderBox?;
    final itemBox = itemContext.findRenderObject() as RenderBox?;
    final bgBox = bgKey.currentContext?.findRenderObject() as RenderBox?;
    if (scrollBox == null || itemBox == null || bgBox == null) {
      context.paintChild(0);
      return;
    }

    final itemOffset = itemBox.localToGlobal(
      itemBox.size.centerLeft(Offset.zero),
      ancestor: scrollBox,
    );
    final viewport = scrollable.position.viewportDimension;
    final scrollFraction =
        (itemOffset.dy / viewport).clamp(0.0, 1.0).toDouble();
    final alignment = Alignment(0.0, scrollFraction * 2 - 1);

    final childRect =
        alignment.inscribe(bgBox.size, Offset.zero & context.size);
    context.paintChild(
      0,
      transform: Matrix4.translationValues(0.0, childRect.top, 0.0),
    );
  }

  @override
  bool shouldRepaint(_ParallaxFlowDelegate oldDelegate) =>
      scrollable != oldDelegate.scrollable ||
      itemContext != oldDelegate.itemContext ||
      bgKey != oldDelegate.bgKey;
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

class _EnrolledBadge extends StatelessWidget {
  const _EnrolledBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.tickSquare, size: 12, color: AppColors.onPrimary),
          const SizedBox(width: 4),
          Text(
            'Inscrit',
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaStat extends StatelessWidget {
  const _MetaStat({required this.icon, required this.label, this.iconColor});
  final IconData icon;
  final String label;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: iconColor ?? AppColors.hintColor),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTextStyles.labelSm.copyWith(
            color: AppColors.bodyColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSm.copyWith(
          color: AppColors.bodyColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
