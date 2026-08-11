import 'package:flutter/material.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:get/get.dart';

import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_dimens.dart';
import 'package:baara/app/core/theme/app_shapes.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/app/core/widgets/widgets.dart';
import '../controllers/messages_controller.dart';

/// Bandeau de demande de message (conversation `pending`).
/// - Destinataire → boutons Accepter / Refuser.
/// - Demandeur → simple mention « en attente d'acceptation ».
class ChatRequestBanner extends StatelessWidget {
  const ChatRequestBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MessagesController>();
    return Obx(() {
      final convId = controller.activeConversationId.value;
      final conv =
          controller.conversations.firstWhereOrNull((c) => c.id == convId);
      if (conv == null || !conv.isRequest) return const SizedBox.shrink();

      if (conv.isRequester) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppColors.surfaceLow,
          child: Row(
            children: [
              Icon(AppIcons.time,
                  size: 18, color: AppColors.hintColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Demande envoyée. Vous pourrez écrire à nouveau une fois acceptée.',
                  style: AppTextStyles.bodySm
                      .copyWith(color: AppColors.bodyColor),
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          border: Border(
            bottom: BorderSide(color: AppColors.outlineVariant, width: 1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${conv.title} souhaite vous envoyer un message.',
              style:
                  AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ChatRequestAction(
                    label: 'Refuser',
                    filled: false,
                    onTap: () async {
                      AppHaptics.tap();
                      await controller.declineRequest(conv.id);
                      Get.back();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChatRequestAction(
                    label: 'Accepter',
                    filled: true,
                    onTap: () {
                      AppHaptics.success();
                      controller.acceptRequest(conv.id);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

/// Bouton compact du bandeau de demande de message (Accepter / Refuser).
class ChatRequestAction extends StatelessWidget {
  const ChatRequestAction({
    super.key,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: filled ? AppColors.primary : AppColors.surfaceLow,
          shape: AppShapes.squircle(
            AppRadius.md,
            side: filled ? null : AppColors.outlineVariant,
            width: filled ? 0 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMd.copyWith(
            color: filled ? AppColors.onPrimary : AppColors.bodyColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
