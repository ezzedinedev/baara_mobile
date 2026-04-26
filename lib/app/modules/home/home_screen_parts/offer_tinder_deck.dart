part of '../home_screen.dart';

class _OfferTinderDeck extends StatelessWidget {
  const _OfferTinderDeck({
    required this.controller,
    required this.height,
    required this.showActions,
    required this.compact,
  });

  final HomeController controller;
  final double height;
  final bool showActions;
  final bool compact;

  void _showOfferDetails(
    BuildContext context,
    HomeOfferPreview offer,
    int score,
  ) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
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
              Text(
                offer.title,
                style: AppTextStyles.headlineMd.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 4),
              Text(
                '${offer.company} - ${offer.location}',
                style: AppTextStyles.bodyMd,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _OfferMetaChip(
                    icon: Icons.work_outline_rounded,
                    text: offer.contractType,
                  ),
                  _OfferMetaChip(
                    icon: Icons.apartment_rounded,
                    text: offer.sector,
                  ),
                  _OfferMetaChip(
                    icon: Icons.schedule_rounded,
                    text: offer.deadlineLabel,
                  ),
                  _OfferMetaChip(
                    icon: offer.isRemote
                        ? Icons.wifi_tethering_rounded
                        : Icons.location_on_outlined,
                    text: offer.experienceLabel,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (offer.requiredSkills.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: offer.requiredSkills.map((skill) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceIconSoft,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        skill,
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }).toList(),
                )
              else
                Text(
                  'Competences non precisees par l\'entreprise.',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.bodyColor,
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                'Salaire: ${offer.salary}',
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.titleColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                offer.description,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.bodyColor,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Compatibilite estimee: $score%',
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingOffers.value && controller.offers.isEmpty) {
        return SizedBox(
          height: height,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: OfferCardSkeleton(height: 360),
          ),
        );
      }

      if (controller.offers.isEmpty) {
        return SizedBox(
          height: height,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _ContentStatusCard(
                message: controller.offersLoadError.value.isNotEmpty
                    ? controller.offersLoadError.value
                    : 'Aucune offre publiee pour le moment.',
                onRetry: () => controller.reloadOffers(),
              ),
            ),
          ),
        );
      }

      final dragDx = controller.offerDragDx.value;
      final swipeFactor = (dragDx / 140).clamp(-1.0, 1.0);
      final top = controller.offerAtOffset(0);
      final second = controller.offerAtOffset(1);
      final third = controller.offerAtOffset(2);
      final topScore = controller.scoreForOffset(0);
      final secondScore = controller.scoreForOffset(1);
      final thirdScore = controller.scoreForOffset(2);

      return Column(
        children: [
          SizedBox(
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Transform.translate(
                    offset: const Offset(0, 18),
                    child: Transform.scale(
                      scale: 0.93,
                      child: Opacity(
                        opacity: 0.34,
                        child: _OfferDeckCard(
                          offer: third,
                          matchScore: thirdScore,
                          compact: compact,
                          muted: true,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Transform.translate(
                    offset: const Offset(0, 9),
                    child: Transform.scale(
                      scale: 0.97,
                      child: Opacity(
                        opacity: 0.66,
                        child: _OfferDeckCard(
                          offer: second,
                          matchScore: secondScore,
                          compact: compact,
                          muted: true,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      controller.updateOfferDrag(details.delta.dx);
                    },
                    onPanEnd: (details) {
                      controller.endOfferDrag(
                        details.velocity.pixelsPerSecond.dx,
                      );
                    },
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
                            matchScore: topScore,
                            compact: compact,
                            // Tap sur "Postuler" = meme flux qu'un swipe droite
                            // (animation + pendingMatch + soumission backend).
                            onApply: () => controller.swipeOfferRight(),
                          ),
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Opacity(
                              opacity: (-swipeFactor).clamp(0.0, 1.0),
                              child: const _OfferSwipeBadge(
                                label: 'PASSER',
                                color: AppColors.error,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Opacity(
                              opacity: swipeFactor.clamp(0.0, 1.0),
                              child: const _OfferSwipeBadge(
                                label: 'INTERESSE',
                                color: AppColors.success,
                              ),
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
                  iconSize: 22,
                ),
                const SizedBox(width: 10),
                _OfferActionButton(
                  icon: Icons.close_rounded,
                  color: AppColors.error,
                  onTap: controller.swipeOfferLeft,
                  size: 58,
                  iconSize: 30,
                ),
                const SizedBox(width: 14),
                _OfferActionButton(
                  icon: Icons.favorite_rounded,
                  color: AppColors.success,
                  onTap: controller.swipeOfferRight,
                  size: 58,
                  iconSize: 30,
                ),
                const SizedBox(width: 10),
                _OfferActionButton(
                  icon: Icons.info_outline_rounded,
                  color: AppColors.primary,
                  onTap: () => _showOfferDetails(context, top, topScore),
                  size: 46,
                  iconSize: 22,
                ),
              ],
            ),
          ],
        ],
      );
    });
  }
}

