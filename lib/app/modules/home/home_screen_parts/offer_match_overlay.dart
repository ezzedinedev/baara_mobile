part of '../home_screen.dart';

class _OfferMatchOverlay extends StatelessWidget {
  const _OfferMatchOverlay({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final match = controller.pendingMatch.value;
      if (match == null) {
        return const SizedBox.shrink();
      }

      return Positioned.fill(
        child: Container(
          color: AppColors.onDark.withValues(alpha: 0.72),
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppColors.ambientShadow,
                border: Border.all(
                  color: AppColors.primaryLight.withValues(alpha: 0.36),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: AppColors.onPrimary,
                      size: 46,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'C\'EST UN MATCH !',
                    style: AppTextStyles.displayMd.copyWith(
                      fontSize: 36,
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${match.score}% de compatibilite entre votre profil et cette offre',
                    style: AppTextStyles.titleMd.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    match.offer.title,
                    style: AppTextStyles.titleLg.copyWith(
                      color: AppColors.titleColor,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${match.offer.company} - ${match.offer.location}',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.bodyColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: controller.clearPendingMatch,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: AppColors.outlineVariant.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                          ),
                          child: Text(
                            'Continuer',
                            style: AppTextStyles.titleMd.copyWith(
                              color: AppColors.bodyColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GradientButton(
                          label: 'VOIR L\'OFFRE',
                          onPressed: () {
                            controller.clearPendingMatch();
                            controller.changeTab(2);
                          },
                          textColor: AppColors.onPrimary,
                          height: 46,
                          borderRadius: 12,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

