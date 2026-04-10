import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../../widgets/gradient_button.dart';
import '../../../widgets/opportune_logo.dart';
import 'home_controller.dart';
import 'home_profile_tab.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Obx(
              () => IndexedStack(
                index: controller.currentTabIndex.value,
                children: [
                  _AccueilTab(controller: controller),
                  _MessagerieTab(controller: controller),
                  _OffresTab(controller: controller),
                  _FormationsTab(controller: controller),
                  HomeProfileTab(controller: controller),
                ],
              ),
            ),
            _OfferMatchOverlay(controller: controller),
            _MessagingOverlay(controller: controller),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
          child: Obx(
            () => _HomeBottomNav(
              items: controller.navItems,
              currentIndex: controller.currentTabIndex.value,
              onTap: controller.changeTab,
            ),
          ),
        ),
      ),
    );
  }
}

class _AccueilTab extends StatelessWidget {
  const _AccueilTab({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 130),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const OpportuneLogo(iconSize: 16, fontSize: 18),
                const Spacer(),
                _NotificationBell(controller: controller),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'Bonjour, bienvenue',
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.bodyColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Trouvez votre prochaine opportunite',
              style: AppTextStyles.headlineLg.copyWith(
                fontSize: 28,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 12),
            _SectionHeader(
              title: 'Swipe des offres',
              actionLabel: 'Liste',
              onAction: () => controller.changeTab(2),
            ),
            const SizedBox(height: 14),
            _OfferTinderDeck(
              controller: controller,
              height: 432,
              showActions: true,
              compact: false,
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'Formations publiees',
              actionLabel: 'Tout voir',
              onAction: () => controller.changeTab(3),
            ),
            const SizedBox(height: 14),
            if (controller.isLoadingFormations.value &&
                controller.formations.isEmpty)
              const SizedBox(
                height: 220,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (controller.formations.isEmpty)
              SizedBox(
                height: 220,
                child: _ContentStatusCard(
                  message: controller.formationsLoadError.value.isNotEmpty
                      ? controller.formationsLoadError.value
                      : 'Aucune formation publiee pour le moment.',
                  onRetry: () => controller.reloadFormations(),
                ),
              )
            else
              SizedBox(
                height: 284,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.formations.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final formation = controller.formations[index];
                    return SizedBox(
                      width: 292,
                      child: _FormationDarkCard(
                        formation: formation,
                        compact: true,
                        onTap: () => _showFormationDetails(
                          context,
                          formation,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final unreadCount = controller.unreadNotificationsCount;
      return InkWell(
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.surfaceCard,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (_) => _NotificationsSheet(controller: controller),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppColors.lightShadow,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 20,
                color: AppColors.titleColor,
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                right: -4,
                top: -5,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 18),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 3,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.onPrimary,
                      fontSize: 9,
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

class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          14,
          18,
          18 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Obx(
          () => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Notifications',
                      style: AppTextStyles.headlineMd.copyWith(fontSize: 22),
                    ),
                  ),
                  TextButton(
                    onPressed: controller.notifications.isEmpty
                        ? null
                        : controller.markAllNotificationsAsRead,
                    child: const Text('Tout lire'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (controller.notifications.isEmpty)
                const _ContentStatusCard(
                  message: 'Aucune notification pour le moment.',
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: controller.notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final notification = controller.notifications[index];
                      return _NotificationTile(
                        notification: notification,
                        onTap: () => controller.markNotificationAsRead(
                          notification.id,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  final HomeNotificationPreview notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: notification.isRead
              ? AppColors.surfaceLow
              : const Color(0xFFE7FFF4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead
                ? AppColors.outlineVariant.withValues(alpha: 0.16)
                : AppColors.primary.withValues(alpha: 0.24),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(notification.icon, color: AppColors.primary),
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
                          notification.title,
                          style: AppTextStyles.titleMd.copyWith(
                            color: AppColors.titleColor,
                          ),
                        ),
                      ),
                      Text(
                        _formatNotificationTime(notification.createdAt),
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.hintColor,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: AppTextStyles.bodySm.copyWith(height: 1.35),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notification.category,
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.primary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNotificationTime(DateTime createdAt) {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inMinutes < 1) {
      return 'Maintenant';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes} min';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours} h';
    }
    return '${difference.inDays} j';
  }
}

class _OffresTab extends StatelessWidget {
  const _OffresTab({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 130),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Offres disponibles',
              style: AppTextStyles.headlineMd.copyWith(
                fontSize: 24,
                color: AppColors.titleColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Consultez ici toutes les offres publiees, organisees en cartes.',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.bodyColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Cartes d\'offres',
              style: AppTextStyles.headlineMd.copyWith(
                fontSize: 21,
                color: AppColors.titleColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Faites defiler pour parcourir chaque opportunite en detail.',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.bodyColor,
              ),
            ),
            const SizedBox(height: 12),
            if (controller.isLoadingOffers.value && controller.offers.isEmpty)
              const SizedBox(
                height: 240,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
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
                    ),
                  ),
                );
              }),
          ],
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

class _MessagerieTab extends StatelessWidget {
  const _MessagerieTab({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 130),
      itemCount: controller.conversations.length + 2,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          return const _MessagingHeroCard();
        }

        if (index == 1) {
          return Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 2),
            child: Text(
              'Conversations',
              style: AppTextStyles.headlineMd.copyWith(
                fontSize: 22,
                color: AppColors.titleColor,
              ),
            ),
          );
        }

        final conversation = controller.conversations[index - 2];
        return _ConversationTile(
          controller: controller,
          conversation: conversation,
        );
      },
    );
  }
}

class _MessagingHeroCard extends StatelessWidget {
  const _MessagingHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.lightShadow,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  color: AppColors.onPrimary,
                  size: 38,
                ),
              ),
              Positioned(
                right: -6,
                bottom: -4,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Icon(
                    Icons.more_horiz_rounded,
                    color: AppColors.primary,
                    size: 21,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Messagerie OpporTune',
                  style: AppTextStyles.headlineSm.copyWith(
                    color: AppColors.titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Discutez avec les recruteurs et suivez vos candidatures en direct.',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.bodyColor,
                    height: 1.45,
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

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.controller,
    required this.conversation,
  });

  final HomeController controller;
  final HomeConversationPreview conversation;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => controller.openConversation(conversation),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 11),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceIconSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.mode_comment_rounded,
                    size: 22,
                    color: AppColors.primary,
                  ),
                ),
                if (conversation.online)
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.surfaceCard,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.title,
                    style: AppTextStyles.titleMd.copyWith(
                      color: AppColors.titleColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    conversation.preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.bodyColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  conversation.timeLabel,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.hintColor,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 6),
                Obx(() {
                  final unreadCount = controller.unreadFor(conversation.id);
                  if (unreadCount <= 0) {
                    return const SizedBox(height: 18);
                  }

                  return Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                    ),
                    child: Text(
                      '$unreadCount',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.onPrimary,
                        fontSize: 9,
                        letterSpacing: 0.5,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MessagingOverlay extends StatelessWidget {
  const _MessagingOverlay({required this.controller});

  final HomeController controller;

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final conversation = controller.activeConversation;
      if (conversation == null) {
        return const SizedBox.shrink();
      }

      final thread = controller.threadFor(conversation.id);
      return Positioned.fill(
        child: Container(
          color: AppColors.onDark.withValues(alpha: 0.22),
          child: SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: AppColors.ambientShadow,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLow,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.outlineVariant.withValues(
                              alpha: 0.20,
                            ),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: controller.closeConversation,
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: AppColors.titleColor,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  conversation.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.titleLg.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  conversation.online
                                      ? 'En ligne'
                                      : 'Hors ligne',
                                  style: AppTextStyles.bodySm.copyWith(
                                    color: AppColors.bodyColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Obx(
                        () => ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                          itemCount: thread.length,
                          itemBuilder: (context, index) {
                            final message = thread[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Align(
                                alignment: message.isMine
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  constraints: const BoxConstraints(
                                    maxWidth: 280,
                                  ),
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    10,
                                    12,
                                    8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: message.isMine
                                        ? AppColors.surfaceIconSoft
                                        : AppColors.surfaceLow,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppColors.outlineVariant
                                          .withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        message.text,
                                        style: AppTextStyles.bodyMd.copyWith(
                                          color: AppColors.titleColor,
                                          height: 1.45,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatTime(message.sentAt),
                                        style: AppTextStyles.bodySm.copyWith(
                                          color: AppColors.hintColor,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller.chatInputCtrl,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) =>
                                  controller.sendActiveMessage(),
                              decoration: InputDecoration(
                                hintText: 'Ecrire un message...',
                                hintStyle: AppTextStyles.bodyMd.copyWith(
                                  color: AppColors.hintColor,
                                ),
                                filled: true,
                                fillColor: AppColors.inputFill,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 1.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Obx(() {
                            return SizedBox(
                              width: 48,
                              height: 48,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: controller.isSendingChat.value
                                      ? null
                                      : controller.sendActiveMessage,
                                  borderRadius: BorderRadius.circular(14),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      gradient: AppColors.primaryGradient,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: controller.isSendingChat.value
                                        ? const Center(
                                            child: SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation(
                                                  AppColors.onPrimary,
                                                ),
                                              ),
                                            ),
                                          )
                                        : const Icon(
                                            Icons.send_rounded,
                                            color: AppColors.onPrimary,
                                            size: 22,
                                          ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
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
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      }

      if (controller.formations.isEmpty) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
          child: _ContentStatusCard(
            message: controller.formationsLoadError.value.isNotEmpty
                ? controller.formationsLoadError.value
                : 'Aucune formation publiee pour le moment.',
            onRetry: () => controller.reloadFormations(),
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
        itemCount: controller.formations.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Text(
              '${controller.formations.length} FORMATIONS PUBLIEES',
              style: AppTextStyles.labelLg.copyWith(
                color: AppColors.bodyColor,
                fontSize: 11,
                letterSpacing: 1.3,
              ),
            );
          }

          final formation = controller.formations[index - 1];
          return _FormationDarkCard(
            formation: formation,
            onTap: () => _showFormationDetails(context, formation),
          );
        },
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
          onTap: onAction,
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
                borderRadius: BorderRadius.circular(20),
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
                    decoration: const BoxDecoration(
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
                              borderRadius: BorderRadius.circular(12),
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
                    borderRadius: BorderRadius.circular(999),
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
                        borderRadius: BorderRadius.circular(999),
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
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
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

class _OfferMetaChip extends StatelessWidget {
  const _OfferMetaChip({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceIconSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppColors.primaryDark,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
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
  });

  final HomeOfferPreview offer;
  final int matchScore;
  final bool compact;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        gradient: muted
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryDark, AppColors.onDark],
              )
            : AppColors.landingHeroGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: muted ? [] : AppColors.ambientShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 10,
                  vertical: compact ? 3 : 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  offer.contractType,
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.onPrimary,
                    fontSize: compact ? 9 : 10,
                    letterSpacing: compact ? 0.5 : 0.7,
                  ),
                ),
              ),
              const Spacer(),
              _OfferScoreChip(score: matchScore),
            ],
          ),
          SizedBox(height: compact ? 6 : 8),
          if (!compact) ...[
            Text(
              'Compatibilite profil: $matchScore%',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.surfaceCard.withValues(alpha: 0.88),
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 6),
            if (offer.requiredSkills.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: offer.requiredSkills.take(3).map((skill) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      skill,
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.surfaceCard,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  );
                }).toList(),
              )
            else
              Text(
                'Competences non precisees',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.surfaceCard.withValues(alpha: 0.85),
                  fontSize: 11,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Experience requise: ${offer.experienceLabel}',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.surfaceCard.withValues(alpha: 0.85),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (compact)
            Text(
              '$matchScore% de compatibilite',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.surfaceCard.withValues(alpha: 0.88),
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          if (compact) const SizedBox(height: 6),
          Text(
            offer.title,
            style: AppTextStyles.headlineLg.copyWith(
              color: AppColors.onPrimary,
              fontSize: compact ? 22 : 26,
              height: 1.1,
            ),
            maxLines: compact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: compact ? 4 : 7),
          Text(
            offer.company,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.surfaceCard.withValues(alpha: 0.92),
              fontSize: compact ? 13 : 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: compact ? 1 : 2),
          Text(
            offer.location,
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.surfaceCard.withValues(alpha: 0.82),
              fontSize: compact ? 11 : 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  offer.salary,
                  style: AppTextStyles.titleMd.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 12 : 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: compact ? 8 : 10),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 10 : 12,
                  vertical: compact ? 7 : 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Postuler',
                  style: AppTextStyles.titleMd.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 12 : 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OfferScoreChip extends StatelessWidget {
  const _OfferScoreChip({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final isStrong = score >= 75;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isStrong
            ? AppColors.primaryLight.withValues(alpha: 0.26)
            : AppColors.surfaceCard.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isStrong ? AppColors.primaryLight : AppColors.surfaceHighest,
        ),
      ),
      child: Text(
        '$score%',
        style: AppTextStyles.labelMd.copyWith(
          color: AppColors.surfaceCard,
          letterSpacing: 0.4,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _OfferDeckIndicators extends StatelessWidget {
  const _OfferDeckIndicators({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(controller.offers.length, (index) {
        final isActive = controller.currentOfferIndex.value == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 6,
          width: isActive ? 24 : 7,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.surfaceHighest,
            borderRadius: BorderRadius.circular(999),
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
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          shape: BoxShape.circle,
          boxShadow: AppColors.lightShadow,
          border: Border.all(
            color: color.withValues(alpha: 0.24),
          ),
        ),
        child: Icon(
          icon,
          color: color,
          size: iconSize,
        ),
      ),
    );
  }
}

class _OfferSwipeBadge extends StatelessWidget {
  const _OfferSwipeBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMd.copyWith(
          color: AppColors.surfaceCard,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          fontSize: 10,
        ),
      ),
    );
  }
}

void _showFormationDetails(
  BuildContext context,
  HomeFormationPreview formation,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _FormationDetailsSheet(formation: formation),
  );
}

class _FormationDetailsSheet extends StatelessWidget {
  const _FormationDetailsSheet({required this.formation});

  final HomeFormationPreview formation;

  @override
  Widget build(BuildContext context) {
    final objectives = formation.objectives.isEmpty
        ? const ['Objectifs non precises.']
        : formation.objectives;
    final requirements = formation.requirements.isEmpty
        ? const ['Prerequis non precises.']
        : formation.requirements;

    return FractionallySizedBox(
      heightFactor: 0.92,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
          children: [
            Center(
              child: Container(
                width: 46,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7FFF4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formation.title,
                        style: AppTextStyles.headlineMd.copyWith(
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formation.providerName,
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.bodyColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FormationBadge(
                  text: formation.status,
                  background: const Color(0xFFE7FFF4),
                  textColor: AppColors.primary,
                ),
                _FormationBadge(
                  text: formation.level,
                  background: const Color(0xFFE8F1FF),
                  textColor: const Color(0xFF2B7FFF),
                ),
                _FormationBadge(
                  text: formation.formatLabel,
                  background: const Color(0xFFFFF4DE),
                  textColor: const Color(0xFFB45309),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _FormationDetailTile(
                  icon: Icons.location_on_outlined,
                  color: const Color(0xFF2B7FFF),
                  title: 'Lieu',
                  value: formation.location,
                ),
                _FormationDetailTile(
                  icon: Icons.access_time_rounded,
                  color: const Color(0xFFEB4D8A),
                  title: 'Duree',
                  value: formation.durationLabel,
                ),
                _FormationDetailTile(
                  icon: Icons.calendar_month_outlined,
                  color: const Color(0xFF7A5CFA),
                  title: 'Debut',
                  value: formation.startDateLabel,
                ),
                _FormationDetailTile(
                  icon: Icons.event_busy_outlined,
                  color: const Color(0xFFB45309),
                  title: 'Limite',
                  value: formation.deadlineLabel,
                ),
                _FormationDetailTile(
                  icon: Icons.payments_outlined,
                  color: const Color(0xFFFF9D00),
                  title: 'Prix',
                  value: formation.priceLabel,
                ),
                _FormationDetailTile(
                  icon: Icons.menu_book_rounded,
                  color: const Color(0xFF0CA6A6),
                  title: 'Modules',
                  value: '${formation.lessons} module(s)',
                ),
                _FormationDetailTile(
                  icon: Icons.verified_outlined,
                  color: const Color(0xFF00A86B),
                  title: 'Certificat',
                  value: formation.certificationLabel,
                ),
                _FormationDetailTile(
                  icon: Icons.language_rounded,
                  color: const Color(0xFF374151),
                  title: 'Langue',
                  value: formation.languageLabel,
                ),
                _FormationDetailTile(
                  icon: Icons.groups_rounded,
                  color: const Color(0xFF45A735),
                  title: 'Inscrits',
                  value: '${formation.enrolledCount}',
                ),
                _FormationDetailTile(
                  icon: Icons.star_rounded,
                  color: AppColors.warning,
                  title: 'Note',
                  value: formation.rating.toStringAsFixed(1),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _FormationDetailSection(
              title: 'Description',
              icon: Icons.notes_rounded,
              color: const Color(0xFF2B7FFF),
              child: Text(
                formation.description,
                style: AppTextStyles.bodyMd.copyWith(height: 1.45),
              ),
            ),
            const SizedBox(height: 12),
            _FormationBulletSection(
              title: 'Objectifs',
              icon: Icons.flag_outlined,
              color: const Color(0xFF00A86B),
              items: objectives,
            ),
            const SizedBox(height: 12),
            _FormationBulletSection(
              title: 'Prerequis',
              icon: Icons.rule_rounded,
              color: const Color(0xFF7A5CFA),
              items: requirements,
            ),
            const SizedBox(height: 12),
            _FormationDetailSection(
              title: 'Contact',
              icon: Icons.support_agent_rounded,
              color: const Color(0xFFEB4D8A),
              child: Text(
                formation.contactLabel,
                style: AppTextStyles.bodyMd.copyWith(height: 1.45),
              ),
            ),
            const SizedBox(height: 18),
            GradientButton(
              label: 'JE SUIS INTERESSE',
              onPressed: () {
                Navigator.of(context).pop();
                Get.snackbar(
                  'Formation',
                  'Votre interet pour cette formation est note.',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              textColor: AppColors.onPrimary,
              height: 52,
              borderRadius: 14,
            ),
          ],
        ),
      ),
    );
  }
}

class _FormationDetailTile extends StatelessWidget {
  const _FormationDetailTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.hintColor,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleMd.copyWith(
                color: AppColors.titleColor,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormationDetailSection extends StatelessWidget {
  const _FormationDetailSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.titleMd),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _FormationBulletSection extends StatelessWidget {
  const _FormationBulletSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return _FormationDetailSection(
      title: title,
      icon: icon,
      color: color,
      child: Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: color,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: AppTextStyles.bodyMd.copyWith(height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _FormationDarkCard extends StatelessWidget {
  const _FormationDarkCard({
    required this.formation,
    this.compact = false,
    this.onTap,
  });

  final HomeFormationPreview formation;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const textPrimary = AppColors.surfaceCard;
    final textSecondary = AppColors.surfaceCard.withValues(alpha: 0.72);
    final textMeta = AppColors.surfaceCard.withValues(alpha: 0.62);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: EdgeInsets.all(compact ? 10 : 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryDark, AppColors.onDark],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryLight.withValues(alpha: 0.14),
          ),
          boxShadow: AppColors.lightShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FormationMedia(formation: formation, compact: compact),
            SizedBox(height: compact ? 10 : 12),
            Text(
              formation.title,
              style: AppTextStyles.titleLg.copyWith(
                color: textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: compact ? 15 : 17,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              formation.providerName,
              style: AppTextStyles.bodySm.copyWith(
                color: textSecondary,
                fontSize: compact ? 11 : 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '${formation.sector} • ${formation.location}',
              style: AppTextStyles.bodySm.copyWith(
                color: textMeta,
                fontSize: compact ? 10 : 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: compact ? 8 : 10),
            Row(
              children: [
                const Icon(
                  Icons.cast_for_education_rounded,
                  size: 14,
                  color: Color(0xFF78EB54),
                ),
                const SizedBox(width: 4),
                Text(
                  formation.formatLabel,
                  style: AppTextStyles.bodySm.copyWith(
                    color: textMeta,
                    fontSize: compact ? 10 : 11,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.menu_book_rounded,
                  size: 14,
                  color: Color(0xFF5AD7FF),
                ),
                const SizedBox(width: 4),
                Text(
                  '${formation.lessons} modules',
                  style: AppTextStyles.bodySm.copyWith(
                    color: textMeta,
                    fontSize: compact ? 10 : 11,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 3),
                Text(
                  formation.rating.toStringAsFixed(1),
                  style: AppTextStyles.bodySm.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: compact ? 10 : 11,
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 10 : 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FormationInfoChip(
                  icon: Icons.payments_outlined,
                  color: const Color(0xFFFFC857),
                  text: formation.priceLabel,
                ),
                _FormationInfoChip(
                  icon: Icons.groups_rounded,
                  color: const Color(0xFF78EB54),
                  text: '${formation.enrolledCount} inscrits',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FormationMedia extends StatelessWidget {
  const _FormationMedia({
    required this.formation,
    required this.compact,
  });

  final HomeFormationPreview formation;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 94 : 122,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.onDark, AppColors.primaryDark],
        ),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.24),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _ChartPatternPainter(),
            ),
          ),
          Positioned(
            left: 8,
            top: 8,
            child: _FormationBadge(
              text: formation.level,
              background: AppColors.surfaceIconSoft.withValues(alpha: 0.95),
              textColor: AppColors.primaryDark,
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: _FormationBadge(
              text: formation.status,
              background: AppColors.primary,
              textColor: AppColors.onPrimary,
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: compact ? 34 : 40,
              height: compact ? 34 : 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceCard.withValues(alpha: 0.30),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.surfaceCard.withValues(alpha: 0.46),
                ),
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                size: compact ? 18 : 22,
                color: AppColors.surfaceCard,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormationBadge extends StatelessWidget {
  const _FormationBadge({
    required this.text,
    required this.background,
    required this.textColor,
  });

  final String text;
  final Color background;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodySm.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 9,
        ),
      ),
    );
  }
}

class _FormationInfoChip extends StatelessWidget {
  const _FormationInfoChip({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.surfaceCard.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.surfaceCard,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.surfaceCard.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (double x = 0; x <= size.width; x += size.width / 6) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }

    for (double y = 0; y <= size.height; y += size.height / 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final curve = Paint()
      ..color = AppColors.primaryLight.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height * 0.66)
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height * 0.38,
        size.width * 0.36,
        size.height * 0.56,
      )
      ..quadraticBezierTo(
        size.width * 0.54,
        size.height * 0.74,
        size.width * 0.72,
        size.height * 0.50,
      )
      ..quadraticBezierTo(
        size.width * 0.84,
        size.height * 0.34,
        size.width,
        size.height * 0.58,
      );
    canvas.drawPath(path, curve);

    final candle = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.70)
      ..strokeWidth = 2;
    for (double i = 0; i < 7; i++) {
      final dx = (size.width / 7) * i + 6;
      final top = size.height * (0.22 + (i % 3) * 0.12);
      final bottom = size.height * (0.74 - (i % 2) * 0.10);
      canvas.drawLine(Offset(dx, top), Offset(dx, bottom), candle);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HomeBottomNav extends StatelessWidget {
  const _HomeBottomNav({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<HomeNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.26),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemCount = items.length;
          final slotWidth = constraints.maxWidth / itemCount;
          final selectedItem = items[currentIndex];
          const indicatorHeight = 42.0;
          final indicatorWidth = (slotWidth + 18).clamp(84.0, 106.0).toDouble();
          final rawLeft =
              (slotWidth * currentIndex) + ((slotWidth - indicatorWidth) / 2);
          final indicatorLeft =
              rawLeft.clamp(0.0, constraints.maxWidth - indicatorWidth);

          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                left: indicatorLeft,
                top: (constraints.maxHeight - indicatorHeight) / 2,
                width: indicatorWidth,
                height: indicatorHeight,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            selectedItem.icon,
                            size: 13,
                            color: AppColors.surfaceCard,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            selectedItem.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleMd.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: List.generate(itemCount, (index) {
                  final selected = index == currentIndex;
                  return Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () => onTap(index),
                        child: Center(
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 180),
                            opacity: selected ? 0 : 1,
                            child: Icon(
                              items[index].icon,
                              size: 20,
                              color: AppColors.surfaceCard.withValues(
                                alpha: 0.82,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}
