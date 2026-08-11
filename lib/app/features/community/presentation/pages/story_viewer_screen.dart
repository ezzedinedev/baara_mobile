import 'package:flutter/material.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_dimens.dart';
import 'package:baara/app/core/theme/app_motion.dart';
import 'package:baara/app/core/theme/app_shapes.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/app/core/widgets/widgets.dart';
import '../controllers/story_controller.dart';
import '../widgets/rich_post_text.dart';
import '../../domain/entities/story.dart';

/// segmentées, auto-avance, tap (préc./suiv.), maintien (pause), glissé bas
/// (fermer), réponse en privé et réactions.
class StoryViewerScreen extends StatefulWidget {
  const StoryViewerScreen({
    super.key,
    required this.buckets,
    required this.initialBucket,
  });

  final List<StoryBucket> buckets;
  final int initialBucket;

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  final _controller = Get.find<StoryController>();
  final _replyCtrl = TextEditingController();
  final _replyFocus = FocusNode();

  // Avancement (0..1) de la story active, alimenté par [_StoryContent]
  // (timer 6 s pour l'image, position pour la vidéo).
  final _progress = ValueNotifier<double>(0.0);
  int _bucketIndex = 0;
  int _storyIndex = 0;
  bool _showReactions = false;
  bool _paused = false;

  // Aperçu « vu par » (auteur) : data des viewers mise en cache par story.
  final Map<String, Map<String, dynamic>> _seenBy = {};

  StoryBucket get _bucket => widget.buckets[_bucketIndex];
  StoryItem get _story => _bucket.stories[_storyIndex];

  @override
  void initState() {
    super.initState();
    _bucketIndex = widget.initialBucket.clamp(0, widget.buckets.length - 1);
    _replyFocus.addListener(() {
      setState(() => _paused = _replyFocus.hasFocus || _showReactions);
    });
    _start();
  }

  @override
  void dispose() {
    _progress.dispose();
    _replyCtrl.dispose();
    _replyFocus.dispose();
    super.dispose();
  }

  void _start() {
    _progress.value = 0;
    _paused = false;
    _controller.markViewed(_story);
    if (_story.isMine) _loadSeenBy(_story.id);
  }

  Future<void> _loadSeenBy(String storyId) async {
    if (_seenBy.containsKey(storyId)) return;
    try {
      final data = await _controller.viewers(storyId);
      if (mounted) setState(() => _seenBy[storyId] = data);
    } catch (_) {}
  }

  void _next() {
    if (_storyIndex < _bucket.stories.length - 1) {
      setState(() => _storyIndex++);
      _start();
    } else {
      _nextBucket();
    }
  }

  void _nextBucket() {
    if (_bucketIndex < widget.buckets.length - 1) {
      setState(() {
        _bucketIndex++;
        _storyIndex = 0;
      });
      _start();
    } else {
      Get.back<void>();
    }
  }

  void _prev() {
    if (_storyIndex > 0) {
      setState(() => _storyIndex--);
      _start();
    } else if (_bucketIndex > 0) {
      setState(() {
        _bucketIndex--;
        _storyIndex = 0;
      });
      _start();
    } else {
      _start(); // déjà au début → on redémarre la story courante
    }
  }

  void _pause() => setState(() => _paused = true);
  void _resume() {
    if (_replyFocus.hasFocus || _showReactions) return;
    setState(() => _paused = false);
  }

  Future<void> _sendReply() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty) return;
    _replyCtrl.clear();
    _replyFocus.unfocus();
    final ok = await _controller.reply(_story.id, text);
    if (ok) AppToast.success('Réponse envoyée');
    _resume();
  }

  Future<void> _react(String type) async {
    setState(() => _showReactions = false);
    AppHaptics.success();
    await _controller.react(_story.id, type);
    AppToast.success('Réaction envoyée');
    _resume();
  }

  Future<void> _confirmDelete() async {
    _pause();
    final ok = await showConfirmSheet(
      context: context,
      icon: AppIcons.delete,
      iconColor: AppColors.errorAccent,
      title: 'Supprimer la story ?',
      message: 'Elle ne sera plus visible par personne.',
      confirmLabel: 'Supprimer',
      isDestructive: true,
    );
    if (ok == true) {
      await _controller.delete(_story.id);
      Get.back<void>();
    } else {
      _resume();
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) {
          if (_replyFocus.hasFocus) {
            _replyFocus.unfocus();
            return;
          }
          if (_showReactions) {
            setState(() => _showReactions = false);
            _resume();
            return;
          }
          d.globalPosition.dx < w * 0.32 ? _prev() : _next();
        },
        onLongPressStart: (_) => _pause(),
        onLongPressEnd: (_) => _resume(),
        onVerticalDragEnd: (d) {
          if ((d.primaryVelocity ?? 0) > 250) Get.back<void>();
        },
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v < -250) {
            _nextBucket();
          } else if (v > 250) {
            if (_bucketIndex > 0) {
              setState(() {
                _bucketIndex--;
                _storyIndex = 0;
              });
              _start();
            }
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            _media(),
            _topScrim(),
            _bottomScrim(),
            SafeArea(
              child: Column(
                children: [
                  _progressBars(),
                  _header(),
                  const Spacer(),
                  if (!_story.isText &&
                      _story.caption != null &&
                      _story.caption!.isNotEmpty)
                    _caption(),
                  if (_showReactions) _reactionPicker(),
                  _bottomBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Média (image Ken Burns OU vidéo) ──────────────────────────────────────
  Widget _media() {
    return _StoryContent(
      key: ValueKey('$_bucketIndex-$_storyIndex-${_story.id}'),
      story: _story,
      paused: _paused,
      onProgress: (v) => _progress.value = v,
      onCompleted: _next,
    );
  }

  Widget _topScrim() => const Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: 160,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black54, Colors.transparent],
            ),
          ),
        ),
      );

  Widget _bottomScrim() => const Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        height: 220,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black87, Colors.transparent],
            ),
          ),
        ),
      );

  // ── Barres de progression segmentées ──────────────────────────────────────
  // Fines (2.5 px), coins pill, transitions emphasized.
  Widget _progressBars() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
      child: Row(
        children: [
          for (var i = 0; i < _bucket.stories.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: ClipRRect(
                  borderRadius: AppShapes.pill,
                  child: SizedBox(
                    height: 2.5,
                    child: i < _storyIndex
                        ? const ColoredBox(color: AppColors.onPrimary)
                        : i > _storyIndex
                            ? ColoredBox(
                                color:
                                    AppColors.onPrimary.withValues(alpha: 0.3))
                            : ValueListenableBuilder<double>(
                                valueListenable: _progress,
                                builder: (_, v, __) =>
                                    TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: v, end: v),
                                  duration: AppMotion.short,
                                  curve: AppMotion.emphasized,
                                  builder: (_, anim, __) =>
                                      LinearProgressIndicator(
                                    value: anim,
                                    backgroundColor: AppColors.onPrimary
                                        .withValues(alpha: 0.3),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            AppColors.onPrimary),
                                  ),
                                ),
                              ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── En-tête (auteur + temps + actions) ────────────────────────────────────
  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 8, 0),
      child: Row(
        children: [
          // Hero lié depuis la tuile de la story bar (tag par utilisateur). Le
          // tag suit le bucket courant ; la navigation interne entre buckets se
          // fait par setState (pas de push), donc pas de conflit de tag.
          Hero(
            tag: 'story-avatar-${_bucket.user.id}',
            child: BrandAvatar(
              seed: _bucket.user.id,
              label: _bucket.user.name.isEmpty ? '?' : _bucket.user.name,
              imageUrl: _bucket.user.avatarUrl,
              size: 38,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _bucket.isMine ? 'Ma story' : _bucket.user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMd.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  _timeAgo(_story.createdAt),
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.onPrimary.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (_story.isMine)
            _RoundAction(
              icon: AppIcons.delete,
              onTap: _confirmDelete,
            ),
          _RoundAction(
              icon: AppIcons.closeSquare, onTap: () => Get.back<void>()),
        ],
      ),
    );
  }

  Widget _caption() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        // @mentions cliquables (ouvre le profil communauté via la recherche).
        child: RichPostText(
          text: _story.caption!,
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.onPrimary,
            height: 1.35,
            shadows: const [Shadow(blurRadius: 6, color: Colors.black54)],
          ),
        ),
      );

  // ── Picker de réactions (5 emojis) — encapsulé en GlassSurface (chrome) ──
  Widget _reactionPicker() {
    const emojis = {
      'love': '❤️',
      'like': '👍',
      'haha': '😂',
      'wow': '😮',
      'sad': '😢',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GlassSurface(
        borderRadius: AppShapes.pill,
        enableBlur: true,
        blurSigma: 18,
        tintAlpha: 0.45,
        color: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (final e in emojis.entries)
              PressScale(
                onTap: () => _react(e.key),
                curve: AppMotion.springEmphasized,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(e.value, style: const TextStyle(fontSize: 28)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Barre du bas : réponse ou (pour l'auteur) « vu par » enrichi ───────────
  Widget _bottomBar() {
    if (_story.isMine) {
      final data = _seenBy[_story.id];
      final viewers = (data?['viewers'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();
      final count = (data?['count'] as num?)?.toInt() ?? _story.viewsCount ?? 0;

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: PressScale(
          onTap: _openViewers,
          curve: AppMotion.spring,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (viewers.isNotEmpty)
                _StackedAvatars(viewers: viewers.take(3).toList())
              else
                const Icon(AppIcons.show,
                    size: 18, color: AppColors.onPrimary),
              const SizedBox(width: 10),
              Text(
                '$count vue${count > 1 ? 's' : ''}',
                style: AppTextStyles.titleMd.copyWith(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (_reactionSummary(viewers).isNotEmpty) ...[
                const SizedBox(width: 10),
                Text(
                  _reactionSummary(viewers),
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.onPrimary.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Barre de réponse — champ squircle pill + boutons actions
    return Padding(
      padding: EdgeInsets.fromLTRB(
          12, 4, 12, 12 + MediaQuery.of(context).viewInsets.bottom),
      child: Row(
        children: [
          Expanded(
            child: GlassSurface(
              borderRadius: AppShapes.pill,
              enableBlur: true,
              blurSigma: 16,
              tintAlpha: 0.18,
              color: Colors.white,
              borderColor: Colors.white24,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _replyCtrl,
                focusNode: _replyFocus,
                style:
                    AppTextStyles.bodyMd.copyWith(color: AppColors.onPrimary),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendReply(),
                decoration: InputDecoration(
                  hintText: 'Répondre en privé…',
                  hintStyle: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onPrimary.withValues(alpha: 0.7)),
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _RoundAction(
            icon: AppIcons.heart,
            onTap: () {
              setState(() => _showReactions = !_showReactions);
              _showReactions ? _pause() : _resume();
            },
          ),
          _RoundAction(icon: AppIcons.send, onTap: _sendReply),
        ],
      ),
    );
  }

  Future<void> _openViewers() async {
    _pause();
    final data = await _controller.viewers(_story.id);
    final viewers = (data['viewers'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: AppShapes.squircleRadius(AppRadius.xxl)),
      builder: (ctx) => GlassSurface(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl * 1.7),
        ),
        enableBlur: true,
        blurSigma: 20,
        tintAlpha: 0.88,
        specular: true,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SheetHandle(topPadding: 0),
                const SizedBox(height: 14),
                Text('${data['count'] ?? viewers.length} vue(s)',
                    style: AppTextStyles.titleLg
                        .copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                if (viewers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('Personne n\'a encore vu cette story.',
                          style: AppTextStyles.bodyMd
                              .copyWith(color: AppColors.hintColor)),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: viewers.length,
                      itemBuilder: (_, i) {
                        final v = viewers[i];
                        final reaction = v['reaction']?.toString();
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: BrandAvatar(
                            seed: v['id']?.toString() ?? '$i',
                            label: v['name']?.toString() ?? '?',
                            imageUrl: v['avatar_url']?.toString(),
                            size: 40,
                          ),
                          title: Text(v['name']?.toString() ?? '',
                              style: AppTextStyles.titleMd),
                          trailing: reaction != null
                              ? Text(_emojiFor(reaction),
                                  style: const TextStyle(fontSize: 20))
                              : null,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    _resume();
  }

  /// Résumé des réactions « ❤️ 2 · 👍 1 » (top 3 types).
  String _reactionSummary(List<Map<String, dynamic>> viewers) {
    final counts = <String, int>{};
    for (final v in viewers) {
      final r = v['reaction']?.toString();
      if (r != null && r.isNotEmpty) counts[r] = (counts[r] ?? 0) + 1;
    }
    if (counts.isEmpty) return '';
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .take(3)
        .map((e) => '${_emojiFor(e.key)} ${e.value}')
        .join(' · ');
  }

  String _emojiFor(String type) =>
      const {
        'love': '❤️',
        'like': '👍',
        'haha': '😂',
        'wow': '😮',
        'sad': '😢',
      }[type] ??
      '👍';

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    return 'il y a ${diff.inDays} j';
  }
}

// ── Bouton action arrondi squircle (chrome viewer) ────────────────────────
class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      curve: AppMotion.spring,
      child: Container(
        margin: const EdgeInsets.all(4),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.28),
          borderRadius: AppShapes.squircleRadius(AppRadius.md),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.14),
            width: 1,
          ),
        ),
        child: Icon(icon, color: AppColors.onPrimary, size: 20),
      ),
    );
  }
}

/// Mini-avatars empilés (chevauchement) — aperçu « vu par ».
class _StackedAvatars extends StatelessWidget {
  const _StackedAvatars({required this.viewers});
  final List<Map<String, dynamic>> viewers;

  @override
  Widget build(BuildContext context) {
    const size = 26.0;
    const overlap = 16.0;
    return SizedBox(
      width: size + (viewers.length - 1) * overlap,
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < viewers.length; i++)
            Positioned(
              left: i * overlap,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: AppShapes.squircleRadius(size / 2),
                  color: Colors.black,
                ),
                padding: const EdgeInsets.all(1.5),
                child: BrandAvatar(
                  seed: viewers[i]['id']?.toString() ?? '$i',
                  label: viewers[i]['name']?.toString() ?? '?',
                  imageUrl: viewers[i]['avatar_url']?.toString(),
                  size: size,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Contenu d'une story : image (Ken Burns + minuterie 6 s) ou vidéo (lecture +
/// progression liée à la durée). Pilote l'avancement via [onProgress] et
/// signale la fin via [onCompleted]. Réagit à [paused] (pause/reprise).
class _StoryContent extends StatefulWidget {
  const _StoryContent({
    super.key,
    required this.story,
    required this.paused,
    required this.onProgress,
    required this.onCompleted,
  });

  final StoryItem story;
  final bool paused;
  final ValueChanged<double> onProgress;
  final VoidCallback onCompleted;

  @override
  State<_StoryContent> createState() => _StoryContentState();
}

class _StoryContentState extends State<_StoryContent>
    with SingleTickerProviderStateMixin {
  static const _imageDuration = Duration(seconds: 6);

  AnimationController? _imageCtrl;
  VideoPlayerController? _video;
  bool _done = false;

  bool get _isVideo => widget.story.mediaType == 'video';

  @override
  void initState() {
    super.initState();
    _isVideo ? _initVideo() : _initImage();
  }

  void _initImage() {
    _imageCtrl = AnimationController(vsync: this, duration: _imageDuration)
      ..addListener(() => widget.onProgress(_imageCtrl!.value))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onCompleted();
      });
    if (!widget.paused) _imageCtrl!.forward();
  }

  void _initVideo() {
    final url = widget.story.mediaUrl;
    if (url == null || url.isEmpty) {
      widget.onCompleted();
      return;
    }
    final c = VideoPlayerController.networkUrl(Uri.parse(url));
    _video = c;
    c.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
      c.addListener(_onVideoTick);
      if (!widget.paused) c.play();
    }).catchError((_) {
      if (mounted) widget.onCompleted();
    });
  }

  void _onVideoTick() {
    final v = _video?.value;
    if (v == null || !v.isInitialized) return;
    final total = v.duration.inMilliseconds;
    if (total > 0) {
      widget.onProgress((v.position.inMilliseconds / total).clamp(0.0, 1.0));
      if (!_done && v.position >= v.duration) {
        _done = true;
        widget.onCompleted();
      }
    }
  }

  @override
  void didUpdateWidget(covariant _StoryContent old) {
    super.didUpdateWidget(old);
    if (widget.paused != old.paused) {
      if (widget.paused) {
        _imageCtrl?.stop();
        _video?.pause();
      } else {
        _imageCtrl?.forward();
        _video?.play();
      }
    }
  }

  @override
  void dispose() {
    _imageCtrl?.dispose();
    _video?.removeListener(_onVideoTick);
    _video?.dispose();
    super.dispose();
  }

  Color _parseBg(String? hex) {
    if (hex == null || hex.isEmpty) return AppColors.primary;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.story.mediaUrl;

    // Story TEXTE : fond coloré + légende centrée.
    if (url == null || url.isEmpty) {
      return Container(
        color: _parseBg(widget.story.backgroundColor),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        // Légende centrée + @mentions cliquables (style story texte conservé).
        child: RichPostText(
          text: widget.story.caption ?? '',
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineMd.copyWith(
            color: AppColors.onPrimary,
            fontWeight: FontWeight.w800,
            height: 1.3,
          ),
        ),
      );
    }

    if (_isVideo) {
      final c = _video;
      if (c == null || !c.value.isInitialized) {
        return ColoredBox(
          color: AppColors.onDark,
          child: const Center(
            child: AppLoader(color: AppColors.onPrimary, strokeWidth: 2),
          ),
        );
      }
      return FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: c.value.size.width,
          height: c.value.size.height,
          child: VideoPlayer(c),
        ),
      );
    }

    // Image avec Ken Burns subtil — courbe emphasizedDecelerate.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 1.08),
      duration: _imageDuration,
      curve: AppMotion.emphasizedDecelerate,
      builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (_, child, p) => p == null
            ? child
            : ColoredBox(
                color: AppColors.onDark,
                child: const Center(
                  child: AppLoader(color: AppColors.onPrimary, strokeWidth: 2),
                ),
              ),
        errorBuilder: (_, __, ___) => ColoredBox(
          color: AppColors.onDark,
          child: Center(
            child: Icon(
              Icons.broken_image_rounded,
              color: AppColors.onPrimary.withValues(alpha: 0.38),
              size: 48,
            ),
          ),
        ),
      ),
    );
  }
}
