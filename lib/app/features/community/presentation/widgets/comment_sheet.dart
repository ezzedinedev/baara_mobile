import 'package:flutter/material.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/utils/relative_time.dart';
import 'package:opportune_bf/app/core/widgets/common/brand_avatar.dart';
import '../../domain/entities/community_comment.dart';
import '../../domain/entities/post.dart';
import '../controllers/community_controller.dart';

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
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
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

  Future<void> _deleteComment(String commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer'),
        content: const Text('Supprimer ce commentaire\u00a0?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: AppColors.error)),
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
                      icon: Icon(Icons.close_rounded, color: AppColors.hintColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(
                  height: 1, thickness: 1, color: AppColors.outlineVariant),
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
      return const Center(child: CircularProgressIndicator());
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
            Icon(Icons.mode_comment_outlined,
                size: 44, color: AppColors.hintColor),
            const SizedBox(height: AppSpacing.sm),
            Text('Soyez le premier à commenter',
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.bodyColor)),
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

  Widget _commentTile(CommunityComment c) {
    final name = c.user?.fullName ?? 'Membre';
    final isMine = c.user?.isSelf == true;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BrandAvatar(
          seed: c.user?.id ?? name,
          label: name,
          size: 36,
          imageUrl: c.user?.avatarUrl,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(AppRadius.md),
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
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text('Vous',
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.primary,
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
                        onTap: () => _deleteComment(c.id),
                        child: Icon(Icons.delete_outline,
                            size: 16, color: AppColors.hintColor),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  c.body,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.bodyColor,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Material(
              color: AppColors.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _send,
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: _sending
                      ? const Padding(
                          padding: EdgeInsets.all(11),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded,
                          color: AppColors.onPrimary, size: 19),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
