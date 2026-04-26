part of '../cv_import_screen.dart';

class _AnalysisStep extends StatelessWidget {
  const _AnalysisStep({required this.controller});
  final CvBuilderController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final analysis = controller.importAnalysis.value ?? {};
      final filename = controller.importFileName.value;
      final isImproving = controller.isImportImproving.value;

      final overall = (analysis['overall_score'] as num?)?.toInt();
      final ats = (analysis['ats_score'] as num?)?.toInt();
      final summary = analysis['summary']?.toString() ?? '';
      final issues = (analysis['issues'] as List?) ?? [];
      final improvements = (analysis['improvements'] as List?) ?? [];
      final missing = (analysis['missing_sections'] as List?) ?? [];
      final keywordsSuggested = (analysis['keywords_suggested'] as List?) ?? [];

      return Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
              children: [
                _FileChip(filename: filename),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _ScoreCard(
                        label: 'Score global',
                        value: overall,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ScoreCard(
                        label: 'Score ATS',
                        value: ats,
                        color: AppColors.categoryBlue,
                      ),
                    ),
                  ],
                ),
                if (summary.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _InfoBlock(
                    icon: Icons.insights_rounded,
                    color: AppColors.categoryPurple,
                    title: 'Résumé',
                    body: Text(
                      summary,
                      style: AppTextStyles.bodyMd.copyWith(height: 1.45),
                    ),
                  ),
                ],
                if (issues.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _InfoBlock(
                    icon: Icons.error_outline_rounded,
                    color: AppColors.errorStrong,
                    title: 'Points à corriger (${issues.length})',
                    body: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: issues
                          .take(6)
                          .map((i) => _IssueRow(data: i))
                          .toList(),
                    ),
                  ),
                ],
                if (missing.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _InfoBlock(
                    icon: Icons.playlist_add_rounded,
                    color: AppColors.warning,
                    title: 'Sections manquantes',
                    body: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: missing
                          .whereType<String>()
                          .map((m) => _TagChip(text: m, color: AppColors.warning))
                          .toList(),
                    ),
                  ),
                ],
                if (keywordsSuggested.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _InfoBlock(
                    icon: Icons.key_rounded,
                    color: AppColors.categoryCyan,
                    title: 'Mots-clés à ajouter',
                    body: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: keywordsSuggested
                          .whereType<String>()
                          .map((k) =>
                              _TagChip(text: k, color: AppColors.categoryCyan))
                          .toList(),
                    ),
                  ),
                ],
                if (improvements.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _InfoBlock(
                    icon: Icons.auto_fix_high_rounded,
                    color: AppColors.successDark,
                    title: 'Améliorations proposées',
                    body: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: improvements
                          .whereType<String>()
                          .take(5)
                          .map((tip) => _BulletLine(tip))
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
              child: FilledButton.icon(
                onPressed: isImproving
                    ? null
                    : () async {
                        AppHaptics.tap();
                        final ok = await controller.importImprove();
                        if (!context.mounted) return;
                        if (!ok) {
                          AppHaptics.error();
                          Get.snackbar(
                            'Échec',
                            controller.errorMessage.value.isEmpty
                                ? 'Amélioration impossible.'
                                : controller.errorMessage.value,
                            backgroundColor: AppColors.errorSoft,
                            colorText: AppColors.errorStrong,
                            snackPosition: SnackPosition.BOTTOM,
                            margin: const EdgeInsets.all(16),
                            borderRadius: 14,
                          );
                        } else {
                          AppHaptics.success();
                        }
                      },
                icon: isImproving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation(AppColors.onPrimary),
                        ),
                      )
                    : const Icon(Icons.auto_awesome_rounded),
                label: Text(
                  isImproving ? 'Réécriture…' : 'Améliorer avec l\'IA',
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
              ),
            ),
          ),
        ],
      );
    });
  }
}

