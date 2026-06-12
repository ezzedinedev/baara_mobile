import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_motion.dart';
import 'package:opportune_bf/app/core/theme/app_shapes.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/services/realtime_service.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import '../controllers/messages_controller.dart';
import '../widgets/voice_recorder.dart';
import '../widgets/voice_message_player.dart';
import '../../domain/entities/message.dart';

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
              : _SmartRepliesBar(
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
                    _PresenceLabel(),
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
          return const _TypingBubble();
        }
        final msg = controller.activeMessages[index];
        final bool isFirstOfGroup = index == 0 ||
            controller.activeMessages[index - 1].isMine != msg.isMine;
        // Lu si readAt présent, ou si le pair a lu jusqu'à/au-delà de l'envoi.
        final bool isRead = msg.isMine &&
            (msg.isRead || (peerRead != null && !msg.sentAt.isAfter(peerRead)));

        return _MessageBubble(
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

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool showAvatar;
  final bool isRead;
  final ValueChanged<String> onReact;

  const _MessageBubble({
    required this.message,
    required this.showAvatar,
    required this.isRead,
    required this.onReact,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMine = message.isMine;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
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
            child: Column(
              crossAxisAlignment:
                  isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onLongPress: () => _openReactionBar(context),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: message.messageType == 'image' ? 6 : 10,
                    ),
                    decoration: BoxDecoration(
                      // Bulle reçue : surface carte (mieux détachée du fond,
                      // surtout en dark) + filet fin. Émise : vert plein.
                      color: isMine ? AppColors.primary : AppColors.surfaceCard,
                      border: isMine
                          ? null
                          : Border.all(
                              color: AppColors.outlineVariant
                                  .withValues(alpha: 0.6),
                              width: 1,
                            ),
                      borderRadius: BorderRadius.only(
                        // Squircle continu : rayon perçu lg (~20) sur les gros
                        // coins, xs (~8) sur le coin « queue » côté émetteur.
                        topLeft: Radius.circular(AppRadius.lg * 1.7),
                        topRight: Radius.circular(AppRadius.lg * 1.7),
                        bottomLeft: Radius.circular(
                            !isMine ? AppRadius.xs * 1.7 : AppRadius.lg * 1.7),
                        bottomRight: Radius.circular(
                            isMine ? AppRadius.xs * 1.7 : AppRadius.lg * 1.7),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (message.isStoryReply) ...[
                          _storyReplyContext(isMine),
                          const SizedBox(height: 6),
                        ],
                        _buildContent(context, isMine),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat('HH:mm').format(message.sentAt),
                              style: AppTextStyles.bodySm.copyWith(
                                fontSize: 9,
                                color: isMine
                                    ? AppColors.onPrimary.withValues(alpha: 0.7)
                                    : AppColors.hintColor,
                              ),
                            ),
                            if (isMine) ...[
                              const SizedBox(width: 4),
                              _ReadReceipt(isRead: isRead),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (message.reactionsSummary.isNotEmpty)
                  _ReactionChips(message: message),
              ],
            ),
          ),
          if (isMine) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Future<void> _openReactionBar(BuildContext context) async {
    AppHaptics.tap();
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReactionPicker(currentEmoji: message.myEmoji),
    );
    if (selected != null) {
      AppHaptics.success();
      // Burst au centre de la bulle SEULEMENT à l'AJOUT/CHANGEMENT (pas si on
      // re-sélectionne l'emoji courant, ce qui le retire en toggle).
      final adding = selected != message.myEmoji;
      onReact(selected);
      if (adding && context.mounted) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          final center = box.localToGlobal(box.size.center(Offset.zero));
          showBurst(context, center, emoji: selected);
        }
      }
    }
  }

  /// Bandeau « Réponse à une story » + vignette du snapshot (image/texte).
  Widget _storyReplyContext(bool isMine) {
    final fg = isMine ? AppColors.onPrimary : AppColors.titleColor;
    final snap = message.storySnapshot;
    Widget thumb;
    if (snap?.url != null && snap!.type == 'image') {
      thumb = ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(snap.url!,
            width: 30,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _thumbFallback(snap)),
      );
    } else {
      thumb = _thumbFallback(snap);
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: (isMine ? AppColors.onPrimary : AppColors.titleColor)
            .withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: fg.withValues(alpha: 0.5), width: 3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          thumb,
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Réponse à une story',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySm.copyWith(
                color: fg.withValues(alpha: 0.85),
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumbFallback(StorySnapshot? snap) {
    Color bg = AppColors.primary;
    final hex = snap?.backgroundColor;
    if (hex != null && hex.isNotEmpty) {
      try {
        bg = Color(int.parse(hex.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }
    return Container(
      width: 30,
      height: 40,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        snap?.type == 'video' ? IconlyLight.play : Icons.auto_stories_rounded,
        size: 16,
        color: AppColors.onPrimary,
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isMine) {
    switch (message.messageType) {
      case 'image':
        return _buildImage(context, isMine);
      case 'voice':
        return _buildVoice(isMine);
      case 'file':
        return _buildFile(context, isMine);
      case 'location':
        return _buildLocation(isMine);
      default:
        return _buildText(isMine);
    }
  }

  Widget _buildText(bool isMine) {
    return Text(
      message.text,
      style: AppTextStyles.bodyMd.copyWith(
        color: isMine ? AppColors.onPrimary : AppColors.titleColor,
        height: 1.4,
      ),
    );
  }

  Widget _buildImage(BuildContext context, bool isMine) {
    final url = message.attachmentUrl;
    if (url == null || url.isEmpty) return _buildText(isMine);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GestureDetector(
        onTap: () => _previewImage(url),
        child: Image.network(
          url,
          width: 200,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildText(isMine),
        ),
      ),
    );
  }

  Widget _buildVoice(bool isMine) {
    final url = message.attachmentUrl;
    if (url == null || url.isEmpty) {
      return Text('Message vocal',
          style: AppTextStyles.bodySm.copyWith(
              color: isMine
                  ? AppColors.onPrimary.withValues(alpha: 0.7)
                  : AppColors.bodyColor));
    }
    // Lecteur in-app : play/pause + progression + durée (plus d'ouverture
    // externe).
    return VoiceMessagePlayer(url: url, isMine: isMine);
  }

  Widget _buildFile(BuildContext context, bool isMine) {
    final name = message.fileName ?? message.text;
    final icon = _fileIcon(name);
    final color = isMine ? AppColors.onPrimary : AppColors.primaryAccent;
    return GestureDetector(
      onTap: message.attachmentUrl != null && message.attachmentUrl!.isNotEmpty
          ? () => _openFile(message.attachmentUrl!)
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySm.copyWith(
                color: isMine ? AppColors.onPrimary : AppColors.titleColor,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          if (message.fileSize != null) ...[
            const SizedBox(width: 4),
            Text(_formatSize(message.fileSize!),
                style: AppTextStyles.bodySm.copyWith(
                    fontSize: 10,
                    color: isMine
                        ? AppColors.onPrimary.withValues(alpha: 0.6)
                        : AppColors.hintColor)),
          ],
        ],
      ),
    );
  }

  Widget _buildLocation(bool isMine) {
    Map<String, dynamic>? loc;
    try {
      loc = jsonDecode(message.text) as Map<String, dynamic>;
    } catch (_) {}
    final lat = loc?['lat'];
    final lng = loc?['lng'];
    final address = loc?['address'] as String? ?? 'Position partagée';
    return GestureDetector(
      onTap: lat != null && lng != null
          ? () => _openMaps(lat.toDouble(), lng.toDouble())
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(IconlyLight.location,
              color: isMine ? AppColors.onPrimary : AppColors.errorAccent,
              size: 22),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              address,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySm.copyWith(
                color: isMine ? AppColors.onPrimary : AppColors.titleColor,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _fileIcon(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return IconlyLight.paper;
      case 'doc':
      case 'docx':
        return IconlyLight.paper;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
        return IconlyLight.folder;
      default:
        return IconlyLight.paper;
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes o';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} Ko';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }

  void _previewImage(String url) {
    Get.to(() => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ),
        ));
  }

  Future<void> _openFile(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openMaps(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps?q=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Sous-titre de présence dans l'en-tête : « en train d'écrire… »,
/// « en ligne » (pastille verte) ou « Vu il y a … ».
class _PresenceLabel extends StatelessWidget {
  final MessagesController controller = Get.find<MessagesController>();

  _PresenceLabel();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.peerTyping.value) {
        return Text(
          'en train d\'écrire…',
          style: AppTextStyles.bodySm.copyWith(
            color: AppColors.primaryAccent,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        );
      }
      if (controller.peerOnline.value) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PulsingDot(
              color: AppColors.successAccent,
              size: 7,
              haloSize: 11,
            ),
            const SizedBox(width: 5),
            Text(
              'en ligne',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.successAccent,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        );
      }
      final seen = controller.peerLastSeen.value;
      if (seen == null) return const SizedBox.shrink();
      return Text(
        'Vu ${_lastSeenLabel(seen)}',
        style: AppTextStyles.bodySm.copyWith(
          color: AppColors.hintColor,
          fontSize: 11,
        ),
      );
    });
  }

  String _lastSeenLabel(DateTime when) {
    final diff = DateTime.now().difference(when.toLocal());
    if (diff.inMinutes < 1) return 'à l\'instant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    if (diff.inDays == 1) return 'hier';
    if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
    return 'le ${DateFormat('dd/MM').format(when.toLocal())}';
  }
}

/// Accusé de lecture sur MES bulles : ✓ envoyé / ✓✓ lu (vert).
class _ReadReceipt extends StatelessWidget {
  final bool isRead;
  const _ReadReceipt({required this.isRead});

  @override
  Widget build(BuildContext context) {
    return Icon(
      isRead ? IconlyBold.tick_square : IconlyLight.tick_square,
      size: 13,
      color: isRead
          ? AppColors.successAccent
          : AppColors.onPrimary.withValues(alpha: 0.7),
    );
  }
}

/// Réactions affichées sous la bulle (emoji + count, surbrillance si la mienne).
class _ReactionChips extends StatelessWidget {
  final Message message;
  const _ReactionChips({required this.message});

  @override
  Widget build(BuildContext context) {
    final entries = message.reactionsSummary.entries.toList();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        children: entries.map((e) {
          final mine = message.myEmoji == e.key;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: mine
                  ? AppColors.primaryAccent.withValues(alpha: 0.15)
                  : AppColors.surfaceLow,
              borderRadius: AppShapes.pill,
              border: mine
                  ? Border.all(color: AppColors.primaryAccent, width: 1)
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e.key, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 3),
                Text(
                  '${e.value}',
                  style: AppTextStyles.bodySm.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: mine ? AppColors.primaryAccent : AppColors.bodyColor,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Indicateur "typing" : bulle reçue avec 3 points animés en cascade.
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const SizedBox(width: 36),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.6),
                width: 1,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppRadius.lg * 1.7),
                topRight: Radius.circular(AppRadius.lg * 1.7),
                bottomLeft: Radius.circular(AppRadius.xs * 1.7),
                bottomRight: Radius.circular(AppRadius.lg * 1.7),
              ),
            ),
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final t = (_ctrl.value - i * 0.2) % 1.0;
                    final scale =
                        0.6 + 0.4 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
                    return Padding(
                      padding: EdgeInsets.only(right: i < 2 ? 5 : 0),
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: AppColors.primaryAccent
                                .withValues(alpha: 0.55 + 0.45 * scale),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Rangée de réponses suggérées (IA) au-dessus du composer. Apparition animée
/// (fade + slide), une puce par suggestion, préfixée d'une étincelle IA.
class _SmartRepliesBar extends StatelessWidget {
  const _SmartRepliesBar({
    required this.suggestions,
    required this.loading,
    required this.onTap,
  });

  final List<String> suggestions;
  final bool loading;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final visible = suggestions.isNotEmpty;
    return AnimatedSwitcher(
      duration: AppMotion.base,
      switchInCurve: AppMotion.enter,
      switchOutCurve: AppMotion.exit,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SizeTransition(
          sizeFactor: anim,
          child: child,
        ),
      ),
      child: !visible
          ? const SizedBox(width: double.infinity)
          : Container(
              key: const ValueKey('smart-replies'),
              width: double.infinity,
              color: AppColors.background,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(IconlyLight.star,
                        size: 16, color: AppColors.primaryAccent),
                  ),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: suggestions.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final s = suggestions[i];
                          return Center(
                            child: PressScale(
                              onTap: () => onTap(s),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryAccent
                                      .withValues(alpha: 0.10),
                                  borderRadius: AppShapes.pill,
                                  border: Border.all(
                                    color: AppColors.primaryAccent
                                        .withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Text(
                                  s,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.labelMd.copyWith(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Barre d'emojis animée (appui long) — renvoie l'emoji choisi via Get.back.
class _ReactionPicker extends StatelessWidget {
  final String? currentEmoji;
  const _ReactionPicker({this.currentEmoji});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: AppMotion.fast,
          curve: AppMotion.enter,
          builder: (context, v, child) => Opacity(
            opacity: v,
            child: Transform.translate(
              offset: Offset(0, (1 - v) * 16),
              child: child,
            ),
          ),
          child: GlassSurface(
            borderRadius: AppShapes.pill,
            enableBlur: true,
            blurSigma: 20,
            boxShadow: AppColors.lightShadow,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: kReactionEmojis.map((emoji) {
                final selected = emoji == currentEmoji;
                return PressScale(
                  onTap: () => Navigator.of(context).pop(emoji),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: selected
                        ? BoxDecoration(
                            color:
                                AppColors.primaryAccent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          )
                        : null,
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
