import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_motion.dart';
import 'package:opportune_bf/app/core/theme/app_shapes.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import 'package:opportune_bf/routes/app_routes.dart';
import '../../domain/entities/network_user.dart';
import '../controllers/community_controller.dart';
import '../widgets/network_user_tile.dart';

/// « Personnes à suivre » : suggestions enrichies (`reason`, relations en
/// commun, secteur/ville, accroche IA) chargées par [CommunityController].
/// Suivre / se connecter en optimiste, pull-to-refresh, états vide/skeleton,
/// cascade d'apparition.
class SuggestionsScreen extends StatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> {
  final _controller = Get.find<CommunityController>();
  bool _firstLoad = false;

  @override
  void initState() {
    super.initState();
    // Recharge si la liste est vide (entrée directe sans passer par le feed).
    if (_controller.suggestions.isEmpty) {
      _firstLoad = true;
      _controller.loadSuggestions().whenComplete(() {
        if (mounted) setState(() => _firstLoad = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SankSheetScaffold(
      title: 'Personnes à suivre',
      titleIcon: IconlyLight.user,
      body: Obx(() {
        final people = _controller.suggestions;

        if (_firstLoad && people.isEmpty) {
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: 7,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, __) => const MessageTileSkeleton(),
          );
        }

        if (people.isEmpty) {
          return AppRefreshIndicator(
            color: AppColors.primaryAccent,
            onRefresh: _controller.loadSuggestions,
            child: ListView(
              children: const [
                SizedBox(height: 60),
                EmptyState(
                  illustration: EmptyPeopleIllustration(),
                  title: 'Aucune suggestion',
                  subtitle:
                      'Revenez plus tard : nous vous proposerons des membres '
                      'à suivre selon votre réseau et votre secteur.',
                ),
              ],
            ),
          );
        }

        return AppRefreshIndicator(
          color: AppColors.primaryAccent,
          onRefresh: _controller.loadSuggestions,
          child: AnimationLimiter(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: people.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, i) {
                final user = people[i];
                return AnimationConfiguration.staggeredList(
                  position: i,
                  duration: AppMotion.medium,
                  child: SlideAnimation(
                    verticalOffset: AppMotion.listSlideOffset,
                    curve: AppMotion.emphasizedDecelerate,
                    child: FadeInAnimation(
                      curve: AppMotion.emphasizedDecelerate,
                      child: NetworkUserTile(
                        user: user,
                        onTap: () => Get.toNamed(
                          AppRoutes.communityProfile
                              .replaceFirst(':id', user.id),
                        ),
                        trailing: SuggestionActions(user: user),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }),
    );
  }
}

/// Boutons d'action d'une suggestion : « Suivre » (toggle optimiste) et, si
/// pas encore connecté, « Se connecter ». Réagit à l'état du membre.
class SuggestionActions extends StatelessWidget {
  const SuggestionActions({super.key, required this.user});

  final NetworkUser user;

  CommunityController get _controller => Get.find<CommunityController>();

  @override
  Widget build(BuildContext context) {
    if (user.isSelf) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FollowPillButton(
          following: user.isFollowing,
          onTap: () {
            AppHaptics.tap();
            _controller.toggleFollow(user);
          },
        ),
        if (user.connectionStatus == 'none') ...[
          const SizedBox(height: AppSpacing.sm),
          _ConnectPill(
            onTap: () {
              AppHaptics.tap();
              _controller.connectUser(user);
            },
          ),
        ] else if (user.connectionStatus == 'pending_sent') ...[
          const SizedBox(height: AppSpacing.sm),
          _StatusPill(label: 'En attente', icon: IconlyLight.time_circle),
        ] else if (user.connectionStatus == 'connected') ...[
          const SizedBox(height: AppSpacing.sm),
          _StatusPill(label: 'Connecté', icon: IconlyBold.tick_square),
        ],
      ],
    );
  }
}

/// Pastille « Se connecter » (contour neutre, icône add_user).
class _ConnectPill extends StatelessWidget {
  const _ConnectPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: AppShapes.pill,
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(IconlyLight.add_user, size: 15, color: AppColors.bodyColor),
            const SizedBox(width: 4),
            Text(
              'Connexion',
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.bodyColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pastille d'état non interactive (En attente / Connecté).
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.primaryAccent;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: AppShapes.pill,
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: accent),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelMd.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
