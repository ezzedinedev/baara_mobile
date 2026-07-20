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
import '../controllers/chatbot_controller.dart';
import '../../domain/entities/chat_message.dart';

/// Assistant IA — langage 2026 : en-tête en verre liquide (GlassSurface) sur
/// halo mesh de marque, bulles squircle (IA / utilisateur), suggestions en
/// chips pill, indicateur de saisie premium et champ de saisie net. Le
/// [Scaffold] / la [Material] sont conservés pour l'ancêtre requis par le
/// [TextField]. Aucune logique de conversation modifiée.
class ChatbotScreen extends GetView<ChatbotController> {
  const ChatbotScreen({super.key});

  // Suggestions de démarrage (chips pill) : empruntent le même chemin d'envoi
  // que la saisie clavier (controller.send), pas de logique nouvelle.
  static const _suggestions = <String>[
    'Comment améliorer mon CV ?',
    'Quelles offres me correspondent ?',
    'Conseils pour un entretien',
    'Formations recommandées',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _ChatHeader(onBack: () => Get.back(), onReset: () => _confirmReset()),
          Expanded(
            child: Obx(() {
              if (controller.isLoadingHistory.value &&
                  controller.messages.isEmpty) {
                return const ChatMessagesSkeleton();
              }
              final showSuggestions = controller.messages.length <= 1 &&
                  !controller.isSending.value;
              return ListView.builder(
                controller: controller.scrollController,
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                    AppSpacing.xxl, AppSpacing.lg, AppSpacing.lg),
                itemCount: controller.messages.length +
                    (controller.isSending.value ? 1 : 0) +
                    (showSuggestions ? 1 : 0),
                itemBuilder: (context, index) {
                  final msgCount = controller.messages.length;
                  if (index < msgCount) {
                    return _ChatBubble(message: controller.messages[index]);
                  }
                  if (controller.isSending.value && index == msgCount) {
                    return const _TypingIndicator();
                  }
                  // Dernière entrée : chips de suggestions.
                  return _SuggestionChips(
                    suggestions: _suggestions,
                    onTap: (text) {
                      AppHaptics.tap();
                      controller.send(text);
                    },
                  );
                },
              );
            }),
          ),
          _ChatInput(
            inputCtrl: controller.inputCtrl,
            controller: controller,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset() async {
    final ctx = Get.context!;
    final confirmed = await showConfirmSheet(
      context: ctx,
      icon: IconlyLight.delete,
      iconColor: AppColors.errorAccent,
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
}

/// En-tête en verre liquide (chrome) posé sur un voile mesh de marque.
class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.onBack, required this.onReset});

  final VoidCallback onBack;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: AppColors.heroNotificationsGradient),
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: AppColors.meshBrandGlow),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
            child: Row(
              children: [
                AppBackButton(onDark: true, onTap: onBack),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(
                    color: AppColors.onPrimary.withValues(alpha: 0.18),
                    shape: AppShapes.squircle(AppRadius.sm),
                  ),
                  child: const Icon(IconlyBold.discovery,
                      color: AppColors.onPrimary, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assistant IA',
                        style: AppTextStyles.headlineMd.copyWith(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.onPrimary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'En ligne',
                            style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.onPrimary.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AppIconButton(
                  onBrandHeader: true,
                  icon: IconlyLight.delete,
                  tooltip: 'Effacer la discussion',
                  onTap: onReset,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bandeau de saisie : chrome en verre liquide, champ squircle, bouton d'envoi
/// rond avec press spring. Le [TextField] reste sous une [Material] (Scaffold).
class _ChatInput extends StatelessWidget {
  const _ChatInput({required this.inputCtrl, required this.controller});

  final TextEditingController inputCtrl;
  final ChatbotController controller;

  void _submit(String val) {
    final text = val.trim();
    if (text.isEmpty) return;
    AppHaptics.tap();
    controller.send(text);
    inputCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: BorderRadius.zero,
      blurSigma: 18,
      specular: false,
      boxShadow: AppColors.ambientShadow,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: AppColors.surfaceLow,
                  shape: AppShapes.squircle(AppRadius.xxl),
                ),
                child: TextField(
                  controller: inputCtrl,
                  style: AppTextStyles.bodyMd,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(
                    hintText: 'Posez-moi une question...',
                    hintStyle: AppTextStyles.bodyMd
                        .copyWith(color: AppColors.hintColor),
                    filled: false,
                    isCollapsed: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 13),
                  ),
                  onSubmitted: _submit,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Obx(() {
              final sending = controller.isSending.value;
              return PressScale(
                curve: AppMotion.spring,
                onTap: sending ? null : () => _submit(inputCtrl.text),
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(
                    color: sending ? AppColors.surfaceLow : AppColors.primary,
                    shape: AppShapes.squircle(AppRadius.md),
                    shadows: sending ? null : AppColors.lightShadow,
                  ),
                  child: Icon(
                    IconlyBold.send,
                    color: sending ? AppColors.hintColor : AppColors.onPrimary,
                    size: 20,
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

/// Suggestions de démarrage en chips pill (wrap).
class _SuggestionChips extends StatelessWidget {
  const _SuggestionChips({required this.suggestions, required this.onTap});

  final List<String> suggestions;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: suggestions
            .map(
              (s) => PressScale(
                curve: AppMotion.spring,
                onTap: () => onTap(s),
                child: Material(
                  type: MaterialType.transparency,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.10),
                      borderRadius: AppShapes.pill,
                      border: Border.all(
                        color: AppColors.primaryAccent.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(IconlyLight.chat,
                            size: 15, color: AppColors.primaryAccent),
                        const SizedBox(width: 6),
                        Text(
                          s,
                          style: AppTextStyles.labelLg.copyWith(
                            color: AppColors.primaryAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
            .toList(growable: false),
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
    final radius = AppShapes.squircleRadius(AppRadius.lg);
    // Coin "tail" adouci côté émetteur (asymétrie squircle).
    final bubbleRadius = BorderRadius.only(
      topLeft: radius.topLeft,
      topRight: radius.topRight,
      bottomLeft: isUser ? radius.bottomLeft : const Radius.circular(6),
      bottomRight: isUser ? const Radius.circular(6) : radius.bottomRight,
    );

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
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(
                    color: AppColors.primary,
                    shape: AppShapes.squircle(AppRadius.xs),
                  ),
                  child: const Icon(IconlyBold.discovery,
                      size: 16, color: AppColors.onPrimary),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Semantics(
                  label: isUser ? 'Votre message' : 'Message de l\'IA',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.primary : AppColors.surfaceLow,
                      borderRadius: bubbleRadius,
                      boxShadow: isUser ? AppColors.lightShadow : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.content,
                          style: AppTextStyles.bodyMd.copyWith(
                            color: isUser
                                ? AppColors.onPrimary
                                : AppColors.titleColor,
                            height: 1.5,
                          ),
                        ),
                        if (message.ctaActions.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          ...message.ctaActions
                              .map((cta) => _CtaButton(cta: cta)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              if (isUser) const SizedBox(width: AppSpacing.sm),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
                top: 4, left: isUser ? 0 : 40, right: isUser ? 8 : 0),
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

class _CtaButton extends StatelessWidget {
  final CtaAction cta;
  const _CtaButton({required this.cta});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: PressScale(
        curve: AppMotion.spring,
        onTap: () {
          AppHaptics.tap();
          // Handle CTA types (link, route, etc.)
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
              vertical: 10, horizontal: AppSpacing.md),
          decoration: ShapeDecoration(
            color: AppColors.onPrimary.withValues(alpha: 0.2),
            shape: AppShapes.squircle(
              AppRadius.xs,
              side: AppColors.onPrimary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                cta.label,
                style:
                    AppTextStyles.labelMd.copyWith(color: AppColors.onPrimary),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(IconlyLight.arrow_right_2,
                  size: 14, color: AppColors.onPrimary),
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
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: AppColors.primary,
              shape: AppShapes.squircle(AppRadius.xs),
            ),
            child: const Icon(IconlyBold.discovery,
                size: 16, color: AppColors.onPrimary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceLow,
              borderRadius: BorderRadius.only(
                topLeft: AppShapes.squircleRadius(AppRadius.lg).topLeft,
                topRight: AppShapes.squircleRadius(AppRadius.lg).topRight,
                bottomLeft: const Radius.circular(6),
                bottomRight: AppShapes.squircleRadius(AppRadius.lg).bottomRight,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return FadeTransition(
                  opacity: _controller.drive(
                    Tween<double>(begin: 0.3, end: 1.0).chain(
                      CurveTween(
                          curve: Interval(index * 0.2, 0.6 + index * 0.2,
                              curve: Curves.easeInOut)),
                    ),
                  ),
                  child: Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    decoration: BoxDecoration(
                        color: AppColors.primaryAccent, shape: BoxShape.circle),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
