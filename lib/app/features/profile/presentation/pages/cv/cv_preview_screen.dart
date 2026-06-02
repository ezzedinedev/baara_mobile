import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';

import '../../controllers/cv_preview_controller.dart';

/// Aperçu du CV : sélection de modèle + rendu réel du PDF généré côté serveur
/// (partage / impression / téléchargement via `printing`). Câblé à l'API.
class CvPreviewScreen extends GetView<CvPreviewController> {
  const CvPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          WavyContentHeader(
            title: 'Aperçu du CV',
            subtitle: 'Choisissez un modèle, partagez ou téléchargez',
            height: 200,
            gradient: AppColors.heroProfileGradient,
            onLeadingTap: () => Get.back<void>(),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                );
              }
              if (controller.errorMessage.value != null) {
                return ErrorStateView(
                  message: controller.errorMessage.value!,
                  onRetry: controller.load,
                );
              }
              return Column(
                children: [
                  const SizedBox(height: 16),
                  const _TemplateSelector(),
                  const SizedBox(height: 12),
                  Expanded(child: _PdfArea()),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _TemplateSelector extends StatelessWidget {
  const _TemplateSelector();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CvPreviewController>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Obx(() {
        final selected = controller.selectedTemplate.value;
        return Row(
          children: [
            for (var i = 0; i < CvPreviewController.templates.length; i++) ...[
              Expanded(
                child: _TemplateChip(
                  label: CvPreviewController.templates[i].label,
                  selected: CvPreviewController.templates[i].id == selected,
                  onTap: () {
                    AppHaptics.tap();
                    controller.changeTemplate(CvPreviewController.templates[i].id);
                  },
                ),
              ),
              if (i != CvPreviewController.templates.length - 1)
                const SizedBox(width: 10),
            ],
          ],
        );
      }),
    );
  }
}

class _TemplateChip extends StatelessWidget {
  const _TemplateChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceSelected : AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primaryLight : AppColors.surfaceLow,
            width: 1.4,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMd.copyWith(
            color: selected ? AppColors.primary : AppColors.bodyColor,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PdfArea extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CvPreviewController>();
    return Obx(
      // La clé force PdfPreview à régénérer l'aperçu quand le modèle change.
      () => PdfPreview(
        key: ValueKey(controller.selectedTemplate.value),
        build: (PdfPageFormat format) => controller.pdfBytes(),
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        allowPrinting: true,
        allowSharing: true,
        pdfFileName: 'CV-OpporTune.pdf',
        loadingWidget: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        previewPageMargin: const EdgeInsets.all(16),
        scrollViewDecoration: BoxDecoration(color: AppColors.surfaceLow),
      ),
    );
  }
}
