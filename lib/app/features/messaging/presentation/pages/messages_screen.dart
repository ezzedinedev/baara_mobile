import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';

import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_dimens.dart';
import 'package:baara/app/core/theme/app_motion.dart';
import 'package:baara/app/core/theme/app_shapes.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/app/core/widgets/widgets.dart';
import 'package:baara/routes/app_routes.dart';
import '../controllers/messages_controller.dart';
import '../../domain/entities/conversation.dart';

class MessagesScreen extends GetView<MessagesController> {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SankTabShell(
        title: 'Messages',
        subtitle: 'Vos discussions avec les recruteurs.',
        headerChild: AppSearchBar(
          controller: controller.searchCtrl,
          hint: 'Rechercher une discussion...',
          onChanged: (v) => controller.searchQuery.value = v,
        ),
        body: Obx(() {
          if (controller.isLoadingConversations.value &&
              controller.conversations.isEmpty &&
              controller.conversationsError.value.isEmpty) {
            return _buildSkeletons();
          }

          if (controller.conversationsError.value.isNotEmpty &&
              controller.conversations.isEmpty) {
            return ErrorStateView(
              message: controller.conversationsError.value,
              onRetry: () => controller.loadConversations(),
            );
          }

          if (controller.conversations.isEmpty &&
              !controller.isLoadingConversations.value) {
            return _buildEmptyState();
          }

          return _buildList();
        }),
      ),
    );
  }

  Widget _buildSkeletons() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const MessageTileSkeleton(),
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      illustration: const EmptyInboxIllustration(),
      title: 'Aucun message',
      subtitle: 'Commencez à discuter avec des recruteurs.',
      onAction: () => controller.loadConversations(),
    );
  }

  Widget _buildList() {
    final items = controller.filteredConversations;
    if (items.isEmpty) {
      return const Center(
        child: EmptyState(
          illustration: NoResultsIllustration(),
          title: 'Aucun résultat',
          subtitle: 'Aucune discussion ne correspond à ta recherche.',
        ),
      );
    }
    final showLoadMore = controller.searchQuery.value.trim().isEmpty &&
        controller.hasMoreConversations.value;
    return AppRefreshIndicator(
      color: AppColors.primaryAccent,
      onRefresh: () => controller.loadConversations(),
      child: AnimationLimiter(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: items.length + (showLoadMore ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            if (index >= items.length) {
              controller.loadMoreConversations();
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
            final conv = items[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: AppMotion.medium,
              child: SlideAnimation(
                verticalOffset: AppMotion.listSlideOffset,
                curve: AppMotion.emphasizedDecelerate,
                child: FadeInAnimation(
                  curve: AppMotion.emphasizedDecelerate,
                  child: _ConversationTile(conversation: conv),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  const _ConversationTile({required this.conversation});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () {
        AppHaptics.tap();
        Get.toNamed(
            AppRoutes.conversation.replaceFirst(':id', conversation.id));
      },
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
            borderRadius: AppShapes.squircleRadius(AppRadius.md)),
        // Le poste ajoute une 3e ligne : sans ça le ListTile centre son contenu
        // sur deux lignes et le sous-titre déborde.
        isThreeLine: conversation.offerTitle != null,
        onTap: null,
        leading: _AvatarWithPresence(conversation: conversation),
        title: Row(
          children: [
            Expanded(
              child: Text(
                conversation.title,
                style: AppTextStyles.titleLg.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              _formatDate(conversation.lastMessageTime),
              style: AppTextStyles.bodySm.copyWith(
                fontSize: 11,
                color: conversation.unreadCount > 0
                    ? AppColors.primaryAccent
                    : AppColors.hintColor,
                fontWeight: conversation.unreadCount > 0
                    ? FontWeight.w700
                    : FontWeight.w400,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Poste concerné : seul élément qui distingue deux conversations
              // avec le même employeur (une par candidature). Absent sur les DM
              // directs et les conversations sans candidature liée.
              if (conversation.offerTitle != null) ...[
                Text(
                  conversation.offerTitle!,
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      conversation.lastMessage,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: conversation.unreadCount > 0
                            ? AppColors.titleColor
                            : AppColors.bodyColor,
                        fontWeight: conversation.unreadCount > 0
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (conversation.unreadCount > 0)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      constraints: const BoxConstraints(minWidth: 20),
                      height: 20,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        conversation.unreadCount > 99
                            ? '99+'
                            : conversation.unreadCount.toString(),
                        style: AppTextStyles.labelSm.copyWith(
                          fontSize: 11,
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // (helper de date conservé ci-dessous)

  /// Aujourd'hui -> "HH:mm" ; sinon -> "JJ/MM".
  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final now = DateTime.now();
    final isToday = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    if (isToday) {
      final hh = local.hour.toString().padLeft(2, '0');
      final mm = local.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }
    final dd = local.day.toString().padLeft(2, '0');
    final mo = local.month.toString().padLeft(2, '0');
    return '$dd/$mo';
  }
}

/// Avatar de l'interlocuteur avec pastille de présence en ligne (en bas-droite).
class _AvatarWithPresence extends StatelessWidget {
  final Conversation conversation;
  const _AvatarWithPresence({required this.conversation});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          BrandAvatar(
            seed: conversation.id,
            label: conversation.title,
            size: 52,
          ),
          if (conversation.isOnline)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  shape: BoxShape.circle,
                ),
                child: PulsingDot(
                  color: AppColors.successAccent,
                  size: 10,
                  haloSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
