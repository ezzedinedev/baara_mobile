import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import '../controllers/chatbot_controller.dart';
import '../../domain/entities/chat_message.dart';

class ChatbotScreen extends GetView<ChatbotController> {
  const ChatbotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController inputCtrl = TextEditingController();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assistant IA', style: AppTextStyles.headlineMd.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
            Text('En ligne', style: AppTextStyles.bodySm.copyWith(color: Colors.white70, fontSize: 10)),
          ],
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(IconlyLight.delete, color: Colors.white),
            onPressed: () => _confirmReset(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.isLoadingHistory.value && controller.messages.isEmpty) {
                return const ChatMessagesSkeleton();
              }
              return ListView.builder(
                controller: controller.scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                itemCount: controller.messages.length + (controller.isSending.value ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == controller.messages.length) {
                    return const _TypingIndicator();
                  }
                  final msg = controller.messages[index];
                  return _ChatBubble(message: msg);
                },
              );
            }),
          ),
          _buildInput(inputCtrl),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showConfirmSheet(
      context: context,
      icon: IconlyLight.delete,
      iconColor: AppColors.error,
      title: 'Effacer la discussion ?',
      message: 'Cela supprimera l\'historique local de cette session.',
      confirmLabel: 'Effacer',
      isDestructive: true,
    );
    if (confirmed == true) {
      AppHaptics.confirm();
      controller.resetSession();
    }
  }

  Widget _buildInput(TextEditingController inputCtrl) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: TextField(
                  controller: inputCtrl,
                  style: AppTextStyles.bodyMd,
                  maxLines: 4,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Posez-moi une question...',
                    hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.hintColor),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onSubmitted: (val) {
                    if (val.isNotEmpty) {
                      controller.send(val);
                      inputCtrl.clear();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Obx(() => PressScale(
              onTap: controller.isSending.value ? null : () {
                if (inputCtrl.text.isNotEmpty) {
                  AppHaptics.tap();
                  controller.send(inputCtrl.text);
                  inputCtrl.clear();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: controller.isSending.value ? AppColors.surfaceLow : AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  IconlyBold.send,
                  color: controller.isSending.value ? AppColors.hintColor : Colors.white,
                  size: 20,
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary,
                  child: Icon(IconlyBold.discovery, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Semantics(
                  label: isUser ? 'Votre message' : 'Message de l\'IA',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.primary : AppColors.surfaceLow,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isUser ? 20 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 20),
                      ),
                      boxShadow: [
                        if (isUser)
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.content,
                          style: AppTextStyles.bodyMd.copyWith(
                            color: isUser ? Colors.white : AppColors.titleColor,
                            height: 1.5,
                          ),
                        ),
                        if (message.ctaActions.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ...message.ctaActions.map((cta) => _CtaButton(cta: cta)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              if (isUser) const SizedBox(width: 8),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: 4, left: isUser ? 0 : 40, right: isUser ? 8 : 0),
            child: Text(
              '${message.at.hour}:${message.at.minute.toString().padLeft(2, '0')}',
              style: AppTextStyles.bodySm.copyWith(fontSize: 10, color: AppColors.hintColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  final CtaAction cta;
  const _CtaButton({required this.cta});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: PressScale(
        onTap: () {
          AppHaptics.tap();
          // Handle CTA types (link, route, etc.)
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                cta.label,
                style: AppTextStyles.labelMd.copyWith(color: Colors.white),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16, left: 40),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceLow,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              return FadeTransition(
                opacity: _controller.drive(
                  Tween<double>(begin: 0.3, end: 1.0).chain(
                    CurveTween(curve: Interval(index * 0.2, 0.6 + index * 0.2, curve: Curves.easeInOut)),
                  ),
                ),
                child: Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(color: AppColors.hintColor, shape: BoxShape.circle),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
