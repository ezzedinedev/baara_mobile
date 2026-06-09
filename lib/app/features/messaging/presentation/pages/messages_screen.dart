import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_motion.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import 'package:opportune_bf/routes/app_routes.dart';
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
          controller: TextEditingController(),
          hint: 'Rechercher une discussion...',
          onChanged: (v) => controller.searchQuery.value = v,
        ),
        body: Obx(() {
          if (controller.isLoadingConversations.value &&
              controller.conversations.isEmpty) {
            return _buildSkeletons();
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
      icon: IconlyLight.chat,
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
          icon: IconlyLight.search,
          title: 'Aucun résultat',
          subtitle: 'Aucune discussion ne correspond à ta recherche.',
        ),
      );
    }
    final showLoadMore = controller.searchQuery.value.trim().isEmpty &&
        controller.hasMoreConversations.value;
    return RefreshIndicator(
      color: AppColors.primary,
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
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              );
            }
            final conv = items[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: AppMotion.base,
              child: SlideAnimation(
                verticalOffset: AppMotion.listSlideOffset,
                child: FadeInAnimation(
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
        Get.toNamed(AppRoutes.conversation.replaceFirst(':id', conversation.id));
      },
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: null,
        leading: BrandAvatar(
          seed: conversation.id,
          label: conversation.title,
          size: 52,
        ),
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
              style: AppTextStyles.bodySm.copyWith(fontSize: 11),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
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
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    conversation.unreadCount.toString(),
                    style: const TextStyle(
                      fontSize: 10,
                    color: AppColors.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        ),
    );
  }

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
