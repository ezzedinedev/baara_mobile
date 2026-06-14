import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_motion.dart';
import 'package:opportune_bf/app/core/theme/app_shapes.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/utils/relative_time.dart';
import 'package:opportune_bf/app/core/widgets/common/brand_avatar.dart';
import 'package:opportune_bf/app/core/widgets/common/press_scale.dart';
import 'package:opportune_bf/app/core/widgets/common/emoji_picker_panel.dart';
import 'package:opportune_bf/app/core/widgets/effects/burst_effect.dart';
import 'package:opportune_bf/app/core/widgets/skeletons/message_tile_skeleton.dart';
import '../../domain/entities/community_comment.dart';
import '../../domain/entities/post.dart';
import '../controllers/community_controller.dart';
import 'rich_post_text.dart';

/// Ouvre la feuille des commentaires d'une publication (style web `net-comments`).
Future<void> showCommentSheet(
  BuildContext context,
  CommunityController controller,
  Post post,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceCard,
    shape: ContinuousRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppRadius.xxl * 1.7)),
    ),
    builder: (_) => _CommentSheet(controller: controller, post: post),
  );
}

class _CommentSheet extends StatefulWidget {
  const _CommentSheet({required this.controller, required this.post});

  final CommunityController controller;
  final Post post;

  @override
  State<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<_CommentSheet> {
  final _input = TextEditingController();
  final _comments = <CommunityComment>[];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  // Édition inline d'un commentaire.
  String? _editingId;
  final _editInput = TextEditingController();
  bool _savingEdit = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    _editInput.dispose();
    super.dispose();
  }

  void _startEdit(CommunityComment c) {
    AppHaptics.tap();
    setState(() {
      _editingId = c.id;
      _editInput.text = c.body;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingId = null;
      _editInput.clear();
    });
  }

  Future<void> _saveEdit(CommunityComment c) async {
    final text = _editInput.text.trim();
    if (text.isEmpty || _savingEdit) return;
    setState(() => _savingEdit = true);
    AppHaptics.tap();
    final updated = await widget.controller.editComment(c.id, text);
    if (!mounted) return;
    setState(() {
      _savingEdit = false;
      if (updated != null) {
        final idx = _comments.indexWhere((x) => x.id == c.id);
        if (idx >= 0) _comments[idx] = updated;
        _editingId = null;
        _editInput.clear();
      }
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await widget.controller.fetchComments(widget.post.id);
      if (!mounted) return;
      setState(() {
        _comments
          ..clear()
          ..addAll(list);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger les commentaires.';
      });
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    AppHaptics.tap();
    final comment = await widget.controller.addComment(widget.post.id, text);
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (comment != null) {
        _comments.add(comment);
        _input.clear();
      }
    });
  }

  /// Réaction (toggle) optimiste sur un commentaire ou une réponse.
  /// Met à jour l'état local immédiatement puis réaligne sur la réponse
  /// serveur ; rollback intégral en cas d'échec.
  Future<void> _toggleCommentReaction(CommunityComment c) async {
    AppHaptics.tap();
    final liked = c.myReaction != null;
    final optimistic = c.copyWith(
      reactionsCount: liked
          ? (c.reactionsCount - 1).clamp(0, 1 << 30)
          : c.reactionsCount + 1,
      myReaction: liked ? null : 'like',
      clearMyReaction: liked,
    );
    setState(() => _replaceComment(c.id, (_) => optimistic));

    final res = await widget.controller.reactComment(c.id);
    if (!mounted) return;
    if (res == null) {
      // Rollback : on remet l'état précédent.
      setState(() => _replaceComment(c.id, (_) => c));
      return;
    }
    final count = (res['reactions_count'] as num?)?.toInt();
    final mine = res['my_reaction']?.toString();
    setState(() {
      _replaceComment(
        c.id,
        (cur) => cur.copyWith(
          reactionsCount: count ?? cur.reactionsCount,
          myReaction: mine,
          clearMyReaction: mine == null,
        ),
      );
    });
  }

  /// Remplace un commentaire par son id (cherche aussi dans les réponses).
  void _replaceComment(
    String id,
    CommunityComment Function(CommunityComment current) update,
  ) {
    for (var i = 0; i < _comments.length; i++) {
      final top = _comments[i];
      if (top.id == id) {
        _comments[i] = update(top);
        return;
      }
      final ri = top.replies.indexWhere((r) => r.id == id);
      if (ri >= 0) {
        final replies = List<CommunityComment>.from(top.replies);
        replies[ri] = update(replies[ri]);
        _comments[i] = top.copyWith(replies: replies);
        return;
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog.adaptive(
        title: const Text('Supprimer'),
        content: const Text('Supprimer ce commentaire\u00a0?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Supprimer',
                style: TextStyle(color: AppColors.errorAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await widget.controller.removeComment(widget.post.id, commentId);
    if (!mounted) return;
    if (ok) {
      setState(() => _comments.removeWhere((c) => c.id == commentId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Column(
            children: [
              const SizedBox(height: AppSpacing.md),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
                child: Row(
                  children: [
                    Text('Commentaires',
                        style: AppTextStyles.titleLg
                            .copyWith(color: AppColors.titleColor)),
                    const Spacer(),
                    IconButton(
                      icon: Icon(IconlyLight.close_square,
                          color: AppColors.hintColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: AppColors.outlineVariant),
              Expanded(child: _list(scrollController)),
              _composer(),
            ],
          );
        },
      ),
    );
  }

  Widget _list(ScrollController scrollController) {
    if (_loading) {
      return ListView.separated(
        controller: scrollController,
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, __) => const MessageTileSkeleton(),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: AppTextStyles.bodyMd),
            const SizedBox(height: AppSpacing.md),
            TextButton(onPressed: _load, child: const Text('Réessayer')),
          ],
        ),
      );
    }
    if (_comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(IconlyLight.message, size: 44, color: AppColors.hintColor),
            const SizedBox(height: AppSpacing.sm),
            Text('Soyez le premier à commenter',
                style:
                    AppTextStyles.bodyMd.copyWith(color: AppColors.bodyColor)),
          ],
        ),
      );
    }
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _comments.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, i) => _commentTile(_comments[i]),
    );
  }

  Widget _commentTile(CommunityComment c, {bool isReply = false}) {
    final name = c.user?.fullName ?? 'Membre';
    final isMine = c.user?.isSelf == true;
    final avatarSize = isReply ? 28.0 : 36.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BrandAvatar(
          seed: c.user?.id ?? name,
          label: name,
          size: avatarSize,
          imageUrl: c.user?.avatarUrl,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: AppShapes.squircleRadius(AppRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelLg
                                .copyWith(color: AppColors.titleColor),
                          ),
                        ),
                        if (isMine) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.primaryAccent
                                  .withValues(alpha: 0.12),
                              borderRadius: AppShapes.pill,
                            ),
                            child: Text(
                              'Vous',
                              style: AppTextStyles.labelSm.copyWith(
                                color: AppColors.primaryAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 6),
                        Text(
                          relativeTimeFr(c.createdAt),
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.hintColor,
                            fontSize: 11,
                          ),
                        ),
                        if (isMine) ...[
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _startEdit(c),
                            child: Icon(IconlyLight.edit,
                                size: 15, color: AppColors.hintColor),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => _deleteComment(c.id),
                            child: Icon(IconlyLight.delete,
                                size: 16, color: AppColors.hintColor),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    if (_editingId == c.id)
                      _editField(c)
                    else
                      RichPostText(
                        text: c.body,
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.bodyColor,
                          height: 1.45,
                        ),
                      ),
                  ],
                ),
              ),
              _commentActions(c),
              if (c.replies.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                for (final reply in c.replies) ...[
                  _commentTile(reply, isReply: true),
                  if (reply != c.replies.last)
                    const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Ligne d'actions sous la bulle : bouton « J'aime » animé + compteur.
  Widget _commentActions(CommunityComment c) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, top: 4),
      child: Row(
        children: [
          _CommentLikeButton(
            liked: c.myReaction != null,
            count: c.reactionsCount,
            onTap: () => _toggleCommentReaction(c),
          ),
        ],
      ),
    );
  }

  Widget _editField(CommunityComment c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(height: 4),
        TextField(
          controller: _editInput,
          autofocus: true,
          minLines: 1,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.bodyColor),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.surfaceCard,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: AppShapes.squircleRadius(AppRadius.sm),
              borderSide: BorderSide(color: AppColors.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppShapes.squircleRadius(AppRadius.sm),
              borderSide: BorderSide(color: AppColors.outlineVariant),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: _cancelEdit,
              child: Text('Annuler',
                  style: AppTextStyles.labelMd
                      .copyWith(color: AppColors.hintColor)),
            ),
            TextButton(
              onPressed: _savingEdit ? null : () => _saveEdit(c),
              child: _savingEdit
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryAccent,
                      ),
                    )
                  : Text('Enregistrer',
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.primaryAccent,
                        fontWeight: FontWeight.w800,
                      )),
            ),
          ],
        ),
      ],
    );
  }

  /// Ouvre la banque d'emojis dans une feuille, liée au champ commentaire.
  void _openEmojiSheet() {
    AppHaptics.tap();
    FocusScope.of(context).unfocus();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: ContinuousRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (_) =>
          SafeArea(child: EmojiPickerPanel(controller: _input, height: 320)),
    );
  }

  Widget _composer() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          border: Border(
            top: BorderSide(color: AppColors.outlineVariant),
          ),
        ),
        child: Row(
          children: [
            Semantics(
              button: true,
              label: 'Emojis',
              child: PressScale(
                onTap: _openEmojiSheet,
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: Icon(Icons.emoji_emotions_outlined,
                      color: AppColors.hintColor, size: 24),
                ),
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: TextField(
                controller: _input,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Écrire un commentaire…',
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.surfaceLow,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Semantics(
              button: true,
              label: 'Envoyer le commentaire',
              child: PressScale(
                onTap: _send,
                child: Material(
                  color: AppColors.primary,
                  shape: const CircleBorder(),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.onPrimary),
                          )
                        : const Icon(IconlyLight.send,
                            color: AppColors.onPrimary, size: 19),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton « J'aime » d'un commentaire : cœur (IconlyLight/Bold), compteur, état
/// actif en [AppColors.primaryAccent] et micro-animation de scale au tap.
class _CommentLikeButton extends StatefulWidget {
  const _CommentLikeButton({
    required this.liked,
    required this.count,
    required this.onTap,
  });

  final bool liked;
  final int count;
  final VoidCallback onTap;

  @override
  State<_CommentLikeButton> createState() => _CommentLikeButtonState();
}

class _CommentLikeButtonState extends State<_CommentLikeButton>
    with SingleTickerProviderStateMixin {
  final _iconKey = GlobalKey();
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: AppMotion.fast,
  );

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _handleTap() {
    // Pulse : 1.0 → 1.3 → 1.0.
    _anim.forward().then((_) => _anim.reverse());
    // Burst au cœur SEULEMENT quand on AJOUTE le like (pas au retrait).
    final adding = !widget.liked;
    widget.onTap();
    if (adding) {
      final box = _iconKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        final center = box.localToGlobal(box.size.center(Offset.zero));
        showBurst(context, center, emoji: '❤️', particleCount: 8, spread: 36);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final liked = widget.liked;
    final color = liked ? AppColors.primaryAccent : AppColors.hintColor;
    return PressScale(
      onTap: _handleTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 1.3).animate(
                CurvedAnimation(parent: _anim, curve: Curves.easeOut),
              ),
              child: Icon(
                liked ? IconlyBold.heart : IconlyLight.heart,
                key: _iconKey,
                size: 16,
                color: color,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              widget.count > 0 ? '${widget.count}' : "J'aime",
              style: AppTextStyles.labelSm.copyWith(
                color: color,
                fontWeight: liked ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
