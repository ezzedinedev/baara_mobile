part of '../home_profile_tab.dart';

extension HomeProfileTabPortfolioEditor on HomeProfileTab {
  // ignore: unused_element
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
                        selectedColor: AppColors.categoryPinkSoft,
                        selectedTextColor: AppColors.categoryPinkDeep,
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
                        activeTrackColor: AppColors.successSwitchTrack,
                        activeThumbColor: AppColors.successSwitch,
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

}
