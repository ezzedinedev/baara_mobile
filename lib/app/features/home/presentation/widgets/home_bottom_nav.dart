import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_motion.dart';
import 'package:opportune_bf/app/core/theme/app_shapes.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import 'package:opportune_bf/app/features/community/presentation/controllers/community_controller.dart';
import 'package:opportune_bf/app/features/messaging/presentation/controllers/messages_controller.dart';
import '../controllers/home_controller.dart';

/// Pastille de compteur sur un onglet de nav. [kind] : 'messages' (conversations
/// non lues) ou 'network' (demandes de connexion en attente). Réactif (Obx) ;
/// rien si compteur = 0 ou controller absent.
class HomeNavBadge extends StatelessWidget {
  const HomeNavBadge({super.key, required this.kind, required this.child});

  final String kind;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    switch (kind) {
      case 'messages':
        if (!Get.isRegistered<MessagesController>()) return child;
        final messages = Get.find<MessagesController>();
        return Obx(() => _wrap(
              messages.conversations
                  .fold<int>(0, (sum, c) => sum + c.unreadCount),
              child,
            ));
      case 'network':
        if (!Get.isRegistered<CommunityController>()) return child;
        final community = Get.find<CommunityController>();
        return Obx(() => _wrap(community.pendingConnections.length, child));
      default:
        return child;
    }
  }

  static Widget _wrap(int count, Widget child) {
    if (count <= 0) return child;
    return Badge(
      label: Text(count > 99 ? '99+' : '$count'),
      backgroundColor: AppColors.error,
      child: child,
    );
  }
}

/// Barre de navigation « glass » flottante : fond translucide + flou
/// d'arrière-plan (BackdropFilter), pill qui s'étire sur l'onglet actif (icône
/// + label). Le contenu défile dessous (Scaffold.extendBody) pour l'effet verre.
class HomeBottomNav extends GetView<HomeController> {
  const HomeBottomNav({super.key});

  // `badge` = source du compteur de pastille (null = aucune) :
  // 'network' → demandes de connexion en attente ; 'messages' → non-lus.
  static const _items =
      <({IconData icon, IconData active, String labelKey, String? badge})>[
    (
      icon: IconlyLight.home,
      active: IconlyBold.home,
      labelKey: 'nav.home',
      badge: null
    ),
    (
      icon: IconlyLight.work,
      active: IconlyBold.work,
      labelKey: 'nav.offers',
      badge: null
    ),
    (
      icon: IconlyLight.user,
      active: IconlyBold.user_3,
      labelKey: 'nav.network',
      badge: 'network'
    ),
    (
      icon: IconlyLight.category,
      active: IconlyBold.category,
      labelKey: 'nav.tracking',
      badge: null
    ),
    (
      icon: IconlyLight.profile,
      active: IconlyBold.profile,
      labelKey: 'nav.profile',
      badge: null
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        // Verre liquide flottant (chrome) : GlassSurface = blur + couche tonale
        // + liseré spéculaire, dans un RepaintBoundary.
        child: GlassSurface(
          borderRadius: AppShapes.pill,
          blurSigma: 20,
          boxShadow: AppColors.ambientShadow,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: SizedBox(
            height: 62,
            child: Obx(() {
              final current = controller.currentTabIndex.value;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (var i = 0; i < _items.length; i++)
                    HomeGlassNavItem(
                      item: _items[i],
                      selected: i == current,
                      onTap: () {
                        AppHaptics.tap();
                        controller.changeTab(i);
                      },
                    ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

class HomeGlassNavItem extends StatelessWidget {
  const HomeGlassNavItem({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final ({IconData icon, IconData active, String labelKey, String? badge}) item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryAccent : AppColors.hintColor;
    // Icône avec micro-bascule de scale en spring quand l'onglet devient actif.
    Widget icon = AnimatedScale(
      scale: selected ? 1.0 : 0.92,
      duration: AppMotion.medium,
      curve: AppMotion.spring,
      child: Icon(selected ? item.active : item.icon, size: 22, color: color),
    );
    if (item.badge != null) {
      icon = HomeNavBadge(kind: item.badge!, child: icon);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        // Sélection en spring : la pill « gonfle » avec un léger overshoot.
        duration: AppMotion.medium,
        curve: AppMotion.spring,
        height: 42,
        padding:
            EdgeInsets.symmetric(horizontal: selected ? 14 : 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryAccent.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: AppShapes.pill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            // Le nom « pousse » en spring sur l'onglet actif.
            AnimatedSize(
              duration: AppMotion.medium,
              curve: AppMotion.spring,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        item.labelKey.tr,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.clip,
                        style: AppTextStyles.labelSm.copyWith(
                          color: color,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
