import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../controllers/profile_controller.dart';
import '../data/models/profile_model.dart';

/// Écran CV candidat — permet de lister, importer (PDF/DOCX), supprimer les CV
/// et définir le CV par défaut qui sera envoyé automatiquement au recruteur
/// lors d'une candidature.
class CvScreen extends GetView<ProfileController> {
  const CvScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.cvs.isEmpty && !controller.isLoadingCvs.value) {
        controller.loadCvs();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Mes CV', style: AppTextStyles.headlineSm),
        leading: IconButton(
          tooltip: 'Retour',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            AppHaptics.tap();
            Navigator.of(context).maybePop();
          },
        ),
      ),
      body: Obx(() {
        final cvs = controller.cvs;
        final isLoading = controller.isLoadingCvs.value;
        final errorMessage = controller.errorMessage.value;

        if (isLoading && cvs.isEmpty) {
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, __) => const MessageTileSkeleton(),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.loadCvs,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _InfoCard(),
              const SizedBox(height: 18),
              if (cvs.isEmpty && errorMessage.isEmpty)
                Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.sizeOf(context).height * 0.1,
                  ),
                  child: const EmptyState(
                    icon: Icons.description_outlined,
                    title: 'Aucun CV importé',
                    subtitle:
                        'Importez un CV (PDF, DOCX) ou créez-en un avec l\'assistant IA pour postuler aux offres.',
                  ),
                )
              else if (cvs.isEmpty && errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: ErrorStateView(
                    message: errorMessage,
                    onRetry: controller.loadCvs,
                    compact: true,
                  ),
                )
              else ...[
                Text(
                  '${cvs.length} CV',
                  style: AppTextStyles.labelLg.copyWith(
                    color: AppColors.bodyColor,
                    fontSize: 11,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                AnimationLimiter(
                  child: Column(
                    children: AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 280),
                      childAnimationBuilder: (child) => SlideAnimation(
                        verticalOffset: 14,
                        child: FadeInAnimation(child: child),
                      ),
                      children: cvs
                          .map(
                            (cv) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _CvTile(cv: cv),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
          child: Obx(() {
            final isUploading = controller.isUploading.value;
            return FilledButton.icon(
              onPressed: isUploading ? null : () => _pickAndUpload(context),
              icon: isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation(AppColors.onPrimary),
                      ),
                    )
                  : const Icon(Icons.upload_file_rounded),
              label: Text(
                isUploading ? 'Envoi…' : 'Importer un CV (PDF ou DOCX)',
                style: AppTextStyles.buttonMd,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(BuildContext context) async {
    AppHaptics.tap();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
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

    final fileName = file.name;
    final bytes = Uint8List.fromList(file.bytes!);

    final success = await controller.uploadCv(fileName, bytes);
    if (!context.mounted) return;

    if (success) {
      AppHaptics.success();
      Get.snackbar(
        'CV importé',
        'Votre CV a bien été enregistré.',
        backgroundColor: AppColors.successSoft,
        colorText: AppColors.primary,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
      );
    } else {
      AppHaptics.error();
      Get.snackbar(
        'Erreur',
        controller.errorMessage.value.isEmpty
            ? 'Impossible d\'importer le CV.'
            : controller.errorMessage.value,
        backgroundColor: AppColors.errorSoft,
        colorText: AppColors.errorStrong,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
      );
    }
  }

}

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.lightShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Votre CV par défaut',
                  style: AppTextStyles.titleLg.copyWith(
                    color: AppColors.onPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Le CV marqué par défaut est envoyé automatiquement au recruteur dès que vous postulez à une offre.',
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
    );
  }
}

class _CvTile extends StatelessWidget {
  const _CvTile({required this.cv});

  final CvModel cv;

  @override
  Widget build(BuildContext context) {
    final isDefault = cv.isDefault;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDefault ? AppColors.successSoft : AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDefault
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isDefault
                  ? AppColors.primary.withValues(alpha: 0.18)
                  : AppColors.surfaceIconSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.description_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        cv.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleMd,
                      ),
                    ),
                    if (isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'DÉFAUT',
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.onPrimary,
                            fontSize: 9,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  cv.sizeLabel,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.hintColor,
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
