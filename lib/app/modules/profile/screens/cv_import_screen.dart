import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../controllers/cv_builder_controller.dart';

part 'cv_import_parts/upload_step.dart';
part 'cv_import_parts/analysis_step.dart';
part 'cv_import_parts/improved_step.dart';
part 'cv_import_parts/shared.dart';


/// Import CV en 3 étapes : upload → analyse IA → amélioration → apply/download.
/// Flow stateless : le controller stocke `extracted_text` + `analysis` +
/// `improved` côté client et les renvoie au backend à chaque étape.
class CvImportScreen extends GetView<CvBuilderController> {
  const CvImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Importer un CV', style: AppTextStyles.headlineSm),
        leading: IconButton(
          tooltip: 'Retour',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            AppHaptics.tap();
            Navigator.of(context).maybePop();
          },
        ),
        actions: [
          Obx(() {
            if (controller.importAnalysis.value == null) {
              return const SizedBox.shrink();
            }
            return IconButton(
              tooltip: 'Recommencer',
              onPressed: () {
                AppHaptics.confirm();
                controller.resetImport();
              },
              icon: const Icon(Icons.refresh_rounded),
            );
          }),
        ],
      ),
      body: Obx(() {
        final analysis = controller.importAnalysis.value;
        final improved = controller.importImproved.value;

        // Index unique pour AnimatedSwitcher : pousser une nouvelle étape
        // déclenche slide+fade depuis la droite.
        final stepIndex = improved != null ? 2 : (analysis != null ? 1 : 0);

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            // Glissement + fondu pour l'arrivée, fondu seul pour la sortie
            // (évite un croisement brutal de deux écrans en mouvement).
            final slide = Tween<Offset>(
              begin: const Offset(0.12, 0),
              end: Offset.zero,
            ).animate(animation);
            return SlideTransition(
              position: slide,
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          layoutBuilder: (currentChild, previousChildren) => Stack(
            alignment: Alignment.topCenter,
            children: [
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          ),
          child: KeyedSubtree(
            key: ValueKey<int>(stepIndex),
            child: switch (stepIndex) {
              0 => _UploadStep(controller: controller),
              1 => _AnalysisStep(controller: controller),
              _ => _ImprovedStep(controller: controller),
            },
          ),
        );
      }),
    );
  }
}
