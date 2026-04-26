part of '../home_profile_manager.dart';

/// PDF builders extraits de HomeProfileManager.
extension HomeProfileManagerPdf on HomeProfileManager {
  Future<void> exportCvPdf() async {
    isExportingCv.value = true;

    try {
      final bytes = await buildCvPdfBytes();
      await Printing.sharePdf(
        bytes: bytes,
        filename: _cvDownloadFileName(),
      );
    } finally {
      isExportingCv.value = false;
    }
  }

  Future<void> previewCvPdf() async {
    isPreviewingCv.value = true;

    try {
      final bytes = await buildCvPdfBytes();
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: _cvDownloadFileName(),
      );
    } finally {
      isPreviewingCv.value = false;
    }
  }

  void changeCvTemplate(String templateId) {
    final exists = HomeProfileManager.cvTemplateOptions.any((entry) => entry.id == templateId);
    if (exists) {
      selectedCvTemplate.value = templateId;
    }
  }

  Future<Uint8List> buildCvPdfBytes({String? templateId}) async {
    final document = pw.Document();
    final currentProfile = profile.value;
    final sections = _sortedCvSections();
    final template = templateId ?? selectedCvTemplate.value;

    switch (template) {
      case 'ats':
        _addAtsCvPage(document, currentProfile, sections);
        break;
      case 'executive':
        _addExecutiveCvPage(document, currentProfile, sections);
        break;
      case 'international':
      default:
        _addInternationalCvPage(document, currentProfile, sections);
        break;
    }

    return document.save();
  }

  void _addInternationalCvPage(
    pw.Document document,
    HomeUserProfile currentProfile,
    List<HomeCvSection> sections,
  ) {
    document.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(30),
        ),
        build: (context) {
          return [
            _pdfHeader(
              currentProfile,
              accent: PdfColors.green700,
              filled: true,
            ),
            pw.SizedBox(height: 16),
            if (currentProfile.summary.trim().isNotEmpty) ...[
              _pdfSectionTitle('Profil', accent: PdfColors.green700),
              pw.Text(
                currentProfile.summary,
                style: const pw.TextStyle(fontSize: 11, lineSpacing: 3),
              ),
              pw.SizedBox(height: 14),
            ],
            if (currentProfile.skills.isNotEmpty) ...[
              _pdfSectionTitle('Competences cles', accent: PdfColors.green700),
              _pdfSkillWrap(currentProfile.skills, PdfColors.green50),
              pw.SizedBox(height: 14),
            ],
            ..._buildPdfCvSections(sections, accent: PdfColors.green700),
          ];
        },
      ),
    );
  }

  void _addAtsCvPage(
    pw.Document document,
    HomeUserProfile currentProfile,
    List<HomeCvSection> sections,
  ) {
    document.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.symmetric(horizontal: 36, vertical: 32),
        ),
        build: (context) {
          return [
            pw.Center(
              child: pw.Text(
                currentProfile.fullName.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Center(child: _pdfContactLine(currentProfile)),
            if (currentProfile.headline.trim().isNotEmpty) ...[
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  currentProfile.headline,
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ),
            ],
            pw.SizedBox(height: 18),
            if (currentProfile.summary.trim().isNotEmpty) ...[
              _pdfSectionTitle('Professional summary',
                  accent: PdfColors.grey900),
              pw.Text(
                currentProfile.summary,
                style: const pw.TextStyle(fontSize: 11, lineSpacing: 3),
              ),
              pw.SizedBox(height: 12),
            ],
            if (currentProfile.skills.isNotEmpty) ...[
              _pdfSectionTitle('Skills', accent: PdfColors.grey900),
              pw.Text(
                currentProfile.skills.join(', '),
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.SizedBox(height: 12),
            ],
            ..._buildPdfCvSections(
              sections,
              accent: PdfColors.grey900,
              uppercaseTitles: true,
              useChips: false,
            ),
          ];
        },
      ),
    );
  }

  void _addExecutiveCvPage(
    pw.Document document,
    HomeUserProfile currentProfile,
    List<HomeCvSection> sections,
  ) {
    document.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(28),
        ),
        build: (context) {
          return [
            _pdfHeader(
              currentProfile,
              accent: PdfColors.blueGrey800,
              filled: true,
              darkHeader: true,
            ),
            pw.SizedBox(height: 16),
            if (currentProfile.summary.trim().isNotEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.blueGrey200),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _pdfSectionTitle('Profil executif',
                        accent: PdfColors.blueGrey800),
                    pw.Text(
                      currentProfile.summary,
                      style: const pw.TextStyle(fontSize: 11, lineSpacing: 3),
                    ),
                  ],
                ),
              ),
            if (currentProfile.summary.trim().isNotEmpty)
              pw.SizedBox(height: 14),
            if (currentProfile.skills.isNotEmpty) ...[
              _pdfSectionTitle('Expertises', accent: PdfColors.blueGrey800),
              _pdfSkillWrap(currentProfile.skills, PdfColors.blueGrey50),
              pw.SizedBox(height: 14),
            ],
            ..._buildPdfCvSections(sections, accent: PdfColors.blueGrey800),
          ];
        },
      ),
    );
  }

  List<pw.Widget> _buildPdfCvSections(
    List<HomeCvSection> sections, {
    PdfColor accent = PdfColors.green700,
    bool uppercaseTitles = false,
    bool useChips = true,
  }) {
    if (sections.isEmpty) {
      return [
        _pdfSectionTitle('CV', accent: accent),
        pw.Text(
          'Aucune section n\'a encore ete renseignee.',
          style: const pw.TextStyle(fontSize: 11),
        ),
      ];
    }

    return sections.expand<pw.Widget>((section) {
      final widgets = <pw.Widget>[
        _pdfSectionTitle(
          uppercaseTitles
              ? _englishSectionLabel(section.sectionType)
              : _sectionLabel(section.sectionType),
          accent: accent,
        ),
        pw.Text(
          section.title,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ];

      final meta = [
        if (section.organization.trim().isNotEmpty) section.organization,
        _formatCvSectionDates(section),
      ].where((value) => value.trim().isNotEmpty).join('  |  ');

      if (meta.isNotEmpty) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 3),
            child: pw.Text(
              meta,
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
          ),
        );
      }

      final details = [
        if (section.level.trim().isNotEmpty) section.level.trim(),
        if (section.mention.trim().isNotEmpty) section.mention.trim(),
      ];
      if (details.isNotEmpty) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 5),
            child: useChips
                ? _pdfSkillWrap(details, PdfColors.grey100)
                : pw.Text(
                    details.join(' | '),
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
          ),
        );
      }

      if (section.description.trim().isNotEmpty) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 6),
            child: pw.Text(
              section.description,
              style: const pw.TextStyle(fontSize: 11, lineSpacing: 3),
            ),
          ),
        );
      }

      final bullets = [
        ...section.missions,
        ...section.achievements,
      ].where((item) => item.trim().isNotEmpty);

      if (bullets.isNotEmpty) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 6),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: bullets
                  .map(
                    (item) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 3),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('- ',
                              style: const pw.TextStyle(fontSize: 11)),
                          pw.Expanded(
                            child: pw.Text(
                              item,
                              style: const pw.TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        );
      }

      widgets.add(pw.SizedBox(height: 12));
      return widgets;
    }).toList(growable: false);
  }

  pw.Widget _pdfSectionTitle(
    String label, {
    PdfColor accent = PdfColors.green700,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        label.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: accent,
        ),
      ),
    );
  }

  pw.Widget _pdfHeader(
    HomeUserProfile currentProfile, {
    required PdfColor accent,
    bool filled = false,
    bool darkHeader = false,
  }) {
    final foreground = darkHeader ? PdfColors.white : PdfColors.grey900;
    final secondary = darkHeader ? PdfColors.grey200 : PdfColors.grey700;

    return pw.Container(
      width: double.infinity,
      padding: filled
          ? const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 14)
          : pw.EdgeInsets.zero,
      decoration: filled
          ? pw.BoxDecoration(
              color: darkHeader ? accent : PdfColors.green50,
              borderRadius: pw.BorderRadius.circular(8),
            )
          : null,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            currentProfile.fullName,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: foreground,
            ),
          ),
          if (currentProfile.headline.trim().isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 5),
              child: pw.Text(
                currentProfile.headline,
                style: pw.TextStyle(fontSize: 12, color: secondary),
              ),
            ),
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 8),
            child: _pdfContactLine(currentProfile, color: secondary),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfContactLine(
    HomeUserProfile currentProfile, {
    PdfColor color = PdfColors.grey700,
  }) {
    final parts = [
      if (currentProfile.email.trim().isNotEmpty) currentProfile.email,
      if (currentProfile.phone.trim().isNotEmpty) currentProfile.phone,
      if (currentProfile.locationLabel.trim().isNotEmpty)
        currentProfile.locationLabel,
    ];

    return pw.Text(
      parts.isEmpty ? 'Coordonnees non renseignees' : parts.join('  |  '),
      style: pw.TextStyle(fontSize: 10, color: color),
    );
  }

  pw.Widget _pdfSkillWrap(List<String> values, PdfColor background) {
    return pw.Wrap(
      spacing: 6,
      runSpacing: 6,
      children: values
          .map(
            (value) => pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: pw.BoxDecoration(
                color: background,
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
            ),
          )
          .toList(growable: false),
    );
  }

}
