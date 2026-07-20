import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:photo_view/photo_view.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import 'package:jobaway/app/core/services/auth_token_store.dart';
import 'package:jobaway/app/core/theme/app_colors.dart';
import 'package:jobaway/app/core/theme/app_dimens.dart' show AppRadius;
import 'package:jobaway/app/core/theme/app_motion.dart';
import 'package:jobaway/app/core/theme/app_shapes.dart';
import 'package:jobaway/app/core/theme/app_text_styles.dart';
import 'package:jobaway/app/core/utils/haptics.dart';
import 'package:jobaway/app/core/widgets/widgets.dart';

import '../../domain/entities/training.dart';
import '../controllers/training_player_controller.dart';

/// Rayon squircle commun des cadres média (vidéo / PDF / image / Office) du
/// lecteur de leçon — langage 2026 (coins continus).
final BorderRadius _mediaRadius = AppShapes.squircleRadius(AppRadius.md);

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
          illustration: EmptyTrainingsIllustration(),
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
      // La barre de nav gère sa propre marge basse (SafeArea interne).
      bottom: false,
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

  Future<void> _onNext(
      TrainingModule lesson, int currentIndex, bool isLast) async {
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
      AppToast.error(
          'Lien invalide', 'Le lien de la ressource est indisponible.');
      return;
    }
    AppHaptics.tap();
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        AppToast.error('Ouverture impossible',
            'Aucune application ne peut ouvrir ce lien.');
      }
    } on Exception {
      AppToast.error(
          'Ouverture impossible', 'Aucune application ne peut ouvrir ce lien.');
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
              valueColor: AlwaysStoppedAnimation(AppColors.primaryAccent),
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
      decoration: ShapeDecoration(
        color: AppColors.surfaceCard,
        shape: AppShapes.cardBordered(
          AppColors.outlineVariant.withValues(alpha: 0.20),
        ),
        shadows: AppColors.lightShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  lesson.title,
                  style: AppTextStyles.titleMd
                      .copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (lesson.duration > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '${lesson.duration} min',
                  style:
                      AppTextStyles.bodySm.copyWith(color: AppColors.hintColor),
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
    // Barre de navigation des leçons en verre liquide (chrome sticky 2026).
    return GlassSurface(
      borderRadius: BorderRadius.zero,
      blurSigma: 18,
      specular: false,
      boxShadow: AppColors.ambientShadow,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPrev,
                icon: const Icon(IconlyLight.arrow_left_2),
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
      decoration: ShapeDecoration(
        color: color.withValues(alpha: 0.12),
        shape: AppShapes.squircle(AppRadius.xs),
      ),
      child: Text(
        lesson.typeLabel,
        style: AppTextStyles.labelMd.copyWith(color: color, letterSpacing: 0),
      ),
    );
  }
}

Color _lessonColor(TrainingModule lesson) {
  if (lesson.isVideo) return AppColors.primaryAccent;
  if (lesson.isPdf) return AppColors.errorBright;
  if (lesson.isImage) return AppColors.successDark;
  return AppColors.secondary;
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

    // YouTube : détecté par l'URL quel que soit le content_type backend, lu
    // avec le vrai lecteur YouTube (plein écran natif).
    final ytId = _youtubeId(url);
    if (ytId != null && ytId.isNotEmpty) {
      return _InlineYoutubePlayer(videoId: ytId);
    }

    // Word / PowerPoint / Excel : rendus via la visionneuse Office en ligne
    // (le viewer PDF natif ne sait pas les lire). Fichiers servis en URL
    // publique → le viewer Microsoft peut les récupérer.
    if (_isOfficeUrl(url)) {
      return _InlineOfficeViewer(url: url);
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

/// Vrai pour une URL de document Office (Word / PowerPoint / Excel).
/// Vérifie aussi que le domaine est cohérent avec le viewer Microsoft.
bool _isOfficeUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  final path = uri.path.toLowerCase();
  final isOfficeExt = path.endsWith('.doc') ||
      path.endsWith('.docx') ||
      path.endsWith('.ppt') ||
      path.endsWith('.pptx') ||
      path.endsWith('.xls') ||
      path.endsWith('.xlsx');
  if (!isOfficeExt) return false;
  return uri.scheme == 'https';
}

/// Ouvre [child] en plein écran (fond sombre, bouton fermer en haut à droite).
void _openFullscreen(BuildContext context, Widget child) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(child: child),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(IconlyLight.close_square,
                        color: Colors.white),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Petit bouton « plein écran » posé en surimpression sur un média inline.
class _FullscreenButton extends StatelessWidget {
  const _FullscreenButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      right: 8,
      child: Material(
        color: Colors.black54,
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: 'Plein écran',
          icon: const Icon(Icons.fullscreen_rounded,
              color: Colors.white, size: 22),
          onPressed: () {
            AppHaptics.tap();
            onTap();
          },
        ),
      ),
    );
  }
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({required this.lesson, required this.onOpen});
  final TrainingModule lesson;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      curve: AppMotion.spring,
      onTap: onOpen,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: ShapeDecoration(
          color: AppColors.surfaceCard,
          shape: AppShapes.cardBordered(
            AppColors.outlineVariant.withValues(alpha: 0.22),
          ),
          shadows: AppColors.lightShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                color: AppColors.primaryAccent.withValues(alpha: 0.12),
                shape: AppShapes.squircle(AppRadius.sm),
              ),
              child: Icon(Icons.link_rounded, color: AppColors.primaryAccent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ouvrir la ressource',
                    style: AppTextStyles.titleMd
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Le lien s\'ouvre dans votre navigateur.',
                    style: AppTextStyles.bodySm
                        .copyWith(color: AppColors.hintColor),
                  ),
                ],
              ),
            ),
            Icon(IconlyLight.arrow_right_2, color: AppColors.hintColor),
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
      decoration: ShapeDecoration(
        color: AppColors.surfaceCard,
        shape: AppShapes.cardBordered(
          AppColors.outlineVariant.withValues(alpha: 0.22),
        ),
        shadows: AppColors.lightShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: AppColors.warningAccent.withValues(alpha: 0.14),
              shape: AppShapes.squircle(AppRadius.md),
            ),
            child: Icon(
              Icons.cloud_off_rounded,
              color: AppColors.warningAccent,
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
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                color: AppColors.warningAccent.withValues(alpha: 0.14),
                shape: AppShapes.squircle(AppRadius.sm),
              ),
              child: Icon(icon, color: AppColors.warningAccent, size: 24),
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
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryAccent),
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
      final headers = token == null
          ? <String, String>{}
          : {'Authorization': 'Bearer $token'};
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
          aspectRatio:
              ctrl.value.aspectRatio == 0 ? 16 / 9 : ctrl.value.aspectRatio,
          materialProgressColors: ChewieProgressColors(
            playedColor: AppColors.primaryAccent,
            handleColor: AppColors.primaryAccent,
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
      borderRadius: _mediaRadius,
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
                  ? const _MediaLoadingFill(icon: IconlyLight.play)
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
      borderRadius: _mediaRadius,
      child: Container(
        height: 520,
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: _mediaRadius,
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.18),
          ),
        ),
        child: !_ready
            ? const _MediaLoadingFill(icon: IconlyLight.paper)
            : _error != null
                ? _MediaErrorPane(
                    icon: IconlyLight.paper,
                    title: 'Lecture du document impossible',
                    message: _error!,
                    onRetry: () => setState(() => _error = null),
                  )
                : Stack(
                    children: [
                      Positioned.fill(
                        child: SfPdfViewer.network(
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
                      _FullscreenButton(
                        onTap: () => _openFullscreen(
                          context,
                          SfPdfViewer.network(widget.url, headers: _headers),
                        ),
                      ),
                    ],
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

  Widget _photoView() => PhotoView(
        imageProvider: NetworkImage(widget.url, headers: _headers),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 4,
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        loadingBuilder: (context, event) =>
            const _MediaLoadingFill(icon: IconlyLight.image),
        errorBuilder: (_, __, ___) => Center(
          child: Icon(Icons.broken_image_outlined,
              color: AppColors.hintColor, size: 42),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: _mediaRadius,
      child: Container(
        height: 360,
        color: AppColors.surfaceHigh,
        child: !_ready
            ? const _MediaLoadingFill(icon: IconlyLight.image)
            : Stack(
                children: [
                  Positioned.fill(child: _photoView()),
                  _FullscreenButton(
                    onTap: () => _openFullscreen(context, _photoView()),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Extrait l'identifiant vidéo d'une URL YouTube (watch / youtu.be / embed /
/// shorts). Renvoie `null` si l'URL n'est pas YouTube.
String? _youtubeId(String url) {
  final reg = RegExp(
    r'(?:youtube\.com\/(?:watch\?v=|embed\/|shorts\/|live\/)|youtu\.be\/)([A-Za-z0-9_-]{11})',
    caseSensitive: false,
  );
  final m = reg.firstMatch(url);
  return m?.group(1);
}

/// Lecteur YouTube intégré (youtube_player_flutter). Plein écran natif géré
/// par [YoutubePlayerBuilder] (rotation paysage + retour).
class _InlineYoutubePlayer extends StatefulWidget {
  const _InlineYoutubePlayer({required this.videoId});
  final String videoId;

  @override
  State<_InlineYoutubePlayer> createState() => _InlineYoutubePlayerState();
}

class _InlineYoutubePlayerState extends State<_InlineYoutubePlayer> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(showFullscreenButton: true),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: _mediaRadius,
      child: YoutubePlayer(
        controller: _controller,
        aspectRatio: 16 / 9,
      ),
    );
  }
}

/// Visionneuse Office (Word / PowerPoint / Excel) via le viewer Microsoft en
/// ligne, rendu dans un WebView. Bouton plein écran. Requiert une URL de
/// fichier publiquement accessible (le viewer Microsoft la récupère).
class _InlineOfficeViewer extends StatelessWidget {
  const _InlineOfficeViewer({required this.url});
  final String url;

  static String _viewerUrl(String docUrl) =>
      'https://view.officeapps.live.com/op/embed.aspx?src='
      '${Uri.encodeComponent(docUrl)}';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: _mediaRadius,
      child: Container(
        height: 520,
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: _mediaRadius,
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.18),
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: _OfficeWebView(viewerUrl: _viewerUrl(url))),
            _FullscreenButton(
              onTap: () => _openFullscreen(
                context,
                _OfficeWebView(viewerUrl: _viewerUrl(url)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// WebView qui charge le viewer Office en ligne, avec skeleton tant que la
/// page n'est pas prête et panneau d'erreur si le chargement échoue.
class _OfficeWebView extends StatefulWidget {
  const _OfficeWebView({required this.viewerUrl});
  final String viewerUrl;

  @override
  State<_OfficeWebView> createState() => _OfficeWebViewState();
}

class _OfficeWebViewState extends State<_OfficeWebView> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (!request.url.startsWith('https://view.officeapps.live.com')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (_) {
            if (mounted) {
              setState(() {
                _loading = false;
                _error = true;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.viewerUrl));
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return _MediaErrorPane(
        icon: IconlyLight.paper,
        title: 'Document illisible',
        message:
            'Ce document n\'a pas pu être affiché. Vérifie ta connexion puis réessaie.',
        onRetry: () {
          setState(() {
            _error = false;
            _loading = true;
          });
          _controller.loadRequest(Uri.parse(widget.viewerUrl));
        },
      );
    }
    return Stack(
      children: [
        Positioned.fill(child: WebViewWidget(controller: _controller)),
        if (_loading)
          const Positioned.fill(
            child: _MediaLoadingFill(icon: IconlyLight.paper),
          ),
      ],
    );
  }
}
