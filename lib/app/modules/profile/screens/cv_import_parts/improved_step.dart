part of '../cv_import_screen.dart';

class _ImprovedStep extends StatelessWidget {
  const _ImprovedStep({required this.controller});
  final CvBuilderController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final improved = controller.importImproved.value ?? {};
      final improvementsApplied =
          (improved['improvements_applied'] as List?) ?? [];
      final experiences = (improved['experiences'] as List?) ?? [];
      final summary = improved['summary']?.toString() ?? '';
      final headline = improved['headline']?.toString() ?? '';
      final skills = (improved['hard_skills'] as List?)?.whereType<String>() ?? [];

      return Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.successSoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'CV réécrit par l\'IA',
                          style: AppTextStyles.titleMd.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (headline.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _InfoBlock(
                    icon: Icons.title_rounded,
                    color: AppColors.categoryBlue,
                    title: 'Titre proposé',
                    body: Text(
                      headline,
                      style: AppTextStyles.titleLg,
                    ),
                  ),
                ],
                if (summary.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _InfoBlock(
                    icon: Icons.notes_rounded,
                    color: AppColors.categoryPurple,
                    title: 'Résumé réécrit',
                    body: Text(
                      summary,
                      style: AppTextStyles.bodyMd.copyWith(height: 1.45),
                    ),
                  ),
                ],
                if (skills.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _InfoBlock(
                    icon: Icons.star_outline_rounded,
                    color: AppColors.categoryOrange,
                    title: 'Compétences techniques',
                    body: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: skills
                          .map((s) => _TagChip(
                                text: s,
                                color: AppColors.categoryOrange,
                              ))
                          .toList(),
                    ),
                  ),
                ],
                if (experiences.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _InfoBlock(
                    icon: Icons.work_history_rounded,
                    color: AppColors.successDark,
                    title: 'Expériences (${experiences.length})',
                    body: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: experiences
                          .whereType<Map>()
                          .take(3)
                          .map((e) => _ExperienceCard(
                                data: Map<String, dynamic>.from(e),
                              ))
                          .toList(),
                    ),
                  ),
                ],
                if (improvementsApplied.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _InfoBlock(
                    icon: Icons.auto_fix_high_rounded,
                    color: AppColors.primary,
                    title: 'Améliorations appliquées',
                    body: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: improvementsApplied
                          .whereType<String>()
                          .map(_BulletLine.new)
                          .toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: controller.isImportApplying.value
                          ? null
                          : () => _applyToProfile(context),
                      icon: controller.isImportApplying.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : const Icon(Icons.person_add_alt_1_rounded),
                      label: const Text('Appliquer'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.5),
                        ),
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        AppHaptics.tap();
                        Get.snackbar(
                          'Téléchargement',
                          "Le téléchargement PDF sera disponible prochainement.",
                          backgroundColor: AppColors.warningSoft,
                          colorText: AppColors.warning,
                          snackPosition: SnackPosition.BOTTOM,
                          margin: const EdgeInsets.all(16),
                          borderRadius: 14,
                        );
                      },
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Télécharger'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Future<void> _applyToProfile(BuildContext context) async {
    AppHaptics.confirm();
    final ok = await controller.importApply();
    if (!context.mounted) return;

    if (ok) {
      AppHaptics.success();
      Get.snackbar(
        'Appliqué',
        'Ton profil a été enrichi à partir du CV importé.',
        backgroundColor: AppColors.successSoft,
        colorText: AppColors.primary,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
        icon: const Icon(
          Icons.check_circle_rounded,
          color: AppColors.primary,
        ),
      );
      Navigator.of(context).maybePop();
    } else {
      AppHaptics.error();
      Get.snackbar(
        'Erreur',
        controller.errorMessage.value.isEmpty
            ? 'Impossible d\'appliquer les champs.'
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

