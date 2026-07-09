import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_shapes.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/services/realtime_service.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import '../controllers/messages_controller.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/chat_request_banner.dart';
import '../widgets/chat_smart_replies_bar.dart';
import '../widgets/chat_typing_bubble.dart';
import '../widgets/voice_recorder.dart';

class ChatThreadScreen extends StatefulWidget {
  const ChatThreadScreen({super.key});

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final MessagesController controller = Get.find<MessagesController>();
  // Contrôleurs persistants : créés une seule fois (plus dans build()), donc
  // le texte en cours et le focus survivent aux rebuilds (Obx) → le clavier
  // ne se referme plus en pleine saisie. Libérés proprement dans dispose().
  final TextEditingController inputCtrl = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FocusNode inputFocus = FocusNode();

  /// Affiche la banque d'emojis (à la place du clavier).
  final RxBool _showEmoji = false.obs;

  void _toggleEmoji() {
    if (_showEmoji.value) {
      _showEmoji.value = false;
      inputFocus.requestFocus(); // réouvre le clavier
    } else {
      inputFocus.unfocus(); // ferme le clavier, le panneau prend sa place
      _showEmoji.value = true;
    }
  }

  @override
  void dispose() {
    inputCtrl.dispose();
    scrollController.dispose();
    inputFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String? convId = Get.parameters['id'];
    if (convId != null && controller.activeConversationId.value != convId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.loadMessages(convId);
      });
    }

    if (convId != null && Get.isRegistered<RealtimeService>()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.find<RealtimeService>().setActiveConversation(convId);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          const ChatRequestBanner(),
          Expanded(
            child: Obx(() {
              if (controller.isLoadingMessages.value &&
                  controller.activeMessages.isEmpty) {
                return const ChatMessagesSkeleton();
              }

              if (controller.activeMessages.isEmpty) {
                return _buildEmptyState();
              }

              return _buildMessageList(scrollController);
            }),
          ),
          // Réponses suggérées (IA) — masquées pendant l'enregistrement vocal.
          Obx(() => controller.showVoiceRecorder.value
              ? const SizedBox.shrink()
              : ChatSmartRepliesBar(
                  suggestions: controller.smartReplies.toList(),
                  loading: controller.isLoadingSmartReplies.value,
                  onTap: (text) {
                    AppHaptics.tap();
                    inputCtrl.text = text;
                    inputCtrl.selection =
                        TextSelection.collapsed(offset: inputCtrl.text.length);
                    controller.dismissSmartReplies();
                  },
                )),
          // L'enregistreur vocal REMPLACE le composer (plus de barres empilées).
          Obx(() => controller.showVoiceRecorder.value
              ? VoiceRecorderWidget(
                  onSend: (path) {
                    controller.showVoiceRecorder.value = false;
                    controller.sendVoiceMessage(path);
                    _scrollToBottom(scrollController);
                  },
                  onCancel: () => controller.showVoiceRecorder.value = false,
                )
              : _buildInputBar(inputCtrl, scrollController)),
          // Banque d'emojis (remplace le clavier quand activée).
          Obx(() => _showEmoji.value && !controller.showVoiceRecorder.value
              ? EmojiPickerPanel(controller: inputCtrl, height: 300)
              : const SizedBox.shrink()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: GlassSurface(
        borderRadius: BorderRadius.zero,
        enableBlur: true,
        blurSigma: 18,
        specular: false,
        child: const SizedBox.expand(),
      ),
      leading: IconButton(
        icon: Icon(IconlyLight.arrow_left_2, color: AppColors.primaryAccent),
        onPressed: () => Get.back(),
      ),
      title: Obx(() {
        final convId = controller.activeConversationId.value;
        final conv =
            controller.conversations.firstWhereOrNull((c) => c.id == convId);

        return Row(
          children: [
            if (conv != null) ...[
              SizedBox(
                width: 36,
                height: 36,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    BrandAvatar(seed: conv.id, label: conv.title, size: 36),
                    if (controller.peerOnline.value)
                      Positioned(
                        right: -1,
                        bottom: -1,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.successAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conv.title,
                      style: AppTextStyles.titleLg
                          .copyWith(fontWeight: FontWeight.w800),
                      overflow: TextOverflow.ellipsis,
                    ),
                    ChatPresenceLabel(),
                  ],
                ),
              ),
            ] else
              const Text('Discussion'),
          ],
        );
      }),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
            height: 1, color: AppColors.outlineVariant.withValues(alpha: 0.1)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: EmptyState(
        illustration: EmptyChatIllustration(),
        title: 'Aucun message',
        subtitle: 'Envoyez le premier message pour démarrer la discussion.',
      ),
    );
  }

  Widget _buildMessageList(ScrollController scrollController) {
    final bool typing = controller.peerTyping.value;
    final int count = controller.activeMessages.length + (typing ? 1 : 0);
    final DateTime? peerRead = controller.peerLastReadAt.value;
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: count,
      itemBuilder: (context, index) {
        if (typing && index == controller.activeMessages.length) {
          return const ChatTypingBubble();
        }
        final msg = controller.activeMessages[index];
        final bool isFirstOfGroup = index == 0 ||
            controller.activeMessages[index - 1].isMine != msg.isMine;
        // Lu si readAt présent, ou si le pair a lu jusqu'à/au-delà de l'envoi.
        final bool isRead = msg.isMine &&
            (msg.isRead || (peerRead != null && !msg.sentAt.isAfter(peerRead)));

        return ChatMessageBubble(
          message: msg,
          showAvatar: !msg.isMine && isFirstOfGroup,
          isRead: isRead,
          onReact: (emoji) => controller.reactToMessage(msg.id, emoji),
        );
      },
    );
  }

  Widget _buildInputBar(
      TextEditingController inputCtrl, ScrollController scrollController) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        boxShadow: AppColors.lightShadow,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Obx(() => _mediaButton()),
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(left: 6, right: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: AppShapes.squircleRadius(AppRadius.xl),
                ),
                child: Row(
                  children: [
                    // Bouton banque d'emojis (ouvre/ferme le panneau).
                    Obx(() => Semantics(
                          button: true,
                          label: 'Emojis',
                          child: PressScale(
                            onTap: _toggleEmoji,
                            child: Container(
                              constraints: const BoxConstraints(
                                  minWidth: 44, minHeight: 44),
                              alignment: Alignment.center,
                              child: Icon(
                                _showEmoji.value
                                    ? IconlyBold.chat
                                    : Icons.emoji_emotions_outlined,
                                size: 22,
                                color: _showEmoji.value
                                    ? AppColors.primaryAccent
                                    : AppColors.hintColor,
                              ),
                            ),
                          ),
                        )),
                    Expanded(
                      child: TextField(
                        controller: inputCtrl,
                        focusNode: inputFocus,
                        style: AppTextStyles.bodyMd,
                        maxLines: 4,
                        minLines: 1,
                        onTap: () => _showEmoji.value = false,
                        onChanged: controller.onComposerChanged,
                        decoration: InputDecoration(
                          hintText: 'Votre message...',
                          hintStyle: AppTextStyles.bodyMd
                              .copyWith(color: AppColors.hintColor),
                          // Neutralise le contour vert + le fill hérités du
                          // thème : la pastille `surfaceLow` est le seul visuel.
                          filled: false,
                          isCollapsed: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Champ vide → micro (1 tap = enregistre) ; texte saisi → envoi.
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: inputCtrl,
              builder: (context, value, _) {
                final hasText = value.text.trim().isNotEmpty;
                return Obx(() => Semantics(
                      button: true,
                      label: hasText
                          ? 'Envoyer le message'
                          : 'Enregistrer un message vocal',
                      child: PressScale(
                        onTap: controller.isSending.value
                            ? null
                            : () async {
                                if (hasText) {
                                  final text = inputCtrl.text;
                                  inputCtrl.clear();
                                  AppHaptics.success();
                                  await controller.sendMessage(text);
                                  _scrollToBottom(scrollController);
                                } else {
                                  AppHaptics.tap();
                                  controller.showVoiceRecorder.value = true;
                                }
                              },
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 44,
                          ),
                          padding: const EdgeInsets.all(12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: controller.isSending.value
                                ? AppColors.surfaceLow
                                : AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: controller.isSending.value
                              ? SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator.adaptive(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.hintColor,
                                    ),
                                    backgroundColor: AppColors.hintColor,
                                  ),
                                )
                              : Icon(
                                  hasText ? IconlyBold.send : IconlyLight.voice,
                                  color: AppColors.onPrimary,
                                  size: hasText ? 18 : 22,
                                ),
                        ),
                      ),
                    ));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _mediaButton() {
    return PopupMenuButton<String>(
      enabled: !controller.isSending.value,
      offset: const Offset(0, -200),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (value) async {
        switch (value) {
          case 'camera':
            await controller.pickAndSendImage();
            break;
          case 'gallery':
            await controller.pickAndSendGalleryImage();
            break;
          case 'file':
            await controller.pickAndSendFile();
            break;
          case 'location':
            await controller.sendCurrentLocation();
            break;
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
            value: 'camera',
            child: _menuItem(IconlyLight.camera, 'Appareil photo')),
        PopupMenuItem(
            value: 'gallery', child: _menuItem(IconlyLight.image, 'Galerie')),
        PopupMenuItem(
            value: 'file', child: _menuItem(IconlyLight.paper, 'Fichier')),
        PopupMenuItem(
            value: 'location',
            child: _menuItem(IconlyLight.location, 'Localisation')),
      ],
      child: Container(
        padding: const EdgeInsets.all(10),
        child: Icon(IconlyLight.paper_plus,
            color: AppColors.primaryAccent, size: 22),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.titleColor),
        const SizedBox(width: 12),
        Text(label, style: AppTextStyles.bodyMd),
      ],
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
