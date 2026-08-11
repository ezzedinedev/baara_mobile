import 'package:flutter/material.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:get/get.dart';

import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_dimens.dart';
import 'package:baara/app/core/theme/app_shapes.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/app/core/widgets/widgets.dart';

import '../controllers/parcours_editor_controller.dart';

/// Éditeur direct du parcours : ajoute/retire expériences et formations sans
/// passer par le flux "Créer mon CV". Persiste via le CV-builder.
class ParcoursEditorScreen extends GetView<ParcoursEditorController> {
  const ParcoursEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold fournit l'ancêtre Material pour tous les TextField/InkWell
    // présents dans le sheet _EntryFormSheet.
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
              child: Row(
                children: [
                  AppBackButton(onTap: () => Get.back<void>()),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mon parcours',
                            style: AppTextStyles.titleLg
                                .copyWith(fontWeight: FontWeight.w800)),
                        Text('Vos expériences et formations',
                            style: AppTextStyles.bodySm
                                .copyWith(color: AppColors.hintColor)),
                      ],
                    ),
                  ),
                  Obx(() => controller.isSaving.value
                      ? Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: const AppLoader(strokeWidth: 2),
                          ),
                        )
                      : const SizedBox.shrink()),
                ],
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    SkeletonBox(
                        height: 90,
                        radius:
                            AppShapes.squircleRadius(AppRadius.md).topLeft.x),
                    const SizedBox(height: 12),
                    SkeletonBox(
                        height: 90,
                        radius:
                            AppShapes.squircleRadius(AppRadius.md).topLeft.x),
                  ],
                );
              }
              if (controller.errorMessage.value != null &&
                  controller.experiences.isEmpty &&
                  controller.educations.isEmpty) {
                return ErrorStateView(
                  message: controller.errorMessage.value!,
                  illustration: const ErrorIllustration(),
                  onRetry: controller.load,
                );
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                children: [
                  _SectionTitle(
                    icon: AppIcons.workFilled,
                    color: AppColors.categoryPurple,
                    title: 'Expériences',
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(controller.experiences.length, (i) {
                    final e = controller.experiences[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: RevealOnMount(
                        delay: Duration(milliseconds: 50 * i),
                        child: _EntryCard(
                          title: _str(e, ['title', 'job_title'], 'Expérience'),
                          subtitle: _str(e, ['company', 'company_name'], ''),
                          period: _period(e),
                          onDelete: () => controller.removeExperience(i),
                        ),
                      ),
                    );
                  }),
                  _AddButton(
                    label: 'Ajouter une expérience',
                    onTap: () => _showExperienceForm(context),
                  ),
                  const SizedBox(height: 26),
                  _SectionTitle(
                    icon: AppIcons.bookmarkFilled,
                    color: AppColors.categoryBlue,
                    title: 'Formations',
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(controller.educations.length, (i) {
                    final e = controller.educations[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: RevealOnMount(
                        delay: Duration(milliseconds: 50 * i),
                        child: _EntryCard(
                          title: _str(e, ['degree', 'diploma'], 'Formation'),
                          subtitle: _str(
                              e, ['institution', 'school', 'university'], ''),
                          period: _period(e),
                          onDelete: () => controller.removeEducation(i),
                        ),
                      ),
                    );
                  }),
                  _AddButton(
                    label: 'Ajouter une formation',
                    onTap: () => _showEducationForm(context),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  static String _str(Map<String, dynamic> m, List<String> keys, String fb) {
    for (final k in keys) {
      final v = m[k];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString();
    }
    return fb;
  }

  static String _period(Map<String, dynamic> m) {
    final start = _str(m, ['start_date', 'start'], '');
    final end = _str(m, ['end_date', 'end'], '');
    if (start.isEmpty && end.isEmpty) return '';
    return '$start${start.isNotEmpty && end.isNotEmpty ? ' – ' : ''}$end';
  }

  Future<void> _showExperienceForm(BuildContext context) async {
    final data = await _entryForm(
      context,
      title: 'Nouvelle expérience',
      fields: const [
        _FieldSpec('title', 'Poste', AppIcons.work, required: true),
        _FieldSpec('company', 'Entreprise', AppIcons.work, required: true),
        _FieldSpec('location', 'Ville', AppIcons.location),
        _FieldSpec('start_date', 'Début (ex : 2020)', AppIcons.calendar),
        _FieldSpec(
            'end_date', 'Fin (ex : 2023 / Présent)', AppIcons.calendar),
        _FieldSpec('description', 'Missions', AppIcons.document,
            multiline: true),
      ],
    );
    if (data != null) {
      final ok = await controller.addExperience(data);
      if (ok) AppToast.success('Expérience ajoutée');
    }
  }

  Future<void> _showEducationForm(BuildContext context) async {
    final data = await _entryForm(
      context,
      title: 'Nouvelle formation',
      fields: const [
        _FieldSpec('degree', 'Diplôme', AppIcons.star, required: true),
        _FieldSpec('institution', 'École / Université', AppIcons.work,
            required: true),
        _FieldSpec('location', 'Ville', AppIcons.location),
        _FieldSpec('start_date', 'Début (ex : 2018)', AppIcons.calendar),
        _FieldSpec('end_date', 'Fin (ex : 2021)', AppIcons.calendar),
        _FieldSpec('field_of_study', 'Domaine', AppIcons.document),
      ],
    );
    if (data != null) {
      final ok = await controller.addEducation(data);
      if (ok) AppToast.success('Formation ajoutée');
    }
  }

  Future<Map<String, dynamic>?> _entryForm(
    BuildContext context, {
    required String title,
    required List<_FieldSpec> fields,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
      ),
      builder: (ctx) => _EntryFormSheet(title: title, fields: fields),
    );
  }
}

class _FieldSpec {
  const _FieldSpec(this.key, this.label, this.icon,
      {this.required = false, this.multiline = false});
  final String key;
  final String label;
  final IconData icon;
  final bool required;
  final bool multiline;
}

class _EntryFormSheet extends StatefulWidget {
  const _EntryFormSheet({required this.title, required this.fields});
  final String title;
  final List<_FieldSpec> fields;

  @override
  State<_EntryFormSheet> createState() => _EntryFormSheetState();
}

class _EntryFormSheetState extends State<_EntryFormSheet> {
  late final Map<String, TextEditingController> _ctrls = {
    for (final f in widget.fields) f.key: TextEditingController(),
  };
  String? _error;

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    for (final f in widget.fields) {
      if (f.required && _ctrls[f.key]!.text.trim().isEmpty) {
        setState(() => _error = '« ${f.label} » est requis.');
        return;
      }
    }
    final data = <String, dynamic>{
      for (final f in widget.fields)
        if (_ctrls[f.key]!.text.trim().isNotEmpty)
          f.key: _ctrls[f.key]!.text.trim(),
    };
    AppHaptics.tap();
    Navigator.of(context).pop(data);
  }

  @override
  Widget build(BuildContext context) {
    // showModalBottomSheet fournit un Material racine pour les TextField.
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetHandle(),
              const SizedBox(height: 16),
              Text(widget.title,
                  style: AppTextStyles.titleLg
                      .copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              for (final f in widget.fields) ...[
                AuthTextField(
                  label: f.label,
                  controller: _ctrls[f.key]!,
                  icon: f.icon,
                  keyboardType: f.multiline
                      ? TextInputType.multiline
                      : TextInputType.text,
                ),
                const SizedBox(height: 12),
              ],
              if (_error != null) ...[
                Text(_error!,
                    style: AppTextStyles.bodySm
                        .copyWith(color: AppColors.errorAccent)),
                const SizedBox(height: 12),
              ],
              GradientButton(
                label: 'ENREGISTRER',
                textColor: AppColors.onPrimary,
                height: 52,
                borderRadius: 14,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(
      {required this.icon, required this.color, required this.title});
  final IconData icon;
  final Color color;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: ShapeDecoration(
            color: color.withValues(alpha: 0.12),
            shape: AppShapes.squircle(AppRadius.sm),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: AppTextStyles.titleLg.copyWith(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.title,
    required this.subtitle,
    required this.period,
    required this.onDelete,
  });
  final String title;
  final String subtitle;
  final String period;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: ShapeDecoration(
        color: AppColors.surfaceCard,
        shape: AppShapes.cardBordered(AppColors.outlineVariant),
        shadows: [
          ...AppColors.lightShadow,
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.titleMd
                        .copyWith(fontWeight: FontWeight.w800)),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.bodyColor)),
                ],
                if (period.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(period,
                      style: AppTextStyles.labelSm
                          .copyWith(color: AppColors.hintColor)),
                ],
              ],
            ),
          ),
          IconButton(
            icon: Icon(AppIcons.delete, color: AppColors.errorAccent),
            onPressed: () {
              AppHaptics.tap();
              onDelete();
            },
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: () {
        AppHaptics.tap();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: ShapeDecoration(
          color: Colors.transparent,
          shape: AppShapes.squircle(
            AppRadius.md,
            side: AppColors.primaryAccent.withValues(alpha: 0.4),
            width: 1.4,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(AppIcons.add, color: AppColors.primaryAccent, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: AppTextStyles.titleMd.copyWith(
                    color: AppColors.primaryAccent,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
