import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:opportune_bf/app/core/constants/api_constants.dart';
import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/relative_time.dart';
import 'package:opportune_bf/app/core/widgets/common/app_card.dart';
import 'package:opportune_bf/app/core/widgets/common/brand_avatar.dart';
import '../../domain/entities/post.dart';

/// Carte de publication du fil Communauté — reprend fidèlement le design des
/// cartes réseau du web (`net-post`) : en-tête avatar 48 + nom/rôle/méta, badge
/// catégorie, corps, galerie/PDF, ligne de compteurs, barre à 3 actions séparée
/// par un filet. Couleurs via [AppColors] (dark mode automatique).
class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onRepost;
  final VoidCallback? onFollow;
  final VoidCallback? onTapAuthor;
  final VoidCallback? onReport;
  final VoidCallback? onDelete;

  const PostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onComment,
    this.onRepost,
    this.onFollow,
    this.onTapAuthor,
    this.onReport,
    this.onDelete,
  });

  static const _catLabels = {
    'emploi': 'Offre',
    'formation': 'Formation',
    'article': 'Article',
    'evenement': 'Événement',
  };
  static const _catIcons = {
    'emploi': Icons.work_outline_rounded,
    'formation': Icons.school_outlined,
    'article': Icons.edit_note_rounded,
    'evenement': Icons.event_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final hasBody = (post.body ?? '').trim().isNotEmpty;
    final images = post.images;
    final pdfs = post.pdfs;
    final showCounts = post.reactionsCount > 0 || post.commentsCount > 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          if (hasBody) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              post.body!.trim(),
              style: AppTextStyles.bodyMd.copyWith(
                height: 1.55,
                color: AppColors.titleColor,
              ),
            ),
          ],
          if (post.shared != null) _sharedBlock(),
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
          const Divider(height: 1, thickness: 1, color: AppColors.outlineVariant),
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
                  if (author?.isVerified ?? false) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified_rounded,
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
        if (author?.isSelf == true || onReport != null)
          SizedBox(
            width: 32,
            height: 32,
            child: PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.more_horiz_rounded,
                  size: 20, color: AppColors.hintColor),
              onSelected: (v) {
                if (v == 'delete' && onDelete != null) onDelete!.call();
                if (v == 'report' && onReport != null) onReport!.call();
              },
              itemBuilder: (_) {
                if (author?.isSelf == true) {
                  return [
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                          SizedBox(width: 10),
                          Text('Supprimer'),
                        ],
                      ),
                    ),
                  ];
                }
                return const [
                  PopupMenuItem<String>(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(Icons.flag_outlined, size: 18, color: AppColors.error),
                        SizedBox(width: 10),
                        Text('Signaler'),
                      ],
                    ),
                  ),
                ];
              },
            ),
          ),
      ],
    );
  }

  Widget _followButton() {
    return InkWell(
      onTap: onFollow,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('·  ',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.hintColor)),
            const Icon(Icons.add_rounded, size: 15, color: AppColors.primaryDark),
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
          isPublic ? Icons.public_rounded : Icons.people_alt_rounded,
          size: 12,
          color: AppColors.hintColor,
        ),
        if (post.category != 'general') ...[
          const SizedBox(width: 6),
          _categoryChip(),
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
        borderRadius: BorderRadius.circular(AppRadius.pill),
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
        borderRadius: BorderRadius.circular(AppRadius.sm),
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
                  style: AppTextStyles.labelLg.copyWith(color: AppColors.titleColor),
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
  Widget _gallery(List<PostMedia> images) {
    if (images.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: _img(images.first.url, height: 220),
      );
    }
    final shown = images.take(4).toList();
    final extra = images.length - shown.length;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (var i = 0; i < shown.length; i++)
            Stack(
              fit: StackFit.expand,
              children: [
                _img(shown[i].url),
                if (i == shown.length - 1 && extra > 0)
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
            ),
        ],
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
        child: Icon(Icons.broken_image_outlined,
            color: AppColors.hintColor),
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
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.errorSoft,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: const Icon(Icons.picture_as_pdf_rounded,
                  color: AppColors.error, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                pdf.name ?? 'Document.pdf',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelLg.copyWith(color: AppColors.titleColor),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.download_rounded,
                size: 18, color: AppColors.hintColor),
          ],
        ),
      ),
    );
  }

  // ── Compteurs ─────────────────────────────────────────────────────────
  Widget _countsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (post.reactionsCount > 0)
          Row(
            children: [
              const Icon(Icons.thumb_up_rounded, size: 13, color: AppColors.primary),
              const SizedBox(width: 4),
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
          child: _actionBtn(
            icon: post.isLiked
                ? Icons.thumb_up_rounded
                : Icons.thumb_up_outlined,
            label: "J'aime",
            active: post.isLiked,
            onTap: onLike,
          ),
        ),
        Expanded(
          child: _actionBtn(
            icon: Icons.mode_comment_outlined,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xs),
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
