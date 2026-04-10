import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/providers/api_provider.dart';
import '../../../widgets/gradient_button.dart';
import 'home_controller.dart';
import 'home_profile_manager.dart';
import 'home_profile_models.dart';

class _PendingUploadFile {
  const _PendingUploadFile({
    required this.name,
    required this.bytes,
  });

  final String name;
  final Uint8List bytes;
}

class HomeProfileTab extends StatelessWidget {
  HomeProfileTab({
    required this.controller,
    super.key,
  });

  final HomeController controller;
  final ImagePicker _imagePicker = ImagePicker();

  HomeProfileManager get _manager => controller.profileManager;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_manager.isLoadingProfile.value &&
          _manager.profile.value.id.isEmpty &&
          _manager.profileLoadError.value.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      }

      final profile = _manager.profile.value;
      final prefs = _manager.preferences.value;

      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _manager.loadAll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
          children: [
            Row(
              children: [
                Text(
                  'Mon Profil',
                  style: AppTextStyles.displayMd.copyWith(fontSize: 28),
                ),
                const Spacer(),
                _CircleActionButton(
                  icon: Icons.refresh_rounded,
                  onTap: _manager.loadAll,
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ProfileHeroCard(
              profile: profile,
              isUploadingAvatar: _manager.isUploadingAvatar.value,
              onEditAvatar: () => _pickAvatar(context),
            ),
            if (_manager.profileLoadError.value.isNotEmpty &&
                profile.id.isEmpty) ...[
              const SizedBox(height: 14),
              _InlineMessageCard(
                icon: Icons.warning_amber_rounded,
                color: const Color(0xFFB45309),
                message: _manager.profileLoadError.value,
                actionLabel: 'Recharger',
                onAction: _manager.loadProfile,
              ),
            ],
            const SizedBox(height: 22),
            _SectionHeader(
              title: 'Informations de contact',
              actionLabel: 'Modifier',
              onTap: () => _openProfileEditor(context),
            ),
            const SizedBox(height: 12),
            _ContactGrid(profile: profile),
            const SizedBox(height: 22),
            const _SectionHeader(
              title: 'Preferences',
              actionLabel: 'Auto-save',
              onTap: null,
            ),
            const SizedBox(height: 12),
            _PreferencesCard(
              preferences: prefs,
              isBusy: _manager.isSavingPreferences.value,
              onChanged: _savePreferences,
            ),
            const SizedBox(height: 22),
            _SectionHeader(
              title: 'CV moderne',
              actionLabel: 'Ajouter',
              onTap: () => _openCvEditor(context),
            ),
            const SizedBox(height: 12),
            _CvOverviewCard(
              manager: _manager,
              onAdd: () => _openCvEditor(context),
              onEdit: (section) => _openCvEditor(context, section: section),
              onDelete: _removeCvSection,
              onUploadCv: _pickCvFile,
              onPreviewCv: _manager.previewCvPdf,
              onTemplateChanged: _manager.changeCvTemplate,
            ),
            const SizedBox(height: 22),
            _SectionHeader(
              title: 'Portfolio & projets',
              actionLabel: 'Ajouter',
              onTap: () => _openPortfolioEditor(context),
            ),
            const SizedBox(height: 12),
            _PortfolioOverviewCard(
              manager: _manager,
              onAdd: () => _openPortfolioEditor(context),
              onEdit: (item) => _openPortfolioEditor(context, item: item),
              onDelete: _deletePortfolioItem,
              onOpenLink: _openExternal,
            ),
            const SizedBox(height: 26),
            GradientButton(
              label: 'SE DECONNECTER',
              onPressed: controller.logout,
              textColor: AppColors.onPrimary,
              height: 54,
              borderRadius: 16,
            ),
          ],
        ),
      );
    });
  }

  Future<void> _pickAvatar(BuildContext context) async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1600,
      );
      if (image == null) {
        return;
      }

      await _manager.uploadAvatar(image);
      Get.snackbar(
        'Profil',
        'Photo de profil mise a jour.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on Exception catch (error) {
      _showError(error);
    }
  }

  Future<void> _pickCvFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'doc', 'docx'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        throw Exception('Impossible de lire le fichier selectionne.');
      }

      await _manager.uploadCvFile(
        bytes: bytes,
        filename: file.name.isEmpty ? 'cv.pdf' : file.name,
      );
      Get.snackbar(
        'CV',
        'CV importe avec succes.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on Exception catch (error) {
      _showError(error);
    }
  }

  Future<void> _savePreferences(HomeProfilePreferences nextPreferences) async {
    try {
      await _manager.savePreferences(nextPreferences);
    } on Exception catch (error) {
      _showError(error);
    }
  }

  Future<void> _removeCvSection(HomeCvSection section) async {
    final updated = _manager.cvSections
        .where((entry) => entry.id != section.id)
        .toList(growable: true);

    try {
      await _manager.saveCv(updated);
      Get.snackbar(
        'CV',
        'Section supprimee.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on Exception catch (error) {
      _showError(error);
    }
  }

  Future<void> _deletePortfolioItem(HomePortfolioItem item) async {
    try {
      await _manager.deletePortfolioItem(item);
      Get.snackbar(
        'Portfolio',
        'Projet supprime.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on Exception catch (error) {
      _showError(error);
    }
  }

  Future<void> _openExternal(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null) {
      _showError(Exception('URL invalide.'));
      return;
    }

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showError(Exception('Impossible d\'ouvrir ce lien.'));
    }
  }

  Future<void> _openProfileEditor(BuildContext context) async {
    final profile = _manager.profile.value;
    final firstNameCtrl = TextEditingController(text: profile.firstName);
    final lastNameCtrl = TextEditingController(text: profile.lastName);
    final emailCtrl = TextEditingController(text: profile.email);
    final phoneCtrl = TextEditingController(text: profile.phone);
    final cityCtrl = TextEditingController(text: profile.city);
    final regionCtrl = TextEditingController(text: profile.region);
    final headlineCtrl = TextEditingController(text: profile.headline);
    final summaryCtrl = TextEditingController(text: profile.summary);
    final skillsCtrl = TextEditingController(text: profile.skills.join(', '));
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            18,
            20,
            20 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _BottomSheetHandle(),
                  const SizedBox(height: 14),
                  Text('Modifier le profil', style: AppTextStyles.headlineLg),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _TextFieldBlock(
                          controller: firstNameCtrl,
                          label: 'Nom',
                          validator: _requiredValidator,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TextFieldBlock(
                          controller: lastNameCtrl,
                          label: 'Prenom',
                          validator: _requiredValidator,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _TextFieldBlock(
                    controller: emailCtrl,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: _requiredValidator,
                  ),
                  const SizedBox(height: 12),
                  _TextFieldBlock(
                    controller: phoneCtrl,
                    label: 'Telephone',
                    keyboardType: TextInputType.phone,
                    validator: _requiredValidator,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _TextFieldBlock(
                          controller: cityCtrl,
                          label: 'Ville',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TextFieldBlock(
                          controller: regionCtrl,
                          label: 'Region',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _TextFieldBlock(
                    controller: headlineCtrl,
                    label: 'Accroche',
                  ),
                  const SizedBox(height: 12),
                  _TextFieldBlock(
                    controller: summaryCtrl,
                    label: 'Resume',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  _TextFieldBlock(
                    controller: skillsCtrl,
                    label: 'Competences',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 18),
                  Obx(
                    () => GradientButton(
                      label: _manager.isSavingProfile.value
                          ? 'ENREGISTREMENT...'
                          : 'ENREGISTRER',
                      onPressed: _manager.isSavingProfile.value
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) {
                                return;
                              }

                              try {
                                await _manager.saveProfile(
                                  firstName: firstNameCtrl.text.trim(),
                                  lastName: lastNameCtrl.text.trim(),
                                  email: emailCtrl.text.trim(),
                                  phone: phoneCtrl.text.trim(),
                                  city: cityCtrl.text.trim(),
                                  region: regionCtrl.text.trim(),
                                  headline: headlineCtrl.text.trim(),
                                  summary: summaryCtrl.text.trim(),
                                  skills: _splitCommaList(skillsCtrl.text),
                                );
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                                Get.snackbar(
                                  'Profil',
                                  'Informations mises a jour.',
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              } on Exception catch (error) {
                                _showError(error);
                              }
                            },
                      textColor: AppColors.onPrimary,
                      height: 54,
                      borderRadius: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openCvEditor(
    BuildContext context, {
    HomeCvSection? section,
  }) async {
    final titleCtrl = TextEditingController(text: section?.title ?? '');
    final organizationCtrl =
        TextEditingController(text: section?.organization ?? '');
    final descriptionCtrl =
        TextEditingController(text: section?.description ?? '');
    final missionsCtrl = TextEditingController(
      text: (section?.missions ?? const []).join('\n'),
    );
    final achievementsCtrl = TextEditingController(
      text: (section?.achievements ?? const []).join('\n'),
    );
    final levelCtrl = TextEditingController(text: section?.level ?? '');
    final mentionCtrl = TextEditingController(text: section?.mention ?? '');
    final linkCtrl = TextEditingController(text: section?.externalUrl ?? '');
    final formKey = GlobalKey<FormState>();
    var sectionType = section?.sectionType ?? 'experience';
    var startDate = section?.startDate;
    var endDate = section?.endDate;
    var isCurrent = section?.isCurrent ?? false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            18,
            20,
            20 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              final labels = _cvLabelsFor(sectionType);

              Future<void> submitCvSection({
                required bool addAnother,
              }) async {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                final updated = _manager.cvSections.toList(
                  growable: true,
                );
                final next = HomeCvSection(
                  id: section?.id,
                  sectionType: sectionType,
                  title: titleCtrl.text.trim(),
                  organization: organizationCtrl.text.trim(),
                  startDate: startDate,
                  endDate: endDate,
                  isCurrent: isCurrent,
                  description: descriptionCtrl.text.trim(),
                  missions: _splitLines(missionsCtrl.text),
                  achievements: _splitLines(
                    achievementsCtrl.text,
                  ),
                  level: levelCtrl.text.trim(),
                  mention: mentionCtrl.text.trim(),
                  externalUrl: linkCtrl.text.trim(),
                  displayOrder: section?.displayOrder ?? updated.length,
                );

                if (section == null) {
                  updated.add(next);
                } else {
                  final index = updated.indexWhere(
                    (entry) => entry.id == section.id,
                  );
                  if (index >= 0) {
                    updated[index] = next;
                  }
                }

                try {
                  await _manager.saveCv(updated);
                  if (!addAnother || section != null) {
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  } else {
                    titleCtrl.clear();
                    organizationCtrl.clear();
                    descriptionCtrl.clear();
                    missionsCtrl.clear();
                    achievementsCtrl.clear();
                    levelCtrl.clear();
                    mentionCtrl.clear();
                    linkCtrl.clear();
                    setState(() {
                      startDate = null;
                      endDate = null;
                      isCurrent = false;
                    });
                  }
                  Get.snackbar(
                    'CV',
                    addAnother && section == null
                        ? 'Section sauvegardee. Ajoutez la suivante.'
                        : 'Section sauvegardee.',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                } on Exception catch (error) {
                  _showError(error);
                }
              }

              return SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _BottomSheetHandle(),
                      const SizedBox(height: 14),
                      Text(
                        section == null
                            ? 'Ajouter une section CV'
                            : 'Modifier la section CV',
                        style: AppTextStyles.headlineLg,
                      ),
                      const SizedBox(height: 14),
                      _TypeWrapPicker(
                        value: sectionType,
                        items: const {
                          'experience': 'Experience',
                          'education': 'Formation',
                          'certification': 'Certification',
                          'project': 'Projet',
                          'skill': 'Competence',
                          'language': 'Langue',
                          'volunteer': 'Benevolat',
                          'award': 'Prix',
                          'publication': 'Publication',
                          'reference': 'Reference',
                          'other': 'Autre',
                        },
                        selectedColor: const Color(0xFFE7FFF4),
                        selectedTextColor: const Color(0xFF087443),
                        onChanged: (value) =>
                            setState(() => sectionType = value),
                      ),
                      const SizedBox(height: 12),
                      _TextFieldBlock(
                        controller: titleCtrl,
                        label: labels.title,
                        validator: _requiredValidator,
                      ),
                      const SizedBox(height: 12),
                      _TextFieldBlock(
                        controller: organizationCtrl,
                        label: labels.organization,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _DateFieldBlock(
                              label: 'Debut',
                              value: _formatDate(startDate),
                              onTap: () async {
                                final picked = await _pickDate(
                                  context,
                                  initialDate: startDate,
                                );
                                if (picked != null) {
                                  setState(() => startDate = picked);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DateFieldBlock(
                              label: 'Fin',
                              value:
                                  isCurrent ? 'En cours' : _formatDate(endDate),
                              onTap: isCurrent
                                  ? null
                                  : () async {
                                      final picked = await _pickDate(
                                        context,
                                        initialDate: endDate,
                                      );
                                      if (picked != null) {
                                        setState(() => endDate = picked);
                                      }
                                    },
                            ),
                          ),
                        ],
                      ),
                      SwitchListTile.adaptive(
                        value: isCurrent,
                        onChanged: (value) {
                          setState(() {
                            isCurrent = value;
                            if (value) {
                              endDate = null;
                            }
                          });
                        },
                        activeTrackColor: const Color(0xFFB9F4C5),
                        activeThumbColor: const Color(0xFF0F9D58),
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          labels.current,
                          style: AppTextStyles.titleMd,
                        ),
                      ),
                      _TextFieldBlock(
                        controller: descriptionCtrl,
                        label: labels.description,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 12),
                      _TextFieldBlock(
                        controller: missionsCtrl,
                        label: labels.missions,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 12),
                      _TextFieldBlock(
                        controller: achievementsCtrl,
                        label: labels.achievements,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _TextFieldBlock(
                              controller: levelCtrl,
                              label: labels.level,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _TextFieldBlock(
                              controller: mentionCtrl,
                              label: labels.mention,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _TextFieldBlock(
                        controller: linkCtrl,
                        label: labels.link,
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 18),
                      Obx(
                        () => GradientButton(
                          label: _manager.isSavingCv.value
                              ? 'ENREGISTREMENT...'
                              : 'SAUVEGARDER',
                          onPressed: _manager.isSavingCv.value
                              ? null
                              : () => submitCvSection(addAnother: false),
                          textColor: AppColors.onPrimary,
                          height: 54,
                          borderRadius: 16,
                        ),
                      ),
                      if (section == null) ...[
                        const SizedBox(height: 10),
                        Obx(
                          () => _AddMoreButton(
                            label: '+ Enregistrer et ajouter encore',
                            onTap: _manager.isSavingCv.value
                                ? null
                                : () => submitCvSection(addAnother: true),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _openPortfolioEditor(
    BuildContext context, {
    HomePortfolioItem? item,
  }) async {
    final titleCtrl = TextEditingController(text: item?.title ?? '');
    final descriptionCtrl =
        TextEditingController(text: item?.description ?? '');
    final resultsCtrl = TextEditingController(text: item?.results ?? '');
    final linkCtrl = TextEditingController(text: item?.externalUrl ?? '');
    final stackCtrl =
        TextEditingController(text: (item?.techStack ?? const []).join(', '));
    final urlsCtrl =
        TextEditingController(text: (item?.mediaUrls ?? const []).join('\n'));
    final formKey = GlobalKey<FormState>();
    var itemType = item?.itemType ?? 'project';
    var isPublic = item?.isPublic ?? true;
    final localFiles = <_PendingUploadFile>[];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            18,
            20,
            20 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              final labels = _portfolioLabelsFor(itemType);

              Future<void> submitPortfolioItem({
                required bool addAnother,
              }) async {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                final next = HomePortfolioItem(
                  id: item?.id,
                  itemType: itemType,
                  title: titleCtrl.text.trim(),
                  description: descriptionCtrl.text.trim(),
                  results: resultsCtrl.text.trim(),
                  externalUrl: linkCtrl.text.trim(),
                  techStack: _splitCommaList(stackCtrl.text),
                  mediaUrls: _splitLines(urlsCtrl.text),
                  displayOrder:
                      item?.displayOrder ?? _manager.portfolioItems.length,
                  isVerified: item?.isVerified ?? false,
                  isPublic: isPublic,
                );

                try {
                  await _manager.savePortfolioItem(
                    next,
                    mediaFiles: localFiles
                        .map(
                          (file) => ApiMultipartFile(
                            field: 'media_uploads[]',
                            bytes: file.bytes,
                            filename: file.name,
                          ),
                        )
                        .toList(growable: false),
                  );
                  if (!addAnother || item != null) {
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  } else {
                    titleCtrl.clear();
                    descriptionCtrl.clear();
                    resultsCtrl.clear();
                    linkCtrl.clear();
                    stackCtrl.clear();
                    urlsCtrl.clear();
                    setState(() => localFiles.clear());
                  }
                  Get.snackbar(
                    'Portfolio',
                    addAnother && item == null
                        ? 'Projet sauvegarde. Ajoutez le suivant.'
                        : 'Projet sauvegarde.',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                } on Exception catch (error) {
                  _showError(error);
                }
              }

              return SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _BottomSheetHandle(),
                      const SizedBox(height: 14),
                      Text(
                        item == null ? labels.addTitle : labels.editTitle,
                        style: AppTextStyles.headlineLg,
                      ),
                      const SizedBox(height: 14),
                      _TypeWrapPicker(
                        value: itemType,
                        items: const {
                          'project': 'Projet',
                          'case_study': 'Etude de cas',
                          'certification': 'Certification',
                          'document': 'Document',
                          'media': 'Media',
                          'testimonial': 'Temoignage',
                          'other': 'Autre',
                        },
                        selectedColor: const Color(0xFFFFE7F1),
                        selectedTextColor: const Color(0xFFB42369),
                        onChanged: (value) => setState(() => itemType = value),
                      ),
                      const SizedBox(height: 12),
                      _TextFieldBlock(
                        controller: titleCtrl,
                        label: labels.title,
                        validator: _requiredValidator,
                      ),
                      const SizedBox(height: 12),
                      _TextFieldBlock(
                        controller: descriptionCtrl,
                        label: labels.description,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 12),
                      _TextFieldBlock(
                        controller: resultsCtrl,
                        label: labels.results,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      _TextFieldBlock(
                        controller: linkCtrl,
                        label: labels.link,
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 12),
                      _TextFieldBlock(
                        controller: stackCtrl,
                        label: labels.stack,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      _TextFieldBlock(
                        controller: urlsCtrl,
                        label: labels.mediaUrls,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        value: isPublic,
                        onChanged: (value) => setState(() => isPublic = value),
                        activeTrackColor: const Color(0xFFB9F4C5),
                        activeThumbColor: const Color(0xFF0F9D58),
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          labels.visibilityTitle,
                          style: AppTextStyles.titleMd,
                        ),
                        subtitle: Text(
                          labels.visibilitySubtitle,
                          style: AppTextStyles.bodySm,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _FilePickerBox(
                        title: labels.filesTitle,
                        emptyLabel: labels.emptyFiles,
                        fileNames: localFiles.map((file) => file.name).toList(),
                        onAddFiles: () async {
                          final picked = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: const [
                              'jpg',
                              'jpeg',
                              'png',
                              'webp',
                              'pdf',
                              'doc',
                              'docx',
                              'mp4',
                              'mov',
                            ],
                            allowMultiple: true,
                            withData: true,
                          );
                          if (picked == null || picked.files.isEmpty) {
                            return;
                          }
                          final files = <_PendingUploadFile>[];
                          for (final file in picked.files) {
                            final bytes = file.bytes;
                            if (bytes != null) {
                              files.add(
                                _PendingUploadFile(
                                  name: file.name,
                                  bytes: bytes,
                                ),
                              );
                            }
                          }
                          if (files.isNotEmpty) {
                            setState(() => localFiles.addAll(files));
                          }
                        },
                        onRemoveFile: (index) {
                          setState(() => localFiles.removeAt(index));
                        },
                      ),
                      const SizedBox(height: 18),
                      Obx(
                        () => GradientButton(
                          label: _manager.isSavingPortfolio.value
                              ? 'ENREGISTREMENT...'
                              : 'SAUVEGARDER',
                          onPressed: _manager.isSavingPortfolio.value
                              ? null
                              : () => submitPortfolioItem(addAnother: false),
                          textColor: AppColors.onPrimary,
                          height: 54,
                          borderRadius: 16,
                        ),
                      ),
                      if (item == null) ...[
                        const SizedBox(height: 10),
                        Obx(
                          () => _AddMoreButton(
                            label: '+ Enregistrer et ajouter encore',
                            onTap: _manager.isSavingPortfolio.value
                                ? null
                                : () => submitPortfolioItem(addAnother: true),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<DateTime?> _pickDate(
    BuildContext context, {
    DateTime? initialDate,
  }) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      locale: const Locale('fr', 'FR'),
      initialDate: initialDate ?? now,
      firstDate: DateTime(1990),
      lastDate: DateTime(now.year + 5),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Champ requis';
    }
    return null;
  }

  List<String> _splitCommaList(String raw) {
    return raw
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  List<String> _splitLines(String raw) {
    return raw
        .split(RegExp(r'\r\n|\r|\n'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'Choisir';
    }
    return DateFormat('dd/MM/yyyy').format(value);
  }

  _CvFieldLabels _cvLabelsFor(String sectionType) {
    switch (sectionType) {
      case 'education':
        return const _CvFieldLabels(
          title: 'Diplome / formation',
          organization: 'Etablissement',
          description: 'Description du programme',
          missions: 'Modules / cours importants (une ligne par point)',
          achievements: 'Resultats / projets academiques (une ligne par point)',
          level: 'Niveau',
          mention: 'Mention / statut',
          link: 'Lien du diplome ou etablissement',
          current: 'Formation en cours',
        );
      case 'certification':
        return const _CvFieldLabels(
          title: 'Nom de la certification',
          organization: 'Organisme certificateur',
          description: 'Description de la certification',
          missions: 'Competences validees (une ligne par point)',
          achievements: 'Preuves / scores / validations (une ligne par point)',
          level: 'Niveau',
          mention: 'Identifiant / statut',
          link: 'Lien de verification',
          current: 'Certification en cours',
        );
      case 'project':
        return const _CvFieldLabels(
          title: 'Nom du projet',
          organization: 'Client / organisation',
          description: 'Description du projet',
          missions: 'Responsabilites (une ligne par point)',
          achievements: 'Resultats obtenus (une ligne par point)',
          level: 'Role',
          mention: 'Statut',
          link: 'Lien du projet',
          current: 'Projet en cours',
        );
      case 'skill':
        return const _CvFieldLabels(
          title: 'Domaine de competence',
          organization: 'Contexte',
          description: 'Description',
          missions: 'Outils / savoir-faire (une ligne par point)',
          achievements: 'Preuves / realisations (une ligne par point)',
          level: 'Niveau',
          mention: 'Experience',
          link: 'Lien de preuve',
          current: 'Competence en cours de developpement',
        );
      case 'language':
        return const _CvFieldLabels(
          title: 'Langue',
          organization: 'Certification / contexte',
          description: 'Details',
          missions: 'Usages professionnels (une ligne par point)',
          achievements: 'Certifications / preuves (une ligne par point)',
          level: 'Niveau',
          mention: 'Score / mention',
          link: 'Lien de certification',
          current: 'Apprentissage en cours',
        );
      case 'volunteer':
        return const _CvFieldLabels(
          title: 'Role benevole',
          organization: 'Association / organisation',
          description: 'Description',
          missions: 'Missions (une ligne par point)',
          achievements: 'Impact (une ligne par point)',
          level: 'Role',
          mention: 'Statut',
          link: 'Lien externe',
          current: 'Engagement en cours',
        );
      case 'award':
        return const _CvFieldLabels(
          title: 'Prix / distinction',
          organization: 'Organisme',
          description: 'Description',
          missions: 'Criteres / contexte (une ligne par point)',
          achievements: 'Resultats / classement (une ligne par point)',
          level: 'Categorie',
          mention: 'Mention',
          link: 'Lien de preuve',
          current: 'Distinction en cours',
        );
      case 'publication':
        return const _CvFieldLabels(
          title: 'Titre de la publication',
          organization: 'Editeur / support',
          description: 'Resume',
          missions: 'Contributions (une ligne par point)',
          achievements: 'Impact / citations (une ligne par point)',
          level: 'Type',
          mention: 'Statut',
          link: 'Lien de publication',
          current: 'Publication en cours',
        );
      case 'reference':
        return const _CvFieldLabels(
          title: 'Nom de la reference',
          organization: 'Entreprise / relation',
          description: 'Contexte',
          missions: 'Informations de contact (une ligne par point)',
          achievements: 'Points recommandes (une ligne par point)',
          level: 'Role',
          mention: 'Disponibilite',
          link: 'Lien profil',
          current: 'Reference actuelle',
        );
      case 'other':
        return const _CvFieldLabels(
          title: 'Titre',
          organization: 'Organisation / contexte',
          description: 'Description',
          missions: 'Details (une ligne par point)',
          achievements: 'Points importants (une ligne par point)',
          level: 'Niveau / type',
          mention: 'Mention / statut',
          link: 'Lien externe',
          current: 'Toujours en cours',
        );
      case 'experience':
      default:
        return const _CvFieldLabels(
          title: 'Poste / intitule',
          organization: 'Entreprise / organisation',
          description: 'Description du poste',
          missions: 'Missions / responsabilites (une ligne par point)',
          achievements: 'Resultats / realisations (une ligne par point)',
          level: 'Niveau / seniorite',
          mention: 'Contrat / statut',
          link: 'Lien externe',
          current: 'Toujours en poste',
        );
    }
  }

  _PortfolioFieldLabels _portfolioLabelsFor(String itemType) {
    switch (itemType) {
      case 'case_study':
        return const _PortfolioFieldLabels(
          addTitle: 'Ajouter une etude de cas',
          editTitle: 'Modifier l\'etude de cas',
          title: 'Titre de l\'etude de cas',
          description: 'Probleme / contexte',
          results: 'Solution / impact mesure',
          link: 'Lien de l\'etude ou demo',
          stack: 'Outils / methodes',
          mediaUrls: 'Liens de preuves (une URL par ligne)',
          visibilityTitle: 'Visible par les entreprises',
          visibilitySubtitle:
              'Les recruteurs peuvent consulter cette etude de cas.',
          filesTitle: 'Fichiers de l\'etude',
          emptyFiles: 'Importez captures, documents, rapports ou videos.',
        );
      case 'certification':
        return const _PortfolioFieldLabels(
          addTitle: 'Ajouter une certification',
          editTitle: 'Modifier la certification',
          title: 'Nom de la certification',
          description: 'Description / organisme',
          results: 'Score / competences validees',
          link: 'Lien de verification',
          stack: 'Competences associees',
          mediaUrls: 'Liens de certificat (une URL par ligne)',
          visibilityTitle: 'Visible par les entreprises',
          visibilitySubtitle:
              'Les recruteurs peuvent verifier cette certification.',
          filesTitle: 'Fichiers de certification',
          emptyFiles: 'Importez certificat, badge ou preuve PDF/image.',
        );
      case 'document':
        return const _PortfolioFieldLabels(
          addTitle: 'Ajouter un document',
          editTitle: 'Modifier le document',
          title: 'Titre du document',
          description: 'Description du document',
          results: 'Utilite / valeur pour l\'entreprise',
          link: 'Lien du document',
          stack: 'Thematique / mots-cles',
          mediaUrls: 'Liens de documents (une URL par ligne)',
          visibilityTitle: 'Visible par les entreprises',
          visibilitySubtitle: 'Les recruteurs peuvent consulter ce document.',
          filesTitle: 'Documents a joindre',
          emptyFiles: 'Importez PDF, DOC, DOCX ou images.',
        );
      case 'media':
        return const _PortfolioFieldLabels(
          addTitle: 'Ajouter un media',
          editTitle: 'Modifier le media',
          title: 'Titre du media',
          description: 'Description du media',
          results: 'Message / impact',
          link: 'Lien du media',
          stack: 'Outils / format',
          mediaUrls: 'Liens media (une URL par ligne)',
          visibilityTitle: 'Visible par les entreprises',
          visibilitySubtitle:
              'Les recruteurs peuvent voir ce media dans le portfolio.',
          filesTitle: 'Medias a joindre',
          emptyFiles: 'Importez images, videos ou documents associes.',
        );
      case 'testimonial':
        return const _PortfolioFieldLabels(
          addTitle: 'Ajouter un temoignage',
          editTitle: 'Modifier le temoignage',
          title: 'Auteur / source du temoignage',
          description: 'Temoignage',
          results: 'Contexte / resultat cite',
          link: 'Lien de reference',
          stack: 'Relation / domaine',
          mediaUrls: 'Liens de preuves (une URL par ligne)',
          visibilityTitle: 'Visible par les entreprises',
          visibilitySubtitle: 'Les recruteurs peuvent consulter ce temoignage.',
          filesTitle: 'Preuves du temoignage',
          emptyFiles: 'Importez capture, lettre, PDF ou image.',
        );
      case 'other':
        return const _PortfolioFieldLabels(
          addTitle: 'Ajouter un element',
          editTitle: 'Modifier l\'element',
          title: 'Titre',
          description: 'Description',
          results: 'Impact / informations importantes',
          link: 'Lien externe',
          stack: 'Tags / mots-cles',
          mediaUrls: 'Liens associes (une URL par ligne)',
          visibilityTitle: 'Visible par les entreprises',
          visibilitySubtitle: 'Les recruteurs peuvent consulter cet element.',
          filesTitle: 'Fichiers a joindre',
          emptyFiles: 'Importez les fichiers utiles.',
        );
      case 'project':
      default:
        return const _PortfolioFieldLabels(
          addTitle: 'Ajouter un projet',
          editTitle: 'Modifier le projet',
          title: 'Titre du projet',
          description: 'Description du projet',
          results: 'Impact / resultats',
          link: 'Lien web / demo',
          stack: 'Technologies',
          mediaUrls: 'Liens de medias (une URL par ligne)',
          visibilityTitle: 'Visible par les entreprises',
          visibilitySubtitle: 'Les recruteurs peuvent consulter ce projet.',
          filesTitle: 'Fichiers du projet',
          emptyFiles: 'Importez captures, documents ou videos.',
        );
    }
  }

  void _showError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    Get.snackbar(
      'Erreur',
      message.isEmpty ? 'Une erreur est survenue.' : message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFFFF0F0),
      colorText: const Color(0xFFB42318),
    );
  }
}

class _CvFieldLabels {
  const _CvFieldLabels({
    required this.title,
    required this.organization,
    required this.description,
    required this.missions,
    required this.achievements,
    required this.level,
    required this.mention,
    required this.link,
    required this.current,
  });

  final String title;
  final String organization;
  final String description;
  final String missions;
  final String achievements;
  final String level;
  final String mention;
  final String link;
  final String current;
}

class _PortfolioFieldLabels {
  const _PortfolioFieldLabels({
    required this.addTitle,
    required this.editTitle,
    required this.title,
    required this.description,
    required this.results,
    required this.link,
    required this.stack,
    required this.mediaUrls,
    required this.visibilityTitle,
    required this.visibilitySubtitle,
    required this.filesTitle,
    required this.emptyFiles,
  });

  final String addTitle;
  final String editTitle;
  final String title;
  final String description;
  final String results;
  final String link;
  final String stack;
  final String mediaUrls;
  final String visibilityTitle;
  final String visibilitySubtitle;
  final String filesTitle;
  final String emptyFiles;
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.22),
          ),
        ),
        child: Icon(icon, color: AppColors.primaryDark),
      ),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.profile,
    required this.isUploadingAvatar,
    required this.onEditAvatar,
  });

  final HomeUserProfile profile;
  final bool isUploadingAvatar;
  final VoidCallback onEditAvatar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF4F7FB),
            Color(0xFFF2FBF0),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.22),
        ),
        boxShadow: AppColors.ambientShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AvatarEditor(
                imageUrl: profile.avatarUrl,
                isLoading: isUploadingAvatar,
                onEdit: onEditAvatar,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.fullName,
                      style: AppTextStyles.headlineLg.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.referenceLabel,
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.hintColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _VerificationPill(isVerified: profile.isVerified),
                  ],
                ),
              ),
            ],
          ),
          if (profile.headline.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              profile.headline,
              style: AppTextStyles.titleLg.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
          ],
          if (profile.summary.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              profile.summary,
              style: AppTextStyles.bodyMd.copyWith(height: 1.5),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetaChip(
                icon: Icons.calendar_month_rounded,
                color: const Color(0xFF2B7FFF),
                label: 'Membre depuis',
                value: profile.memberSinceLabel,
              ),
              _MetaChip(
                icon: Icons.location_on_outlined,
                color: const Color(0xFF00A86B),
                label: 'Localisation',
                value: profile.locationLabel.isEmpty
                    ? 'Non renseignee'
                    : profile.locationLabel,
              ),
            ],
          ),
          if (profile.skills.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.skills
                  .take(8)
                  .map(
                    (skill) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard.withValues(alpha: 0.80),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        skill,
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}

class _AvatarEditor extends StatelessWidget {
  const _AvatarEditor({
    required this.imageUrl,
    required this.isLoading,
    required this.onEdit,
  });

  final String imageUrl;
  final bool isLoading;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(26),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: imageUrl.trim().isEmpty
                ? const Icon(
                    Icons.person_rounded,
                    size: 42,
                    color: AppColors.primary,
                  )
                : CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.person_rounded,
                      size: 42,
                      color: AppColors.primary,
                    ),
                  ),
          ),
        ),
        Positioned(
          top: -2,
          right: -2,
          child: Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: Color(0xFF00C26F),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          right: -4,
          bottom: -4,
          child: GestureDetector(
            onTap: isLoading ? null : onEdit,
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF584BFF)],
                ),
                shape: BoxShape.circle,
              ),
              child: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.photo_camera_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VerificationPill extends StatelessWidget {
  const _VerificationPill({required this.isVerified});

  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    final color = isVerified ? const Color(0xFF169B51) : AppColors.bodyColor;
    final background =
        isVerified ? const Color(0xFFE6F8EB) : const Color(0xFFF4F3F0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.verified_rounded : Icons.shield_outlined,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            isVerified ? 'Verifie' : 'Non verifie',
            style: AppTextStyles.bodySm.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.bodySm),
              Text(
                value,
                style: AppTextStyles.titleMd.copyWith(
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactGrid extends StatelessWidget {
  const _ContactGrid({required this.profile});

  final HomeUserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _InfoTileCard(
                icon: Icons.mail_outline_rounded,
                color: const Color(0xFF2B7FFF),
                title: 'Email',
                value: profile.email.isEmpty ? 'Non renseigne' : profile.email,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoTileCard(
                icon: Icons.phone_in_talk_outlined,
                color: const Color(0xFF00A86B),
                title: 'Telephone',
                value: profile.phone.isEmpty ? 'Non renseigne' : profile.phone,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _InfoTileCard(
                icon: Icons.pin_drop_outlined,
                color: const Color(0xFFFF8A00),
                title: 'Ville',
                value: profile.city.isEmpty ? 'Non renseignee' : profile.city,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoTileCard(
                icon: Icons.map_outlined,
                color: const Color(0xFF7A5CFA),
                title: 'Region',
                value:
                    profile.region.isEmpty ? 'Non renseignee' : profile.region,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoTileCard extends StatelessWidget {
  const _InfoTileCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 12),
          Text(title, style: AppTextStyles.bodySm),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.titleMd.copyWith(color: AppColors.primaryDark),
          ),
        ],
      ),
    );
  }
}

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard({
    required this.preferences,
    required this.isBusy,
    required this.onChanged,
  });

  final HomeProfilePreferences preferences;
  final bool isBusy;
  final ValueChanged<HomeProfilePreferences> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        children: [
          _PreferenceSwitchRow(
            icon: Icons.notifications_active_outlined,
            color: const Color(0xFFFF9D00),
            title: 'Notifications',
            subtitle: 'Alertes, messages et mises a jour',
            value: preferences.notificationsEnabled,
            isBusy: isBusy,
            onChanged: (value) =>
                onChanged(preferences.copyWith(notificationsEnabled: value)),
          ),
          const SizedBox(height: 8),
          _PreferenceSwitchRow(
            icon: Icons.local_offer_outlined,
            color: const Color(0xFF2B7FFF),
            title: 'Nouvelles offres',
            subtitle: 'Offres ciblees selon votre profil',
            value: preferences.offerUpdates,
            isBusy: isBusy || !preferences.notificationsEnabled,
            onChanged: (value) =>
                onChanged(preferences.copyWith(offerUpdates: value)),
          ),
          const SizedBox(height: 8),
          _PreferenceSwitchRow(
            icon: Icons.forum_outlined,
            color: const Color(0xFF00A86B),
            title: 'Messages recruteurs',
            subtitle: 'Conversations et relances',
            value: preferences.messageAlerts,
            isBusy: isBusy || !preferences.notificationsEnabled,
            onChanged: (value) =>
                onChanged(preferences.copyWith(messageAlerts: value)),
          ),
          const SizedBox(height: 8),
          _PreferenceSwitchRow(
            icon: Icons.school_outlined,
            color: const Color(0xFF7A5CFA),
            title: 'Formations',
            subtitle: 'Parcours et certifications',
            value: preferences.trainingUpdates,
            isBusy: isBusy || !preferences.notificationsEnabled,
            onChanged: (value) =>
                onChanged(preferences.copyWith(trainingUpdates: value)),
          ),
          const SizedBox(height: 10),
          _ChoiceRow(
            icon: Icons.language_rounded,
            color: const Color(0xFF0CA6A6),
            title: 'Langue',
            subtitle: 'Choisissez la langue d\'affichage',
            options: const {'fr': 'Francais', 'en': 'English'},
            selected: preferences.language,
            isBusy: isBusy,
            onSelected: (value) =>
                onChanged(preferences.copyWith(language: value)),
          ),
          const SizedBox(height: 10),
          _ChoiceRow(
            icon: Icons.contrast_rounded,
            color: const Color(0xFF374151),
            title: 'Theme',
            subtitle: 'Preference synchronisee',
            options: const {'light': 'Clair', 'dark': 'Sombre'},
            selected: preferences.theme,
            isBusy: isBusy,
            onSelected: (value) =>
                onChanged(preferences.copyWith(theme: value)),
          ),
        ],
      ),
    );
  }
}

class _PreferenceSwitchRow extends StatelessWidget {
  const _PreferenceSwitchRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.isBusy,
    required this.onChanged,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final bool isBusy;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _SquareIconBadge(icon: icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleMd),
                Text(subtitle, style: AppTextStyles.bodySm),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: isBusy ? null : onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primaryMedium,
          ),
        ],
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selected,
    required this.isBusy,
    required this.onSelected,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Map<String, String> options;
  final String selected;
  final bool isBusy;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _SquareIconBadge(icon: icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleMd),
                Text(subtitle, style: AppTextStyles.bodySm),
              ],
            ),
          ),
          Wrap(
            spacing: 6,
            children: options.entries
                .map(
                  (entry) => ChoiceChip(
                    label: Text(entry.value),
                    selected: selected == entry.key,
                    onSelected: isBusy ? null : (_) => onSelected(entry.key),
                    selectedColor: color.withValues(alpha: 0.16),
                    labelStyle: AppTextStyles.bodySm.copyWith(
                      color:
                          selected == entry.key ? color : AppColors.bodyColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _SquareIconBadge extends StatelessWidget {
  const _SquareIconBadge({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color),
    );
  }
}

class _CvOverviewCard extends StatelessWidget {
  const _CvOverviewCard({
    required this.manager,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onUploadCv,
    required this.onPreviewCv,
    required this.onTemplateChanged,
  });

  final HomeProfileManager manager;
  final VoidCallback onAdd;
  final ValueChanged<HomeCvSection> onEdit;
  final ValueChanged<HomeCvSection> onDelete;
  final VoidCallback onUploadCv;
  final VoidCallback onPreviewCv;
  final ValueChanged<String> onTemplateChanged;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (manager.isLoadingCv.value && manager.cvSections.isEmpty) {
        return const _InlineLoader(label: 'Chargement du CV...');
      }

      return _SectionCard(
        icon: Icons.description_outlined,
        color: const Color(0xFF7A5CFA),
        title: 'CV interactif',
        subtitle: '${manager.cvSections.length} sections structurees',
        action: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              onPressed: manager.isPreviewingCv.value ? null : onPreviewCv,
              icon: manager.isPreviewingCv.value
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.visibility_outlined),
              label: const Text('Apercu'),
            ),
            TextButton.icon(
              onPressed:
                  manager.isExportingCv.value ? null : manager.exportCvPdf,
              icon: manager.isExportingCv.value
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded),
              label: const Text('Telecharger'),
            ),
          ],
        ),
        child: manager.cvLoadError.value.isNotEmpty &&
                manager.cvSections.isEmpty
            ? _InlineMessageCard(
                icon: Icons.warning_amber_rounded,
                color: const Color(0xFFB45309),
                message: manager.cvLoadError.value,
                actionLabel: 'Recharger',
                onAction: manager.loadCv,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CvTemplatePicker(
                    selected: manager.selectedCvTemplate.value,
                    onChanged: onTemplateChanged,
                  ),
                  const SizedBox(height: 12),
                  _UploadedCvTile(
                    uploadedCv: manager.uploadedCv.value,
                    isUploading: manager.isUploadingCvFile.value,
                    onUpload: onUploadCv,
                  ),
                  const SizedBox(height: 12),
                  if (manager.cvSections.isEmpty)
                    _InlineMessageCard(
                      icon: Icons.auto_awesome_outlined,
                      color: const Color(0xFF7A5CFA),
                      message:
                          'Ajoutez vos experiences, formations et certifications.',
                      actionLabel: 'Creer le CV',
                      onAction: onAdd,
                    )
                  else ...[
                    ...manager.cvSections.asMap().entries.map(
                          (entry) => Padding(
                            padding: EdgeInsets.only(
                              bottom: entry.key == manager.cvSections.length - 1
                                  ? 0
                                  : 12,
                            ),
                            child: _CvCard(
                              section: entry.value,
                              onEdit: () => onEdit(entry.value),
                              onDelete: () => onDelete(entry.value),
                            ),
                          ),
                        ),
                    const SizedBox(height: 12),
                    _AddMoreButton(
                      label: '+ Ajouter encore',
                      onTap: onAdd,
                    ),
                  ],
                ],
              ),
      );
    });
  }
}

class _CvTemplatePicker extends StatelessWidget {
  const _CvTemplatePicker({
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Modele du CV', style: AppTextStyles.titleMd),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: HomeProfileManager.cvTemplateOptions
              .map(
                (template) => ChoiceChip(
                  label: Text(template.label),
                  selected: selected == template.id,
                  onSelected: (_) => onChanged(template.id),
                  selectedColor: const Color(0xFFE7FFF4),
                  labelStyle: AppTextStyles.bodySm.copyWith(
                    color: selected == template.id
                        ? const Color(0xFF087443)
                        : AppColors.bodyColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _UploadedCvTile extends StatelessWidget {
  const _UploadedCvTile({
    required this.uploadedCv,
    required this.isUploading,
    required this.onUpload,
  });

  final HomeUploadedCv uploadedCv;
  final bool isUploading;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const _SquareIconBadge(
            icon: Icons.upload_file_outlined,
            color: Color(0xFF2B7FFF),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CV importe', style: AppTextStyles.titleMd),
                const SizedBox(height: 2),
                Text(
                  uploadedCv.hasFile
                      ? (uploadedCv.fileName.isNotEmpty
                          ? uploadedCv.fileName
                          : uploadedCv.url)
                      : 'Ajoutez votre CV PDF, DOC ou DOCX.',
                  style: AppTextStyles.bodySm,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: isUploading ? null : onUpload,
            icon: isUploading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_rounded),
            label: Text(uploadedCv.hasFile ? 'Remplacer' : 'Importer'),
          ),
        ],
      ),
    );
  }
}

class _AddMoreButton extends StatelessWidget {
  const _AddMoreButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.add_rounded),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _PortfolioOverviewCard extends StatelessWidget {
  const _PortfolioOverviewCard({
    required this.manager,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onOpenLink,
  });

  final HomeProfileManager manager;
  final VoidCallback onAdd;
  final ValueChanged<HomePortfolioItem> onEdit;
  final ValueChanged<HomePortfolioItem> onDelete;
  final ValueChanged<String> onOpenLink;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (manager.isLoadingPortfolio.value && manager.portfolioItems.isEmpty) {
        return const _InlineLoader(label: 'Chargement du portfolio...');
      }

      return _SectionCard(
        icon: Icons.workspaces_outlined,
        color: const Color(0xFFEB4D8A),
        title: 'Projets & portfolio',
        subtitle: 'Visible par les entreprises selon chaque projet',
        child: manager.portfolioLoadError.value.isNotEmpty &&
                manager.portfolioItems.isEmpty
            ? _InlineMessageCard(
                icon: Icons.warning_amber_rounded,
                color: const Color(0xFFB45309),
                message: manager.portfolioLoadError.value,
                actionLabel: 'Recharger',
                onAction: manager.loadPortfolio,
              )
            : manager.portfolioItems.isEmpty
                ? _InlineMessageCard(
                    icon: Icons.collections_bookmark_outlined,
                    color: const Color(0xFFEB4D8A),
                    message:
                        'Ajoutez vos projets avec captures, demo, stack et resultats.',
                    actionLabel: 'Ajouter un projet',
                    onAction: onAdd,
                  )
                : Column(
                    children: [
                      ...manager.portfolioItems.asMap().entries.map(
                            (entry) => Padding(
                              padding: EdgeInsets.only(
                                bottom: entry.key ==
                                        manager.portfolioItems.length - 1
                                    ? 0
                                    : 14,
                              ),
                              child: _ProjectCard(
                                item: entry.value,
                                onEdit: () => onEdit(entry.value),
                                onDelete: () => onDelete(entry.value),
                                onOpenLink:
                                    entry.value.externalUrl.trim().isEmpty
                                        ? null
                                        : () => onOpenLink(
                                              entry.value.externalUrl,
                                            ),
                              ),
                            ),
                          ),
                      const SizedBox(height: 12),
                      _AddMoreButton(
                        label: '+ Ajouter encore',
                        onTap: onAdd,
                      ),
                    ],
                  ),
      );
    });
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.child,
    this.action,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SquareIconBadge(icon: icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.titleLg),
                    Text(subtitle, style: AppTextStyles.bodySm),
                  ],
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _CvCard extends StatelessWidget {
  const _CvCard({
    required this.section,
    required this.onEdit,
    required this.onDelete,
  });

  final HomeCvSection section;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(section.title, style: AppTextStyles.titleLg),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Modifier')),
                  PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                ],
              ),
            ],
          ),
          Text(
            [
              if (section.organization.trim().isNotEmpty) section.organization,
              _cvDates(section),
            ].where((entry) => entry.trim().isNotEmpty).join(' • '),
            style: AppTextStyles.bodySm,
          ),
          if (section.description.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(section.description, style: AppTextStyles.bodyMd),
          ],
          if (section.level.trim().isNotEmpty ||
              section.mention.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (section.level.trim().isNotEmpty)
                  _MiniInfoPill(label: section.level.trim()),
                if (section.mention.trim().isNotEmpty)
                  _MiniInfoPill(label: section.mention.trim()),
              ],
            ),
          ],
          if ([...section.missions, ...section.achievements].isNotEmpty) ...[
            const SizedBox(height: 8),
            ...[...section.missions, ...section.achievements].take(4).map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: AppTextStyles.bodyMd),
                        Expanded(
                            child: Text(item, style: AppTextStyles.bodyMd)),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  String _cvDates(HomeCvSection section) {
    final formatter = DateFormat('MM/yyyy');
    final start =
        section.startDate == null ? '' : formatter.format(section.startDate!);
    final end = section.isCurrent
        ? 'En cours'
        : section.endDate == null
            ? ''
            : formatter.format(section.endDate!);
    if (start.isEmpty && end.isEmpty) {
      return '';
    }
    if (start.isEmpty) {
      return end;
    }
    if (end.isEmpty) {
      return start;
    }
    return '$start - $end';
  }
}

class _MiniInfoPill extends StatelessWidget {
  const _MiniInfoPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySm.copyWith(
          color: const Color(0xFF2B7FFF),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onOpenLink,
  });

  final HomePortfolioItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onOpenLink;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(item.title, style: AppTextStyles.titleLg)),
              _PortfolioVisibilityPill(isPublic: item.isPublic),
              const SizedBox(width: 6),
              PopupMenuButton<String>(
                onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Modifier')),
                  PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                ],
              ),
            ],
          ),
          if (item.description.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(item.description, style: AppTextStyles.bodyMd),
          ],
          if (item.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: item.mediaUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  return _PortfolioMediaTile(url: item.mediaUrls[index]);
                },
              ),
            ),
          ],
          if (item.techStack.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: item.techStack
                  .map(
                    (tech) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F1FF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        tech,
                        style: AppTextStyles.bodySm.copyWith(
                          color: const Color(0xFF2B7FFF),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          if (item.results.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE7FFF4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                item.results,
                style: AppTextStyles.bodyMd.copyWith(
                  color: const Color(0xFF087443),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (onOpenLink != null) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onOpenLink,
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Ouvrir le lien'),
            ),
          ],
        ],
      ),
    );
  }
}

class _PortfolioVisibilityPill extends StatelessWidget {
  const _PortfolioVisibilityPill({required this.isPublic});

  final bool isPublic;

  @override
  Widget build(BuildContext context) {
    final color = isPublic ? const Color(0xFF087443) : AppColors.bodyColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isPublic ? const Color(0xFFE7FFF4) : AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isPublic ? 'Visible' : 'Prive',
        style: AppTextStyles.bodySm.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _PortfolioMediaTile extends StatelessWidget {
  const _PortfolioMediaTile({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final isImage = _looksLikeImageUrl(url);
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 130,
        child: isImage
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _FileMediaPlaceholder(url: url),
              )
            : _FileMediaPlaceholder(url: url),
      ),
    );
  }

  bool _looksLikeImageUrl(String rawUrl) {
    final path = Uri.tryParse(rawUrl)?.path.toLowerCase() ?? rawUrl;
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.webp') ||
        path.endsWith('.gif');
  }
}

class _FileMediaPlaceholder extends StatelessWidget {
  const _FileMediaPlaceholder({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final pathSegments = Uri.tryParse(url)?.pathSegments ?? const <String>[];
    final fileName = pathSegments.isEmpty ? url : pathSegments.last;
    return Container(
      color: AppColors.surfaceContainer,
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.insert_drive_file_outlined),
          const SizedBox(height: 8),
          Text(
            fileName.isEmpty ? 'Fichier' : fileName,
            style: AppTextStyles.bodySm,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.headlineMd.copyWith(fontSize: 20),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            actionLabel,
            style: AppTextStyles.bodySm.copyWith(
              color: onTap == null ? AppColors.hintColor : AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _InlineLoader extends StatelessWidget {
  const _InlineLoader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 12),
            Text(label, style: AppTextStyles.bodyMd),
          ],
        ),
      ),
    );
  }
}

class _InlineMessageCard extends StatelessWidget {
  const _InlineMessageCard({
    required this.icon,
    required this.color,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final Color color;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: AppTextStyles.bodyMd)),
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _BottomSheetHandle extends StatelessWidget {
  const _BottomSheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 46,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.surfaceHighest,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _TextFieldBlock extends StatelessWidget {
  const _TextFieldBlock({
    required this.controller,
    required this.label,
    this.validator,
    this.maxLines = 1,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.titleMd),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.primaryDark),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceLow,
            contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}

class _TypeWrapPicker extends StatelessWidget {
  const _TypeWrapPicker({
    required this.value,
    required this.items,
    required this.selectedColor,
    required this.selectedTextColor,
    required this.onChanged,
  });

  final String value;
  final Map<String, String> items;
  final Color selectedColor;
  final Color selectedTextColor;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.entries
          .map(
            (entry) => ChoiceChip(
              label: Text(entry.value),
              selected: value == entry.key,
              onSelected: (_) => onChanged(entry.key),
              selectedColor: selectedColor,
              labelStyle: AppTextStyles.bodySm.copyWith(
                color: value == entry.key
                    ? selectedTextColor
                    : AppColors.bodyColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _DateFieldBlock extends StatelessWidget {
  const _DateFieldBlock({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.titleMd),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: AppColors.bodyColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FilePickerBox extends StatelessWidget {
  const _FilePickerBox({
    required this.title,
    required this.emptyLabel,
    required this.fileNames,
    required this.onAddFiles,
    required this.onRemoveFile,
  });

  final String title;
  final String emptyLabel;
  final List<String> fileNames;
  final VoidCallback onAddFiles;
  final ValueChanged<int> onRemoveFile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: AppTextStyles.titleMd),
              const Spacer(),
              TextButton(
                onPressed: onAddFiles,
                child: const Text('Ajouter'),
              ),
            ],
          ),
          if (fileNames.isEmpty)
            Text(
              emptyLabel,
              style: AppTextStyles.bodySm,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: fileNames
                  .asMap()
                  .entries
                  .map(
                    (entry) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE7F1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.photo_outlined,
                            size: 16,
                            color: Color(0xFFB42369),
                          ),
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 180),
                            child: Text(
                              entry.value,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySm.copyWith(
                                color: const Color(0xFFB42369),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => onRemoveFile(entry.key),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: Color(0xFFB42369),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}
