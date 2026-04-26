import 'dart:typed_data';

import 'package:get/get.dart';

import '../../../data/providers/api_provider.dart';
import '../repositories/cv_builder_repository.dart';

/// Rôle des messages dans l'historique assistant.
enum CvChatRole { user, assistant }

class CvChatMessage {
  const CvChatMessage({
    required this.role,
    required this.content,
    required this.sentAt,
  });

  final CvChatRole role;
  final String content;
  final DateTime sentAt;

  bool get isUser => role == CvChatRole.user;

  Map<String, String> toPayload() => {
        'role': role == CvChatRole.assistant ? 'assistant' : 'user',
        'content': content,
      };
}

/// Controller qui pilote le CV Builder structuré (écran d'accueil, assistant
/// IA, éditeur manuel, import). S'appuie sur [CvBuilderRepository] qui expose
/// le contrat API `/api/v1/profile/cv-builder/*`.
///
/// L'état `confirmedFields` est géré ici côté client (l'API est stateless —
/// c'est au client de conserver la progression entre les appels assistant).
class CvBuilderController extends GetxController {
  CvBuilderController({ApiProvider? apiProvider}) {
    _repository = CvBuilderRepository(
      apiProvider: apiProvider ?? Get.find(),
    );
  }

  late final CvBuilderRepository _repository;

  // ── CV courant
  final cv = Rxn<Map<String, dynamic>>();
  final user = Rxn<Map<String, dynamic>>();
  final completionPct = 0.obs;
  final xpPoints = 0.obs;
  final level = ''.obs;
  final nextLevel = ''.obs;
  final badges = <String>[].obs;

  // ── État réactif UI
  final isLoading = false.obs;
  final isSaving = false.obs;
  final isSending = false.obs;
  final errorMessage = ''.obs;

  // ── Assistant chat
  final chatHistory = <CvChatMessage>[].obs;
  final confirmedFields = <String>[].obs;
  final progressPct = 0.obs;
  final expectedField = RxnString();
  final freeEditMode = false.obs;

  // ── Import CV
  final importFileName = ''.obs;
  final importExtractedText = ''.obs;
  final importAnalysis = Rxn<Map<String, dynamic>>();
  final importImproved = Rxn<Map<String, dynamic>>();
  final isImportAnalyzing = false.obs;
  final isImportImproving = false.obs;
  final isImportApplying = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  // ──────────────────────────────────────────────────────
  // CRUD de base
  // ──────────────────────────────────────────────────────

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final data = await _repository.show();
      _applyMetrics(data);
      cv.value = data['cv'] is Map ? Map<String, dynamic>.from(data['cv']) : {};
      user.value =
          data['user'] is Map ? Map<String, dynamic>.from(data['user']) : {};

      // Hydrate l'etat assistant depuis le serveur : champs deja remplis
      // + prochain a demander + progression. Sans ca, en rouvrant le chat
      // on repartirait de `confirmed_fields: []` et l'IA reposerait toutes
      // les questions deja repondues.
      final assistantState = data['assistant_state'];
      if (assistantState is Map<String, dynamic>) {
        final confirmed = (assistantState['confirmed_fields'] as List?)
                ?.whereType<String>()
                .toList() ??
            const <String>[];
        confirmedFields.value = confirmed;
        progressPct.value =
            (assistantState['progress_pct'] as num?)?.toInt() ?? 0;
        expectedField.value = assistantState['expected_field']?.toString();
      }
    } catch (e) {
      errorMessage.value = _friendlyError(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Met à jour un champ scalaire (ou liste) en une seule requête.
  Future<bool> updateField(String field, dynamic value) async {
    isSaving.value = true;
    errorMessage.value = '';
    try {
      final data = await _repository.update(field: field, value: value);
      _applyMetrics(data);
      if (data['cv'] is Map) {
        cv.value = Map<String, dynamic>.from(data['cv']);
      }
      return true;
    } catch (e) {
      errorMessage.value = _friendlyError(e);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// Update en batch (plusieurs champs en une fois).
  Future<bool> updateFields(Map<String, dynamic> fields) async {
    if (fields.isEmpty) return true;
    isSaving.value = true;
    errorMessage.value = '';
    try {
      final data = await _repository.update(fields: fields);
      _applyMetrics(data);
      if (data['cv'] is Map) {
        cv.value = Map<String, dynamic>.from(data['cv']);
      }
      return true;
    } catch (e) {
      errorMessage.value = _friendlyError(e);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  // ──────────────────────────────────────────────────────
  // Assistant chat
  // ──────────────────────────────────────────────────────

  Future<bool> sendAssistantMessage(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty || isSending.value) return false;

    // Optimiste : ajouter le message user au fil, on rollback si échec
    chatHistory.add(CvChatMessage(
      role: CvChatRole.user,
      content: trimmed,
      sentAt: DateTime.now(),
    ));

    isSending.value = true;
    errorMessage.value = '';

    try {
      final history = chatHistory
          .take(30)
          .map((m) => m.toPayload())
          .toList(growable: false);

      final data = await _repository.assistant(
        message: trimmed,
        history: history,
        confirmedFields: confirmedFields.toList(growable: false),
        freeEditMode: freeEditMode.value,
      );

      final reply = data['reply']?.toString() ?? '';
      chatHistory.add(CvChatMessage(
        role: CvChatRole.assistant,
        content: reply,
        sentAt: DateTime.now(),
      ));

      final newConfirmed = (data['confirmed_fields'] as List?)
              ?.whereType<String>()
              .toList() ??
          const <String>[];
      confirmedFields.value = newConfirmed;
      progressPct.value = (data['progress_pct'] as num?)?.toInt() ?? 0;
      expectedField.value = data['expected_field']?.toString();
      freeEditMode.value = data['free_edit_mode'] == true;

      if (data['cv'] is Map) {
        cv.value = Map<String, dynamic>.from(data['cv']);
      }
      _applyMetrics(data);

      final sessionBadges = (data['badges'] as List?)
              ?.whereType<String>()
              .toList() ??
          const <String>[];
      if (sessionBadges.isNotEmpty) {
        badges.value = sessionBadges;
      }

      return true;
    } catch (e) {
      // Rollback du message user (meilleur UX : le réécrire plutôt que le perdre)
      chatHistory.removeLast();
      errorMessage.value = _friendlyError(e);
      return false;
    } finally {
      isSending.value = false;
    }
  }

  /// Vide l'historique conversationnel local sans toucher a l'etat de
  /// progression : `confirmedFields` / `progressPct` / `expectedField`
  /// refletent ce qui est en BDD, donc les preserver evite que l'IA
  /// repose les questions deja repondues lors d'une nouvelle session.
  /// Pour repartir vraiment de zero, l'utilisateur doit vider son CV.
  void resetChat() {
    chatHistory.clear();
    freeEditMode.value = false;
  }

  // ──────────────────────────────────────────────────────
  // Import CV
  // ──────────────────────────────────────────────────────

  Future<bool> importAnalyze(String fileName, Uint8List bytes) async {
    isImportAnalyzing.value = true;
    errorMessage.value = '';
    try {
      final data = await _repository.importAnalyze(
        fileName: fileName,
        bytes: bytes,
      );
      importFileName.value = data['filename']?.toString() ?? fileName;
      importExtractedText.value = data['extracted_text']?.toString() ?? '';
      importAnalysis.value = data['analysis'] is Map
          ? Map<String, dynamic>.from(data['analysis'])
          : null;
      importImproved.value = null;
      return true;
    } catch (e) {
      errorMessage.value = _friendlyError(e);
      return false;
    } finally {
      isImportAnalyzing.value = false;
    }
  }

  Future<bool> importImprove() async {
    final text = importExtractedText.value;
    final analysis = importAnalysis.value;
    if (text.isEmpty || analysis == null) {
      errorMessage.value = 'Analyse manquante. Relancez l\'import.';
      return false;
    }

    isImportImproving.value = true;
    errorMessage.value = '';
    try {
      final data = await _repository.importImprove(
        extractedText: text,
        analysis: analysis,
      );
      importImproved.value = data['improved'] is Map
          ? Map<String, dynamic>.from(data['improved'])
          : null;
      return importImproved.value != null;
    } catch (e) {
      errorMessage.value = _friendlyError(e);
      return false;
    } finally {
      isImportImproving.value = false;
    }
  }

  /// Écrit les `extracted_fields` de l'analyse courante dans le UserCv de
  /// l'utilisateur. Utile pour fusionner rapidement un CV importé dans
  /// le profil.
  Future<bool> importApply() async {
    final analysis = importAnalysis.value;
    final extracted = analysis != null && analysis['extracted_fields'] is Map
        ? Map<String, dynamic>.from(analysis['extracted_fields'])
        : <String, dynamic>{};
    if (extracted.isEmpty) {
      errorMessage.value = 'Aucun champ à appliquer.';
      return false;
    }

    isImportApplying.value = true;
    errorMessage.value = '';
    try {
      final data = await _repository.importApply(extractedFields: extracted);
      _applyMetrics(data);
      if (data['cv'] is Map) {
        cv.value = Map<String, dynamic>.from(data['cv']);
      }
      return true;
    } catch (e) {
      errorMessage.value = _friendlyError(e);
      return false;
    } finally {
      isImportApplying.value = false;
    }
  }

  void resetImport() {
    importFileName.value = '';
    importExtractedText.value = '';
    importAnalysis.value = null;
    importImproved.value = null;
  }

  // ──────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────

  void _applyMetrics(Map<String, dynamic> data) {
    completionPct.value = (data['completion_pct'] as num?)?.toInt() ?? 0;
    xpPoints.value = (data['xp_points'] as num?)?.toInt() ?? 0;
    level.value = data['level']?.toString() ?? '';
    nextLevel.value = data['next_level']?.toString() ?? '';
    final b = (data['badges'] as List?)?.whereType<String>().toList();
    if (b != null) badges.value = b;
  }

  String _friendlyError(Object error) {
    final msg = error.toString();
    if (msg.contains('Unable to connect')) {
      return 'Connexion impossible. Vérifiez votre réseau.';
    }
    if (msg.contains('missing_openai_key') || msg.contains('missing_mistral_key')) {
      return 'Assistant IA non configuré côté serveur.';
    }
    if (msg.contains('rate_limited')) {
      return 'Trop de requêtes. Réessayez dans quelques minutes.';
    }
    return 'Erreur lors du traitement.';
  }
}

class CvBuilderBinding extends Bindings {
  @override
  void dependencies() {
    // permanent: true pour que la session assistant survive a la navigation
    // (l'utilisateur peut quitter le chat, voir l'apercu, et reprendre la
    // conversation au meme endroit). Le controller reste en memoire tant
    // que l'app tourne — acceptable, l'etat est leger.
    if (!Get.isRegistered<CvBuilderController>()) {
      Get.put<CvBuilderController>(CvBuilderController(), permanent: true);
    }
  }
}
