part of '../home_training_flow.dart';

class FormationLessonScreen extends StatefulWidget {
  const FormationLessonScreen({
    super.key,
    required this.controller,
    required this.formation,
    required this.initialIndex,
  });

  final HomeController controller;
  final HomeFormationPreview formation;
  final int initialIndex;

  @override
  State<FormationLessonScreen> createState() => _FormationLessonScreenState();
}

class _FormationLessonScreenState extends State<FormationLessonScreen> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final formation = widget.controller.formationById(widget.formation.id) ??
          widget.formation;
      final modules = formation.modules;
      if (modules.isEmpty) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            foregroundColor: AppColors.titleColor,
          ),
          body: _EmptyLessonsBlock(formation: formation),
        );
      }

      final currentIndex = _index.clamp(0, modules.length - 1);
      final lesson = modules[currentIndex];
      final isFirst = currentIndex == 0;
      final isLast = currentIndex == modules.length - 1;

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
                formation.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySm,
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
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              _LessonMedia(
                lesson: lesson,
                onOpenAsset: () => _openLessonAsset(lesson),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Description', style: AppTextStyles.titleMd),
                    const SizedBox(height: 8),
                    Text(
                      lesson.description,
                      style: AppTextStyles.bodyMd.copyWith(height: 1.45),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isFirst
                          ? null
                          : () => setState(() => _index = currentIndex - 1),
                      icon: const Icon(Icons.chevron_left_rounded),
                      label: const Text('Precedent'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Obx(
                      () {
                        final isCompleting =
                            widget.controller.completingLessonId.value ==
                                lesson.id;
                        return GradientButton(
                          label: isLast ? 'TERMINER' : 'SUIVANT',
                          isLoading: isCompleting,
                          borderRadius: 8,
                          textColor: AppColors.onPrimary,
                          onPressed: isCompleting
                              ? null
                              : () async {
                                  final completed = await _completeLesson(
                                    formation,
                                    lesson,
                                  );
                                  if (!completed) {
                                    return;
                                  }
                                  if (isLast) {
                                    Get.snackbar(
                                      'Formation',
                                      'Progression mise a jour.',
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                    Get.back<void>();
                                    return;
                                  }
                                  setState(() => _index = currentIndex + 1);
                                },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Future<bool> _completeLesson(
    HomeFormationPreview formation,
    HomeTrainingLesson lesson,
  ) {
    return widget.controller.completeFormationLesson(formation, lesson);
  }
}

class _LessonTypePill extends StatelessWidget {
  const _LessonTypePill({required this.lesson});

  final HomeTrainingLesson lesson;

  @override
  Widget build(BuildContext context) {
    final color = _lessonColor(lesson);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        lesson.typeLabel,
        style: AppTextStyles.labelMd.copyWith(
          color: color,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _LessonMedia extends StatelessWidget {
  const _LessonMedia({
    required this.lesson,
    required this.onOpenAsset,
  });

  final HomeTrainingLesson lesson;
  final VoidCallback onOpenAsset;

  @override
  Widget build(BuildContext context) {
    final url = lesson.assetUrl.trim();
    final hasFileType = lesson.isPdf || lesson.isImage || lesson.isVideo;

    if (url.isEmpty) {
      // Lecon de type article : le contenu est dans la description ci-dessous,
      // pas dans un fichier — on n'affiche aucun bloc media.
      if (!hasFileType) return const SizedBox.shrink();
      // PDF / video / image attendus mais sans URL : on previent l'utilisateur.
      return _MediaUnavailableCard(lesson: lesson);
    }

    if (lesson.isPdf) {
      return _InlinePdfPlayer(url: url);
    }
    if (lesson.isImage) {
      return _InlineImagePlayer(url: url);
    }
    if (lesson.isVideo) {
      return _InlineVideoPlayer(url: url);
    }

    // Type article avec URL : on ouvre le contenu dans une visionneuse PDF
    // (la plupart des liens "article" pointent vers des documents).
    return _InlinePdfPlayer(url: url);
  }
}

class _MediaUnavailableCard extends StatelessWidget {
  const _MediaUnavailableCard({required this.lesson});

  final HomeTrainingLesson lesson;

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
            'Contenu non disponible',
            textAlign: TextAlign.center,
            style: AppTextStyles.titleMd.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Le formateur n\'a pas encore attache de fichier a "${lesson.title}".',
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

/// Lecteur video integre via Chewie. Initialise / dispose le controller
/// avec le cycle de vie du widget. Aucune sortie hors de l'app.
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
      Map<String, String> headers = const {};
      try {
        final token = await const AuthTokenStore().readToken();
        headers = {'Authorization': 'Bearer $token'};
      } catch (_) {
        // Pas de token : on lit en public.
      }
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
          aspectRatio: ctrl.value.aspectRatio == 0
              ? 16 / 9
              : ctrl.value.aspectRatio,
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
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Lecture impossible : ${_error!.replaceFirst('Exception: ', '')}',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                )
              : _chewie == null
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : Chewie(controller: _chewie!),
        ),
      ),
    );
  }
}

/// Visionneuse PDF inline (Syncfusion). Auth header injecte automatiquement
/// si le backend protege le storage. Pinch zoom + scroll, pas de telechargement.
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
    try {
      final token = await const AuthTokenStore().readToken();
      if (!mounted) return;
      setState(() {
        _headers = {'Authorization': 'Bearer $token'};
        _ready = true;
      });
    } catch (_) {
      if (!mounted) return;
      // Pas de token : on tente une lecture publique sans header.
      setState(() {
        _headers = null;
        _ready = true;
      });
    }
  }

  void _onLoadFailed(String message) {
    if (!mounted) return;
    setState(() => _error = message);
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
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _error != null
                ? _PdfErrorPane(message: _error!)
                : SfPdfViewer.network(
                    widget.url,
                    headers: _headers,
                    canShowScrollHead: false,
                    canShowScrollStatus: true,
                    enableDoubleTapZooming: true,
                    onDocumentLoadFailed: (details) {
                      _onLoadFailed(details.description);
                    },
                  ),
      ),
    );
  }
}

class _PdfErrorPane extends StatelessWidget {
  const _PdfErrorPane({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.warning.withValues(alpha: 0.14),
            ),
            child: const Icon(
              Icons.picture_as_pdf_rounded,
              color: AppColors.warning,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Lecture du PDF impossible',
            textAlign: TextAlign.center,
            style: AppTextStyles.titleMd.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
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

/// Image plein cadre avec pinch-to-zoom (PhotoView). Auth header optionnel.
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
    try {
      final token = await const AuthTokenStore().readToken();
      if (!mounted) return;
      setState(() {
        _headers = {'Authorization': 'Bearer $token'};
        _ready = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _ready = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 360,
        color: AppColors.surfaceHigh,
        child: !_ready
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : PhotoView(
                imageProvider: NetworkImage(widget.url, headers: _headers),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 4,
                backgroundDecoration: const BoxDecoration(color: Colors.black),
                loadingBuilder: (context, event) => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
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


