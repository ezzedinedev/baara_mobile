part of '../home_profile_tab.dart';

class _SquareIconBadge extends StatelessWidget {
  const _SquareIconBadge({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color),
    );
  }
}

// ignore: unused_element
class _CvOverviewCard extends StatelessWidget {
  const _CvOverviewCard({
    required this.manager,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onUploadCv,
    required this.onPreviewCv,
    required this.onTemplateChanged,
  });

  final HomeProfileManager manager;
  final VoidCallback onAdd;
  final ValueChanged<HomeCvSection> onEdit;
  final ValueChanged<HomeCvSection> onDelete;
  final VoidCallback onUploadCv;
  final VoidCallback onPreviewCv;
  final ValueChanged<String> onTemplateChanged;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (manager.isLoadingCv.value && manager.cvSections.isEmpty) {
        return const _InlineLoader(label: 'Chargement du CV...');
      }

      return _SectionCard(
        icon: Icons.description_outlined,
        color: AppColors.categoryPurple,
        title: 'CV interactif',
        subtitle: '${manager.cvSections.length} sections structurees',
        action: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              onPressed: manager.isPreviewingCv.value ? null : onPreviewCv,
              icon: manager.isPreviewingCv.value
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.visibility_outlined),
              label: const Text('Apercu'),
            ),
            TextButton.icon(
              onPressed:
                  manager.isExportingCv.value ? null : manager.exportCvPdf,
              icon: manager.isExportingCv.value
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded),
              label: const Text('Telecharger'),
            ),
          ],
        ),
        child: manager.cvLoadError.value.isNotEmpty &&
                manager.cvSections.isEmpty
            ? _InlineMessageCard(
                icon: Icons.warning_amber_rounded,
                color: AppColors.warning,
                message: manager.cvLoadError.value,
                actionLabel: 'Recharger',
                onAction: manager.loadCv,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CvTemplatePicker(
                    selected: manager.selectedCvTemplate.value,
                    onChanged: onTemplateChanged,
                  ),
                  const SizedBox(height: 12),
                  _UploadedCvTile(
                    uploadedCv: manager.uploadedCv.value,
                    isUploading: manager.isUploadingCvFile.value,
                    onUpload: onUploadCv,
                  ),
                  const SizedBox(height: 12),
                  if (manager.cvSections.isEmpty)
                    _InlineMessageCard(
                      icon: Icons.auto_awesome_outlined,
                      color: AppColors.categoryPurple,
                      message:
                          'Ajoutez vos experiences, formations et certifications.',
                      actionLabel: 'Creer le CV',
                      onAction: onAdd,
                    )
                  else ...[
                    ...manager.cvSections.asMap().entries.map(
                          (entry) => Padding(
                            padding: EdgeInsets.only(
                              bottom: entry.key == manager.cvSections.length - 1
                                  ? 0
                                  : 12,
                            ),
                            child: _CvCard(
                              section: entry.value,
                              onEdit: () => onEdit(entry.value),
                              onDelete: () => onDelete(entry.value),
                            ),
                          ),
                        ),
                    const SizedBox(height: 12),
                    _AddMoreButton(
                      label: '+ Ajouter encore',
                      onTap: onAdd,
                    ),
                  ],
                ],
              ),
      );
    });
  }
}

class _CvTemplatePicker extends StatelessWidget {
  const _CvTemplatePicker({
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Modele du CV', style: AppTextStyles.titleMd),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: HomeProfileManager.cvTemplateOptions
              .map(
                (template) => ChoiceChip(
                  label: Text(template.label),
                  selected: selected == template.id,
                  onSelected: (_) => onChanged(template.id),
                  selectedColor: AppColors.successSoft,
                  labelStyle: AppTextStyles.bodySm.copyWith(
                    color: selected == template.id
                        ? AppColors.successStrong
                        : AppColors.bodyColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _UploadedCvTile extends StatelessWidget {
  const _UploadedCvTile({
    required this.uploadedCv,
    required this.isUploading,
    required this.onUpload,
  });

  final HomeUploadedCv uploadedCv;
  final bool isUploading;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const _SquareIconBadge(
            icon: Icons.upload_file_outlined,
            color: AppColors.categoryBlue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CV importe', style: AppTextStyles.titleMd),
                const SizedBox(height: 2),
                Text(
                  uploadedCv.hasFile
                      ? (uploadedCv.fileName.isNotEmpty
                          ? uploadedCv.fileName
                          : uploadedCv.url)
                      : 'Ajoutez votre CV PDF, DOC ou DOCX.',
                  style: AppTextStyles.bodySm,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: isUploading ? null : onUpload,
            icon: isUploading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_rounded),
            label: Text(uploadedCv.hasFile ? 'Remplacer' : 'Importer'),
          ),
        ],
      ),
    );
  }
}

class _AddMoreButton extends StatelessWidget {
  const _AddMoreButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.add_rounded),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
