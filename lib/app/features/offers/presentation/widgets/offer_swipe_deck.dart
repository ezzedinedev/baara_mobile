import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';

import '../../domain/entities/offer.dart';
import '../controllers/offer_controller.dart';

/// Deck d'offres type Tinder (restauré de l'app d'origine) : pile de 3 cartes,
/// drag horizontal avec badges PASSER / INTÉRESSÉ, rewind, et candidature
/// réelle au swipe droite. Câblé sur [OfferController].
class OfferSwipeDeck extends StatelessWidget {
  const OfferSwipeDeck({
    super.key,
    required this.controller,
    this.height = 380,
    this.showActions = true,
    this.compact = false,
  });

  final OfferController controller;
  final double height;
  final bool showActions;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.offers.isEmpty) {
        return SizedBox(
          height: height,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: OfferCardSkeleton(),
          ),
        );
      }

      if (controller.offers.isEmpty) {
        return SizedBox(
          height: height,
          child: controller.errorMessage.value.isNotEmpty
              ? ErrorStateView(
                  message: controller.errorMessage.value,
                  onRetry: () => controller.loadOffers(refresh: true),
                  compact: true,
                )
              : EmptyState(
                  icon: IconlyLight.work,
                  title: 'Aucune offre',
                  subtitle: 'Revenez bientôt : de nouvelles offres arrivent.',
                  actionLabel: 'Actualiser',
                  onAction: () => controller.loadOffers(refresh: true),
                ),
        );
      }

      final dragDx = controller.offerDragDx.value;
      final swipeFactor = (dragDx / 140).clamp(-1.0, 1.0);
      final top = controller.offerAtOffset(0);
      final second = controller.offerAtOffset(1);
      final third = controller.offerAtOffset(2);
      if (top == null) return SizedBox(height: height);

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (third != null)
                  Positioned.fill(
                    child: Transform.translate(
                      offset: const Offset(0, 18),
                      child: Transform.scale(
                        scale: 0.93,
                        child: Opacity(
                          opacity: 0.34,
                          child: _OfferDeckCard(
                              offer: third, matchScore: controller.scoreForOffset(2), compact: compact, muted: true),
                        ),
                      ),
                    ),
                  ),
                if (second != null)
                  Positioned.fill(
                    child: Transform.translate(
                      offset: const Offset(0, 9),
                      child: Transform.scale(
                        scale: 0.97,
                        child: Opacity(
                          opacity: 0.66,
                          child: _OfferDeckCard(
                              offer: second, matchScore: controller.scoreForOffset(1), compact: compact, muted: true),
                        ),
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: GestureDetector(
                    onPanUpdate: (d) => controller.updateOfferDrag(d.delta.dx),
                    onPanEnd: (d) =>
                        controller.endOfferDrag(d.velocity.pixelsPerSecond.dx),
                    onPanCancel: () => controller.endOfferDrag(0),
                    child: AnimatedContainer(
                      duration: controller.isOfferAnimating.value
                          ? const Duration(milliseconds: 210)
                          : Duration.zero,
                      curve: Curves.easeOutCubic,
                      transform:
                          Matrix4.rotationZ((dragDx / 980).clamp(-0.22, 0.22))
                            ..setTranslationRaw(dragDx, 0, 0),
                      child: Stack(
                        children: [
                          _OfferDeckCard(
                            offer: top,
                            matchScore: controller.scoreForOffset(0),
                            compact: compact,
                            onApply: () {
                              AppHaptics.tap();
                              controller.swipeOfferRight();
                            },
                          ),
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Opacity(
                              opacity: (-swipeFactor).clamp(0.0, 1.0),
                              child: const _OfferSwipeBadge(
                                  label: 'PASSER', color: AppColors.error),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Opacity(
                              opacity: swipeFactor.clamp(0.0, 1.0),
                              child: const _OfferSwipeBadge(
                                  label: 'INTÉRESSÉ', color: AppColors.success),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _OfferDeckIndicators(controller: controller),
          if (showActions) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _OfferActionButton(
                    icon: Icons.replay_rounded,
                    color: AppColors.warning,
                    onTap: controller.rewindOffer,
                    size: 46,
                    iconSize: 22),
                const SizedBox(width: 10),
                _OfferActionButton(
                    icon: Icons.close_rounded,
                    color: AppColors.error,
                    onTap: controller.swipeOfferLeft,
                    size: 58,
                    iconSize: 30),
                const SizedBox(width: 14),
                _OfferActionButton(
                    icon: Icons.favorite_rounded,
                    color: AppColors.success,
                    onTap: controller.swipeOfferRight,
                    size: 58,
                    iconSize: 30),
                const SizedBox(width: 10),
                _OfferActionButton(
                    icon: Icons.info_outline_rounded,
                    color: AppColors.primary,
                    onTap: () => _showDetails(context, top,
                        controller.scoreForOffset(0)),
                    size: 46,
                    iconSize: 22),
              ],
            ),
          ],
        ],
      );
    });
  }

  void _showDetails(BuildContext context, Offer offer, int score) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHighest,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(offer.title,
                style: AppTextStyles.headlineMd.copyWith(fontSize: 22)),
            const SizedBox(height: 4),
            Text('${offer.company} · ${offer.location}',
                style: AppTextStyles.bodyMd),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _OfferMetaChip(
                    icon: Icons.work_outline_rounded, text: offer.contractType),
                if (offer.sector.isNotEmpty)
                  _OfferMetaChip(
                      icon: Icons.apartment_rounded, text: offer.sector),
                if ((offer.deadlineLabel ?? '').isNotEmpty)
                  _OfferMetaChip(
                      icon: Icons.schedule_rounded,
                      text: offer.deadlineLabel!),
                _OfferMetaChip(
                    icon: offer.isRemote
                        ? Icons.wifi_tethering_rounded
                        : Icons.location_on_outlined,
                    text: (offer.experienceLabel ?? '').isNotEmpty
                        ? offer.experienceLabel!
                        : offer.location),
              ],
            ),
            if (offer.requiredSkills.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: offer.requiredSkills
                    .map((s) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceIconSoft,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(s,
                              style: AppTextStyles.bodySm.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w700)),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            Text('Salaire : ${offer.salary}',
                style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.titleColor, fontWeight: FontWeight.w600)),
            if (offer.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(offer.description,
                  style: AppTextStyles.bodyMd
                      .copyWith(color: AppColors.bodyColor, height: 1.45)),
            ],
            const SizedBox(height: 8),
            Text('Compatibilité estimée : $score%',
                style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _OfferMetaChip extends StatelessWidget {
  const _OfferMetaChip({required this.icon, required this.text});
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
          Icon(icon, size: 14, color: AppColors.primaryDark),
          const SizedBox(width: 6),
          Text(text,
              style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.primaryDark, fontWeight: FontWeight.w700)),
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

  final Offer offer;
  final int matchScore;
  final bool compact;
  final bool muted;
  final VoidCallback? onApply;

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
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
          Positioned(
            top: -60,
            right: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.onPrimary.withValues(alpha: 0.06)),
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
                  color: AppColors.onPrimary.withValues(alpha: 0.04)),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(compact ? 14 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: compact ? 38 : 46,
                      height: compact ? 38 : 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.onPrimary.withValues(alpha: 0.20),
                        border: Border.all(
                            color: AppColors.onPrimary.withValues(alpha: 0.32)),
                      ),
                      alignment: Alignment.center,
                      child: Text(_initials(offer.company),
                          style: AppTextStyles.titleMd.copyWith(
                              color: AppColors.onPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: compact ? 13 : 16)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(offer.company,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.titleMd.copyWith(
                                  color: AppColors.onPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: compact ? 12 : 13)),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.onPrimary.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(offer.contractType,
                                style: AppTextStyles.labelSm.copyWith(
                                    color: AppColors.onPrimary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: compact ? 9 : 10,
                                    letterSpacing: 0.4)),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (onApply != null) _DeckFavoriteButton(offer: offer),
                        if (onApply != null) const SizedBox(height: 6),
                        _CircularScoreBadge(score: matchScore, compact: compact),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: compact ? 12 : 16),
                Text(offer.title,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headlineLg.copyWith(
                        color: AppColors.onPrimary,
                        fontSize: compact ? 20 : 24,
                        fontWeight: FontWeight.w800,
                        height: 1.15)),
                if (!compact && offer.sector.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(offer.sector.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          fontSize: 10)),
                ],
                SizedBox(height: compact ? 6 : 8),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 14, color: muteText),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(offer.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySm.copyWith(
                              color: softText, fontSize: compact ? 11 : 12)),
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
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.onPrimary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                              color:
                                  AppColors.onPrimary.withValues(alpha: 0.20)),
                        ),
                        child: Text(skill,
                            style: AppTextStyles.labelSm.copyWith(
                                color: AppColors.onPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                                letterSpacing: 0.2)),
                      );
                    }).toList(),
                  ),
                ],
                const Spacer(),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(compact ? 10 : 12, compact ? 8 : 10,
                      compact ? 10 : 12, compact ? 8 : 10),
                  decoration: BoxDecoration(
                    color: AppColors.onPrimary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.onPrimary.withValues(alpha: 0.20)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.payments_rounded,
                          size: compact ? 14 : 16, color: AppColors.primaryLight),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(offer.salary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleMd.copyWith(
                                color: AppColors.onPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: compact ? 12 : 14)),
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
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: compact ? 12 : 14,
                                vertical: compact ? 6 : 8),
                            decoration: BoxDecoration(
                              color: AppColors.onPrimary,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              boxShadow: [
                                BoxShadow(
                                    color: AppColors.secondaryDeep
                                        .withValues(alpha: 0.18),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Postuler',
                                    style: AppTextStyles.titleMd.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: compact ? 11 : 12)),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_forward_rounded,
                                    size: compact ? 12 : 14,
                                    color: AppColors.primary),
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
  const _CircularScoreBadge({required this.score, required this.compact});
  final int score;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 44.0 : 56.0;
    final ratio = (score / 100).clamp(0.0, 1.0);
    final ringColor = score >= 75 ? AppColors.primaryLight : AppColors.warning;

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
              backgroundColor: AppColors.onPrimary.withValues(alpha: 0.18),
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
            child: Text('$score%',
                style: AppTextStyles.titleMd.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: compact ? 11 : 13,
                    height: 1.0)),
          ),
        ],
      ),
    );
  }
}

class _OfferDeckIndicators extends StatelessWidget {
  const _OfferDeckIndicators({required this.controller});
  final OfferController controller;

  @override
  Widget build(BuildContext context) {
    // Limité à 8 points pour éviter une ligne trop longue sur grandes listes.
    final count = controller.offers.length.clamp(0, 8);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = controller.currentOfferIndex.value % count == index;
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
      onTap: () {
        AppHaptics.tap();
        onTap();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          shape: BoxShape.circle,
          boxShadow: AppColors.lightShadow,
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
        child: Icon(icon, color: color, size: iconSize),
      ),
    );
  }
}

class _DeckFavoriteButton extends StatelessWidget {
  const _DeckFavoriteButton({required this.offer});
  final Offer offer;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OfferController>();
    return Obx(() {
      final saved = controller.isOfferSaved(offer.id);
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            AppHaptics.tap();
            controller.toggleSaveOffer(offer);
          },
          customBorder: const CircleBorder(),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.onPrimary.withValues(alpha: 0.18),
              border:
                  Border.all(color: AppColors.onPrimary.withValues(alpha: 0.32)),
            ),
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(saved ? IconlyBold.heart : IconlyLight.heart,
                  key: ValueKey(saved),
                  size: 18,
                  color: saved ? AppColors.error : AppColors.onPrimary),
            ),
          ),
        ),
      );
    });
  }
}

class _OfferSwipeBadge extends StatelessWidget {
  const _OfferSwipeBadge({required this.label, required this.color});
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
      child: Text(label,
          style: AppTextStyles.labelMd.copyWith(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              fontSize: 10)),
    );
  }
}
