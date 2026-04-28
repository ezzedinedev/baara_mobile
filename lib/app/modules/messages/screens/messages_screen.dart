import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme_controller.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../controllers/messages_controller.dart';
import '../models/message_model.dart';

enum _MessagesFilter { all, unread, recruiters }

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final MessagesController controller = Get.find<MessagesController>();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final RxString _query = ''.obs;
  final Rx<_MessagesFilter> _filter = _MessagesFilter.all.obs;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(ConversationModel c) {
    final q = _query.value.trim().toLowerCase();
    final keep = q.isEmpty ||
        c.title.toLowerCase().contains(q) ||
        c.lastMessage.toLowerCase().contains(q);
    if (!keep) return false;

    switch (_filter.value) {
      case _MessagesFilter.all:
        return true;
      case _MessagesFilter.unread:
        return c.unreadCount > 0;
      case _MessagesFilter.recruiters:
        return c.type == 'recruiter';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<AppThemeController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: ScrollToTopFab(controller: _scrollController),
      body: Column(
        children: [
          _MessagesFlatHeader(
            unreadCountListenable: controller.unreadCount,
            themeController: themeController,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: AppSearchBar(
              controller: _searchController,
              hint: 'Rechercher un contact, un message...',
              onChanged: (v) => _query.value = v,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Obx(() => _FilterStrip(
                  selected: _filter.value,
                  unreadCount: controller.unreadCount.value,
                  onChanged: (next) {
                    AppHaptics.tap();
                    _filter.value = next;
                  },
                )),
          ),
          Expanded(
            child: Obx(() {
              final isLoading = controller.isLoadingConversations.value;
              final raw = controller.conversations;
              final errorMessage = controller.errorMessage.value;
              _query.value;
              _filter.value;
              final conversations =
                  raw.where(_matches).toList(growable: false);

              if (isLoading && raw.isEmpty) {
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: 5,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, __) => const MessageTileSkeleton(),
                );
              }

              if (conversations.isEmpty) {
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () =>
                      controller.loadConversations(refresh: true),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.6,
                        child: errorMessage.isNotEmpty
                            ? ErrorStateView(
                                message: errorMessage,
                                onRetry: () =>
                                    controller.loadConversations(refresh: true),
                              )
                            : EmptyState(
                                icon: _filter.value == _MessagesFilter.unread
                                    ? Icons.mark_email_read_outlined
                                    : Icons.chat_bubble_outline_rounded,
                                title: _filter.value == _MessagesFilter.unread
                                    ? 'Tout est lu'
                                    : 'Aucune conversation',
                                subtitle: _filter.value ==
                                        _MessagesFilter.unread
                                    ? 'Vos messages non lus apparaitront ici.'
                                    : 'Vos echanges avec les recruteurs apparaitront ici.',
                              ),
                      ),
                    ],
                  ),
                );
              }

              final sections = _groupByDate(conversations);

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => controller.loadConversations(refresh: true),
                child: AnimationLimiter(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notif) {
                      if (notif.metrics.pixels >=
                              notif.metrics.maxScrollExtent * 0.8 &&
                          !controller.isLoadingConversations.value &&
                          controller.hasMoreConversations.value) {
                        controller.loadMoreConversations();
                      }
                      return false;
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: sections.length,
                      itemBuilder: (context, sectionIndex) {
                        final section = sections[sectionIndex];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 16, 4, 10),
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
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom:
                                      i == section.items.length - 1 ? 0 : 10,
                                ),
                                child: AnimationConfiguration.staggeredList(
                                  position: i,
                                  duration: const Duration(milliseconds: 280),
                                  child: SlideAnimation(
                                    verticalOffset: 14,
                                    child: FadeInAnimation(
                                      child: _ConversationTile(
                                        conversation: section.items[i],
                                        onTap: () {
                                          AppHaptics.tap();
                                          controller.openConversation(
                                              section.items[i]);
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  List<_ConversationSection> _groupByDate(List<ConversationModel> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekStart = today.subtract(const Duration(days: 7));

    final todays = <ConversationModel>[];
    final yesterdays = <ConversationModel>[];
    final thisWeek = <ConversationModel>[];
    final older = <ConversationModel>[];

    for (final c in items) {
      final d = c.lastMessageTime;
      final dDay = DateTime(d.year, d.month, d.day);
      if (!dDay.isBefore(today)) {
        todays.add(c);
      } else if (dDay.isAtSameMomentAs(yesterday)) {
        yesterdays.add(c);
      } else if (dDay.isAfter(weekStart)) {
        thisWeek.add(c);
      } else {
        older.add(c);
      }
    }

    return [
      if (todays.isNotEmpty)
        _ConversationSection('AUJOURD\'HUI', todays),
      if (yesterdays.isNotEmpty)
        _ConversationSection('HIER', yesterdays),
      if (thisWeek.isNotEmpty)
        _ConversationSection('CETTE SEMAINE', thisWeek),
      if (older.isNotEmpty) _ConversationSection('PLUS ANCIEN', older),
    ];
  }
}

class _ConversationSection {
  const _ConversationSection(this.label, this.items);
  final String label;
  final List<ConversationModel> items;
}

/// Header flat inspire des messageries modernes (Messenger / Telegram / etc.) :
/// bandeau de couleur primary uni, coins inferieurs arrondis, icone chat
/// glassmorphism, titre + bouton theme. Pas de wave, pas d'animation.
class _MessagesFlatHeader extends StatelessWidget {
  const _MessagesFlatHeader({
    required this.unreadCountListenable,
    required this.themeController,
  });

  final RxInt unreadCountListenable;
  final AppThemeController themeController;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding + 14, 16, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.32),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Pastille glass avec icone chat.
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.onPrimary.withValues(alpha: 0.20),
              border: Border.all(
                color: AppColors.onPrimary.withValues(alpha: 0.32),
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.chat_bubble_rounded,
              size: 18,
              color: AppColors.onPrimary,
            ),
          ),
          const SizedBox(width: 12),
          // Titre + sous-titre compteur non-lu.
          Expanded(
            child: Obx(() {
              final unread = unreadCountListenable.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Messages',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headlineMd.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    unread > 0
                        ? '$unread non lu${unread > 1 ? 's' : ''}'
                        : 'Tout est a jour',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.onPrimary.withValues(alpha: 0.85),
                      fontSize: 11,
                    ),
                  ),
                ],
              );
            }),
          ),
          // Bouton theme.
          Obx(() {
            final isDark = themeController.isDarkMode.value;
            return InkWell(
              onTap: () async {
                AppHaptics.tap();
                await themeController.toggle();
              },
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.onPrimary.withValues(alpha: 0.20),
                  border: Border.all(
                    color: AppColors.onPrimary.withValues(alpha: 0.32),
                  ),
                ),
                child: Icon(
                  isDark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  size: 18,
                  color: AppColors.onPrimary,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _FilterStrip extends StatelessWidget {
  const _FilterStrip({
    required this.selected,
    required this.unreadCount,
    required this.onChanged,
  });

  final _MessagesFilter selected;
  final int unreadCount;
  final ValueChanged<_MessagesFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'Tous',
            selected: selected == _MessagesFilter.all,
            onTap: () => onChanged(_MessagesFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Non lus',
            count: unreadCount,
            selected: selected == _MessagesFilter.unread,
            onTap: () => onChanged(_MessagesFilter.unread),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Recruteurs',
            selected: selected == _MessagesFilter.recruiters,
            onTap: () => onChanged(_MessagesFilter.recruiters),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
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
                  color:
                      selected ? AppColors.onPrimary : AppColors.bodyColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              if (count != null && count! > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.onPrimary.withValues(alpha: 0.22)
                        : AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    count! > 99 ? '99+' : '$count',
                    style: AppTextStyles.labelSm.copyWith(
                      color: selected
                          ? AppColors.onPrimary
                          : AppColors.primary,
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

class _ConversationTile extends StatefulWidget {
  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  final ConversationModel conversation;
  final VoidCallback onTap;

  @override
  State<_ConversationTile> createState() => _ConversationTileState();
}

class _ConversationTileState extends State<_ConversationTile> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  IconData _typeIcon() {
    switch (widget.conversation.type) {
      case 'recruiter':
        return Icons.work_outline_rounded;
      case 'system':
        return Icons.campaign_outlined;
      default:
        return Icons.business_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.conversation;
    final hasUnread = c.unreadCount > 0;
    final accentEnd = AppColors.avatarGradientForSeed(c.id).last;

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
          padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
          decoration: BoxDecoration(
            color: hasUnread
                ? AppColors.surfaceSelected
                : AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: hasUnread
                  ? AppColors.primary.withValues(alpha: 0.28)
                  : AppColors.outlineVariant.withValues(alpha: 0.16),
            ),
            boxShadow: AppColors.lightShadow,
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accentEnd.withValues(alpha: 0.30),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: BrandAvatar(
                      seed: c.id,
                      label: c.title,
                      size: 54,
                      fontSize: 18,
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.isOnline
                              ? AppColors.successDark
                              : AppColors.surfaceLow,
                        ),
                        alignment: Alignment.center,
                        child: c.isOnline
                            ? null
                            : Icon(
                                _typeIcon(),
                                size: 10,
                                color: AppColors.bodyColor,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.title.isEmpty ? 'Sans titre' : c.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleMd.copyWith(
                              fontWeight: hasUnread
                                  ? FontWeight.w800
                                  : FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          c.timeLabel,
                          style: AppTextStyles.labelSm.copyWith(
                            color: hasUnread
                                ? AppColors.primary
                                : AppColors.hintColor,
                            fontSize: 11,
                            fontWeight: hasUnread
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (c.type == 'recruiter') ...[
                          const _TypePill(
                            label: 'Recruteur',
                            color: AppColors.categoryBlue,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            c.lastMessage.isEmpty
                                ? 'Aucun message pour le moment'
                                : c.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySm.copyWith(
                              color: hasUnread
                                  ? AppColors.titleColor
                                  : AppColors.bodyColor,
                              fontWeight: hasUnread
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              height: 1.3,
                            ),
                          ),
                        ),
                        if (hasUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            constraints: const BoxConstraints(minWidth: 22),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primaryDark
                                ],
                              ),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(999)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              c.unreadCount > 99 ? '99+' : '${c.unreadCount}',
                              style: AppTextStyles.labelSm.copyWith(
                                color: AppColors.onPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
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
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSm.copyWith(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
