import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import 'package:opportune_bf/app/core/services/auth_token_store.dart';
import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';

import '../../domain/entities/training.dart';
import '../controllers/training_player_controller.dart';

/// Lecteur de leçon multimédia restauré : affiche la leçon (module) courante
/// selon son type (vidéo / PDF / image / texte / lien), permet de naviguer
/// entre les leçons (Précédent / Suivant) et de marquer la leçon comme
/// terminée via [TrainingPlayerController]. Reçoit la formation et l'index
/// initial par le constructeur (ou via `Get.arguments`).
class TrainingLessonScreen extends StatefulWidget {
  const TrainingLessonScreen({
    super.key,
    required this.training,
    this.initialIndex = 0,
  });

  final Training training;
  final int initialIndex;

  @override
  State<TrainingLessonScreen> createState() => _TrainingLessonScreenState();
}

class _TrainingLessonScreenState extends State<TrainingLessonScreen> {
  late int _index;
  TrainingPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    if (Get.isRegistered<TrainingPlayerController>()) {
      _controller = Get.find<TrainingPlayerController>();
    }
  }

  @override
  Widget build(BuildContext context) {
    final modules = widget.training.modules;

    if (modules.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          foregroundColor: AppColors.titleColor,
          title: Text(widget.training.title, style: AppTextStyles.titleMd),
        ),
        body: const EmptyState(
          icon: Icons.menu_book_outlined,
          title: 'Aucune leçon disponible',
          subtitle: 'Cette formation ne contient pas encore de leçon.',
        ),
      );
    }

    final currentIndex = _index.clamp(0, modules.length - 1);
    final lesson = modules[currentIndex];
    final isFirst = currentIndex == 0;
    final isLast = currentIndex == modules.length - 1;

    final controller = _controller;
    final body = SafeArea(
      child: Column(
        children: [
          _ProgressBar(current: currentIndex, total: modules.length),
          Expanded(
            // Fondu doux entre leçons (au lieu d'un saut brutal au setState).
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOut,
              child: ListView(
                key: ValueKey<int>(currentIndex),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  _LessonMedia(
                      lesson: lesson, onOpenLink: () => _openLink(lesson)),
                  const SizedBox(height: 14),
                  _LessonInfoCard(lesson: lesson),
                ],
              ),
            ),
          ),
          _NavBar(
            isFirst: isFirst,
            isLast: isLast,
            controller: controller,
            lessonId: lesson.id,
            onPrev: isFirst
                ? null
                : () {
                    AppHaptics.tap();
                    setState(() => _index = currentIndex - 1);
                  },
            onNext: () => _onNext(lesson, currentIndex, isLast),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.titleColor,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lesson.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleMd,
            ),
            Text(
              widget.training.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.hintColor),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: _LessonTypePill(lesson: lesson)),
          ),
        ],
      ),
      body: controller == null
          ? body
          : Obx(() {
              // Re-build lorsque la complétion change pour rafraîchir le CTA.
              controller.completedIds.length;
              return body;
            }),
    );
  }

  Future<void> _onNext(TrainingModule lesson, int currentIndex, bool isLast) async {
    AppHaptics.tap();
    final completed = await _markCompleted(lesson);
    if (!mounted) return;
    if (!completed) return;
    if (isLast) {
      Get.back<void>();
      return;
    }
    setState(() => _index = currentIndex + 1);
  }

  Future<bool> _markCompleted(TrainingModule lesson) async {
    final controller = _controller;
    if (controller == null) {
      // Pas de controller en mémoire : on considère l'étape franchie pour ne
      // pas bloquer la navigation entre leçons.
      return true;
    }
    if (controller.isCompleted(lesson)) return true;
    await controller.markCompleted(lesson);
    return controller.isCompleted(lesson);
  }

  Future<void> _openLink(TrainingModule lesson) async {
    final url = lesson.effectiveUrl.trim();
    final uri = Uri.tryParse(url);
    if (url.isEmpty || uri == null || !uri.hasScheme) {
      AppToast.error('Lien invalide', 'Le lien de la ressource est indisponible.');
      return;
    }
    AppHaptics.tap();
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        AppToast.error('Ouverture impossible', 'Aucune application ne peut ouvrir ce lien.');
      }
    } on Exception {
      AppToast.error('Ouverture impossible', 'Aucune application ne peut ouvrir ce lien.');
    }
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final value = total == 0 ? 0.0 : (current + 1) / total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Leçon ${current + 1} / $total',
            style: AppTextStyles.labelMd.copyWith(color: AppColors.hintColor),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: AppColors.surfaceHigh,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonInfoCard extends StatelessWidget {
  const _LessonInfoCard({required this.lesson});
  final TrainingModule lesson;

  @override
  Widget build(BuildContext context) {
    final hasDescription = lesson.description.trim().isNotEmpty &&
        lesson.description.trim() != 'Description non fournie.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  lesson.title,
                  style: AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (lesson.duration > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '${lesson.duration} min',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.hintColor),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          if (hasDescription)
            Text(
              lesson.description,
              style: AppTextStyles.bodyMd.copyWith(height: 1.5),
            )
          else if (lesson.isText && lesson.textContent.trim().isNotEmpty)
            Text(
              lesson.textContent,
              style: AppTextStyles.bodyMd.copyWith(height: 1.5),
            )
          else
            Text(
              'Contenu bientôt disponible.',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.hintColor),
            ),
        ],
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({
    required this.isFirst,
    required this.isLast,
    required this.controller,
    required this.lessonId,
    required this.onPrev,
    required this.onNext,
  });

  final bool isFirst;
  final bool isLast;
  final TrainingPlayerController? controller;
  final String lessonId;
  final VoidCallback? onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final busy = controller?.updatingId.value == lessonId;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        boxShadow: AppColors.lightShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onPrev,
              icon: const Icon(Icons.chevron_left_rounded),
              label: const Text('Précédent'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GradientButton(
              label: isLast ? 'TERMINER' : 'SUIVANT',
              isLoading: busy,
              borderRadius: 12,
              height: 48,
              textColor: AppColors.onPrimary,
              onPressed: busy ? null : onNext,
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonTypePill extends StatelessWidget {
  const _LessonTypePill({required this.lesson});
  final TrainingModule lesson;

  @override
  Widget build(BuildContext context) {
    final color = _lessonColor(lesson);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        lesson.typeLabel,
        style: AppTextStyles.labelMd.copyWith(color: color, letterSpacing: 0),
      ),
    );
  }
}

Color _lessonColor(TrainingModule lesson) {
  if (lesson.isVideo) return AppColors.categoryPurpleDeep;
  if (lesson.isPdf) return AppColors.errorBright;
  if (lesson.isImage) return AppColors.successDark;
  return AppColors.categoryCyan;
}

/// Sélectionne le bon lecteur selon le type de leçon, en dégradant proprement
/// quand aucun média n'est attaché (titre + description gérés ailleurs).
class _LessonMedia extends StatelessWidget {
  const _LessonMedia({required this.lesson, required this.onOpenLink});
  final TrainingModule lesson;
  final VoidCallback onOpenLink;

  @override
  Widget build(BuildContext context) {
    final url = lesson.effectiveUrl.trim();

    if (lesson.isText) {
      // Leçon article : contenu dans la carte description, pas de média.
      return const SizedBox.shrink();
    }

    if (lesson.isLink) {
      return _LinkCard(lesson: lesson, onOpen: onOpenLink);
    }

    if (url.isEmpty) {
      if (lesson.contentType == LessonContentType.unknown) {
        // Type inconnu sans URL : on laisse la carte description faire le job.
        return const SizedBox.shrink();
      }
      return const _MediaUnavailableCard();
    }

    if (lesson.isPdf) return _InlinePdfPlayer(url: url);
    if (lesson.isImage) return _InlineImagePlayer(url: url);
    if (lesson.isVideo) return _InlineVideoPlayer(url: url);

    // Type inconnu mais URL présente : on tente la visionneuse PDF.
    return _InlinePdfPlayer(url: url);
  }
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({required this.lesson, required this.onOpen});
  final TrainingModule lesson;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onOpen,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
              child: const Icon(Icons.link_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ouvrir la ressource',
                    style: AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Le lien s\'ouvre dans votre navigateur.',
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.hintColor),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.hintColor),
          ],
        ),
      ),
    );
  }
}

class _MediaUnavailableCard extends StatelessWidget {
  const _MediaUnavailableCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.warning.withValues(alpha: 0.14),
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.warning,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Contenu bientôt disponible',
            textAlign: TextAlign.center,
            style: AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Le formateur n\'a pas encore attaché de fichier à cette leçon.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.bodyColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton de chargement d'un média : remplit le cadre d'un shimmer + icône
/// fantôme, le temps que la vidéo / le PDF / l'image s'initialise.
class _MediaLoadingFill extends StatelessWidget {
  const _MediaLoadingFill({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SkeletonCluster(
      child: Container(
        color: AppColors.surfaceContainer,
        alignment: Alignment.center,
        child: Icon(icon, size: 46, color: AppColors.surfaceHigh),
      ),
    );
  }
}

/// Panneau d'erreur média générique avec bouton Réessayer.
class _MediaErrorPane extends StatelessWidget {
  const _MediaErrorPane({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
    this.onLight = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onRetry;

  /// `true` quand le panneau est posé sur un fond sombre (lecteur vidéo).
  final bool onLight;

  @override
  Widget build(BuildContext context) {
    final textColor = onLight ? AppColors.onPrimary : AppColors.bodyColor;
    // SingleChildScrollView + mainAxisSize.min : ne déborde jamais, même dans
    // une boîte média 16:9 étroite.
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.warning.withValues(alpha: 0.14),
              ),
              child: Icon(icon, color: AppColors.warning, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleMd.copyWith(
                fontWeight: FontWeight.w800,
                color: onLight ? AppColors.onPrimary : AppColors.titleColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style:
                  AppTextStyles.bodySm.copyWith(color: textColor, height: 1.35),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                AppHaptics.tap();
                onRetry();
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Réessayer'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lecteur vidéo intégré (Chewie). Injecte le token d'auth si disponible.
class _InlineVideoPlayer extends StatefulWidget {
  const _InlineVideoPlayer({required this.url});
  final String url;

  @override
  State<_InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<_InlineVideoPlayer> {
  VideoPlayerController? _video;
  ChewieController? _chewie;
  String? _error;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    try {
      final token = await const AuthTokenStore().readTokenOrNull();
      final headers = token == null ? <String, String>{} : {'Authorization': 'Bearer $token'};
      final ctrl = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
        httpHeaders: headers,
      );
      await ctrl.initialize();
      if (!mounted) {
        await ctrl.dispose();
        return;
      }
      setState(() {
        _video = ctrl;
        _chewie = ChewieController(
          videoPlayerController: ctrl,
          autoPlay: false,
          looping: false,
          allowFullScreen: true,
          allowMuting: true,
          aspectRatio: ctrl.value.aspectRatio == 0 ? 16 / 9 : ctrl.value.aspectRatio,
          materialProgressColors: ChewieProgressColors(
            playedColor: AppColors.primary,
            handleColor: AppColors.primary,
            bufferedColor: AppColors.surfaceHigh,
            backgroundColor: AppColors.surfaceLow,
          ),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _chewie?.dispose();
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: Colors.black,
          child: _error != null
              ? _MediaErrorPane(
                  icon: Icons.videocam_off_rounded,
                  title: 'Lecture impossible',
                  message:
                      'La vidéo n\'a pas pu être lue. Vérifiez votre connexion puis réessayez.',
                  onLight: true,
                  onRetry: () {
                    setState(() => _error = null);
                    _setup();
                  },
                )
              : _chewie == null
                  ? const _MediaLoadingFill(
                      icon: Icons.play_circle_outline_rounded)
                  : Chewie(controller: _chewie!),
        ),
      ),
    );
  }
}

/// Visionneuse PDF inline (Syncfusion). Token d'auth injecté si présent.
class _InlinePdfPlayer extends StatefulWidget {
  const _InlinePdfPlayer({required this.url});
  final String url;

  @override
  State<_InlinePdfPlayer> createState() => _InlinePdfPlayerState();
}

class _InlinePdfPlayerState extends State<_InlinePdfPlayer> {
  Map<String, String>? _headers;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final token = await const AuthTokenStore().readTokenOrNull();
    if (!mounted) return;
    setState(() {
      _headers = token == null ? null : {'Authorization': 'Bearer $token'};
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 520,
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.18),
          ),
        ),
        child: !_ready
            ? const _MediaLoadingFill(icon: Icons.picture_as_pdf_rounded)
            : _error != null
                ? _MediaErrorPane(
                    icon: Icons.picture_as_pdf_rounded,
                    title: 'Lecture du document impossible',
                    message: _error!,
                    onRetry: () => setState(() => _error = null),
                  )
                : SfPdfViewer.network(
                    widget.url,
                    headers: _headers,
                    canShowScrollHead: false,
                    canShowScrollStatus: true,
                    enableDoubleTapZooming: true,
                    onDocumentLoadFailed: (details) {
                      if (!mounted) return;
                      setState(() => _error = details.description);
                    },
                  ),
      ),
    );
  }
}

/// Image plein cadre avec pinch-to-zoom (PhotoView). Token d'auth optionnel.
class _InlineImagePlayer extends StatefulWidget {
  const _InlineImagePlayer({required this.url});
  final String url;

  @override
  State<_InlineImagePlayer> createState() => _InlineImagePlayerState();
}

class _InlineImagePlayerState extends State<_InlineImagePlayer> {
  Map<String, String>? _headers;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final token = await const AuthTokenStore().readTokenOrNull();
    if (!mounted) return;
    setState(() {
      _headers = token == null ? null : {'Authorization': 'Bearer $token'};
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 360,
        color: AppColors.surfaceHigh,
        child: !_ready
            ? const _MediaLoadingFill(icon: Icons.image_outlined)
            : PhotoView(
                imageProvider: NetworkImage(widget.url, headers: _headers),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 4,
                backgroundDecoration: const BoxDecoration(color: Colors.black),
                loadingBuilder: (context, event) =>
                    const _MediaLoadingFill(icon: Icons.image_outlined),
                errorBuilder: (_, __, ___) => Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.hintColor,
                    size: 42,
                  ),
                ),
              ),
      ),
    );
  }
}
