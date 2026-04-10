import 'dart:convert';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/constants/api_constants.dart';
import '../../core/security/auth_token_store.dart';
import '../../data/providers/api_provider.dart';
import 'home_profile_models.dart';

class HomeProfileManager {
  HomeProfileManager(this._apiProvider) : _tokenStore = const AuthTokenStore();

  static const cvTemplateOptions = <HomeCvTemplateOption>[
    HomeCvTemplateOption(
      id: 'international',
      label: 'International',
      description: 'Profil, experience, formation, certifications.',
    ),
    HomeCvTemplateOption(
      id: 'ats',
      label: 'ATS',
      description: 'Simple, lisible par les logiciels de recrutement.',
    ),
    HomeCvTemplateOption(
      id: 'executive',
      label: 'Executive',
      description: 'Mise en page plus premium pour profils confirmes.',
    ),
  ];

  final ApiProvider _apiProvider;
  final AuthTokenStore _tokenStore;

  final profile = const HomeUserProfile.empty().obs;
  final preferences = const HomeProfilePreferences.defaults().obs;
  final uploadedCv = const HomeUploadedCv.empty().obs;
  final selectedCvTemplate = 'international'.obs;
  final cvSections = <HomeCvSection>[].obs;
  final portfolioItems = <HomePortfolioItem>[].obs;

  final isLoadingProfile = false.obs;
  final isLoadingCv = false.obs;
  final isLoadingPortfolio = false.obs;
  final isSavingProfile = false.obs;
  final isSavingPreferences = false.obs;
  final isUploadingAvatar = false.obs;
  final isUploadingCvFile = false.obs;
  final isSavingCv = false.obs;
  final isSavingPortfolio = false.obs;
  final isExportingCv = false.obs;
  final isPreviewingCv = false.obs;

  final profileLoadError = ''.obs;
  final cvLoadError = ''.obs;
  final portfolioLoadError = ''.obs;

  Future<void> loadAll() async {
    await Future.wait([
      loadProfile(),
      loadCv(),
      loadPortfolio(),
    ]);
  }

  Future<void> loadProfile() async {
    isLoadingProfile.value = true;
    profileLoadError.value = '';

    try {
      final token = await _readToken();
      final response = await _apiProvider.getJson(
        ApiConstants.profile,
        headers: ApiConstants.authHeadersWithoutContentType(token),
      );

      if (response['success'] != true) {
        throw Exception(
          _extractApiMessage(
            response,
            fallback: 'Impossible de charger le profil.',
          ),
        );
      }

      final data = _asMap(response['data']) ?? const <String, dynamic>{};
      profile.value = _parseProfile(data);
      preferences.value =
          _parsePreferences(_asMap(data['user'])?['preferences']);
    } on Exception catch (error) {
      profileLoadError.value = _friendlyErrorMessage(
        error,
        fallback: 'Impossible de charger le profil.',
      );
    } finally {
      isLoadingProfile.value = false;
    }
  }

  Future<void> loadCv() async {
    isLoadingCv.value = true;
    cvLoadError.value = '';

    try {
      final token = await _readToken();
      final response = await _apiProvider.getJson(
        ApiConstants.profileCv,
        headers: ApiConstants.authHeadersWithoutContentType(token),
      );

      if (response['success'] != true) {
        throw Exception(
          _extractApiMessage(response,
              fallback: 'Impossible de charger le CV.'),
        );
      }

      final data = response['data'];
      final uploaded = _parseUploadedCvFromPayload(data);
      if (uploaded != null) {
        uploadedCv.value = uploaded;
      }

      cvSections.assignAll(
        _extractItems(data).map(_parseCvSection).whereType<HomeCvSection>(),
      );
    } on Exception catch (error) {
      cvLoadError.value = _friendlyErrorMessage(
        error,
        fallback: 'Impossible de charger le CV.',
      );
    } finally {
      isLoadingCv.value = false;
    }
  }

  Future<void> loadPortfolio() async {
    isLoadingPortfolio.value = true;
    portfolioLoadError.value = '';

    try {
      final token = await _readToken();
      final response = await _apiProvider.getJson(
        ApiConstants.profilePortfolio,
        headers: ApiConstants.authHeadersWithoutContentType(token),
      );

      if (response['success'] != true) {
        throw Exception(
          _extractApiMessage(
            response,
            fallback: 'Impossible de charger le portfolio.',
          ),
        );
      }

      portfolioItems.assignAll(
        _extractItems(response['data'])
            .map(_parsePortfolioItem)
            .whereType<HomePortfolioItem>(),
      );
    } on Exception catch (error) {
      portfolioLoadError.value = _friendlyErrorMessage(
        error,
        fallback: 'Impossible de charger le portfolio.',
      );
    } finally {
      isLoadingPortfolio.value = false;
    }
  }

  Future<void> saveProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String city,
    required String region,
    required String headline,
    required String summary,
    required List<String> skills,
  }) async {
    isSavingProfile.value = true;

    try {
      final token = await _readToken();
      final response = await _apiProvider.putJson(
        ApiConstants.profile,
        {
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'phone': phone,
          'city': city,
          'region': region,
          'headline': headline,
          'summary': summary,
          'skills': skills,
        },
        headers: ApiConstants.authHeaders(token),
      );

      if (response['success'] != true) {
        throw Exception(
          _extractApiMessage(
            response,
            fallback: 'Impossible de mettre le profil a jour.',
          ),
        );
      }

      final data = _asMap(response['data']) ?? const <String, dynamic>{};
      final user = _asMap(data['user']) ?? const <String, dynamic>{};
      final candidateProfile =
          _asMap(data['profile']) ?? const <String, dynamic>{};

      profile.value = profile.value.copyWith(
        firstName: _asString(user['first_name']) ?? firstName,
        lastName: _asString(user['last_name']) ?? lastName,
        email: _asString(user['email']) ?? email,
        phone: _asString(user['phone']) ?? phone,
        city: _asString(user['city']) ?? city,
        region: _asString(user['region']) ?? region,
        headline: _asString(candidateProfile['headline']) ?? headline,
        summary: _asString(candidateProfile['summary']) ?? summary,
        skills: _asStringList(candidateProfile['skills']).isNotEmpty
            ? _asStringList(candidateProfile['skills'])
            : skills,
      );
    } finally {
      isSavingProfile.value = false;
    }
  }

  Future<void> savePreferences(HomeProfilePreferences nextPreferences) async {
    isSavingPreferences.value = true;

    try {
      final token = await _readToken();
      final response = await _apiProvider.putJson(
        ApiConstants.profilePreferences,
        {
          'notifications_enabled': nextPreferences.notificationsEnabled,
          'offer_updates': nextPreferences.offerUpdates,
          'application_updates': nextPreferences.applicationUpdates,
          'match_alerts': nextPreferences.matchAlerts,
          'message_alerts': nextPreferences.messageAlerts,
          'training_updates': nextPreferences.trainingUpdates,
          'theme': nextPreferences.theme,
          'language': nextPreferences.language,
        },
        headers: ApiConstants.authHeaders(token),
      );

      if (response['success'] != true) {
        throw Exception(
          _extractApiMessage(
            response,
            fallback: 'Impossible de sauvegarder les preferences.',
          ),
        );
      }

      final data = _asMap(response['data']) ?? const <String, dynamic>{};
      preferences.value = _parsePreferences(data['preferences']);
    } finally {
      isSavingPreferences.value = false;
    }
  }

  Future<void> uploadAvatar(XFile file) async {
    isUploadingAvatar.value = true;

    try {
      final token = await _readToken();
      final bytes = await file.readAsBytes();
      final response = await _apiProvider.sendMultipart(
        ApiConstants.profileAvatar,
        method: 'POST',
        headers: ApiConstants.authHeadersWithoutContentType(token),
        files: [
          ApiMultipartFile(
            field: 'avatar',
            bytes: bytes,
            filename: file.name.isEmpty ? 'avatar.jpg' : file.name,
          ),
        ],
      );

      if (response['success'] != true) {
        throw Exception(
          _extractApiMessage(
            response,
            fallback: 'Impossible de mettre la photo a jour.',
          ),
        );
      }

      final data = _asMap(response['data']) ?? const <String, dynamic>{};
      profile.value = profile.value.copyWith(
        avatarUrl: _resolveAssetUrl(_asString(data['avatar_url']) ?? ''),
      );
    } finally {
      isUploadingAvatar.value = false;
    }
  }

  Future<void> uploadCvFile({
    required Uint8List bytes,
    required String filename,
  }) async {
    isUploadingCvFile.value = true;

    try {
      final token = await _readToken();
      final response = await _apiProvider.sendMultipart(
        ApiConstants.profileCvUpload,
        method: 'POST',
        headers: ApiConstants.authHeadersWithoutContentType(token),
        fields: const {'document_type': 'cv'},
        files: [
          ApiMultipartFile(
            field: 'cv',
            bytes: bytes,
            filename: filename.trim().isEmpty ? 'cv.pdf' : filename.trim(),
          ),
        ],
      );

      if (response['success'] != true) {
        throw Exception(
          _extractApiMessage(
            response,
            fallback: 'Impossible d\'importer le CV.',
          ),
        );
      }

      final saved = _parseUploadedCvFromPayload(
        response['data'],
        fallbackFileName: filename,
      );
      uploadedCv.value = saved ??
          HomeUploadedCv(
            fileName: filename,
            url: '',
            mimeType: '',
            uploadedAt: DateTime.now(),
          );
    } finally {
      isUploadingCvFile.value = false;
    }
  }

  Future<void> saveCv(List<HomeCvSection> sections) async {
    isSavingCv.value = true;

    try {
      final token = await _readToken();
      final response = await _apiProvider.postJson(
        ApiConstants.profileCv,
        {
          'sections': sections
              .asMap()
              .entries
              .map(
                (entry) => {
                  if (entry.value.id != null && entry.value.id!.isNotEmpty)
                    'id': entry.value.id,
                  'section_type': entry.value.sectionType,
                  'title': entry.value.title,
                  'organization': entry.value.organization,
                  'start_date': _formatIsoDate(entry.value.startDate),
                  'end_date': _formatIsoDate(entry.value.endDate),
                  'is_current': entry.value.isCurrent,
                  'description': entry.value.description,
                  'missions': entry.value.missions,
                  'achievements': entry.value.achievements,
                  'level': entry.value.level,
                  'mention': entry.value.mention,
                  'external_url': entry.value.externalUrl,
                  'display_order': entry.key,
                },
              )
              .toList(growable: false),
        },
        headers: ApiConstants.authHeaders(token),
      );

      if (response['success'] != true) {
        throw Exception(
          _extractApiMessage(
            response,
            fallback: 'Impossible de sauvegarder le CV.',
          ),
        );
      }

      cvSections.assignAll(
        _extractItems(response['data'])
            .map(_parseCvSection)
            .whereType<HomeCvSection>(),
      );
    } finally {
      isSavingCv.value = false;
    }
  }

  Future<void> savePortfolioItem(
    HomePortfolioItem item, {
    List<ApiMultipartFile> mediaFiles = const [],
  }) async {
    isSavingPortfolio.value = true;

    try {
      final token = await _readToken();
      final response = await _apiProvider.sendMultipart(
        item.id == null
            ? ApiConstants.profilePortfolio
            : '${ApiConstants.profilePortfolio}/${item.id}',
        method: item.id == null ? 'POST' : 'PUT',
        headers: ApiConstants.authHeadersWithoutContentType(token),
        fields: {
          'item_type': item.itemType,
          'title': item.title,
          'description': item.description,
          'results': item.results,
          'external_url': item.externalUrl,
          'display_order': '${item.displayOrder}',
          'is_public': item.isPublic ? '1' : '0',
          'visibility': item.isPublic ? 'public' : 'private',
          'tech_stack': jsonEncode(item.techStack),
          'media_urls': jsonEncode(item.mediaUrls),
        },
        files: mediaFiles,
      );

      if (response['success'] != true) {
        throw Exception(
          _extractApiMessage(
            response,
            fallback: 'Impossible de sauvegarder le projet.',
          ),
        );
      }

      final saved = _parsePortfolioItem(response['data']);
      if (saved == null) {
        throw Exception('Reponse portfolio invalide.');
      }

      final items = portfolioItems.toList(growable: true);
      final existingIndex = items.indexWhere((entry) => entry.id == saved.id);
      if (existingIndex >= 0) {
        items[existingIndex] = saved;
      } else {
        items.add(saved);
      }
      items.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      portfolioItems.assignAll(items);
    } finally {
      isSavingPortfolio.value = false;
    }
  }

  Future<void> deletePortfolioItem(HomePortfolioItem item) async {
    if (item.id == null) {
      return;
    }

    isSavingPortfolio.value = true;

    try {
      final token = await _readToken();
      final response = await _apiProvider.deleteJson(
        '${ApiConstants.profilePortfolio}/${item.id}',
        headers: ApiConstants.authHeadersWithoutContentType(token),
      );

      if (response['success'] != true) {
        throw Exception(
          _extractApiMessage(
            response,
            fallback: 'Impossible de supprimer le projet.',
          ),
        );
      }

      portfolioItems.removeWhere((entry) => entry.id == item.id);
    } finally {
      isSavingPortfolio.value = false;
    }
  }

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
    final exists = cvTemplateOptions.any((entry) => entry.id == templateId);
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

  List<HomeCvSection> _sortedCvSections() {
    final sections = cvSections.toList(growable: true);
    sections.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return sections;
  }

  String _cvDownloadFileName() {
    final rawName =
        profile.value.fullName.trim().isEmpty ? 'cv' : profile.value.fullName;
    final safeName = rawName
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return '${safeName.isEmpty ? 'cv' : safeName}_${selectedCvTemplate.value}.pdf';
  }

  HomeUserProfile _parseProfile(Map<String, dynamic> payload) {
    final user = _asMap(payload['user']) ?? const <String, dynamic>{};
    final profileData = _asMap(payload['profile']) ?? const <String, dynamic>{};
    final id = _asString(user['id']) ?? '';
    final createdAt = DateTime.tryParse(_asString(user['created_at']) ?? '');

    return HomeUserProfile(
      id: id,
      firstName: _asString(user['first_name']) ?? '',
      lastName: _asString(user['last_name']) ?? '',
      email: _asString(user['email']) ?? '',
      phone: _asString(user['phone']) ?? '',
      avatarUrl: _resolveAssetUrl(_asString(user['avatar_url']) ?? ''),
      city: _asString(user['city']) ?? '',
      region: _asString(user['region']) ?? '',
      userType: _asString(user['user_type']) ?? 'candidate',
      headline: _asString(profileData['headline']) ?? '',
      summary: _asString(profileData['summary']) ?? '',
      skills: _asStringList(profileData['skills']),
      memberSinceLabel: createdAt == null
          ? 'Non renseigne'
          : DateFormat('dd/MM/yyyy').format(createdAt.toLocal()),
      referenceLabel: id.isEmpty
          ? 'ID indisponible'
          : 'WEP-${id.substring(0, 4).toUpperCase()}-${id.substring(id.length - 4).toUpperCase()}',
      isVerified: _asBool(
        profileData['is_verified'] ?? profileData['credibility_badge'],
      ),
    );
  }

  HomeProfilePreferences _parsePreferences(dynamic payload) {
    final data = _asMap(payload) ?? const <String, dynamic>{};
    final notifications =
        _asMap(data['notifications']) ?? const <String, dynamic>{};
    final appearance = _asMap(data['apparence']) ?? const <String, dynamic>{};

    return HomeProfilePreferences(
      notificationsEnabled: _asBool(notifications['enabled']),
      offerUpdates: _asBool(notifications['offer_updates']),
      applicationUpdates: _asBool(notifications['application_updates']),
      matchAlerts: _asBool(notifications['match_alerts']),
      messageAlerts: _asBool(notifications['message_alerts']),
      trainingUpdates: _asBool(notifications['training_updates']),
      theme: _asString(appearance['theme']) ?? 'light',
      language: _asString(appearance['language']) ?? 'fr',
    );
  }

  HomeUploadedCv? _parseUploadedCvFromPayload(
    dynamic payload, {
    String fallbackFileName = '',
  }) {
    final data = _asMap(payload);
    if (data == null) {
      return fallbackFileName.trim().isEmpty
          ? null
          : HomeUploadedCv(
              fileName: fallbackFileName,
              url: '',
              mimeType: '',
              uploadedAt: DateTime.now(),
            );
    }

    final nested = _asMap(data['uploaded_cv']) ??
        _asMap(data['cv_file']) ??
        _asMap(data['file']) ??
        data;

    final fileName = _firstNonEmpty([
      _asString(nested['file_name']),
      _asString(nested['filename']),
      _asString(nested['name']),
      fallbackFileName,
    ]);
    final rawUrl = _firstNonEmpty([
      _asString(nested['url']),
      _asString(nested['file_url']),
      _asString(nested['path']),
    ]);

    if (fileName.isEmpty && rawUrl.isEmpty) {
      return null;
    }

    return HomeUploadedCv(
      fileName: fileName,
      url: rawUrl.isEmpty ? '' : _resolveAssetUrl(rawUrl),
      mimeType: _firstNonEmpty([
        _asString(nested['mime_type']),
        _asString(nested['mime']),
      ]),
      uploadedAt: DateTime.tryParse(
        _firstNonEmpty([
          _asString(nested['uploaded_at']),
          _asString(nested['created_at']),
        ]),
      ),
    );
  }

  HomeCvSection? _parseCvSection(dynamic payload) {
    final data = _asMap(payload);
    if (data == null) {
      return null;
    }

    return HomeCvSection(
      id: _asString(data['id']),
      sectionType: _asString(data['section_type']) ?? 'experience',
      title: _asString(data['title']) ?? '',
      organization: _asString(data['organization']) ?? '',
      startDate: DateTime.tryParse(_asString(data['start_date']) ?? ''),
      endDate: DateTime.tryParse(_asString(data['end_date']) ?? ''),
      isCurrent: _asBool(data['is_current']),
      description: _asString(data['description']) ?? '',
      missions: _asStringList(data['missions']),
      achievements: _asStringList(data['achievements']),
      level: _asString(data['level']) ?? '',
      mention: _asString(data['mention']) ?? '',
      externalUrl: _asString(data['external_url']) ?? '',
      displayOrder: _asInt(data['display_order']),
    );
  }

  HomePortfolioItem? _parsePortfolioItem(dynamic payload) {
    final data = _asMap(payload);
    if (data == null) {
      return null;
    }

    return HomePortfolioItem(
      id: _asString(data['id']),
      itemType: _asString(data['item_type']) ?? 'project',
      title: _asString(data['title']) ?? '',
      description: _asString(data['description']) ?? '',
      results: _asString(data['results']) ?? '',
      externalUrl: _asString(data['external_url']) ?? '',
      techStack: _asStringList(data['tech_stack']),
      mediaUrls: _asStringList(data['media_urls'])
          .map(_resolveAssetUrl)
          .toList(growable: false),
      displayOrder: _asInt(data['display_order']),
      isVerified: _asBool(data['is_verified']),
      isPublic:
          data.containsKey('is_public') ? _asBool(data['is_public']) : true,
    );
  }

  List<dynamic> _extractItems(dynamic payload) {
    if (payload is List) {
      return payload;
    }

    final map = _asMap(payload);
    if (map == null) {
      return const [];
    }

    if (map['items'] is List) {
      return map['items'] as List<dynamic>;
    }

    if (map['data'] is List) {
      return map['data'] as List<dynamic>;
    }

    return const [];
  }

  Future<String> _readToken() async {
    return _tokenStore.readToken();
  }

  String _resolveAssetUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('/')) {
      return '${ApiConstants.resolvedHost}$trimmed';
    }
    return '${ApiConstants.resolvedHost}/$trimmed';
  }

  String _friendlyErrorMessage(
    Object error, {
    required String fallback,
  }) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    if (message.contains('Impossible de joindre l\'API')) {
      return 'Connexion au service impossible pour le moment.';
    }
    return message.isEmpty ? fallback : message;
  }

  String _extractApiMessage(
    Map<String, dynamic> data, {
    required String fallback,
  }) {
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }

    final errors = data['errors'];
    if (errors is Map<String, dynamic>) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    }

    return fallback;
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, val) => MapEntry('$key', val));
    }
    return null;
  }

  String? _asString(dynamic value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty || text == 'null' ? null : text;
  }

  String _firstNonEmpty(Iterable<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => _asString(item))
          .whereType<String>()
          .where((item) => item.trim().isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }

  bool _asBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    final text = (_asString(value) ?? '').toLowerCase();
    return text == '1' || text == 'true' || text == 'yes';
  }

  int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(_asString(value) ?? '') ?? 0;
  }

  String? _formatIsoDate(DateTime? date) {
    if (date == null) {
      return null;
    }
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _sectionLabel(String sectionType) {
    switch (sectionType) {
      case 'experience':
        return 'Experience';
      case 'education':
        return 'Formation';
      case 'certification':
        return 'Certification';
      case 'skill':
        return 'Competence';
      case 'language':
        return 'Langues';
      case 'project':
        return 'Projet';
      case 'volunteer':
        return 'Benevolat';
      case 'award':
        return 'Prix et distinctions';
      case 'publication':
        return 'Publications';
      case 'reference':
        return 'References';
      case 'other':
        return 'Autres informations';
      default:
        return sectionType;
    }
  }

  String _englishSectionLabel(String sectionType) {
    switch (sectionType) {
      case 'experience':
        return 'Professional experience';
      case 'education':
        return 'Education';
      case 'certification':
        return 'Certifications';
      case 'skill':
        return 'Skills';
      case 'language':
        return 'Languages';
      case 'project':
        return 'Projects';
      case 'volunteer':
        return 'Volunteer work';
      case 'award':
        return 'Awards';
      case 'publication':
        return 'Publications';
      case 'reference':
        return 'References';
      case 'other':
        return 'Additional information';
      default:
        return sectionType;
    }
  }

  String _formatCvSectionDates(HomeCvSection section) {
    final start = section.startDate == null
        ? ''
        : DateFormat('MM/yyyy').format(section.startDate!);
    final end = section.isCurrent
        ? 'Present'
        : section.endDate == null
            ? ''
            : DateFormat('MM/yyyy').format(section.endDate!);

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
