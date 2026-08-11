import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_dimens.dart';
import 'package:baara/app/core/theme/app_shapes.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/app/core/widgets/widgets.dart';
import 'dart:async';

import 'package:baara/app/features/profile/presentation/controllers/profile_controller.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/i_community_repository.dart';
import '../controllers/community_controller.dart';

/// Composer de publication plein écran (style Threads/Instagram) : texte,
/// images (galerie multi), document PDF, emojis, catégorie et visibilité.
/// S'appuie sur le support média déjà présent (`publish(mediaPaths:)`).
///
/// En mode **édition** ([editing] non nul) : préremplit le corps, change le
/// titre et publie via `editPost` (médias non modifiables ici).
class ComposePostScreen extends StatefulWidget {
  const ComposePostScreen({super.key, this.editing});

  final Post? editing;

  @override
  State<ComposePostScreen> createState() => _ComposePostScreenState();
}

class _ComposePostScreenState extends State<ComposePostScreen> {
  final _controller = Get.find<CommunityController>();
  final _text = TextEditingController();
  final _focus = FocusNode();
  final _fieldKey = GlobalKey();

  final _images = <XFile>[];
  String? _pdfPath;
  String? _pdfName;

  // ── Vidéo (mutuellement exclusive avec images/PDF/sondage) ─────────────────
  String? _videoPath;
  String? _videoName;
  VideoPlayerController? _videoPreview;

  String _category = 'general';
  String _visibility = 'public';
  bool _showEmojis = false;

  // ── Sondage ───────────────────────────────────────────────────────────────
  bool _pollEnabled = false;
  final _pollQuestion = TextEditingController();
  final _pollOptions = <_PollOptionField>[];
  bool _pollMultiple = false;
  static const _minPollOptions = 2;
  static const _maxPollOptions = 6;

  bool get _isEditing => widget.editing != null;

  // ── Autocomplétion @mentions ──────────────────────────────────────────────
  OverlayEntry? _mentionOverlay;
  Timer? _mentionDebounce;
  List<Mentionable> _mentionResults = const [];
  bool _mentionLoading = false;
  // Plage [start,end) du token @… en cours de saisie dans le texte.
  int _mentionStart = -1;
  int _mentionEnd = -1;
  // Noms mentionnés mémorisés pour l'envoi (best-effort).
  final _mentions = <String>{};

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    if (editing != null) {
      _text.text = editing.body ?? '';
      _category = editing.category;
      _visibility = editing.visibility;
    }
    _text.addListener(_onTextChanged);
  }

  static const _maxImages = 10;
  static const _categories = {
    'general': 'Général',
    'emploi': 'Offre',
    'formation': 'Formation',
    'article': 'Article',
    'evenement': 'Événement',
  };

  bool get _canPublish =>
      _text.text.trim().isNotEmpty ||
      _images.isNotEmpty ||
      _pdfPath != null ||
      _videoPath != null ||
      _hasValidPoll;

  /// Le sondage est valide : activé, et au moins 2 options non vides.
  bool get _hasValidPoll =>
      _pollEnabled &&
      _pollOptions.where((o) => o.controller.text.trim().isNotEmpty).length >=
          _minPollOptions;

  @override
  void dispose() {
    _mentionDebounce?.cancel();
    _removeMentionOverlay();
    _text.removeListener(_onTextChanged);
    _text.dispose();
    _focus.dispose();
    _pollQuestion.dispose();
    _videoPreview?.dispose();
    for (final o in _pollOptions) {
      o.dispose();
    }
    super.dispose();
  }

  // ── Sondage : activation et gestion des options ───────────────────────────
  void _togglePoll() {
    AppHaptics.tap();
    setState(() {
      _pollEnabled = !_pollEnabled;
      if (_pollEnabled) {
        // Sondage et média sont mutuellement exclusifs.
        _images.clear();
        _pdfPath = null;
        _pdfName = null;
        _clearVideo();
        if (_pollOptions.isEmpty) {
          _pollOptions
            ..add(_PollOptionField())
            ..add(_PollOptionField());
        }
      }
    });
  }

  void _addPollOption() {
    if (_pollOptions.length >= _maxPollOptions) return;
    AppHaptics.tap();
    setState(() => _pollOptions.add(_PollOptionField()));
  }

  void _removePollOption(int index) {
    if (_pollOptions.length <= _minPollOptions) return;
    AppHaptics.tap();
    setState(() {
      _pollOptions.removeAt(index).dispose();
    });
  }

  // ── Détection du token @… sous le curseur ────────────────────────────────
  void _onTextChanged() {
    final sel = _text.selection;
    if (!sel.isValid || !sel.isCollapsed) {
      _closeMentions();
      return;
    }
    final caret = sel.baseOffset;
    final text = _text.text;
    // Cherche le '@' le plus proche à gauche du curseur sans espace entre.
    var i = caret - 1;
    while (i >= 0) {
      final ch = text[i];
      if (ch == '@') break;
      if (ch == ' ' || ch == '\n' || ch == '\t') {
        i = -1;
        break;
      }
      i--;
    }
    if (i < 0) {
      _closeMentions();
      return;
    }
    // '@' doit être en début de texte ou précédé d'un séparateur.
    if (i > 0) {
      final before = text[i - 1];
      if (before != ' ' && before != '\n' && before != '\t') {
        _closeMentions();
        return;
      }
    }
    final query = text.substring(i + 1, caret);
    _mentionStart = i;
    _mentionEnd = caret;
    _scheduleMentionSearch(query);
  }

  void _scheduleMentionSearch(String query) {
    _mentionDebounce?.cancel();
    _mentionDebounce = Timer(const Duration(milliseconds: 250), () async {
      if (!mounted) return;
      setState(() => _mentionLoading = true);
      _showMentionOverlay();
      final results = await _controller.fetchMentionables(query);
      if (!mounted) return;
      setState(() {
        _mentionResults = results;
        _mentionLoading = false;
      });
      if (_mentionOverlay != null) _mentionOverlay!.markNeedsBuild();
    });
  }

  void _closeMentions() {
    _mentionDebounce?.cancel();
    _mentionStart = -1;
    _mentionEnd = -1;
    _mentionResults = const [];
    _removeMentionOverlay();
  }

  void _selectMention(Mentionable m) {
    if (_mentionStart < 0 || _mentionEnd < 0) return;
    final text = _text.text;
    final insert = '@${m.name} ';
    final newText = text.replaceRange(_mentionStart, _mentionEnd, insert);
    _mentions.add(m.name);
    _text.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: _mentionStart + insert.length),
    );
    _closeMentions();
    setState(() {});
  }

  void _showMentionOverlay() {
    if (_mentionOverlay != null) {
      _mentionOverlay!.markNeedsBuild();
      return;
    }
    final overlay = Overlay.of(context);
    final box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final offset = box.localToGlobal(Offset.zero);
    final width = box.size.width;
    _mentionOverlay = OverlayEntry(
      builder: (_) => Positioned(
        left: offset.dx,
        top: offset.dy + 36,
        width: width,
        child: _mentionList(),
      ),
    );
    overlay.insert(_mentionOverlay!);
  }

  void _removeMentionOverlay() {
    _mentionOverlay?.remove();
    _mentionOverlay = null;
  }

  Widget _mentionList() {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 220),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.outlineVariant),
          boxShadow: AppColors.lightShadow,
        ),
        child: _mentionLoading && _mentionResults.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: AppLoader(strokeWidth: 2),
                  ),
                ),
              )
            : _mentionResults.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      'Aucun membre',
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.hintColor),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _mentionResults.length,
                    itemBuilder: (_, i) {
                      final m = _mentionResults[i];
                      return ListTile(
                        dense: true,
                        leading: BrandAvatar(
                          seed: m.id,
                          label: m.name,
                          size: 32,
                          imageUrl: m.avatarUrl,
                        ),
                        title: Text(
                          m.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelLg
                              .copyWith(color: AppColors.titleColor),
                        ),
                        subtitle: (m.headline ?? '').isEmpty
                            ? null
                            : Text(
                                m.headline!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodySm
                                    .copyWith(color: AppColors.hintColor),
                              ),
                        onTap: () => _selectMention(m),
                      );
                    },
                  ),
      ),
    );
  }

  Future<void> _pickImages() async {
    AppHaptics.tap();
    try {
      final imgs = await ImagePicker()
          .pickMultiImage(maxWidth: 1600, maxHeight: 1600, imageQuality: 85);
      if (imgs.isEmpty) return;
      setState(() {
        for (final img in imgs) {
          if (_images.length >= _maxImages) break;
          _images.add(img);
        }
        _pdfPath = null; // image et PDF mutuellement exclusifs côté affichage
        _pdfName = null;
        _clearVideo(); // image et vidéo mutuellement exclusifs
        _pollEnabled = false; // média et sondage mutuellement exclusifs
      });
    } catch (_) {
      AppToast.error('Galerie inaccessible', 'Vérifiez les autorisations.');
    }
  }

  Future<void> _pickVideo() async {
    AppHaptics.tap();
    XFile? video;
    try {
      video = await ImagePicker().pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 3),
      );
    } catch (_) {
      AppToast.error('Galerie inaccessible', 'Vérifiez les autorisations.');
      return;
    }
    if (video == null) return;
    // Vidéo mutuellement exclusive avec images/PDF/sondage.
    final previous = _videoPreview;
    final controller = VideoPlayerController.file(File(video.path))
      ..setLooping(true)
      ..setVolume(0);
    setState(() {
      _videoPath = video!.path;
      _videoName = video.name;
      _videoPreview = controller;
      _images.clear();
      _pdfPath = null;
      _pdfName = null;
      _pollEnabled = false;
    });
    previous?.dispose();
    controller.initialize().then((_) {
      if (mounted && _videoPreview == controller) {
        setState(() {});
        controller.play();
      } else {
        controller.dispose();
      }
    }).catchError((_) {
      // Aperçu impossible : on garde le chemin (publiable), fallback visuel.
      if (mounted) setState(() {});
    });
  }

  void _clearVideo() {
    _videoPath = null;
    _videoName = null;
    _videoPreview?.dispose();
    _videoPreview = null;
  }

  Future<void> _pickPdf() async {
    AppHaptics.tap();
    FilePickerResult? result;
    try {
      result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
    } catch (_) {
      AppToast.error('Sélecteur indisponible', 'Vérifiez les autorisations.');
      return;
    }
    final path = result?.files.firstOrNull?.path;
    if (path == null) return;
    setState(() {
      _pdfPath = path;
      _pdfName = result?.files.first.name ?? 'Document.pdf';
      _images.clear();
      _clearVideo(); // PDF et vidéo mutuellement exclusifs
      _pollEnabled = false; // média et sondage mutuellement exclusifs
    });
  }

  // ── Assistant IA ───────────────────────────────────────────────────────────
  void _openAiSheet() {
    AppHaptics.tap();
    _closeMentions();
    FocusScope.of(context).unfocus();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _AiComposeSheet(
        controller: _controller,
        draft: _text.text.trim(),
        onReplaceText: _replaceComposerText,
        onAppendHashtag: _appendHashtag,
        onUseIdea: _useIdea,
      ),
    );
  }

  /// Remplace tout le texte du composer (improve/rephrase/shorten/expand).
  void _replaceComposerText(String value) {
    _text.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    setState(() {});
    AppToast.success('Texte mis à jour', 'Le brouillon a été remplacé.');
  }

  /// Ajoute un hashtag à la fin du texte (sans doublon brut).
  void _appendHashtag(String tag) {
    final current = _text.text;
    final needsSpace = current.isNotEmpty && !current.endsWith(' ');
    final next = '$current${needsSpace ? ' ' : ''}$tag ';
    _text.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    setState(() {});
  }

  /// Utilise une idée de post : insère le texte (si vide) ou l'ajoute.
  void _useIdea(String idea) {
    final current = _text.text.trim();
    final next = current.isEmpty ? idea : '$current\n\n$idea';
    _text.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    setState(() {});
  }

  Future<void> _publish() async {
    if (!_canPublish) return;
    AppHaptics.tap();
    _closeMentions();

    if (_isEditing) {
      final ok =
          await _controller.editPost(widget.editing!.id, _text.text.trim());
      if (ok) {
        AppToast.success('Modifié', 'Votre publication a été mise à jour.');
        if (mounted) Get.back<void>();
      } else {
        AppToast.error(
            'Échec', 'La modification n\'a pas pu être enregistrée.');
      }
      return;
    }

    final paths = <String>[
      ..._images.map((x) => x.path),
      if (_pdfPath != null) _pdfPath!,
      if (_videoPath != null) _videoPath!,
    ];
    PollDraft? poll;
    if (_hasValidPoll) {
      final options = _pollOptions
          .map((o) => o.controller.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      poll = PollDraft(
        question: _pollQuestion.text.trim().isEmpty
            ? null
            : _pollQuestion.text.trim(),
        options: options,
        multiple: _pollMultiple,
      );
    }
    final ok = await _controller.publish(
      body: _text.text.trim(),
      category: _category,
      visibility: _visibility,
      mediaPaths: paths,
      poll: poll,
    );
    if (ok) {
      AppToast.success('Publié', 'Votre publication est en ligne.');
      if (mounted) Get.back<void>();
    } else {
      AppToast.error('Échec', 'La publication n\'a pas pu être envoyée.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>().profile.value
        : null;
    final name = profile?.fullName.trim().isNotEmpty == true
        ? profile!.fullName
        : 'Vous';
    return Scaffold(
      backgroundColor: AppColors.surfaceCard,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceCard,
        elevation: 0,
        leading: IconButton(
          icon: Icon(AppIcons.closeSquare, color: AppColors.titleColor),
          onPressed: () => Get.back<void>(),
        ),
        title: Text(_isEditing ? 'Modifier' : 'Nouvelle publication',
            style: AppTextStyles.titleLg.copyWith(fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Center(
              child: Obx(() => TextButton(
                    onPressed: (_canPublish && !_controller.isPublishing.value)
                        ? _publish
                        : null,
                    style: TextButton.styleFrom(
                      backgroundColor: _canPublish
                          ? AppColors.primary
                          : AppColors.surfaceLow,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    child: _controller.isPublishing.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: AppLoader(
                              color: AppColors.onPrimary,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(_isEditing ? 'Enregistrer' : 'Publier',
                            style: AppTextStyles.labelLg.copyWith(
                              color: _canPublish
                                  ? AppColors.onPrimary
                                  : AppColors.hintColor,
                              fontWeight: FontWeight.w800,
                            )),
                  )),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
              children: [
                // Auteur
                Row(
                  children: [
                    BrandAvatar(
                        seed: profile?.email ?? name,
                        label: name,
                        size: 44,
                        imageUrl: profile?.avatarUrl),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleMd
                              .copyWith(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _chipsRow(),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  key: _fieldKey,
                  controller: _text,
                  focusNode: _focus,
                  autofocus: true,
                  minLines: 4,
                  maxLines: null,
                  maxLength: 2000,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() {}),
                  style: AppTextStyles.bodyLg
                      .copyWith(color: AppColors.titleColor, height: 1.5),
                  decoration: InputDecoration(
                    hintText: 'Quoi de neuf ?',
                    hintStyle: AppTextStyles.bodyLg
                        .copyWith(color: AppColors.hintColor),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                if (_images.isNotEmpty) _imagePreviews(),
                if (_pdfName != null) _pdfPreview(),
                if (_videoPath != null) _videoPreviewCard(),
                AnimatedSize(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: _pollEnabled
                      ? _pollEditor()
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
          if (_showEmojis) EmojiPickerPanel(controller: _text, height: 280),
          _toolbar(),
        ],
      ),
    );
  }

  Widget _chipsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _selectChip(
            icon: _visibility == 'public'
                ? Icons.public_rounded
                : AppIcons.network,
            label: _visibility == 'public' ? 'Public' : 'Mes relations',
            onTap: () => setState(() => _visibility =
                _visibility == 'public' ? 'connections' : 'public'),
          ),
          const SizedBox(width: AppSpacing.sm),
          _selectChip(
            icon: Icons.sell_outlined,
            label: _categories[_category] ?? 'Général',
            onTap: _pickCategory,
          ),
        ],
      ),
    );
  }

  void _pickCategory() {
    AppHaptics.tap();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.lg))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.md),
            for (final entry in _categories.entries)
              ListTile(
                title: Text(entry.value, style: AppTextStyles.titleMd),
                trailing: _category == entry.key
                    ? Icon(AppIcons.tickSquare,
                        color: AppColors.primaryAccent)
                    : null,
                onTap: () {
                  setState(() => _category = entry.key);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _selectChip(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: () {
        AppHaptics.tap();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primaryDark),
            const SizedBox(width: 6),
            Text(label,
                style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.titleColor, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _imagePreviews() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: SizedBox(
        height: 110,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _images.length,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (_, i) => Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Image.file(
                  File(_images[i].path),
                  width: 110,
                  height: 110,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => setState(() => _images.removeAt(i)),
                  child: const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.black54,
                    child: Icon(AppIcons.closeSquare,
                        size: 15, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pdfPreview() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(AppIcons.paper, color: AppColors.errorAccent, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(_pdfName ?? 'Document.pdf',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelLg
                      .copyWith(color: AppColors.titleColor)),
            ),
            GestureDetector(
              onTap: () => setState(() {
                _pdfPath = null;
                _pdfName = null;
              }),
              child: Icon(AppIcons.closeSquare, color: AppColors.hintColor),
            ),
          ],
        ),
      ),
    );
  }

  // ── Aperçu vidéo (carte squircle, 1re frame en lecture muette/boucle) ──────
  Widget _videoPreviewCard() {
    final v = _videoPreview;
    final ready = v != null && v.value.isInitialized;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: ClipRRect(
        borderRadius: AppShapes.squircleRadius(AppRadius.md),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: ready ? v.value.aspectRatio : 16 / 9,
              child: ready
                  ? VideoPlayer(v)
                  : Container(
                      color: AppColors.surfaceLow,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.movie_creation_outlined,
                              size: 34, color: AppColors.primaryDark),
                          const SizedBox(height: AppSpacing.sm),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              _videoName ?? 'Vidéo',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.labelMd
                                  .copyWith(color: AppColors.bodyColor),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            // Pastille « Vidéo » discrète bas-gauche.
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: AppShapes.pill,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(AppIcons.video, size: 13, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Vidéo',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            // Bouton retirer haut-droite.
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  AppHaptics.tap();
                  setState(_clearVideo);
                },
                child: const CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.black54,
                  child: Icon(AppIcons.closeSquare,
                      size: 17, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Éditeur de sondage ────────────────────────────────────────────────────
  Widget _pollEditor() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(AppIcons.chart,
                    size: 18, color: AppColors.primaryAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sondage',
                    style: AppTextStyles.labelLg.copyWith(
                      color: AppColors.titleColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _togglePoll,
                  child: Icon(AppIcons.closeSquare,
                      size: 20, color: AppColors.hintColor),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _pollQuestion,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.titleColor),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Question (optionnel)',
                hintStyle:
                    AppTextStyles.bodyMd.copyWith(color: AppColors.hintColor),
                filled: true,
                fillColor: AppColors.surfaceCard,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  borderSide: BorderSide(color: AppColors.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  borderSide: BorderSide(color: AppColors.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  borderSide:
                      BorderSide(color: AppColors.primaryAccent, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < _pollOptions.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _pollOptionField(i),
              ),
            if (_pollOptions.length < _maxPollOptions)
              TextButton.icon(
                onPressed: _addPollOption,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  minimumSize: const Size(0, 36),
                ),
                icon: Icon(AppIcons.add,
                    size: 18, color: AppColors.primaryAccent),
                label: Text(
                  'Ajouter une option',
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.primaryAccent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            Divider(height: AppSpacing.md, color: AppColors.outlineVariant),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Choix multiples',
                    style: AppTextStyles.labelMd
                        .copyWith(color: AppColors.bodyColor),
                  ),
                ),
                Switch.adaptive(
                  value: _pollMultiple,
                  activeTrackColor: AppColors.primaryAccent,
                  onChanged: (v) {
                    AppHaptics.tap();
                    setState(() => _pollMultiple = v);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pollOptionField(int index) {
    final canRemove = _pollOptions.length > _minPollOptions;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _pollOptions[index].controller,
            onChanged: (_) => setState(() {}),
            maxLength: 80,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.titleColor),
            decoration: InputDecoration(
              isDense: true,
              counterText: '',
              hintText: 'Option ${index + 1}',
              hintStyle:
                  AppTextStyles.bodyMd.copyWith(color: AppColors.hintColor),
              filled: true,
              fillColor: AppColors.surfaceCard,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.xs),
                borderSide: BorderSide(color: AppColors.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.xs),
                borderSide: BorderSide(color: AppColors.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.xs),
                borderSide:
                    BorderSide(color: AppColors.primaryAccent, width: 1.5),
              ),
            ),
          ),
        ),
        if (canRemove)
          IconButton(
            onPressed: () => _removePollOption(index),
            icon: Icon(Icons.remove_circle_outline_rounded,
                size: 20, color: AppColors.hintColor),
          ),
      ],
    );
  }

  Widget _toolbar() {
    return SafeArea(
      top: false,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          border: Border(top: BorderSide(color: AppColors.outlineVariant)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              if (!_isEditing) ...[
                _toolBtn(AppIcons.image, 'Galerie', _pickImages),
                _toolBtn(AppIcons.video, 'Vidéo', _pickVideo,
                    active: _videoPath != null),
                _toolBtn(Icons.attach_file_rounded, 'Document', _pickPdf),
                _toolBtn(AppIcons.chart, 'Sondage', _togglePoll,
                    active: _pollEnabled),
              ],
              _toolBtn(
                Icons.emoji_emotions_outlined,
                'Emoji',
                () {
                  setState(() => _showEmojis = !_showEmojis);
                  if (_showEmojis) {
                    _focus.unfocus(); // la banque prend la place du clavier
                  } else {
                    _focus.requestFocus();
                  }
                },
                active: _showEmojis,
              ),
              _aiToolBtn(),
            ],
          ),
        ),
      ),
    );
  }

  /// Bouton « Assistant IA » : pastille accent dédiée (étincelle + halo +
  /// badge « IA ») pour qu'il soit immédiatement identifiable dans la barre
  /// d'outils. Press spring via [PressScale]. Aucune logique modifiée.
  Widget _aiToolBtn() {
    final accent = AppColors.primaryAccent;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: PressScale(
        onTap: _openAiSheet,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accent.withValues(alpha: 0.18),
                accent.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: AppShapes.pill,
            border: Border.all(color: accent.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded, size: 18, color: accent),
              const SizedBox(width: 6),
              Text(
                'Assistant IA',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelMd.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolBtn(IconData icon, String label, VoidCallback onTap,
      {bool active = false}) {
    final color = active ? AppColors.primaryAccent : AppColors.bodyColor;
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20, color: color),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.labelMd.copyWith(color: color),
      ),
    );
  }
}

/// Champ d'une option de sondage dans l'éditeur (encapsule son contrôleur de
/// texte pour un cycle de vie propre lors des ajouts/suppressions).
class _PollOptionField {
  final TextEditingController controller = TextEditingController();

  void dispose() => controller.dispose();
}

// ── Assistant IA — bottom sheet ──────────────────────────────────────────────

/// Action proposée par l'assistant IA de rédaction.
class _AiAction {
  const _AiAction(this.id, this.label, this.icon, this.needsDraft);
  final String id;
  final String label;
  final IconData icon;

  /// L'action requiert un brouillon non vide (improve/rephrase/shorten/expand).
  final bool needsDraft;
}

const _aiActions = <_AiAction>[
  _AiAction('improve', 'Améliorer', Icons.auto_awesome_rounded, true),
  _AiAction('rephrase', 'Reformuler', Icons.cached_rounded, true),
  _AiAction('shorten', 'Raccourcir', AppIcons.paper, true),
  _AiAction('expand', 'Développer', AppIcons.paper, true),
  _AiAction('hashtags', 'Suggérer des hashtags', Icons.tag_rounded, true),
  _AiAction('ideas', 'Idées de post', Icons.lightbulb_outline_rounded, false),
];

/// Feuille de l'assistant IA : liste d'actions, puis état de chargement
/// premium et résultat (aperçu texte / chips hashtags / idées tappables).
class _AiComposeSheet extends StatefulWidget {
  const _AiComposeSheet({
    required this.controller,
    required this.draft,
    required this.onReplaceText,
    required this.onAppendHashtag,
    required this.onUseIdea,
  });

  final CommunityController controller;
  final String draft;
  final ValueChanged<String> onReplaceText;
  final ValueChanged<String> onAppendHashtag;
  final ValueChanged<String> onUseIdea;

  @override
  State<_AiComposeSheet> createState() => _AiComposeSheetState();
}

class _AiComposeSheetState extends State<_AiComposeSheet> {
  _AiAction? _active;
  bool _loading = false;
  // Résultat texte (improve/rephrase/shorten/expand).
  String? _textResult;
  // Suggestions (hashtags/ideas).
  List<String>? _suggestions;

  Future<void> _run(_AiAction action) async {
    final draft = widget.draft;
    if (action.needsDraft && draft.isEmpty) {
      AppToast.info(
          'Écrivez d\'abord', 'Saisissez un brouillon à transformer.');
      return;
    }
    AppHaptics.tap();
    setState(() {
      _active = action;
      _loading = true;
      _textResult = null;
      _suggestions = null;
    });
    final result = await widget.controller.aiCompose(draft, action.id);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result == null) {
        // Toast d'erreur déjà émis par le contrôleur.
        _active = null;
        return;
      }
      if (result.hasSuggestions) {
        _suggestions = result.suggestions;
      } else {
        _textResult = result.text;
      }
    });
  }

  void _reset() => setState(() {
        _active = null;
        _loading = false;
        _textResult = null;
        _suggestions = null;
      });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHandle(),
            const SizedBox(height: 14),
            _header(),
            const SizedBox(height: AppSpacing.lg),
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final showBack = _active != null;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryAccent.withValues(alpha: 0.14),
          ),
          child: Icon(Icons.auto_awesome_rounded,
              color: AppColors.primaryAccent, size: 22),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _active?.label ?? 'Assistant IA',
                style:
                    AppTextStyles.titleLg.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                showBack ? 'Résultat proposé' : 'Choisissez une action',
                style:
                    AppTextStyles.bodySm.copyWith(color: AppColors.hintColor),
              ),
            ],
          ),
        ),
        if (showBack && !_loading)
          IconButton(
            onPressed: _reset,
            icon: Icon(AppIcons.closeSquare, color: AppColors.hintColor),
          ),
      ],
    );
  }

  Widget _buildContent() {
    if (_active == null) return _actionList();
    if (_loading) return const _AiComposeSkeleton();
    if (_suggestions != null) {
      return _active!.id == 'hashtags'
          ? _hashtagsResult(_suggestions!)
          : _ideasResult(_suggestions!);
    }
    if (_textResult != null) return _textPreview(_textResult!);
    return const SizedBox(width: double.infinity);
  }

  Widget _actionList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final action in _aiActions)
          PressScale(
            onTap: () => _run(action),
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(action.icon, size: 20, color: AppColors.primaryAccent),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      action.label,
                      style: AppTextStyles.titleMd.copyWith(
                        color: AppColors.titleColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(AppIcons.arrowRight, color: AppColors.hintColor),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _textPreview(String result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 280),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceLow,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: SingleChildScrollView(
            child: Text(
              result,
              style: AppTextStyles.bodyMd
                  .copyWith(color: AppColors.titleColor, height: 1.55),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _reset,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                      color: AppColors.outlineVariant.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Annuler',
                  style: AppTextStyles.titleMd.copyWith(
                    color: AppColors.bodyColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  AppHaptics.success();
                  widget.onReplaceText(result);
                  Navigator.of(context).pop();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Remplacer',
                  style: AppTextStyles.titleMd.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _hashtagsResult(List<String> tags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Touchez un hashtag pour l\'ajouter à votre texte.',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.hintColor),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: tags.map((raw) {
            final tag = raw.startsWith('#') ? raw : '#$raw';
            return PressScale(
              onTap: () {
                AppHaptics.tap();
                widget.onAppendHashtag(tag);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                      color: AppColors.primaryAccent.withValues(alpha: 0.35)),
                ),
                child: Text(
                  tag,
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _ideasResult(List<String> ideas) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Touchez une idée pour l\'utiliser.',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.hintColor),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final idea in ideas)
          PressScale(
            onTap: () {
              AppHaptics.success();
              widget.onUseIdea(idea);
              Navigator.of(context).pop();
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline_rounded,
                      size: 18, color: AppColors.primaryAccent),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      idea,
                      style: AppTextStyles.bodyMd
                          .copyWith(color: AppColors.titleColor, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Skeleton « typing » pendant la génération IA dans le composer.
class _AiComposeSkeleton extends StatelessWidget {
  const _AiComposeSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SkeletonBox(height: 14, width: double.infinity),
        SizedBox(height: 10),
        SkeletonBox(height: 14, width: double.infinity),
        SizedBox(height: 10),
        SkeletonBox(height: 14, width: 200),
        SizedBox(height: 18),
      ],
    );
  }
}
