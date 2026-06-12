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
import '../controllers/notifications_controller.dart';
import '../../domain/entities/notification.dart';

class NotificationsScreen extends GetView<NotificationsController> {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SankSheetScaffold(
        title: 'Notifications',
        titleIcon: IconlyLight.notification,
        showBack: Navigator.of(context).canPop(),
        actions: [
          AppIconButton(
            onBrandHeader: true,
            icon: IconlyLight.tick_square,
            tooltip: 'Tout marquer comme lu',
            onTap: () {
              AppHaptics.tap();
              controller.markAllRead();
            },
          ),
        ],
        body: Obx(() {
          if (controller.isLoading.value) {
            return const PageSkeleton();
          }

          if (controller.notifications.isEmpty) {
            return const EmptyState(
              illustration: EmptyNotificationsIllustration(),
              title: 'Aucune notification',
              subtitle: 'Les nouvelles alertes apparaitront ici.',
            );
          }

          return AppRefreshIndicator(
            color: AppColors.primaryAccent,
            onRefresh: () => controller.fetchNotifications(),
            child: AnimationLimiter(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: controller.notifications.length +
                    (controller.hasMore.value ? 1 : 0),
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  // Sentinelle de fin de liste : déclenche le chargement de la
                  // page suivante et affiche un indicateur.
                  if (index >= controller.notifications.length) {
                    controller.loadMore();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: const AppLoader(),
                        ),
                      ),
                    );
                  }
                  final notification = controller.notifications[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: AppMotion.medium,
                    child: SlideAnimation(
                      curve: AppMotion.emphasizedDecelerate,
                      verticalOffset: AppMotion.listSlideOffset,
                      child: FadeInAnimation(
                        child: _NotificationCard(
                          notification: notification,
                          onTap: () {
                            AppHaptics.tap();
                            controller.openNotification(notification);
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Carte de notification : icône colorée selon le type, heure relative, et
/// emphase non-lu (icône saturée + titre gras + point).
class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final read = notification.isRead;
    // On mappe l'icône sur le type métier (`target.type`, ex. `mention_post`),
    // qui retombe sur `category` si absent.
    final visual = _visualFor(notification.typeKey);

    return PressScale(
      curve: AppMotion.spring,
      onTap: onTap,
      // Carte squircle (langage 2026), bordure accentuée si non-lu. Material
      // sous le contenu pour rester cohérent avec les autres écrans.
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: ShapeDecoration(
            color: AppColors.surfaceCard,
            shape: AppShapes.cardBordered(
              read
                  ? AppColors.outlineVariant
                  : AppColors.primaryAccent.withValues(alpha: 0.40),
              width: read ? 1 : 1.4,
            ),
            shadows: AppColors.lightShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NotifIcon(icon: visual.icon, color: visual.color, read: read),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleMd.copyWith(
                              fontWeight:
                                  read ? FontWeight.w700 : FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        if (!read)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Text(
                          _relativeTime(notification.createdAt),
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.hintColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      notification.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.bodyColor,
                        height: 1.3,
                      ),
                    ),
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

/// Pastille d'icône teintée selon le type (atténuée si la notif est lue).
class _NotifIcon extends StatelessWidget {
  const _NotifIcon({
    required this.icon,
    required this.color,
    required this.read,
  });

  final IconData icon;
  final Color color;
  final bool read;

  @override
  Widget build(BuildContext context) {
    final c = read ? AppColors.hintColor : color;
    // Pastille squircle tonale (langage 2026) au lieu d'un cercle.
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: c.withValues(alpha: read ? 0.10 : 0.14),
        shape: AppShapes.squircle(AppRadius.sm),
      ),
      child: Icon(icon, color: c, size: 21),
    );
  }
}

/// Icône + couleur par type de notification (robuste : on mappe par mots-clés
/// du `category`, avec une cloche par défaut).
({IconData icon, Color color}) _visualFor(String category) {
  final c = category.toLowerCase();
  bool has(String s) => c.contains(s);
  // Mentions (`mention_post`, `mention_comment`) : prioritaire car la clé
  // contient aussi « post »/« comment ».
  if (has('mention')) {
    return (icon: IconlyBold.chat, color: AppColors.categoryPurple);
  }
  if (has('message') || has('new_message')) {
    return (icon: IconlyBold.chat, color: AppColors.categoryBlue);
  }
  if (has('network') || has('connection') || has('connexion')) {
    return (icon: IconlyBold.add_user, color: AppColors.categoryCyan);
  }
  if (has('story') || has('reaction')) {
    return (icon: IconlyBold.heart, color: AppColors.categoryPink);
  }
  if (has('interview') || has('entretien')) {
    return (icon: IconlyBold.calendar, color: AppColors.categoryPurple);
  }
  if (has('application') || has('candidat') || has('status')) {
    return (icon: IconlyBold.tick_square, color: AppColors.secondary);
  }
  if (has('offer') || has('job') || has('emploi')) {
    return (icon: IconlyBold.work, color: AppColors.primaryAccent);
  }
  if (has('training') || has('formation') || has('course')) {
    return (icon: IconlyBold.bookmark, color: AppColors.categoryOrange);
  }
  if (has('comment') ||
      has('commentaire') ||
      has('post') ||
      has('community') ||
      has('follow') ||
      has('réseau') ||
      has('reseau')) {
    return (icon: IconlyBold.chat, color: AppColors.categoryCyan);
  }
  if (has('profile') || has('profil') || has('portfolio')) {
    return (icon: IconlyBold.profile, color: AppColors.categoryPink);
  }
  return (icon: IconlyBold.notification, color: AppColors.primaryAccent);
}

/// Heure relative compacte (Maintenant / 5 min / 2 h / 3 j / 2 sem).
String _relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'Maintenant';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min';
  if (diff.inHours < 24) return '${diff.inHours} h';
  if (diff.inDays < 7) return '${diff.inDays} j';
  return '${(diff.inDays / 7).floor()} sem';
}
