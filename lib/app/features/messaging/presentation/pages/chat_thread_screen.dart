import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:intl/intl.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import '../controllers/messages_controller.dart';
import '../../domain/entities/message.dart';

class ChatThreadScreen extends GetView<MessagesController> {
  const ChatThreadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController inputCtrl = TextEditingController();
    final ScrollController scrollController = ScrollController();

    // Re-load messages if navigating directly or switching
    final String? convId = Get.parameters['id'];
    if (convId != null && controller.activeConversationId.value != convId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.loadMessages(convId);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.isLoadingMessages.value && controller.activeMessages.isEmpty) {
                return const ChatMessagesSkeleton();
              }

              if (controller.activeMessages.isEmpty) {
                return _buildEmptyState();
              }

              return _buildMessageList(scrollController);
            }),
          ),
          _buildInputBar(inputCtrl, scrollController),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surfaceCard,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary),
        onPressed: () => Get.back(),
      ),
      title: Obx(() {
        final convId = controller.activeConversationId.value;
        final conv = controller.conversations.firstWhereOrNull((c) => c.id == convId);
        
        return Row(
          children: [
            if (conv != null) ...[
              BrandAvatar(seed: conv.id, label: conv.title, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conv.title,
                      style: AppTextStyles.titleLg.copyWith(fontWeight: FontWeight.w800),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'En ligne',
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ] else
              const Text('Discussion'),
          ],
        );
      }),
      actions: [
        IconButton(
          icon: const Icon(IconlyLight.call, color: AppColors.primary),
          onPressed: () => AppHaptics.tap(),
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.outlineVariant.withValues(alpha: 0.1)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: EmptyState(
        icon: IconlyLight.chat,
        title: 'Aucun message',
        subtitle: 'Envoyez le premier message pour démarrer la discussion.',
      ),
    );
  }

  Widget _buildMessageList(ScrollController scrollController) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: controller.activeMessages.length,
      itemBuilder: (context, index) {
        final msg = controller.activeMessages[index];
        final bool isFirstOfGroup = index == 0 || controller.activeMessages[index - 1].isMine != msg.isMine;
        
        return _MessageBubble(message: msg, showAvatar: !msg.isMine && isFirstOfGroup);
      },
    );
  }

  Widget _buildInputBar(TextEditingController inputCtrl, ScrollController scrollController) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            PressScale(
              onTap: () => AppHaptics.tap(),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.surfaceLow, shape: BoxShape.circle),
                child: Icon(IconlyLight.plus, color: AppColors.bodyColor, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: inputCtrl,
                  style: AppTextStyles.bodyMd,
                  maxLines: 4,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Votre message...',
                    hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.hintColor),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Obx(() => PressScale(
              onTap: controller.isSending.value ? null : () async {
                if (inputCtrl.text.trim().isNotEmpty) {
                  final text = inputCtrl.text;
                  inputCtrl.clear();
                  AppHaptics.success();
                  await controller.sendMessage(text);
                  _scrollToBottom(scrollController);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: controller.isSending.value ? AppColors.surfaceLow : AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: controller.isSending.value
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.hintColor,
                      ),
                    )
                  : const Icon(IconlyBold.send, color: Colors.white, size: 18),
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _scrollToBottom(ScrollController scrollController) {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool showAvatar;

  const _MessageBubble({required this.message, required this.showAvatar});

  @override
  Widget build(BuildContext context) {
    final bool isMine = message.isMine;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            if (showAvatar)
              BrandAvatar(seed: message.id, label: message.senderName, size: 28)
            else
              const SizedBox(width: 28),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMine ? AppColors.primary : AppColors.surfaceLow,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(!isMine ? 4 : 18),
                  bottomRight: Radius.circular(isMine ? 4 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.text,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: isMine ? Colors.white : AppColors.titleColor,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(message.sentAt),
                    style: AppTextStyles.bodySm.copyWith(
                      fontSize: 9,
                      color: isMine ? Colors.white70 : AppColors.hintColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMine) const SizedBox(width: 4),
        ],
      ),
    );
  }
}
