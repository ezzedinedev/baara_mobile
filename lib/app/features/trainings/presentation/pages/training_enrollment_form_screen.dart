import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import 'package:jobaway/app/core/theme/app_colors.dart';
import 'package:jobaway/app/core/theme/app_dimens.dart';
import 'package:jobaway/app/core/theme/app_motion.dart';
import 'package:jobaway/app/core/theme/app_shapes.dart';
import 'package:jobaway/app/core/theme/app_text_styles.dart';
import 'package:jobaway/app/core/utils/haptics.dart';
import 'package:jobaway/app/core/widgets/widgets.dart';

import '../../domain/entities/training.dart';

/// Dossier d'inscription exigé par le formateur.
///
/// Certaines formations le rendent obligatoire (`enrollment_form_required`).
/// Le web le faisait remplir avant toute inscription ; le mobile l'ignorait, et
/// le formateur recevait des apprenants sans motivation ni réponses à son
/// questionnaire. Cet écran rétablit la parité, questions libres comprises.
///
/// Retourne les données saisies via `Get.back(result: …)`, ou `null` si l'on
/// abandonne.
class TrainingEnrollmentFormScreen extends StatefulWidget {
  const TrainingEnrollmentFormScreen({super.key, required this.training});

  final Training training;

  @override
  State<TrainingEnrollmentFormScreen> createState() =>
      _TrainingEnrollmentFormScreenState();
}

class _TrainingEnrollmentFormScreenState
    extends State<TrainingEnrollmentFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _motivation = TextEditingController();
  final _availability = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _expectations = TextEditingController();

  late final List<TextEditingController> _customCtrls = [
    for (final _ in widget.training.formFields) TextEditingController(),
  ];
  late final List<String?> _customSelections = [
    for (final _ in widget.training.formFields) null,
  ];

  String? _level;
  bool _acceptTerms = false;
  bool _showTermsError = false;

  @override
  void dispose() {
    _motivation.dispose();
    _availability.dispose();
    _phone.dispose();
    _city.dispose();
    _expectations.dispose();
    for (final c in _customCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final formOk = _formKey.currentState?.validate() ?? false;
    setState(() => _showTermsError = !_acceptTerms);

    if (!formOk || !_acceptTerms) {
      AppHaptics.error();
      return;
    }

    AppHaptics.tap();

    // Les mêmes clés que le web : le backend range le tout dans
    // `application_data`, que le formateur relit dans son espace.
    final customFields = <String, String>{};
    for (var i = 0; i < widget.training.formFields.length; i++) {
      final field = widget.training.formFields[i];
      final value = field.isSelect
          ? (_customSelections[i] ?? '')
          : _customCtrls[i].text.trim();
      if (value.isNotEmpty) customFields['$i'] = value;
    }

    Get.back<Map<String, dynamic>>(result: {
      'motivation': _motivation.text.trim(),
      'accept_terms': true,
      if (_level != null) 'level': _level,
      if (_availability.text.trim().isNotEmpty)
        'availability': _availability.text.trim(),
      if (_phone.text.trim().isNotEmpty) 'phone': _phone.text.trim(),
      if (_city.text.trim().isNotEmpty) 'city': _city.text.trim(),
      if (_expectations.text.trim().isNotEmpty)
        'expectations': _expectations.text.trim(),
      if (customFields.isNotEmpty) 'custom_fields': customFields,
    });
  }

  @override
  Widget build(BuildContext context) {
    final fields = widget.training.formFields;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          WavyContentHeader(
            title: 'Dossier d\'inscription',
            subtitle: widget.training.title,
            height: 190,
            gradient: AppColors.heroProfileGradient,
            onLeadingTap: () => Get.back<void>(),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  AppSpacing.xl,
                  AppSpacing.xxl,
                  AppSpacing.xxl,
                ),
                children: [
                  Text(
                    'Le formateur souhaite mieux vous connaître avant de '
                    'valider votre place.',
                    style:
                        AppTextStyles.bodyMd.copyWith(color: AppColors.bodyColor),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  LabeledInput(
                    label: 'Votre motivation *',
                    placeholder: 'Pourquoi souhaitez-vous suivre cette '
                        'formation ? (20 caractères minimum)',
                    controller: _motivation,
                    maxLines: 5,
                    validator: (value) {
                      final text = (value ?? '').trim();
                      if (text.length < 20) {
                        return 'Au moins 20 caractères, pour que le formateur '
                            'puisse vous situer.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  SectionLabel('Votre niveau'),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final level in const [
                        (id: 'debutant', label: 'Débutant'),
                        (id: 'intermediaire', label: 'Intermédiaire'),
                        (id: 'avance', label: 'Avancé'),
                      ])
                        _ChoiceChip(
                          label: level.label,
                          selected: _level == level.id,
                          onTap: () {
                            AppHaptics.tap();
                            setState(() => _level = level.id);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  LabeledInput(
                    label: 'Disponibilité',
                    placeholder: 'Ex. soirs et week-ends',
                    controller: _availability,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  LabeledInput(
                    label: 'Téléphone',
                    placeholder: '70 00 00 00',
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  LabeledInput(
                    label: 'Ville',
                    placeholder: 'Ouagadougou',
                    controller: _city,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  LabeledInput(
                    label: 'Vos attentes',
                    placeholder: 'Ce que vous espérez retirer de la formation',
                    controller: _expectations,
                    maxLines: 4,
                  ),

                  if (fields.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    SectionLabel('Questionnaire du formateur'),
                    const SizedBox(height: AppSpacing.sm),
                    for (var i = 0; i < fields.length; i++) ...[
                      _CustomField(
                        field: fields[i],
                        controller: _customCtrls[i],
                        selected: _customSelections[i],
                        onSelected: (value) =>
                            setState(() => _customSelections[i] = value),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ],

                  const SizedBox(height: AppSpacing.lg),
                  _TermsCheckbox(
                    value: _acceptTerms,
                    showError: _showTermsError,
                    onChanged: (value) {
                      AppHaptics.tap();
                      setState(() {
                        _acceptTerms = value;
                        if (value) _showTermsError = false;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  GradientButton(
                    label: 'VALIDER MON DOSSIER',
                    textColor: AppColors.onPrimary,
                    height: 52,
                    borderRadius: 14,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomField extends StatelessWidget {
  const _CustomField({
    required this.field,
    required this.controller,
    required this.selected,
    required this.onSelected,
  });

  final TrainingFormField field;
  final TextEditingController controller;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final label = field.required ? '${field.label} *' : field.label;

    if (field.isSelect) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(label),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in field.options)
                _ChoiceChip(
                  label: option,
                  selected: selected == option,
                  onTap: () {
                    AppHaptics.tap();
                    onSelected(option);
                  },
                ),
            ],
          ),
        ],
      );
    }

    return LabeledInput(
      label: label,
      placeholder: field.label,
      controller: controller,
      maxLines: field.isTextarea ? 4 : 1,
      validator: field.required
          ? (value) => (value ?? '').trim().isEmpty
              ? 'Cette question est obligatoire.'
              : null
          : null,
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      curve: AppMotion.spring,
      child: AnimatedContainer(
        duration: AppMotion.short,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceSelected : AppColors.surfaceLow,
          borderRadius: AppShapes.squircleRadius(AppRadius.sm),
          border: Border.all(
            color: selected ? AppColors.primaryLight : AppColors.outlineVariant,
            width: 1.4,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMd.copyWith(
            color: selected ? AppColors.primaryAccent : AppColors.bodyColor,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({
    required this.value,
    required this.showError,
    required this.onChanged,
  });

  final bool value;
  final bool showError;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PressScale(
          onTap: () => onChanged(!value),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                value
                    ? IconlyBold.tick_square
                    : Icons.check_box_outline_blank_rounded,
                size: 22,
                color: value ? AppColors.primaryAccent : AppColors.hintColor,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'J\'accepte les conditions de la formation et je m\'engage à '
                  'suivre le parcours.',
                  style: AppTextStyles.bodySm
                      .copyWith(color: AppColors.bodyColor, height: 1.35),
                ),
              ),
            ],
          ),
        ),
        if (showError) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Vous devez accepter les conditions pour vous inscrire.',
            style: AppTextStyles.labelSm.copyWith(color: AppColors.errorAccent),
          ),
        ],
      ],
    );
  }
}
