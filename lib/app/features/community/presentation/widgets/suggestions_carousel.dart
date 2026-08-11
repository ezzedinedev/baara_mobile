import 'package:flutter/material.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:get/get.dart';

import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_dimens.dart';
import 'package:baara/app/core/theme/app_shapes.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/app/core/widgets/widgets.dart';
import 'package:baara/routes/app_routes.dart';
import '../../domain/entities/network_user.dart';
import '../controllers/community_controller.dart';
import '../pages/suggestions_screen.dart';
import 'network_user_tile.dart';

/// Aperçu « Suggestions pour vous » inséré dans le fil communauté : carrousel
/// horizontal de petites cartes personne + lien « Voir tout » vers
/// [SuggestionsScreen]. Réactif (Obx) et masqué si la liste est vide.
class SuggestionsCarousel extends StatelessWidget {
  const SuggestionsCarousel({super.key});

  CommunityController get _controller => Get.find<CommunityController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final people = _controller.suggestions;
      if (people.isEmpty) return const SizedBox.shrink();
      // On limite l'aperçu, le reste vit dans l'écran dédié.
      final preview = people.take(10).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded,
                    size: 18, color: AppColors.primaryAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Suggestions pour vous',
                    style: AppTextStyles.titleMd.copyWith(
                      color: AppColors.titleColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                PressScale(
                  onTap: () {
                    AppHaptics.tap();
                    Get.to<void>(() => const SuggestionsScreen());
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'Voir tout',
                      style: AppTextStyles.labelLg.copyWith(
                        color: AppColors.primaryAccent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            // Hauteur du carrousel : marge suffisante pour le contenu de la
            // carte (avatar + nom + rôle + accroche + bouton), évite le
            // « BOTTOM OVERFLOWED » même avec un facteur de police un peu élevé.
            height: 212,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: preview.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (_, i) => _SuggestionCard(user: preview[i]),
            ),
          ),
        ],
      );
    });
  }
}

/// Petite carte personne du carrousel : avatar, nom, rôle, accroche
/// (reason ou insight IA), bouton Suivre optimiste.
class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.user});

  final NetworkUser user;

  CommunityController get _controller => Get.find<CommunityController>();

  @override
  Widget build(BuildContext context) {
    // L'accroche IA prime sur la reason quand elle est présente.
    final tagline = user.hasInsight ? user.insight! : user.reason;
    final taglineIsAi = user.hasInsight;

    return PressScale(
      onTap: () {
        AppHaptics.tap();
        Get.toNamed(
          AppRoutes.communityProfile.replaceFirst(':id', user.id),
        );
      },
      child: Container(
        width: 156,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: AppShapes.cardRadius,
          border: Border.all(color: AppColors.outlineVariant),
          boxShadow: [
            ...AppColors.ambientShadow,
            ...AppColors.lightShadow,
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            BrandAvatar(
              seed: user.id,
              label: user.fullName,
              size: 52,
              imageUrl: user.avatarUrl,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              user.fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMd.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.titleColor,
              ),
            ),
            if (user.role.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                user.role,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style:
                    AppTextStyles.bodySm.copyWith(color: AppColors.hintColor),
              ),
            ],
            const SizedBox(height: 4),
            SizedBox(
              height: 30,
              child: tagline == null
                  ? const SizedBox.shrink()
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          taglineIsAi
                              ? Icons.auto_awesome_rounded
                              : AppIcons.networkFilled,
                          size: 11,
                          color: AppColors.primaryAccent,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            tagline,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.primaryAccent,
                              fontWeight: taglineIsAi
                                  ? FontWeight.w600
                                  : FontWeight.w700,
                              fontStyle: taglineIsAi
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Obx(() {
              // Reste réactif au changement d'état de suivi du membre.
              final current = _controller.suggestions.firstWhere(
                (u) => u.id == user.id,
                orElse: () => user,
              );
              return FollowPillButton(
                following: current.isFollowing,
                onTap: () {
                  AppHaptics.tap();
                  _controller.toggleFollow(current);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
