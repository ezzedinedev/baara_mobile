part of '../cv_import_screen.dart';

class _UploadStep extends StatelessWidget {
  const _UploadStep({required this.controller});
  final CvBuilderController controller;

  Future<void> _pickFile(BuildContext context) async {
    AppHaptics.tap();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'rtf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) {
      Get.snackbar(
        'Erreur',
        'Impossible de lire le fichier.',
        backgroundColor: AppColors.errorSoft,
        colorText: AppColors.errorStrong,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
      );
      return;
    }

    final ok = await controller.importAnalyze(
      file.name,
      Uint8List.fromList(file.bytes!),
    );
    if (!context.mounted) return;
    if (ok) {
      AppHaptics.success();
    } else {
      AppHaptics.error();
      Get.snackbar(
        'Analyse impossible',
        controller.errorMessage.value.isEmpty
            ? "Le fichier n'a pas pu être analysé."
            : controller.errorMessage.value,
        backgroundColor: AppColors.errorSoft,
        colorText: AppColors.errorStrong,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isAnalyzing = controller.isImportAnalyzing.value;

      return ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(22),
              boxShadow: AppColors.ambientShadow,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.onPrimary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.onPrimary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Améliore ton CV en 3 étapes',
                        style: AppTextStyles.titleLg.copyWith(
                          color: AppColors.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Envoie ton CV, l\'IA détecte les points faibles et propose une version réécrite.',
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.onPrimary.withValues(alpha: 0.9),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const _StepRow(
            number: 1,
            title: 'Analyse',
            subtitle: 'Score ATS, fautes, sections manquantes',
          ),
          const _StepRow(
            number: 2,
            title: 'Amélioration',
            subtitle: 'Réécriture par l\'IA, verbes d\'action, chiffrage',
          ),
          const _StepRow(
            number: 3,
            title: 'Téléchargement',
            subtitle: 'PDF amélioré ou fusion dans ton profil',
          ),
          const SizedBox(height: 22),
          DottedDropZone(
            onTap: isAnalyzing ? null : () => _pickFile(context),
            isLoading: isAnalyzing,
          ),
          const SizedBox(height: 16),
          Text(
            'Formats acceptés : PDF, DOCX, TXT, RTF — maximum 10 Mo.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.hintColor,
            ),
          ),
        ],
      );
    });
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  final int number;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.surfaceIconSoft,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: AppTextStyles.titleMd.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleMd),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.bodyColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DottedDropZone extends StatelessWidget {
  const DottedDropZone({
    super.key,
    required this.onTap,
    required this.isLoading,
  });

  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.4),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            if (isLoading) ...[
              const SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Analyse du CV en cours…',
                style: AppTextStyles.titleMd.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Cela peut prendre 15-30 secondes',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.bodyColor,
                ),
              ),
            ] else ...[
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: AppColors.surfaceIconSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.upload_file_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Choisir mon CV',
                style: AppTextStyles.titleLg,
              ),
              const SizedBox(height: 6),
              Text(
                'Appuie ici pour sélectionner un fichier',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.bodyColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

