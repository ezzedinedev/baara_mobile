import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:opportune_bf/app/core/constants/api_constants.dart';
import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_motion.dart';
import 'package:opportune_bf/app/core/theme/app_shapes.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/relative_time.dart';
import 'package:opportune_bf/app/core/widgets/common/app_card.dart';
import 'package:opportune_bf/app/core/widgets/common/brand_avatar.dart';
import 'package:opportune_bf/app/core/widgets/common/press_scale.dart';
import 'ai_post_sheets.dart';
import '../../domain/entities/post.dart';
import 'poll_view.dart';
import 'post_video_player.dart';
import 'reaction_button.dart';
import 'rich_post_text.dart';

/// Carte de publication du fil Communauté — reprend fidèlement le design des
/// cartes réseau du web (`net-post`) : en-tête avatar 48 + nom/rôle/méta, badge
/// catégorie, corps, galerie/PDF, ligne de compteurs, barre à 3 actions séparée
/// par un filet. Couleurs via [AppColors] (dark mode automatique).
class PostCard extends StatelessWidget {
  final Post post;

  /// Tap rapide « J'aime » (legacy). Si [onReact] est fourni, il a priorité.
  final VoidCallback? onLike;

  /// Réaction typée (like | love | bravo | instructif). Permet le picker
  /// d'appui long. Si fourni, le bouton réaction l'utilise pour le tap aussi.
  final void Function(String type)? onReact;
  final VoidCallback? onComment;
  final VoidCallback? onRepost;
  final VoidCallback? onFollow;
  final VoidCallback? onTapAuthor;
  final VoidCallback? onReport;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  /// Tap sur une option de sondage (l'id de l'option).
  final void Function(String optionId)? onVote;

  /// Tap sur le bouton « Enregistrer » (signet).
  final VoidCallback? onSave;

  const PostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onReact,
    this.onComment,
    this.onRepost,
    this.onFollow,
    this.onTapAuthor,
    this.onReport,
    this.onDelete,
    this.onEdit,
    this.onVote,
    this.onSave,
  });

  static const _catLabels = {
    'emploi': 'Offre',
    'formation': 'Formation',
    'article': 'Article',
    'evenement': 'Événement',
  };
  static const _catIcons = {
    'emploi': IconlyLight.work,
    'formation': Icons.school_outlined,
    'article': IconlyLight.edit,
    'evenement': IconlyLight.calendar,
  };

  @override
  Widget build(BuildContext context) {
    final hasBody = (post.body ?? '').trim().isNotEmpty;
    final images = post.images;
    final pdfs = post.pdfs;
    final videos = post.videos;
    final showCounts = post.reactionsCount > 0 || post.commentsCount > 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          if (hasBody) ...[
            const SizedBox(height: AppSpacing.md),
            RichPostText(
              text: post.body!.trim(),
              style: AppTextStyles.bodyMd.copyWith(
                height: 1.55,
                color: AppColors.titleColor,
              ),
            ),
          ],
          if (post.poll != null) ...[
            const SizedBox(height: AppSpacing.md),
            PollView(
              poll: post.poll!,
              onVote: onVote,
            ),
          ],
          if (post.linkPreview != null) ...[
            const SizedBox(height: AppSpacing.md),
            _LinkPreviewCard(preview: post.linkPreview!),
          ],
          if (post.shared != null) _sharedBlock(),
          if (videos.isNotEmpty && post.shared == null)
            for (final video in videos) ...[
              const SizedBox(height: AppSpacing.md),
              PostVideoPlayer(url: video.url, name: video.name),
            ],
          if (images.isNotEmpty && post.shared == null) ...[
            const SizedBox(height: AppSpacing.md),
            _gallery(images),
          ],
          if (pdfs.isNotEmpty && post.shared == null)
            for (final pdf in pdfs) ...[
              const SizedBox(height: AppSpacing.sm),
              _pdfTile(pdf),
            ],
          if (showCounts) ...[
            const SizedBox(height: AppSpacing.md),
            _countsRow(),
          ],
          const SizedBox(height: AppSpacing.sm),
          Divider(height: 1, thickness: 1, color: AppColors.outlineVariant),
          const SizedBox(height: AppSpacing.xs),
          _actions(),
        ],
      ),
    );
  }

  // ── En-tête ───────────────────────────────────────────────────────────
  Widget _header() {
    final author = post.author;
    final name = author?.fullName ?? 'Utilisateur';
    final canFollow = author != null && !author.isSelf && !author.isFollowing;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTapAuthor,
          child: BrandAvatar(
            seed: author?.id ?? name,
            label: name,
            size: 48,
            imageUrl: author?.avatarUrl,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: GestureDetector(
                      onTap: onTapAuthor,
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleMd.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.titleColor,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                  if (author?.isSelf == true) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent.withValues(alpha: 0.12),
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
                  if (author?.isVerified ?? false) ...[
                    const SizedBox(width: 4),
                    const Icon(IconlyBold.shield_done,
                        size: 15, color: AppColors.verified),
                  ],
                  if (canFollow) ...[
                    const SizedBox(width: 6),
                    _followButton(),
                  ],
                ],
              ),
              if ((author?.role ?? '').isNotEmpty) ...[
                const SizedBox(height: 1),
                Text(
                  author!.role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.hintColor,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 2),
              _metaLine(),
            ],
          ),
        ),
        Builder(
          builder: (context) => SizedBox(
            width: 32,
            height: 32,
            child: PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: Icon(IconlyLight.more_circle,
                  size: 20, color: AppColors.hintColor),
              onSelected: (v) {
                switch (v) {
                  case 'edit':
                    onEdit?.call();
                    break;
                  case 'delete':
                    onDelete?.call();
                    break;
                  case 'report':
                    onReport?.call();
                    break;
                  case 'summarize':
                    showPostSummarySheet(context, post.id);
                    break;
                  case 'translate':
                    showPostTranslateSheet(context, post.id);
                    break;
                }
              },
              itemBuilder: (_) => [
                // ── Assistant IA (lecture seule, sur toute publication) ──────
                _aiMenuItem(
                  value: 'summarize',
                  icon: IconlyLight.document,
                  label: 'Résumer (IA)',
                ),
                _aiMenuItem(
                  value: 'translate',
                  icon: IconlyLight.swap,
                  label: 'Traduire (IA)',
                ),
                if (author?.isSelf == true) ...[
                  const PopupMenuDivider(),
                  if (onEdit != null)
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(IconlyLight.edit,
                              size: 18, color: AppColors.bodyColor),
                          const SizedBox(width: 10),
                          const Text('Modifier'),
                        ],
                      ),
                    ),
                  if (onDelete != null)
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(IconlyLight.delete,
                              size: 18, color: AppColors.errorAccent),
                          const SizedBox(width: 10),
                          const Text('Supprimer'),
                        ],
                      ),
                    ),
                ] else if (onReport != null) ...[
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(IconlyLight.danger,
                            size: 18, color: AppColors.errorAccent),
                        const SizedBox(width: 10),
                        const Text('Signaler'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  PopupMenuItem<String> _aiMenuItem({
    required String value,
    required IconData icon,
    required String label,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryAccent),
          const SizedBox(width: 10),
          Text(label),
        ],
      ),
    );
  }

  Widget _followButton() {
    return InkWell(
      onTap: onFollow,
      borderRadius: AppShapes.pill,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('·  ',
                style:
                    AppTextStyles.bodySm.copyWith(color: AppColors.hintColor)),
            const Icon(IconlyLight.plus,
                size: 15, color: AppColors.primaryDark),
            const SizedBox(width: 2),
            Text(
              'Suivre',
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaLine() {
    final isPublic = post.visibility == 'public';
    return Row(
      children: [
        Flexible(
          child: Text(
            relativeTimeFr(post.createdAt),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.hintColor,
              fontSize: 11.5,
            ),
          ),
        ),
        const SizedBox(width: 5),
        Icon(
          isPublic ? Icons.public_rounded : IconlyLight.user_1,
          size: 12,
          color: AppColors.hintColor,
        ),
        if (post.category != 'general') ...[
          const SizedBox(width: 6),
          _categoryChip(),
        ],
        if (post.isEdited) ...[
          const SizedBox(width: 5),
          Text(
            '· modifié',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.hintColor,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _categoryChip() {
    final label = _catLabels[post.category] ?? post.category;
    final icon = _catIcons[post.category] ?? Icons.tag_rounded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.surfaceIconSoft,
        borderRadius: AppShapes.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.primaryDark),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ── Repost ────────────────────────────────────────────────────────────
  Widget _sharedBlock() {
    final sh = post.shared!;
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: AppShapes.squircleRadius(AppRadius.sm),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BrandAvatar(
                seed: sh.author?.id ?? 'shared',
                label: sh.author?.fullName ?? 'Membre',
                size: 28,
                imageUrl: sh.author?.avatarUrl,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  sh.author?.fullName ?? 'Membre',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelLg
                      .copyWith(color: AppColors.titleColor),
                ),
              ),
            ],
          ),
          if ((sh.body ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              sh.body!.trim(),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.bodyColor),
            ),
          ],
        ],
      ),
    );
  }

  // ── Galerie d'images ────────────────────────────────────────────────────
  /// Mosaïque média sans cellule vide (façon réseaux pro). La disposition
  /// dépend du nombre d'images ; cadre toujours plein (BoxFit.cover) et coins
  /// squircle. Au-delà de 4, overlay « +N » sur la dernière tuile.
  Widget _gallery(List<PostMedia> images) {
    final radius = AppShapes.squircleRadius(AppRadius.sm);
    const gap = 4.0;

    if (images.length == 1) {
      return ClipRRect(
        borderRadius: radius,
        child: _img(images.first.url, height: 240),
      );
    }

    if (images.length == 2) {
      return ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          height: 200,
          child: Row(
            children: [
              Expanded(child: _img(images[0].url)),
              const SizedBox(width: gap),
              Expanded(child: _img(images[1].url)),
            ],
          ),
        ),
      );
    }

    if (images.length == 3) {
      // Grande image à gauche + deux empilées à droite (rectangle plein).
      return ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          height: 260,
          child: Row(
            children: [
              Expanded(child: _img(images[0].url)),
              const SizedBox(width: gap),
              Expanded(
                child: Column(
                  children: [
                    Expanded(child: _img(images[1].url)),
                    const SizedBox(height: gap),
                    Expanded(child: _img(images[2].url)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 4 et + : grille 2×2 pleine, « +N » sur la dernière.
    final shown = images.take(4).toList();
    final extra = images.length - shown.length;
    Widget tile(int i) {
      final isLast = i == shown.length - 1 && extra > 0;
      return Stack(
        fit: StackFit.expand,
        children: [
          _img(shown[i].url),
          if (isLast)
            Container(
              color: Colors.black.withValues(alpha: 0.55),
              alignment: Alignment.center,
              child: Text(
                '+$extra',
                style: AppTextStyles.headlineSm.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: 260,
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: tile(0)),
                  const SizedBox(width: gap),
                  Expanded(child: tile(1)),
                ],
              ),
            ),
            const SizedBox(height: gap),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: tile(2)),
                  const SizedBox(width: gap),
                  Expanded(child: tile(3)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _img(String? url, {double? height}) {
    return Image.network(
      ApiConstants.resolveMediaUrl(url) ?? '',
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: height ?? 120,
        color: AppColors.surfaceLow,
        alignment: Alignment.center,
        child: Icon(Icons.broken_image_outlined, color: AppColors.hintColor),
      ),
    );
  }

  // ── Pièce jointe PDF ──────────────────────────────────────────────────
  Widget _pdfTile(PostMedia pdf) {
    return InkWell(
      onTap: () async {
        final url = ApiConstants.resolveMediaUrl(pdf.url);
        if (url == null || url.isEmpty) return;
        final uri = Uri.tryParse(url);
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      borderRadius: AppShapes.squircleRadius(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          borderRadius: AppShapes.squircleRadius(AppRadius.sm),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.errorSoft,
                borderRadius: AppShapes.squircleRadius(AppRadius.xs),
              ),
              child: Icon(IconlyLight.paper,
                  color: AppColors.errorAccent, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                pdf.name ?? 'Document.pdf',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    AppTextStyles.labelLg.copyWith(color: AppColors.titleColor),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(IconlyLight.download, size: 18, color: AppColors.hintColor),
          ],
        ),
      ),
    );
  }

  // ── Compteurs / résumé des réactions ──────────────────────────────────
  Widget _countsRow() {
    // Emojis présents (count > 0), dans l'ordre canonique. Fallback 👍 si le
    // backend ne renvoie pas encore le détail mais qu'il y a des réactions.
    final present = post.presentReactionTypes;
    final emojis = present.isNotEmpty
        ? [for (final t in present) kReactionEmojis[t] ?? ''].join()
        : (post.reactionsCount > 0 ? '👍' : '');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (post.reactionsCount > 0 && emojis.isNotEmpty)
          Row(
            children: [
              Text(emojis, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 5),
              Text(
                '${post.reactionsCount}',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.hintColor,
                  fontSize: 12.5,
                ),
              ),
            ],
          )
        else
          const SizedBox.shrink(),
        if (post.commentsCount > 0)
          Text(
            '${post.commentsCount} commentaire${post.commentsCount > 1 ? 's' : ''}',
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.hintColor,
              fontSize: 12.5,
            ),
          ),
      ],
    );
  }

  // ── Barre d'actions ─────────────────────────────────────────────────────
  Widget _actions() {
    return Row(
      children: [
        Expanded(
          child: ReactionButton(
            myReaction: post.myReaction,
            // Tap : réaction typée si dispo, sinon legacy onLike.
            onReact: (type) {
              if (onReact != null) {
                onReact!(type);
              } else if (type == 'like' && onLike != null) {
                onLike!();
              }
            },
          ),
        ),
        Expanded(
          child: _actionBtn(
            icon: IconlyLight.message,
            label: 'Commenter',
            onTap: onComment,
          ),
        ),
        Expanded(
          child: _actionBtn(
            icon: Icons.repeat_rounded,
            label: 'Republier',
            onTap: onRepost,
          ),
        ),
        if (onSave != null) _SaveButton(saved: post.isSaved, onTap: onSave!),
      ],
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    bool active = false,
    VoidCallback? onTap,
  }) {
    final color = active ? AppColors.primaryDark : AppColors.hintColor;
    return PressScale(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelMd.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte d'aperçu de lien (Open Graph) : image + titre + domaine. Cliquable.
class _LinkPreviewCard extends StatelessWidget {
  const _LinkPreviewCard({required this.preview});

  final PostLinkPreview preview;

  Future<void> _open() async {
    final uri = Uri.tryParse(preview.url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = (preview.image ?? '').isNotEmpty;
    final title = (preview.title ?? '').trim();
    return PressScale(
      onTap: _open,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          borderRadius: AppShapes.squircleRadius(AppRadius.sm),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasImage)
              CachedNetworkImage(
                imageUrl: preview.image!,
                height: 170,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 170,
                  color: AppColors.surfaceIconSoft,
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 170,
                  color: AppColors.surfaceIconSoft,
                  alignment: Alignment.center,
                  child: Icon(Icons.link_rounded, color: AppColors.hintColor),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.public_rounded,
                          size: 13, color: AppColors.hintColor),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          preview.domain,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.hintColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (title.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelLg.copyWith(
                        color: AppColors.titleColor,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ],
                  if ((preview.description ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      preview.description!.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.bodyColor),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton signet « Enregistrer » avec animation bounce au tap.
class _SaveButton extends StatefulWidget {
  const _SaveButton({required this.saved, required this.onTap});

  final bool saved;
  final VoidCallback onTap;

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: AppMotion.base,
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 45),
    TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 55),
  ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    _ctrl.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.saved ? AppColors.primaryAccent : AppColors.hintColor;
    return PressScale(
      onTap: _handleTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: ScaleTransition(
          scale: _scale,
          child: Icon(
            widget.saved ? IconlyBold.bookmark : IconlyLight.bookmark,
            size: 19,
            color: color,
          ),
        ),
      ),
    );
  }
}
