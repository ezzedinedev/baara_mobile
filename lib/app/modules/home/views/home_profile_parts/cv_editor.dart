part of '../home_profile_tab.dart';

extension HomeProfileTabCvEditor on HomeProfileTab {
  // ignore: unused_element
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
                        selectedColor: AppColors.successSoft,
                        selectedTextColor: AppColors.successStrong,
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
                        activeTrackColor: AppColors.successSwitchTrack,
                        activeThumbColor: AppColors.successSwitch,
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

}
