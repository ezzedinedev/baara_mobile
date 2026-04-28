part of '../home_screen.dart';

class _OffresTab extends StatelessWidget {
  const _OffresTab({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => RefreshIndicator(
        onRefresh: controller.reloadOffers,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 130),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!(controller.isLoadingOffers.value &&
                      controller.offers.isEmpty) &&
                  controller.offers.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(
                    '${controller.offers.length} OFFRE(S) DISPONIBLE(S)',
                    style: AppTextStyles.labelLg.copyWith(
                      color: AppColors.bodyColor,
                      fontSize: 11,
                      letterSpacing: 1.3,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              if (controller.isLoadingOffers.value && controller.offers.isEmpty)
                Column(
                  children: List.generate(
                    3,
                    (_) => const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: OfferCardSkeleton(height: 280),
                    ),
                  ),
                )
              else if (controller.offers.isEmpty)
                _ContentStatusCard(
                  message: controller.offersLoadError.value.isNotEmpty
                      ? controller.offersLoadError.value
                      : 'Aucune offre publiee pour le moment.',
                  onRetry: () => controller.reloadOffers(),
                )
              else
                ...List.generate(controller.offers.length, (index) {
                  final offer = controller.offers[index];
                  final score = controller.scoreForOffer(offer);
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == controller.offers.length - 1 ? 0 : 12,
                    ),
                    child: SizedBox(
                      height: 356,
                      child: _OfferDeckCard(
                        offer: offer,
                        matchScore: score,
                        compact: false,
                        // Tap sur "Postuler" depuis la liste verticale : on
                        // soumet la candidature pour CETTE offre (pas via
                        // swipe), avec overlay match + feedback.
                        onApply: () => controller.applyToOfferDirect(offer),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContentStatusCard extends StatelessWidget {
  const _ContentStatusCard({
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceIconSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.bodyColor,
              height: 1.4,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Recharger'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FormationsTab extends StatelessWidget {
  const _FormationsTab({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingFormations.value &&
          controller.formations.isEmpty) {
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, __) => const TrainingCardSkeleton(),
        );
      }

      if (controller.formations.isEmpty) {
        return RefreshIndicator(
          onRefresh: controller.reloadFormations,
          color: AppColors.primary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _ContentStatusCard(
                message: controller.formationsLoadError.value.isNotEmpty
                    ? controller.formationsLoadError.value
                    : 'Aucune formation disponible pour le moment.',
                onRetry: () => controller.reloadFormations(),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.reloadFormations,
        color: AppColors.primary,
        child: AnimationLimiter(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: controller.formations.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Text(
                  '${controller.formations.length} FORMATIONS DISPONIBLES',
                  style: AppTextStyles.labelLg.copyWith(
                    color: AppColors.bodyColor,
                    fontSize: 11,
                    letterSpacing: 1.3,
                  ),
                );
              }

              final formation = controller.formations[index - 1];
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 320),
                child: SlideAnimation(
                  verticalOffset: 18,
                  child: FadeInAnimation(
                    child: _FormationDarkCard(
                      formation: formation,
                      compact: false,
                      onTap: () {
                        AppHaptics.tap();
                        _showFormationDetails(context, formation);
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    });
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.headlineMd.copyWith(fontSize: 21),
          ),
        ),
        GestureDetector(
          onTap: () {
            AppHaptics.tap();
            onAction();
          },
          child: Text(
            actionLabel,
            style: AppTextStyles.titleMd.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

