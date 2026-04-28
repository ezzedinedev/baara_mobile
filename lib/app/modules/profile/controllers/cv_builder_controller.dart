import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';

import '../../../core/services/auth_token_store.dart';
import '../../../core/network/api_provider.dart';
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

  /// Construit un message depuis l'entree JSON persistee cote serveur :
  /// `{role: 'user'|'assistant', content: '...', created_at: ISO8601}`.
  /// Retourne null si la structure n'est pas exploitable (filtre defensif).
  static CvChatMessage? fromServerJson(dynamic raw) {
    if (raw is! Map) return null;
    final content = raw['content']?.toString().trim() ?? '';
    if (content.isEmpty) return null;
    final roleStr = raw['role']?.toString();
    final role = roleStr == 'assistant' ? CvChatRole.assistant : CvChatRole.user;
    DateTime sentAt = DateTime.now();
    final ts = raw['created_at']?.toString();
    if (ts != null && ts.isNotEmpty) {
      sentAt = DateTime.tryParse(ts) ?? sentAt;
    }
    return CvChatMessage(role: role, content: content, sentAt: sentAt);
  }
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
  // Champs SKIPPABLE explicitement passes par l'utilisateur (ex: "non, pas
  // de LinkedIn"). Persiste cote serveur via cv.skipped_fields, restitue
  // par l'API au reload.
  final skippedFields = <String>[].obs;
  final progressPct = 0.obs;
  final expectedField = RxnString();
  final freeEditMode = false.obs;
  /// Vrai quand tous les champs CORE_GUIDED requis sont remplis ou skippes.
  /// Pilote la chip "Voir mon CV" cote chat assistant.
  final isComplete = false.obs;

  /// Vrai pendant un fetch des bytes PDF depuis le backend. Pilote l'etat
  /// loading du bouton "Télécharger le PDF" sur l'apercu CV.
  final isDownloadingCv = false.obs;

  /// Cache local des PDFs deja telecharges (1 entree par template). Permet
  /// au PageView de l'apercu de basculer entre les 3 templates sans
  /// re-fetcher a chaque swipe.
  final cvPdfCache = <String, Uint8List>{}.obs;

  /// Template marque comme "mon CV principal" cote backend (classic |
  /// modern | minimal). Pilote l'index initial du PageView de l'apercu
  /// et l'affichage "Selectionne" du bouton.
  final selectedTemplate = 'classic'.obs;

  /// Vrai pendant le POST /select-template. Pilote le loading du bouton
  /// "Enregistrer comme mon CV".
  final isSelectingTemplate = false.obs;

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
        final skipped = (assistantState['skipped_fields'] as List?)
                ?.whereType<String>()
                .toList() ??
            const <String>[];
        skippedFields.value = skipped;
        progressPct.value =
            (assistantState['progress_pct'] as num?)?.toInt() ?? 0;
        expectedField.value = assistantState['expected_field']?.toString();
        isComplete.value = assistantState['is_complete'] == true;
        final tpl = assistantState['selected_template']?.toString();
        if (tpl != null && tpl.isNotEmpty) {
          selectedTemplate.value = tpl;
        }
      }

      // Restaurer l'historique conversationnel persiste cote serveur. Sans
      // ca, fermer/rouvrir l'app vide le fil et l'utilisateur perd ses
      // anciens messages.
      _hydrateChatHistory(data['chat_history']);
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
      final newSkipped = (data['skipped_fields'] as List?)
              ?.whereType<String>()
              .toList() ??
          const <String>[];
      skippedFields.value = newSkipped;
      progressPct.value = (data['progress_pct'] as num?)?.toInt() ?? 0;
      expectedField.value = data['expected_field']?.toString();
      freeEditMode.value = data['free_edit_mode'] == true;
      isComplete.value = data['is_complete'] == true;
      final tpl = data['selected_template']?.toString();
      if (tpl != null && tpl.isNotEmpty) {
        selectedTemplate.value = tpl;
      }

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

  /// Reconstruit `chatHistory` depuis le payload serveur. Tolere un null /
  /// une structure inattendue : on laisse l'historique courant intact dans
  /// ce cas pour ne pas effacer les messages affiches.
  void _hydrateChatHistory(dynamic raw) {
    if (raw is! List) return;
    final restored = <CvChatMessage>[];
    for (final entry in raw) {
      final msg = CvChatMessage.fromServerJson(entry);
      if (msg != null) restored.add(msg);
    }
    if (restored.isNotEmpty) {
      chatHistory.value = restored;
    }
  }

  // ──────────────────────────────────────────────────────
  // Téléchargement PDF
  // ──────────────────────────────────────────────────────

  /// Récupère les bytes PDF du template demandé, depuis le cache si déjà
  /// téléchargé, sinon via une requête authentifiée. Retourne null en cas
  /// d'échec (token absent, HTTP non-2xx, exception réseau) ; remplit
  /// `errorMessage` avec un message lisible.
  Future<Uint8List?> fetchCvPdfBytes({String template = 'classic'}) async {
    final cached = cvPdfCache[template];
    if (cached != null) return cached;

    errorMessage.value = '';
    try {
      final token = await const AuthTokenStore().readToken();
      if (token.isEmpty) {
        errorMessage.value = 'Connectez-vous pour visualiser votre CV.';
        return null;
      }

      final url = Uri.parse(_repository.downloadUrl(template: template));
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/pdf',
      });

      if (response.statusCode != 200) {
        errorMessage.value =
            'Chargement impossible (code ${response.statusCode}).';
        return null;
      }

      final bytes = response.bodyBytes;
      cvPdfCache[template] = bytes;
      return bytes;
    } catch (e) {
      errorMessage.value = _friendlyError(e);
      return null;
    }
  }

  /// Invalide le cache PDF (a appeler apres une modification du CV pour
  /// forcer un re-fetch a la prochaine visualisation).
  void invalidateCvPdfCache() {
    cvPdfCache.clear();
  }

  /// Marque [template] comme le template principal du CV cote backend.
  /// Utilise sur le bouton "Enregistrer comme mon CV" de l'apercu.
  Future<bool> selectTemplate(String template) async {
    if (isSelectingTemplate.value) return false;
    if (selectedTemplate.value == template) return true;
    isSelectingTemplate.value = true;
    errorMessage.value = '';

    try {
      final data = await _repository.selectTemplate(template);
      final saved = data['selected_template']?.toString();
      if (saved != null && saved.isNotEmpty) {
        selectedTemplate.value = saved;
      } else {
        selectedTemplate.value = template;
      }
      return true;
    } catch (e) {
      errorMessage.value = _friendlyError(e);
      return false;
    } finally {
      isSelectingTemplate.value = false;
    }
  }

  /// Télécharge le PDF officiel du CV et déclenche le sheet système
  /// (Partager / Enregistrer / Ouvrir avec…) via `Printing.sharePdf`.
  /// Retourne true en cas de succès, false sinon ; en cas d'échec
  /// `errorMessage` est rempli avec un message lisible.
  Future<bool> downloadCvPdf({String template = 'classic'}) async {
    if (isDownloadingCv.value) return false;
    isDownloadingCv.value = true;
    errorMessage.value = '';

    try {
      final bytes = await fetchCvPdfBytes(template: template);
      if (bytes == null) {
        // errorMessage deja rempli par fetchCvPdfBytes
        return false;
      }

      // Printing.sharePdf delegue au sheet systeme natif (Android intent /
      // iOS share sheet) qui propose Enregistrer / Ouvrir avec / Partager.
      await Printing.sharePdf(
        bytes: bytes,
        filename: _buildPdfFilename(template: template),
      );
      return true;
    } catch (e) {
      errorMessage.value = _friendlyError(e);
      return false;
    } finally {
      isDownloadingCv.value = false;
    }
  }

  String _buildPdfFilename({String template = 'classic'}) {
    final firstName =
        (user.value?['first_name'] ?? '').toString().trim();
    final lastName = (user.value?['last_name'] ?? '').toString().trim();
    final base = ('$firstName $lastName').trim();
    final nameSlug = base
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final parts = <String>[
      'CV',
      if (nameSlug.isNotEmpty) nameSlug,
      template,
    ];
    return '${parts.join('-')}.pdf';
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
