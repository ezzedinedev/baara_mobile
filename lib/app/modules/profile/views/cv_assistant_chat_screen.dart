import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../../../../routes/app_routes.dart';
import '../controllers/cv_builder_controller.dart';

part 'cv_assistant_chat_parts/widgets.dart';

/// Assistant CV conversationnel — chat IA qui guide l'utilisateur à travers
/// les champs du CV en mode question/réponse. L'état de progression voyage
/// par [CvBuilderController.confirmedFields] (envoyé à chaque requête au
/// backend stateless).
class CvAssistantChatScreen extends GetView<CvBuilderController> {
  const CvAssistantChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Assistant IA', style: AppTextStyles.headlineSm),
        leading: IconButton(
          tooltip: 'Retour',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            AppHaptics.tap();
            Navigator.of(context).maybePop();
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Réinitialiser',
            onPressed: () {
              AppHaptics.confirm();
              _confirmReset(context);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(8),
          child: Obx(() {
            final pct = controller.progressPct.value;
            // Plancher visuel a 4% pour qu'on voit la barre meme a 0% — sinon
            // l'utilisateur croit qu'il n'y a rien a faire.
            final value = (pct.clamp(0, 100)) / 100;
            final displayValue = value < 0.04 ? 0.04 : value;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: displayValue),
              duration: const Duration(milliseconds: 480),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                minHeight: 6,
                backgroundColor: AppColors.surfaceContainer,
                valueColor: AlwaysStoppedAnimation(
                  pct == 0 ? AppColors.primaryLight : AppColors.primary,
                ),
              ),
            );
          }),
        ),
      ),
      body: Column(
        children: [
          _ProgressHeader(controller: controller),
          _FieldStrip(controller: controller),
          Expanded(
            child: Obx(() {
              if (controller.chatHistory.isEmpty) {
                return const _Welcome();
              }
              return _ChatList(controller: controller);
            }),
          ),
          _SuggestionChips(controller: controller),
          const _ComposerDivider(),
          _Composer(controller: controller),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Recommencer la conversation ?',
            style: AppTextStyles.titleLg),
        content: Text(
          'Le fil de discussion sera effacé. Ton CV ne sera pas supprimé.',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.bodyColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            onPressed: () {
              AppHaptics.tap();
              controller.resetChat();
              Navigator.of(ctx).pop();
            },
            child: const Text('Recommencer'),
          ),
        ],
      ),
    );
  }
}

