import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:baara/app/core/constants/app_features.dart';

import '../../../../core/utils/user_facing_error.dart';
import '../../data/repositories/cv_preview_repository.dart';
import '../../domain/entities/cv_template.dart';

/// Aperçu du CV : données, catalogue de modèles, aperçu PDF et téléchargement.
///
/// Le catalogue vient du serveur (`GET /profile/cv-builder/templates`), qui est
/// aussi la source du web : le mobile n'affichait que 3 modèles codés en dur
/// alors que la plateforme en propose 21, dont 5 premium payants.
///
/// Deux flux PDF distincts, volontairement :
/// - l'**aperçu** est toujours accessible, filigrané si le modèle est verrouillé ;
/// - le **téléchargement** exige que le modèle soit débloqué (le serveur répond
///   402 sinon), et c'est lui qui produit le fichier propre.
class CvPreviewController extends GetxController {
  CvPreviewController(this._repository);

  final CvPreviewRepository _repository;

  final isLoading = true.obs;
  final errorMessage = RxnString();
  final selectedTemplate = 'classic'.obs;
  final completionPct = 0.obs;
  final hasCvData = false.obs;
  final isDownloading = false.obs;
  final isPurchasing = false.obs;

  final templates = <CvTemplate>[].obs;

  /// Moyens de paiement acceptés pour un modèle premium (alignés sur le web).
  static const paymentProviders = <({String id, String label})>[
    (id: 'orange', label: 'Orange Money'),
    (id: 'moov', label: 'Moov Money'),
    (id: 'wave', label: 'Wave'),
  ];

  CvTemplate? get current => templates.firstWhereOrNull(
        (t) => t.id == selectedTemplate.value,
      );

  /// Le modèle affiché est premium et pas encore acheté.
  bool get isCurrentLocked => current?.isLocked ?? false;

  int get currentPriceFcfa => current?.priceFcfa ?? 0;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final results = await Future.wait([
        _repository.loadCv(),
        _repository.loadTemplates(),
      ]);
      final data = results[0] as Map<String, dynamic>;
      // Sans facturation Google Play, aucun contenu numérique ne se vend
      // dans l'app (règle du Play Store) : les modèles premium non achetés
      // n'y sont pas proposés. Ceux déjà achetés restent disponibles.
      final all = results[1] as List<CvTemplate>;
      templates.assignAll(
        AppFeatures.inAppPurchases ? all : all.where((t) => !t.isLocked),
      );

      final assistant = data['assistant_state'];
      if (assistant is Map && assistant['selected_template'] is String) {
        selectedTemplate.value = assistant['selected_template'] as String;
      }
      if (templates.isNotEmpty &&
          !templates.any((t) => t.id == selectedTemplate.value)) {
        selectedTemplate.value = templates.first.id;
      }
      completionPct.value = _asInt(data['completion_pct']);
      hasCvData.value = data['cv'] is Map && (data['cv'] as Map).isNotEmpty;
    } catch (e) {
      errorMessage.value = userFacingError(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Change le modèle et le persiste côté serveur (best-effort).
  Future<void> changeTemplate(String template) async {
    if (selectedTemplate.value == template) return;
    selectedTemplate.value = template;
    try {
      await _repository.selectTemplate(template);
    } catch (_) {
      // Non bloquant : l'aperçu PDF se régénère même si la persistance échoue.
    }
  }

  /// Octets PDF de l'aperçu (filigranés si le modèle est verrouillé).
  Future<Uint8List> pdfBytes() =>
      _repository.previewPdf(selectedTemplate.value);

  /// Débloque le modèle premium courant, puis rafraîchit le catalogue pour que
  /// l'aperçu reparte sans filigrane et que le téléchargement s'ouvre.
  Future<void> purchaseCurrent({
    required String provider,
    required String phone,
  }) async {
    final template = selectedTemplate.value;
    if (isPurchasing.value) return;
    isPurchasing.value = true;
    try {
      await _repository.purchaseTemplate(
        template,
        provider: provider,
        phone: phone,
      );
      templates.assignAll([
        for (final t in templates)
          if (t.id == template) t.copyWith(owned: true) else t,
      ]);
    } finally {
      isPurchasing.value = false;
    }
  }

  /// Enregistre le PDF propre sur l'appareil via la boîte de dialogue système.
  /// Retourne le chemin choisi, `null` si l'utilisateur annule.
  Future<String?> downloadToDevice() async {
    if (isDownloading.value) return null;
    isDownloading.value = true;
    try {
      final bytes = await _repository.downloadPdf(selectedTemplate.value);
      return FilePicker.saveFile(
        dialogTitle: 'Enregistrer mon CV',
        fileName: 'CV-Baara-${selectedTemplate.value}.pdf',
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
    } finally {
      isDownloading.value = false;
    }
  }

  int _asInt(dynamic v) {
    if (v is num) return v.round();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}
