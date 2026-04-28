import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme_controller.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../home/controllers/home_controller.dart';

enum _NotifFilter { all, unread, read }

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final HomeController controller = Get.find<HomeController>();
  final AppThemeController themeController = Get.find<AppThemeController>();
  final Rx<_NotifFilter> _filter = _NotifFilter.all.obs;

  bool _matches(HomeNotificationPreview n) {
    switch (_filter.value) {
      case _NotifFilter.all:
        return true;
      case _NotifFilter.unread:
        return !n.isRead;
      case _NotifFilter.read:
        return n.isRead;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      themeController.isDarkMode.value;

      final unread = controller.notifications.where((n) => !n.isRead).length;
      _filter.value;
      final filtered =
          controller.notifications.where(_matches).toList(growable: false);

      return Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            WavyContentHeader(
              title: 'notifs.title'.tr,
              subtitle: 'notifs.subtitle'.tr,
              gradient: AppColors.heroNotificationsGradient,
              height: 240,
              actions: [
                WavyHeaderActionButton(
                  tooltip: themeController.isDarkMode.value
                      ? 'Mode clair'
                      : 'Mode sombre',
                  icon: themeController.isDarkMode.value
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  onTap: () {
                    AppHaptics.tap();
                    themeController.toggle();
                  },
                ),
                const SizedBox(width: 8),
                WavyHeaderActionButton(
                  tooltip: 'Tout marquer comme lu',
                  icon: IconlyBold.tick_square,
                  badgeCount: unread,
                  onTap: controller.notifications.isEmpty
                      ? () {}
                      : () {
                          AppHaptics.success();
                          controller.markAllNotificationsAsRead();
                        },
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: _FilterStrip(
                selected: _filter.value,
                unreadCount: unread,
                totalCount: controller.notifications.length,
                onChanged: (next) {
                  AppHaptics.tap();
                  _filter.value = next;
                },
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: controller.refreshNotifications,
                child: filtered.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.sizeOf(context).height * 0.5,
                            child: _EmptyNotifications(filter: _filter.value),
                          ),
                        ],
                      )
                    : AnimationLimiter(
                        child: _SectionedList(
                          notifications: filtered,
                          onTapItem: (n) {
                            AppHaptics.tap();
                            controller.markNotificationAsRead(n.id);
                          },
                        ),
                      ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _SectionedList extends StatelessWidget {
  const _SectionedList({
    required this.notifications,
    required this.onTapItem,
  });

  final List<HomeNotificationPreview> notifications;
  final ValueChanged<HomeNotificationPreview> onTapItem;

  List<({String label, List<HomeNotificationPreview> items})> _group() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekStart = today.subtract(const Duration(days: 7));

    final todays = <HomeNotificationPreview>[];
    final yesterdays = <HomeNotificationPreview>[];
    final week = <HomeNotificationPreview>[];
    final older = <HomeNotificationPreview>[];

    for (final n in notifications) {
      final d = n.createdAt;
      final dDay = DateTime(d.year, d.month, d.day);
      if (!dDay.isBefore(today)) {
        todays.add(n);
      } else if (dDay.isAtSameMomentAs(yesterday)) {
        yesterdays.add(n);
      } else if (dDay.isAfter(weekStart)) {
        week.add(n);
      } else {
        older.add(n);
      }
    }

    return [
      if (todays.isNotEmpty)
        (label: 'notifs.section.today'.tr, items: todays),
      if (yesterdays.isNotEmpty)
        (label: 'notifs.section.yesterday'.tr, items: yesterdays),
      if (week.isNotEmpty)
        (label: 'notifs.section.this_week'.tr, items: week),
      if (older.isNotEmpty)
        (label: 'notifs.section.older'.tr, items: older),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final sections = _group();
    int globalIndex = 0;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: sections.length,
      itemBuilder: (context, sectionIndex) {
        final section = sections[sectionIndex];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 14, 4, 10),
              child: Text(
                section.label,
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.hintColor,
                  letterSpacing: 0.6,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ...List.generate(section.items.length, (i) {
              final notif = section.items[i];
              final position = globalIndex++;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: i == section.items.length - 1 ? 0 : 10,
                ),
                child: AnimationConfiguration.staggeredList(
                  position: position,
                  duration: const Duration(milliseconds: 280),
                  child: SlideAnimation(
                    verticalOffset: 14,
                    child: FadeInAnimation(
                      child: _NotificationCard(
                        notification: notif,
                        onTap: () => onTapItem(notif),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _FilterStrip extends StatelessWidget {
  const _FilterStrip({
    required this.selected,
    required this.unreadCount,
    required this.totalCount,
    required this.onChanged,
  });

  final _NotifFilter selected;
  final int unreadCount;
  final int totalCount;
  final ValueChanged<_NotifFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'notifs.filter.all'.tr,
            count: totalCount,
            selected: selected == _NotifFilter.all,
            onTap: () => onChanged(_NotifFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'notifs.filter.unread'.tr,
            count: unreadCount,
            selected: selected == _NotifFilter.unread,
            onTap: () => onChanged(_NotifFilter.unread),
            highlight: true,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'notifs.filter.read'.tr,
            count: totalCount - unreadCount,
            selected: selected == _NotifFilter.read,
            onTap: () => onChanged(_NotifFilter.read),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.highlight = false,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final hasCount = count > 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  )
                : null,
            color: selected ? null : AppColors.surfaceLow,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : AppColors.outlineVariant.withValues(alpha: 0.18),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primaryDark.withValues(alpha: 0.32),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.titleMd.copyWith(
                  color: selected ? AppColors.onPrimary : AppColors.bodyColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              if (hasCount) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.onPrimary.withValues(alpha: 0.22)
                        : (highlight && count > 0
                            ? AppColors.error.withValues(alpha: 0.14)
                            : AppColors.primary.withValues(alpha: 0.12)),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: AppTextStyles.labelSm.copyWith(
                      color: selected
                          ? AppColors.onPrimary
                          : (highlight ? AppColors.error : AppColors.primary),
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Traduit le libellé de catégorie utilisé pour le chip de la carte.
/// Le matching reste sur la string brute (cf. `_categoryPalette`) pour
/// que le palette lookup fonctionne aussi avec des seeds anglais.
String _categoryLabel(String category) {
  final c = category.toLowerCase();
  if (c.contains('profil') || c.contains('profile')) {
    return 'notifs.category.profile'.tr;
  }
  if (c.contains('message')) return 'notifs.category.message'.tr;
  if (c.contains('offre') || c.contains('job') || c.contains('offer')) {
    return 'notifs.category.offer'.tr;
  }
  if (c.contains('formation') || c.contains('course') ||
      c.contains('training')) {
    return 'notifs.category.training'.tr;
  }
  if (c.contains('portfolio')) return 'notifs.category.portfolio'.tr;
  return category;
}

/// Resolve a category palette from the notification's category string.
/// Donne une couleur d'accent + soft pour l'icone et le badge.
({Color color, Color soft, IconData icon}) _categoryPalette(String category) {
  final c = category.toLowerCase();
  if (c.contains('profil')) {
    return (
      color: AppColors.primary,
      soft: AppColors.primary.withValues(alpha: 0.12),
      icon: IconlyBold.profile,
    );
  }
  if (c.contains('message')) {
    return (
      color: AppColors.categoryBlue,
      soft: AppColors.categoryBlue.withValues(alpha: 0.12),
      icon: IconlyBold.chat,
    );
  }
  if (c.contains('offre')) {
    return (
      color: AppColors.categoryPurple,
      soft: AppColors.categoryPurple.withValues(alpha: 0.12),
      icon: IconlyBold.work,
    );
  }
  if (c.contains('formation')) {
    return (
      color: AppColors.categoryOrange,
      soft: AppColors.categoryOrange.withValues(alpha: 0.12),
      icon: IconlyBold.paper,
    );
  }
  if (c.contains('portfolio')) {
    return (
      color: AppColors.categoryCyan,
      soft: AppColors.categoryCyan.withValues(alpha: 0.12),
      icon: IconlyBold.bookmark,
    );
  }
  return (
    color: AppColors.bodyColor,
    soft: AppColors.surfaceLow,
    icon: IconlyBold.notification,
  );
}

class _NotificationCard extends StatefulWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  final HomeNotificationPreview notification;
  final VoidCallback onTap;

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  String _formatTime(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'notifs.time.now'.tr;
    if (diff.inHours < 1) return '${diff.inMinutes} ${'notifs.time.min'.tr}';
    if (diff.inDays < 1) return '${diff.inHours} ${'notifs.time.hour'.tr}';
    if (diff.inDays < 7) return '${diff.inDays} ${'notifs.time.day'.tr}';
    return '${(diff.inDays / 7).floor()} ${'notifs.time.week'.tr}';
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    final unread = !n.isRead;
    final palette = _categoryPalette(n.category);

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            // Toujours surfaceCard : pas de fond colore qui clash avec
            // l'icone categorisee. L'unread est marque par l'accent
            // vertical + le bord teinte + le point a droite.
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: unread
                  ? palette.color.withValues(alpha: 0.28)
                  : AppColors.outlineVariant.withValues(alpha: 0.14),
              width: unread ? 1.2 : 1,
            ),
            boxShadow: unread ? AppColors.ambientShadow : AppColors.lightShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              if (unread)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          palette.color,
                          palette.color.withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(unread ? 18 : 14, 16, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icone : container 48x48 avec degrade doux du palette.
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            palette.color.withValues(alpha: 0.18),
                            palette.color.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                          color: palette.color.withValues(alpha: 0.20),
                        ),
                      ),
                      child: Icon(palette.icon, color: palette.color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  n.title.tr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.titleMd.copyWith(
                                    color: AppColors.titleColor,
                                    fontWeight: unread
                                        ? FontWeight.w800
                                        : FontWeight.w700,
                                    fontSize: 15,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  _formatTime(n.createdAt),
                                  style: AppTextStyles.labelSm.copyWith(
                                    color: unread
                                        ? palette.color
                                        : AppColors.hintColor,
                                    fontSize: 11,
                                    fontWeight: unread
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            n.body.tr,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.bodyColor,
                              height: 1.4,
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              // Chip categorie discret : juste le label en
                              // capitales, plus de pill colore qui ajoute du
                              // bruit. La couleur de l'icone porte deja l'info.
                              Text(
                                _categoryLabel(n.category).toUpperCase(),
                                style: AppTextStyles.labelSm.copyWith(
                                  color: palette.color.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 9.5,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              if (unread) ...[
                                const Spacer(),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: palette.color,
                                    boxShadow: [
                                      BoxShadow(
                                        color: palette.color
                                            .withValues(alpha: 0.4),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
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

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications({required this.filter});
  final _NotifFilter filter;

  @override
  Widget build(BuildContext context) {
    switch (filter) {
      case _NotifFilter.unread:
        return EmptyState(
          icon: IconlyBold.tick_square,
          title: 'notifs.empty_unread'.tr,
          subtitle: 'notifs.empty_unread_sub'.tr,
        );
      case _NotifFilter.read:
        return EmptyState(
          icon: IconlyLight.notification,
          title: 'notifs.empty_read'.tr,
          subtitle: 'notifs.empty_read_sub'.tr,
        );
      case _NotifFilter.all:
        return EmptyState(
          icon: IconlyLight.notification,
          title: 'notifs.empty_all'.tr,
          subtitle: 'notifs.empty_all_sub'.tr,
        );
    }
  }
}
