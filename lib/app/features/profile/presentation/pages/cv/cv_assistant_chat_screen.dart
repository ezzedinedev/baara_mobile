import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import 'package:jobaway/app/core/theme/app_colors.dart';
import 'package:jobaway/app/core/theme/app_dimens.dart';
import 'package:jobaway/app/core/theme/app_motion.dart';
import 'package:jobaway/app/core/theme/app_shapes.dart';
import 'package:jobaway/app/core/theme/app_text_styles.dart';
import 'package:jobaway/app/core/utils/haptics.dart';
import 'package:jobaway/app/core/widgets/widgets.dart';

import '../../../../ia/domain/entities/chat_message.dart';
import '../../controllers/cv_assistant_controller.dart';

/// Chat assistant CV — l'utilisateur décrit son parcours en langage naturel
/// et l'IA rédige/améliore le CV. Style aligné sur la charte (header dégradé,
/// bulles arrondies, micro-interactions discrètes).
class CvAssistantChatScreen extends GetView<CvAssistantController> {
  const CvAssistantChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inputCtrl = TextEditingController();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _Header(),
          Expanded(
            child: Obx(() {
              final hasOnlyWelcome = controller.messages.length <= 1;
              return ListView.builder(
                controller: controller.scrollController,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: 24),
                itemCount: controller.messages.length +
                    (controller.isSending.value ? 1 : 0) +
                    (hasOnlyWelcome ? 1 : 0),
                itemBuilder: (context, index) {
                  // Bulles existantes
                  if (index < controller.messages.length) {
                    return _ChatBubble(message: controller.messages[index]);
                  }
                  // Indicateur de frappe
                  if (controller.isSending.value &&
                      index == controller.messages.length) {
                    return const _TypingIndicator();
                  }
                  // Chips de suggestion (uniquement au démarrage)
                  return _StarterPrompts(
                    onTap: (p) {
                      AppHaptics.tap();
                      controller.send(p);
                    },
                  );
                },
              );
            }),
          ),
          _InputBar(inputCtrl: inputCtrl),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: AppColors.headerBrandGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(IconlyLight.arrow_left_2,
                    color: AppColors.onPrimary),
                onPressed: () {
                  AppHaptics.tap();
                  Get.back();
                },
              ),
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.onPrimary.withValues(alpha: 0.2),
                child:
                    const Icon(IconlyBold.document, color: AppColors.onPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assistant CV',
                      style: AppTextStyles.headlineMd.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Rédige et améliore votre CV',
                      style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.onPrimary.withValues(alpha: 0.7),
                          fontSize: 11),
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

class _StarterPrompts extends StatelessWidget {
  const _StarterPrompts({required this.onTap});
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 40, top: 4),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: CvAssistantController.starterPrompts.map((p) {
          return PressScale(
            onTap: () => onTap(p),
            curve: AppMotion.spring,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surfaceSelected,
                borderRadius: AppShapes.squircleRadius(AppRadius.md),
                border: Border.all(color: AppColors.primaryLight),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Text(
                  p,
                  style: AppTextStyles.labelMd
                      .copyWith(color: AppColors.primaryAccent),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final bubbleColor = message.isError
        ? AppColors.errorSoft
        : (isUser ? AppColors.primary : AppColors.surfaceLow);
    final textColor = message.isError
        ? AppColors.errorStrong
        : (isUser ? AppColors.onPrimary : AppColors.titleColor);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary,
                  child: Icon(IconlyBold.document,
                      size: 16, color: AppColors.onPrimary),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    // Rayons asymétriques de bulle de chat : cas légitime,
                    // forme spécifique au contexte conversationnel.
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
                  child: Text(
                    message.content,
                    style: AppTextStyles.bodyMd
                        .copyWith(color: textColor, height: 1.5),
                  ),
                ),
              ),
              if (isUser) const SizedBox(width: AppSpacing.sm),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
                top: AppSpacing.xs,
                left: isUser ? 0 : 40,
                right: isUser ? AppSpacing.sm : 0),
            child: Text(
              '${message.at.hour}:${message.at.minute.toString().padLeft(2, '0')}',
              style: AppTextStyles.bodySm
                  .copyWith(fontSize: 10, color: AppColors.hintColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({required this.inputCtrl});
  final TextEditingController inputCtrl;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CvAssistantController>();

    void submit() {
      final text = inputCtrl.text;
      if (text.trim().isEmpty) return;
      AppHaptics.tap();
      controller.send(text);
      inputCtrl.clear();
    }

    // La barre d'input est de la « chrome » (fixe en bas de l'écran).
    // Le Scaffold racine fournit l'ancêtre Material requis par le TextField.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        boxShadow: AppColors.lightShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 24),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLow,
                    borderRadius: AppShapes.squircleRadius(AppRadius.xl),
                  ),
                  child: TextField(
                    controller: inputCtrl,
                    style: AppTextStyles.bodyMd,
                    maxLines: 4,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    decoration: InputDecoration(
                      hintText: 'Décrivez votre parcours...',
                      hintStyle: AppTextStyles.bodyMd
                          .copyWith(color: AppColors.hintColor),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    onSubmitted: (_) => submit(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Obx(
                () => PressScale(
                  onTap: controller.isSending.value ? null : submit,
                  curve: AppMotion.spring,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: controller.isSending.value
                          ? AppColors.surfaceLow
                          : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      IconlyBold.send,
                      color: controller.isSending.value
                          ? AppColors.hintColor
                          : AppColors.onPrimary,
                      size: 20,
                    ),
                  ),
                ),
              ),
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

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

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
        padding: const EdgeInsets.only(bottom: AppSpacing.lg, left: 40),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceLow,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return FadeTransition(
                  opacity: _controller.drive(
                    Tween<double>(begin: 0.3, end: 1.0).chain(
                      CurveTween(
                        curve: Interval(index * 0.2, 0.6 + index * 0.2,
                            curve: Curves.easeInOut),
                      ),
                    ),
                  ),
                  child: Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: const BoxDecoration(
                        color: AppColors.secondary, shape: BoxShape.circle),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
