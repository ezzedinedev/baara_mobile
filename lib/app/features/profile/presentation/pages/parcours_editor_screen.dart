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
                          onEdit: () => _showExperienceForm(context, index: i),
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
                          title: _str(e, ['diploma', 'degree'], 'Formation'),
                          subtitle: _str(
                              e, ['school', 'institution', 'university'], ''),
                          period: _period(e),
                          onEdit: () => _showEducationForm(context, index: i),
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
    final start = _str(m, ['from', 'start_date', 'start'], '');
    final end = _str(m, ['to', 'end_date', 'end', 'year'], '');
    if (start.isEmpty && end.isEmpty) return '';
    return '$start${start.isNotEmpty && end.isNotEmpty ? ' – ' : ''}$end';
  }

  Future<void> _showExperienceForm(BuildContext context, {int? index}) async {
    final editing = index != null;
    final data = await _entryForm(
      context,
      title: editing ? "Modifier l'expérience" : 'Nouvelle expérience',
      initial: editing ? controller.experiences[index] : null,
      fields: const [
        _FieldSpec('title', 'Poste', AppIcons.work,
            required: true, aliases: ['job_title']),
        _FieldSpec('company', 'Entreprise', AppIcons.work,
            required: true, aliases: ['company_name']),
        _FieldSpec('location', 'Ville', AppIcons.location),
        _FieldSpec('from', 'Début', AppIcons.calendar,
            kind: _FieldKind.date, aliases: ['start_date', 'start']),
        _FieldSpec('to', 'Fin', AppIcons.calendar,
            kind: _FieldKind.dateOrPresent, aliases: ['end_date', 'end']),
        _FieldSpec('description', 'Missions', AppIcons.document,
            multiline: true),
      ],
    );
    if (data == null) return;
    final ok = editing
        ? await controller.updateExperience(index, data)
        : await controller.addExperience(data);
    if (ok) {
      AppToast.success(
          editing ? 'Expérience mise à jour' : 'Expérience ajoutée');
    }
  }

  Future<void> _showEducationForm(BuildContext context, {int? index}) async {
    final editing = index != null;
    final data = await _entryForm(
      context,
      title: editing ? 'Modifier la formation' : 'Nouvelle formation',
      initial: editing ? controller.educations[index] : null,
      fields: const [
        _FieldSpec('diploma', 'Diplôme', AppIcons.star,
            required: true, aliases: ['degree']),
        _FieldSpec('school', 'École / Université', AppIcons.work,
            required: true, aliases: ['institution', 'university']),
        _FieldSpec('location', 'Ville', AppIcons.location),
        _FieldSpec('from', 'Début', AppIcons.calendar,
            kind: _FieldKind.date, aliases: ['start_date', 'start']),
        _FieldSpec('year', 'Fin / année du diplôme', AppIcons.calendar,
            kind: _FieldKind.dateOrPresent, aliases: ['end_date', 'end', 'to']),
        _FieldSpec('description', 'Domaine', AppIcons.document,
            aliases: ['field_of_study']),
      ],
    );
    if (data == null) return;
    final ok = editing
        ? await controller.updateEducation(index, data)
        : await controller.addEducation(data);
    if (ok) {
      AppToast.success(editing ? 'Formation mise à jour' : 'Formation ajoutée');
    }
  }

  Future<Map<String, dynamic>?> _entryForm(
    BuildContext context, {
    required String title,
    required List<_FieldSpec> fields,
    Map<String, dynamic>? initial,
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
      builder: (ctx) =>
          _EntryFormSheet(title: title, fields: fields, initial: initial),
    );
  }
}

enum _FieldKind { text, date, dateOrPresent }

class _FieldSpec {
  const _FieldSpec(
    this.key,
    this.label,
    this.icon, {
    this.required = false,
    this.multiline = false,
    this.kind = _FieldKind.text,
    this.aliases = const [],
  });
  final String key;
  final String label;
  final IconData icon;
  final bool required;
  final bool multiline;
  final _FieldKind kind;

  /// Anciennes clés (premières versions de l'app) lues pour pré-remplir ;
  /// l'enregistrement les remplace par [key].
  final List<String> aliases;
}

class _EntryFormSheet extends StatefulWidget {
  const _EntryFormSheet({
    required this.title,
    required this.fields,
    this.initial,
  });
  final String title;
  final List<_FieldSpec> fields;
  final Map<String, dynamic>? initial;

  @override
  State<_EntryFormSheet> createState() => _EntryFormSheetState();
}

class _EntryFormSheetState extends State<_EntryFormSheet> {
  late final Map<String, TextEditingController> _ctrls = {
    for (final f in widget.fields)
      f.key: TextEditingController(text: _initialValue(f)),
  };

  String _initialValue(_FieldSpec f) {
    final source = widget.initial;
    if (source == null) return '';
    for (final k in [f.key, ...f.aliases]) {
      final v = source[k];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
    return '';
  }

  Future<void> _pickDate(_FieldSpec f) async {
    FocusScope.of(context).unfocus();
    final picked = await showMonthYearPickerSheet(
      context: context,
      title: f.label,
      initial: _ctrls[f.key]!.text,
      allowPresent: f.kind == _FieldKind.dateOrPresent,
    );
    if (picked == null || !mounted) return;
    setState(() => _ctrls[f.key]!.text = picked);
  }

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
                if (f.kind == _FieldKind.text)
                  AuthTextField(
                    label: f.label,
                    controller: _ctrls[f.key]!,
                    icon: f.icon,
                    maxLines: f.multiline ? 4 : 1,
                    keyboardType: f.multiline
                        ? TextInputType.multiline
                        : TextInputType.text,
                  )
                else
                  _DateField(
                    label: f.label,
                    icon: f.icon,
                    value: _ctrls[f.key]!.text,
                    onTap: () => _pickDate(f),
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
    required this.onEdit,
    required this.onDelete,
  });
  final String title;
  final String subtitle;
  final String period;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: () {
        AppHaptics.tap();
        onEdit();
      },
      child: Container(
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
              tooltip: 'Modifier',
              icon: Icon(AppIcons.edit, color: AppColors.hintColor, size: 20),
              onPressed: () {
                AppHaptics.tap();
                onEdit();
              },
            ),
            IconButton(
              tooltip: 'Supprimer',
              icon: Icon(AppIcons.delete, color: AppColors.errorAccent),
              onPressed: () {
                AppHaptics.tap();
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Champ date : ouvre le sélecteur mois / année au lieu du clavier.
class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final empty = value.trim().isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.titleMd.copyWith(
            color: AppColors.titleColor,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: AppShapes.squircleRadius(AppRadius.lg),
            side: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: InkWell(
            borderRadius: AppShapes.squircleRadius(AppRadius.lg),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(icon,
                      size: 20,
                      color: AppColors.primaryAccent.withValues(alpha: 0.85)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      empty ? 'Choisir' : value,
                      style: empty
                          ? AppTextStyles.bodyMd
                              .copyWith(color: AppColors.hintColor)
                          : AppTextStyles.bodyLg.copyWith(
                              color: AppColors.titleColor,
                              fontWeight: FontWeight.w600,
                            ),
                    ),
                  ),
                  Icon(Icons.expand_more_rounded, color: AppColors.hintColor),
                ],
              ),
            ),
          ),
        ),
      ],
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
