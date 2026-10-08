import 'package:flutter/material.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:get/get.dart';

import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_dimens.dart';
import 'package:baara/app/core/theme/app_motion.dart';
import 'package:baara/app/core/theme/app_shapes.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/app/core/widgets/widgets.dart';
import 'package:baara/routes/app_routes.dart';

import '../../controllers/cv_editor_controller.dart';

/// Éditeur manuel du CV — câblé à l'API (GET cv-builder → PUT cv-builder).
/// Édite identité/contact, résumé, compétences et langues ; les expériences
/// et formations (structures riches) restent gérées via l'assistant IA.
class CvManualEditorScreen extends GetView<CvEditorController> {
  const CvManualEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                        Text(
                          'Éditeur de CV',
                          style: AppTextStyles.titleLg
                              .copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Composez votre CV section par section',
                          style: AppTextStyles.bodySm
                              .copyWith(color: AppColors.hintColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const PageSkeleton(showHero: false, rowCount: 4);
              }
              if (controller.errorMessage.value != null &&
                  controller.candidateName.value.isEmpty) {
                return ErrorStateView(
                  message: controller.errorMessage.value!,
                  illustration: const ErrorIllustration(),
                  onRetry: controller.load,
                );
              }
              return _Form(controller: controller);
            }),
          ),
          Obx(() => CvStickyActionBar(
                primaryLabel: 'Enregistrer le CV',
                isLoading: controller.isSaving.value,
                onPrimary: () async {
                  final ok = await controller.save();
                  if (ok) {
                    AppHaptics.confirm();
                    AppToast.success('CV enregistré',
                        'Vos modifications ont été sauvegardées.');
                  } else {
                    AppToast.error('Échec de l\'enregistrement',
                        controller.errorMessage.value);
                  }
                },
                secondaryLabel: "Voir l'aperçu",
                onSecondary: () => Get.toNamed(AppRoutes.profileCvPreview),
              )),
        ],
      ),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({required this.controller});
  final CvEditorController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        24,
      ),
      children: [
        RevealOnMount(
          delay: Duration.zero,
          child: _SectionCard(
            icon: AppIcons.profile,
            title: 'Identité & contact',
            children: [
              Obx(() => controller.candidateName.value.isEmpty
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ReadOnlyRow(
                          label: 'Nom', value: controller.candidateName.value),
                    )),
              _Field(
                  label: 'Poste visé',
                  ctrl: controller.roleCtrl,
                  hint: 'Ex : Développeur Flutter'),
              _Field(
                  label: 'Ville',
                  ctrl: controller.locationCtrl,
                  hint: 'Ex : Ouagadougou'),
              _Field(
                  label: 'Téléphone',
                  ctrl: controller.phoneCtrl,
                  hint: '+226…',
                  keyboard: TextInputType.phone),
              _Field(
                  label: 'Email',
                  ctrl: controller.emailCtrl,
                  hint: 'vous@email.com',
                  keyboard: TextInputType.emailAddress),
              _Field(
                  label: 'LinkedIn',
                  ctrl: controller.linkedinCtrl,
                  hint: 'https://linkedin.com/in/…'),
              _Field(
                  label: 'Portfolio / site',
                  ctrl: controller.portfolioCtrl,
                  hint: 'https://…',
                  isLast: true),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        RevealOnMount(
          delay: const Duration(milliseconds: 60),
          child: _SectionCard(
            icon: AppIcons.document,
            title: 'Résumé',
            children: [
              _Field(
                  label: 'Présentation',
                  ctrl: controller.bioCtrl,
                  hint: 'Quelques lignes sur votre profil…',
                  maxLines: 4),
              _Field(
                  label: 'Objectif',
                  ctrl: controller.objectiveCtrl,
                  hint: 'Votre objectif professionnel…',
                  maxLines: 3,
                  isLast: true),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        RevealOnMount(
          delay: const Duration(milliseconds: 120),
          child: _SectionCard(
            icon: AppIcons.star,
            title: 'Compétences',
            children: [
              _ChipsEditor(
                label: 'Compétences techniques',
                items: controller.hardSkills,
                onAdd: controller.addHardSkill,
                onRemove: controller.removeHardSkill,
              ),
              const SizedBox(height: AppSpacing.lg),
              _ChipsEditor(
                label: 'Compétences humaines',
                items: controller.softSkills,
                onAdd: controller.addSoftSkill,
                onRemove: controller.removeSoftSkill,
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        RevealOnMount(
          delay: const Duration(milliseconds: 180),
          child: _SectionCard(
            icon: AppIcons.chat,
            title: 'Langues',
            children: [_LanguagesEditor(controller: controller)],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        RevealOnMount(
          delay: const Duration(milliseconds: 240),
          child: _AssistantHint(controller: controller),
        ),
      ],
    );
  }
}

// ── Sections riches déléguées à l'assistant ─────────────────────────────
class _AssistantHint extends StatelessWidget {
  const _AssistantHint({required this.controller});
  final CvEditorController controller;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: () {
        AppHaptics.tap();
        Get.toNamed(AppRoutes.profileCvAssistant);
      },
      curve: AppMotion.spring,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: AppColors.surfaceSelected,
          shape: AppShapes.cardBordered(AppColors.primaryLight),
          shadows: [...AppColors.ambientShadow],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Icon(AppIcons.chatFilled, color: AppColors.primaryAccent, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Obx(() => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Expériences & formations',
                            style: AppTextStyles.titleMd
                                .copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(
                          '${controller.experiencesCount.value} expérience(s) · ${controller.educationsCount.value} formation(s). '
                          "Ajoutez-les en discutant avec l'assistant IA.",
                          style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.bodyColor, height: 1.4),
                        ),
                      ],
                    )),
              ),
              ListNavChevron(
                  color: AppColors.primaryAccent, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widgets de formulaire ───────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  const _SectionCard(
      {required this.icon, required this.title, required this.children});
  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // Material(transparency) assure l'ancêtre Material pour les TextField/InkWell
    // contenus dans la carte, sans rompre la chaîne requise par Flutter.
    return Material(
      type: MaterialType.transparency,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: AppColors.surfaceCard,
          shape: AppShapes.cardBordered(AppColors.outlineVariant),
          shadows: [
            ...AppColors.lightShadow,
            ...AppColors.ambientShadow,
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: AppShapes.squircleRadius(AppRadius.sm),
                    ),
                    child: SizedBox(
                      width: 38,
                      height: 38,
                      child: Center(
                        child:
                            Icon(icon, size: 19, color: AppColors.primaryDark),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: AppTextStyles.titleMd
                        .copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.ctrl,
    required this.hint,
    this.maxLines = 1,
    this.keyboard,
    this.isLast = false,
  });
  final String label;
  final TextEditingController ctrl;
  final String hint;
  final int maxLines;
  final TextInputType? keyboard;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.titleColor, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: ctrl,
            maxLines: maxLines,
            keyboardType: keyboard,
            style: AppTextStyles.bodyMd,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  AppTextStyles.bodyMd.copyWith(color: AppColors.hintColor),
              filled: true,
              fillColor: AppColors.inputFill,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label : ',
            style: AppTextStyles.labelMd.copyWith(color: AppColors.hintColor)),
        Expanded(
          child: Text(value,
              style:
                  AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _ChipsEditor extends StatelessWidget {
  const _ChipsEditor({
    required this.label,
    required this.items,
    required this.onAdd,
    required this.onRemove,
    this.isLast = false,
  });
  final String label;
  final RxList<String> items;
  final void Function(String) onAdd;
  final void Function(String) onRemove;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.labelMd.copyWith(
                color: AppColors.titleColor, fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.sm),
        Obx(() => items.isEmpty
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: items
                      .map((s) =>
                          _RemovableChip(label: s, onRemove: () => onRemove(s)))
                      .toList(),
                ),
              )),
        _InlineAdder(hint: 'Ajouter…', onAdd: onAdd),
      ],
    );
  }
}

class _RemovableChip extends StatelessWidget {
  const _RemovableChip({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceSelected,
        borderRadius: AppShapes.pill,
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 12, right: 6, top: 6, bottom: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.primaryAccent,
                    fontWeight: FontWeight.w700)),
            const SizedBox(width: AppSpacing.xs),
            GestureDetector(
              onTap: () {
                AppHaptics.tap();
                onRemove();
              },
              child: Icon(AppIcons.closeSquare,
                  size: 16, color: AppColors.primaryAccent),
            ),
          ],
        ),
      ),
    );
  }
}

/// Petit champ + bouton « + » qui appelle [onAdd] et se vide.
class _InlineAdder extends StatefulWidget {
  const _InlineAdder({required this.hint, required this.onAdd});
  final String hint;
  final void Function(String) onAdd;

  @override
  State<_InlineAdder> createState() => _InlineAdderState();
}

class _InlineAdderState extends State<_InlineAdder> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final v = _ctrl.text.trim();
    if (v.isEmpty) return;
    AppHaptics.tap();
    widget.onAdd(v);
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            style: AppTextStyles.bodyMd,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle:
                  AppTextStyles.bodyMd.copyWith(color: AppColors.hintColor),
              filled: true,
              fillColor: AppColors.inputFill,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        PressScale(
          onTap: _submit,
          curve: AppMotion.spring,
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
                color: AppColors.primary, shape: BoxShape.circle),
            child: const Icon(AppIcons.add, color: AppColors.onPrimary),
          ),
        ),
      ],
    );
  }
}

class _LanguagesEditor extends StatelessWidget {
  const _LanguagesEditor({required this.controller});
  final CvEditorController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() => controller.languages.isEmpty
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  children: [
                    for (var i = 0; i < controller.languages.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _LanguageRow(
                          name: controller.languages[i]['name'] ?? '',
                          level: controller.languages[i]['level'] ?? '',
                          onRemove: () => controller.removeLanguage(i),
                        ),
                      ),
                  ],
                ),
              )),
        _LanguageAdder(
          onAdd: controller.addLanguage,
          existing: () => controller.languages.map((l) => l['name'] ?? ''),
        ),
      ],
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow(
      {required this.name, required this.level, required this.onRemove});
  final String name;
  final String level;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: AppShapes.squircleRadius(AppRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                level.isEmpty ? name : '$name · $level',
                style:
                    AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            GestureDetector(
              onTap: () {
                AppHaptics.tap();
                onRemove();
              },
              child: Icon(AppIcons.closeSquare,
                  size: 18, color: AppColors.hintColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageAdder extends StatelessWidget {
  const _LanguageAdder({required this.onAdd, required this.existing});
  final void Function(String name, String level) onAdd;
  final Iterable<String> Function() existing;

  Future<void> _pick(BuildContext context) async {
    AppHaptics.tap();
    final picked = await showLanguagePickerSheet(
      context: context,
      exclude: existing(),
    );
    if (picked != null) onAdd(picked.name, picked.level);
  }

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: () => _pick(context),
      curve: AppMotion.spring,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(AppIcons.add, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Ajouter une langue',
              style: AppTextStyles.labelLg.copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
