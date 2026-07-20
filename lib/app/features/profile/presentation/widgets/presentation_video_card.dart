import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:video_player/video_player.dart';

import 'package:jobaway/app/core/theme/app_colors.dart';
import 'package:jobaway/app/core/theme/app_dimens.dart';
import 'package:jobaway/app/core/theme/app_shapes.dart';
import 'package:jobaway/app/core/widgets/widgets.dart';
import '../controllers/profile_controller.dart';

/// Carte « Vidéo de présentation » (candidat). Lecture à la demande d'une
/// courte vidéo (~30 s) servie depuis le disque public — la base ne stocke que
/// le chemin. Réactive à [ProfileController.presentationVideoUrl].
class PresentationVideoCard extends StatelessWidget {
  const PresentationVideoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Vidéo de présentation'),
        Material(
          type: MaterialType.transparency,
          child: Container(
            decoration: ShapeDecoration(
              color: AppColors.surfaceCard,
              shape: AppShapes.cardBordered(AppColors.outlineVariant),
              shadows: [
                ...AppColors.lightShadow,
                ...AppColors.ambientShadow,
              ],
            ),
            clipBehavior: Clip.antiAlias,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Obx(() {
              final url = controller.presentationVideoUrl.value;
              final busy = controller.isUploadingVideo.value;
              if (url == null || url.isEmpty) {
                return _EmptyState(busy: busy, onAdd: controller
                    .pickAndUploadPresentationVideo);
              }
              return _LoadedState(
                url: url,
                busy: busy,
                onReplace: controller.pickAndUploadPresentationVideo,
                onDelete: () => _confirmDelete(context, controller),
              );
            }),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, ProfileController controller) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la vidéo ?'),
        content: const Text(
            'Votre vidéo de présentation sera définitivement supprimée.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(ctx).pop();
              controller.deletePresentationVideo();
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.busy, required this.onAdd});
  final bool busy;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(IconlyLight.video, color: AppColors.primaryAccent, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Présentez-vous en ~30 s. Les recruteurs verront votre vidéo '
                'sur votre profil.',
                style: TextStyle(color: AppColors.hintColor, height: 1.35),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: busy ? null : onAdd,
            icon: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(IconlyLight.upload, size: 18),
            label: Text(busy ? 'Envoi…' : 'Ajouter une vidéo'),
          ),
        ),
      ],
    );
  }
}

class _LoadedState extends StatelessWidget {
  const _LoadedState({
    required this.url,
    required this.busy,
    required this.onReplace,
    required this.onDelete,
  });
  final String url;
  final bool busy;
  final VoidCallback onReplace;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _VideoPlayerBox(url: url),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: busy ? null : onReplace,
                icon: const Icon(IconlyLight.upload, size: 18),
                label: const Text('Remplacer'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: busy ? null : onDelete,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: AppColors.error.withValues(alpha: .5)),
                ),
                icon: const Icon(IconlyLight.delete, size: 18),
                label: const Text('Supprimer'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Lecteur vidéo réseau à la demande (preload différé : initialisé seulement
/// quand la carte est montée). Réinitialise proprement quand l'URL change.
class _VideoPlayerBox extends StatefulWidget {
  const _VideoPlayerBox({required this.url});
  final String url;

  @override
  State<_VideoPlayerBox> createState() => _VideoPlayerBoxState();
}

class _VideoPlayerBoxState extends State<_VideoPlayerBox> {
  VideoPlayerController? _video;
  ChewieController? _chewie;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  @override
  void didUpdateWidget(covariant _VideoPlayerBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _dispose();
      _ready = false;
      _error = null;
      _setup();
    }
  }

  Future<void> _setup() async {
    try {
      final video = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      _video = video;
      await video.initialize();
      if (!mounted) return;
      _chewie = ChewieController(
        videoPlayerController: video,
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
        aspectRatio: video.value.aspectRatio == 0
            ? 16 / 9
            : video.value.aspectRatio,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primaryAccent,
          handleColor: AppColors.primaryAccent,
        ),
      );
      setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _error = 'Lecture impossible');
    }
  }

  void _dispose() {
    _chewie?.dispose();
    _video?.dispose();
    _chewie = null;
    _video = null;
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Container(
        height: 200,
        color: AppColors.surfaceContainer,
        alignment: Alignment.center,
        child: Text(_error!, style: TextStyle(color: AppColors.hintColor)),
      );
    }
    if (!_ready || _chewie == null) {
      return Container(
        height: 200,
        color: AppColors.surfaceContainer,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }
    // Hauteur bornée pour les vidéos portrait (sinon écran entier).
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 320),
      child: AspectRatio(
        aspectRatio: _chewie!.aspectRatio ?? 16 / 9,
        child: Chewie(controller: _chewie!),
      ),
    );
  }
}
