part of '../home_profile_tab.dart';


// ignore: unused_element
class _PortfolioOverviewCard extends StatelessWidget {
  const _PortfolioOverviewCard({
    required this.manager,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onOpenLink,
  });

  final HomeProfileManager manager;
  final VoidCallback onAdd;
  final ValueChanged<HomePortfolioItem> onEdit;
  final ValueChanged<HomePortfolioItem> onDelete;
  final ValueChanged<String> onOpenLink;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (manager.isLoadingPortfolio.value && manager.portfolioItems.isEmpty) {
        return const _InlineLoader(label: 'Chargement du portfolio...');
      }

      return _SectionCard(
        icon: Icons.workspaces_outlined,
        color: AppColors.categoryPink,
        title: 'Projets & portfolio',
        subtitle: 'Visible par les entreprises selon chaque projet',
        child: manager.portfolioLoadError.value.isNotEmpty &&
                manager.portfolioItems.isEmpty
            ? _InlineMessageCard(
                icon: Icons.warning_amber_rounded,
                color: AppColors.warning,
                message: manager.portfolioLoadError.value,
                actionLabel: 'Recharger',
                onAction: manager.loadPortfolio,
              )
            : manager.portfolioItems.isEmpty
                ? _InlineMessageCard(
                    icon: Icons.collections_bookmark_outlined,
                    color: AppColors.categoryPink,
                    message:
                        'Ajoutez vos projets avec captures, demo, stack et resultats.',
                    actionLabel: 'Ajouter un projet',
                    onAction: onAdd,
                  )
                : Column(
                    children: [
                      ...manager.portfolioItems.asMap().entries.map(
                            (entry) => Padding(
                              padding: EdgeInsets.only(
                                bottom: entry.key ==
                                        manager.portfolioItems.length - 1
                                    ? 0
                                    : 14,
                              ),
                              child: _ProjectCard(
                                item: entry.value,
                                onEdit: () => onEdit(entry.value),
                                onDelete: () => onDelete(entry.value),
                                onOpenLink:
                                    entry.value.externalUrl.trim().isEmpty
                                        ? null
                                        : () => onOpenLink(
                                              entry.value.externalUrl,
                                            ),
                              ),
                            ),
                          ),
                      const SizedBox(height: 12),
                      _AddMoreButton(
                        label: '+ Ajouter encore',
                        onTap: onAdd,
                      ),
                    ],
                  ),
      );
    });
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.child,
    this.action,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SquareIconBadge(icon: icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.titleLg),
                    Text(subtitle, style: AppTextStyles.bodySm),
                  ],
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _CvCard extends StatelessWidget {
  const _CvCard({
    required this.section,
    required this.onEdit,
    required this.onDelete,
  });

  final HomeCvSection section;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(section.title, style: AppTextStyles.titleLg),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Modifier')),
                  PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                ],
              ),
            ],
          ),
          Text(
            [
              if (section.organization.trim().isNotEmpty) section.organization,
              _cvDates(section),
            ].where((entry) => entry.trim().isNotEmpty).join(' • '),
            style: AppTextStyles.bodySm,
          ),
          if (section.description.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(section.description, style: AppTextStyles.bodyMd),
          ],
          if (section.level.trim().isNotEmpty ||
              section.mention.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (section.level.trim().isNotEmpty)
                  _MiniInfoPill(label: section.level.trim()),
                if (section.mention.trim().isNotEmpty)
                  _MiniInfoPill(label: section.mention.trim()),
              ],
            ),
          ],
          if ([...section.missions, ...section.achievements].isNotEmpty) ...[
            const SizedBox(height: 8),
            ...[...section.missions, ...section.achievements].take(4).map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: AppTextStyles.bodyMd),
                        Expanded(
                            child: Text(item, style: AppTextStyles.bodyMd)),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  String _cvDates(HomeCvSection section) {
    final formatter = DateFormat('MM/yyyy');
    final start =
        section.startDate == null ? '' : formatter.format(section.startDate!);
    final end = section.isCurrent
        ? 'En cours'
        : section.endDate == null
            ? ''
            : formatter.format(section.endDate!);
    if (start.isEmpty && end.isEmpty) {
      return '';
    }
    if (start.isEmpty) {
      return end;
    }
    if (end.isEmpty) {
      return start;
    }
    return '$start - $end';
  }
}

class _MiniInfoPill extends StatelessWidget {
  const _MiniInfoPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.categoryBlueSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySm.copyWith(
          color: AppColors.categoryBlue,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onOpenLink,
  });

  final HomePortfolioItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onOpenLink;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(item.title, style: AppTextStyles.titleLg)),
              _PortfolioVisibilityPill(isPublic: item.isPublic),
              const SizedBox(width: 6),
              PopupMenuButton<String>(
                onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Modifier')),
                  PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                ],
              ),
            ],
          ),
          if (item.description.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(item.description, style: AppTextStyles.bodyMd),
          ],
          if (item.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: item.mediaUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  return _PortfolioMediaTile(url: item.mediaUrls[index]);
                },
              ),
            ),
          ],
          if (item.techStack.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: item.techStack
                  .map(
                    (tech) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.categoryBlueSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        tech,
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.categoryBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          if (item.results.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                item.results,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.successStrong,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (onOpenLink != null) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onOpenLink,
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Ouvrir le lien'),
            ),
          ],
        ],
      ),
    );
  }
}

class _PortfolioVisibilityPill extends StatelessWidget {
  const _PortfolioVisibilityPill({required this.isPublic});

  final bool isPublic;

  @override
  Widget build(BuildContext context) {
    final color = isPublic ? AppColors.successStrong : AppColors.bodyColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isPublic ? AppColors.successSoft : AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isPublic ? 'Visible' : 'Prive',
        style: AppTextStyles.bodySm.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _PortfolioMediaTile extends StatelessWidget {
  const _PortfolioMediaTile({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final isImage = _looksLikeImageUrl(url);
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 130,
        child: isImage
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _FileMediaPlaceholder(url: url),
              )
            : _FileMediaPlaceholder(url: url),
      ),
    );
  }

  bool _looksLikeImageUrl(String rawUrl) {
    final path = Uri.tryParse(rawUrl)?.path.toLowerCase() ?? rawUrl;
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.webp') ||
        path.endsWith('.gif');
  }
}

class _FileMediaPlaceholder extends StatelessWidget {
  const _FileMediaPlaceholder({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final pathSegments = Uri.tryParse(url)?.pathSegments ?? const <String>[];
    final fileName = pathSegments.isEmpty ? url : pathSegments.last;
    return Container(
      color: AppColors.surfaceContainer,
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.insert_drive_file_outlined),
          const SizedBox(height: 8),
          Text(
            fileName.isEmpty ? 'Fichier' : fileName,
            style: AppTextStyles.bodySm,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

