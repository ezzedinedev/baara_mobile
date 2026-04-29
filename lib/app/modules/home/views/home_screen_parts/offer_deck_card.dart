part of '../home_screen.dart';

class _OfferMetaChip extends StatelessWidget {
  const _OfferMetaChip({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceIconSoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppColors.primaryDark,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferDeckCard extends StatelessWidget {
  const _OfferDeckCard({
    required this.offer,
    required this.matchScore,
    this.compact = false,
    this.muted = false,
    this.onApply,
  });

  final HomeOfferPreview offer;
  final int matchScore;
  final bool compact;
  final bool muted;
  // Callback du pill "Postuler". Null = pill purement decoratif (cards
  // d'arriere-plan dans le deck swipe). Top card et liste : on cable.
  // Quand non-null, on affiche aussi le bouton "favoris" (cœur) en haut a
  // droite — sinon la card est passive (background du deck swipe).
  final VoidCallback? onApply;

  String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final softText = AppColors.onPrimary.withValues(alpha: 0.85);
    final muteText = AppColors.onPrimary.withValues(alpha: 0.70);

    return Container(
      decoration: BoxDecoration(
        gradient: muted
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryDark, AppColors.onDark],
              )
            : AppColors.landingHeroGradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: muted ? [] : AppColors.ambientShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Halos decoratifs.
          Positioned(
            top: -60,
            right: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.onPrimary.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -40,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.onPrimary.withValues(alpha: 0.04),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 14 : 18,
              compact ? 14 : 18,
              compact ? 14 : 18,
              compact ? 14 : 18,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top : avatar entreprise + meta + score circulaire.
                Row(
                  children: [
                    Container(
                      width: compact ? 38 : 46,
                      height: compact ? 38 : 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.onPrimary.withValues(alpha: 0.20),
                        border: Border.all(
                          color: AppColors.onPrimary.withValues(alpha: 0.32),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _initials(offer.company),
                        style: AppTextStyles.titleMd.copyWith(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: compact ? 13 : 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            offer.company,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleMd.copyWith(
                              color: AppColors.onPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: compact ? 12 : 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.onPrimary
                                  .withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              offer.contractType,
                              style: AppTextStyles.labelSm.copyWith(
                                color: AppColors.onPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: compact ? 9 : 10,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Bouton favoris : visible uniquement sur la card
                        // active (onApply != null). Etat partage via le
                        // OffersController (savedOffers) pour rester
                        // synchronise avec l'onglet Favoris.
                        if (onApply != null)
                          _DeckFavoriteButton(offerId: offer.id),
                        if (onApply != null) const SizedBox(height: 6),
                        _CircularScoreBadge(
                          score: matchScore,
                          compact: compact,
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: compact ? 12 : 16),
                // Titre + secteur.
                Text(
                  offer.title,
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headlineLg.copyWith(
                    color: AppColors.onPrimary,
                    fontSize: compact ? 20 : 24,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                if (!compact && offer.sector.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    offer.sector.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      fontSize: 10,
                    ),
                  ),
                ],
                SizedBox(height: compact ? 6 : 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 14,
                      color: muteText,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        offer.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySm.copyWith(
                          color: softText,
                          fontSize: compact ? 11 : 12,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!compact && offer.requiredSkills.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: offer.requiredSkills.take(3).map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              AppColors.onPrimary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color:
                                AppColors.onPrimary.withValues(alpha: 0.20),
                          ),
                        ),
                        child: Text(
                          skill,
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            letterSpacing: 0.2,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const Spacer(),
                // Bandeau salaire glassmorphism.
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    compact ? 10 : 12,
                    compact ? 8 : 10,
                    compact ? 10 : 12,
                    compact ? 8 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.onPrimary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.onPrimary.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.payments_rounded,
                        size: compact ? 14 : 16,
                        color: AppColors.primaryLight,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          offer.salary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleMd.copyWith(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: compact ? 12 : 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onApply == null
                              ? null
                              : () {
                                  AppHaptics.tap();
                                  onApply!();
                                },
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: compact ? 12 : 14,
                              vertical: compact ? 6 : 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.onPrimary,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.secondaryDeep
                                      .withValues(alpha: 0.18),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Postuler',
                                  style: AppTextStyles.titleMd.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: compact ? 11 : 12,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: compact ? 12 : 14,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircularScoreBadge extends StatelessWidget {
  const _CircularScoreBadge({
    required this.score,
    required this.compact,
  });

  final int score;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 44.0 : 56.0;
    final ratio = (score / 100).clamp(0.0, 1.0);
    final isStrong = score >= 75;
    final ringColor =
        isStrong ? AppColors.primaryLight : AppColors.warning;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: ratio,
              strokeWidth: compact ? 3 : 4,
              backgroundColor:
                  AppColors.onPrimary.withValues(alpha: 0.18),
              valueColor: AlwaysStoppedAnimation<Color>(ringColor),
            ),
          ),
          Container(
            width: size - (compact ? 10 : 12),
            height: size - (compact ? 10 : 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.onPrimary.withValues(alpha: 0.16),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$score',
                  style: AppTextStyles.titleMd.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: compact ? 12 : 15,
                    height: 1.0,
                  ),
                ),
                Text(
                  '%',
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.onPrimary.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 7 : 8,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _OfferDeckIndicators extends StatelessWidget {
  const _OfferDeckIndicators({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(controller.offers.length, (index) {
        final isActive = controller.currentOfferIndex.value == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 6,
          width: isActive ? 24 : 7,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.surfaceHighest,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        );
      }),
    );
  }
}

class _OfferActionButton extends StatelessWidget {
  const _OfferActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.size = 52,
    this.iconSize = 26,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          shape: BoxShape.circle,
          boxShadow: AppColors.lightShadow,
          border: Border.all(
            color: color.withValues(alpha: 0.24),
          ),
        ),
        child: Icon(
          icon,
          color: color,
          size: iconSize,
        ),
      ),
    );
  }
}

/// Bouton favoris circulaire, glassmorphism, place en haut a droite de la
/// card top du deck. Lit `OffersController.isOfferSaved(offerId)` reactive
/// — donc l'etat reste synchronise avec l'onglet "Favoris" de Mes
/// candidatures et avec la liste /offres. Si le controller n'existe pas
/// encore (premiere visite home avant /offres), on le lazy-cree.
class _DeckFavoriteButton extends StatelessWidget {
  const _DeckFavoriteButton({required this.offerId});

  final String offerId;

  OffersController _ensureController() {
    if (!Get.isRegistered<OffersController>()) {
      Get.lazyPut<OffersController>(() => OffersController());
    }
    return Get.find<OffersController>();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final offers = _ensureController();
      final saved = offers.isOfferSaved(offerId);
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            AppHaptics.tap();
            if (saved) {
              await offers.unsaveOffer(offerId);
            } else {
              await offers.saveOffer(offerId);
            }
          },
          customBorder: const CircleBorder(),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.onPrimary.withValues(alpha: 0.18),
              border: Border.all(
                color: AppColors.onPrimary.withValues(alpha: 0.32),
              ),
            ),
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                saved ? IconlyBold.heart : IconlyLight.heart,
                key: ValueKey(saved),
                size: 18,
                color: saved
                    ? AppColors.error
                    : AppColors.onPrimary,
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _OfferSwipeBadge extends StatelessWidget {
  const _OfferSwipeBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMd.copyWith(
          color: AppColors.onPrimary,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          fontSize: 10,
        ),
      ),
    );
  }
}
