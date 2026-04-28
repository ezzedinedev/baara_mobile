import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../controllers/profile_controller.dart';
import '../models/profile_model.dart';

/// Formulaire création/édition d'un projet portfolio.
/// Si un [PortfolioProjectModel] est passé en `Get.arguments`, l'écran est en mode édition.
class PortfolioEditScreen extends GetView<ProfileController> {
  const PortfolioEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final existing = Get.arguments is PortfolioProjectModel
        ? Get.arguments as PortfolioProjectModel
        : null;
    return _PortfolioEditForm(controller: controller, existing: existing);
  }
}

class _PortfolioEditForm extends StatefulWidget {
  const _PortfolioEditForm({required this.controller, this.existing});

  final ProfileController controller;
  final PortfolioProjectModel? existing;

  @override
  State<_PortfolioEditForm> createState() => _PortfolioEditFormState();
}

class _PortfolioEditFormState extends State<_PortfolioEditForm> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _urlCtrl;
  late final TextEditingController _tagsCtrl;
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _descriptionCtrl = TextEditingController(text: e?.description ?? '');
    _urlCtrl = TextEditingController(text: e?.url ?? '');
    _tagsCtrl = TextEditingController(text: e?.tags.join(', ') ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _urlCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Modifier le projet' : 'Nouveau projet',
          style: AppTextStyles.headlineSm,
        ),
        leading: IconButton(
          tooltip: 'Retour',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            AppHaptics.tap();
            Navigator.of(context).maybePop();
          },
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 120),
          children: [
            const _SectionLabel(text: 'Titre du projet'),
            const SizedBox(height: 8),
            InputField(
              controller: _titleCtrl,
              hint: 'Ex. : Refonte de la plateforme e-commerce',
              label: 'Titre',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Titre requis' : null,
            ),
            const SizedBox(height: 20),
            const _SectionLabel(text: 'Description'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionCtrl,
              maxLines: 6,
              decoration: InputDecoration(
                hintText:
                    'Contexte, technologies utilisées, résultats obtenus…',
                hintStyle:
                    AppTextStyles.bodyMd.copyWith(color: AppColors.hintColor),
                filled: true,
                fillColor: AppColors.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
              style: AppTextStyles.bodyMd,
            ),
            const SizedBox(height: 20),
            const _SectionLabel(text: 'Lien externe (optionnel)'),
            const SizedBox(height: 8),
            InputField(
              controller: _urlCtrl,
              hint: 'https://mon-projet.com',
              label: 'URL',
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 20),
            const _SectionLabel(text: 'Tags / technologies (séparés par virgule)'),
            const SizedBox(height: 8),
            InputField(
              controller: _tagsCtrl,
              hint: 'Flutter, Dart, Firebase, Design',
              label: 'Tags',
            ),
            const SizedBox(height: 28),
            GradientButton(
              label: isEditing ? 'ENREGISTRER' : 'AJOUTER LE PROJET',
              isLoading: _submitting,
              onPressed: _submitting ? null : _submit,
              height: 54,
              borderRadius: 14,
              textColor: AppColors.onPrimary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    AppHaptics.tap();
    setState(() => _submitting = true);

    final payload = <String, dynamic>{
      'title': _titleCtrl.text.trim(),
      'description': _descriptionCtrl.text.trim(),
      if (_urlCtrl.text.trim().isNotEmpty) 'url': _urlCtrl.text.trim(),
      'tags': _tagsCtrl.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
    };

    final existing = widget.existing;
    final success = existing == null
        ? await widget.controller.createProject(payload)
        : await widget.controller.updateProject(existing.id, payload);

    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      AppHaptics.success();
      Get.snackbar(
        'Projet enregistré',
        existing == null
            ? 'Votre projet a été ajouté au portfolio.'
            : 'Les modifications ont été enregistrées.',
        backgroundColor: AppColors.successSoft,
        colorText: AppColors.primary,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
      );
      Navigator.of(context).maybePop();
    } else {
      AppHaptics.error();
      Get.snackbar(
        'Erreur',
        widget.controller.errorMessage.value.isEmpty
            ? 'Impossible d\'enregistrer le projet.'
            : widget.controller.errorMessage.value,
        backgroundColor: AppColors.errorSoft,
        colorText: AppColors.errorStrong,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
      );
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.labelMd.copyWith(
        color: AppColors.bodyColor,
        fontSize: 11,
        letterSpacing: 1.2,
      ),
    );
  }
}
