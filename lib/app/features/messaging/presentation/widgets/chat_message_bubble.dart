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
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import '../../domain/entities/message.dart';
import '../controllers/messages_controller.dart';
import 'voice_message_player.dart';

class ChatMessageBubble extends StatelessWidget {
  final Message message;
  final bool showAvatar;
  final bool isRead;
  final ValueChanged<String> onReact;

  const ChatMessageBubble({
    super.key,
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
                              ChatReadReceipt(isRead: isRead),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (message.reactionsSummary.isNotEmpty)
                  ChatReactionChips(message: message),
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
      builder: (_) => ChatReactionPicker(currentEmoji: message.myEmoji),
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
      thumb = AppNetworkImage(
        url: snap.url,
        width: 30,
        height: 40,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(6),
        errorWidget: _thumbFallback(snap),
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
    return GestureDetector(
      onTap: () => _previewImage(url),
      child: AppNetworkImage(
        url: url,
        width: 200,
        height: 200,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(12),
        errorWidget: _buildText(isMine),
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
              child: AppNetworkImage(url: url, fit: BoxFit.contain),
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
class ChatPresenceLabel extends StatelessWidget {
  ChatPresenceLabel({super.key});

  final MessagesController controller = Get.find<MessagesController>();

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
class ChatReadReceipt extends StatelessWidget {
  final bool isRead;
  const ChatReadReceipt({super.key, required this.isRead});

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
class ChatReactionChips extends StatelessWidget {
  final Message message;
  const ChatReactionChips({super.key, required this.message});

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

/// Barre d'emojis animée (appui long) — renvoie l'emoji choisi via Navigator.pop.
class ChatReactionPicker extends StatelessWidget {
  final String? currentEmoji;
  const ChatReactionPicker({super.key, this.currentEmoji});

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
