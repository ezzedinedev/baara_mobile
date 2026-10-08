import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  static const String apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String webBaseUrl = String.fromEnvironment(
    'WEB_BASE_URL',
    defaultValue: '',
  );


  static const String productionBaseUrl = String.fromEnvironment(
    'PRODUCTION_API_BASE_URL',
    // Hote provisoire (hebergement mutualise). A remplacer par le vrai domaine
    // au passage sur le VPS.
    defaultValue: 'https://baara.strateapps.com',
  );

  /// Nom d'hôte du site public affiché aux utilisateurs (ex. pour renvoyer
  /// les employeurs vers le web). Suit [productionBaseUrl].
  static String get publicSiteHost =>
      Uri.tryParse(productionBaseUrl)?.host ?? productionBaseUrl;

  /// Client OAuth « Web » de Google (le même que la connexion Google du site,
  /// `GOOGLE_CLIENT_ID` côté Laravel). Valeur publique, pas un secret.
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '514652349175-vc72d4k6t5sjmqri56gko0smo214t9v1.apps.googleusercontent.com',
  );

  /// Client OAuth « iOS » (même projet Google Cloud que le client Web).
  /// Doit correspondre à GIDClientID et au schéma d'URL inversé d'Info.plist.
  static const String googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue:
        '514652349175-gffa6sajpgmi2sc7snotserdc5nc231s.apps.googleusercontent.com',
  );

  static const String authDeviceName = 'Baara-mobile';

  /// Serveur par défaut : la production, quel que soit le mode (debug,
  /// profile, release). Le développement local passe explicitement son
  /// adresse via `--dart-define=API_BASE_URL=...`
  /// (`scripts/flutter_run_android_dev.ps1` le fait déjà).
  static String get _defaultHost => productionBaseUrl;

  static bool _isLocalDevHost(String host) {
    if (host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2') {
      return true;
    }
    // RFC 1918 private ranges — couvre 192.168.*, 10.*, 172.16-31.*
    if (host.startsWith('192.168.') || host.startsWith('10.')) return true;
    if (host.startsWith('172.')) {
      final parts = host.split('.');
      if (parts.length >= 2) {
        final second = int.tryParse(parts[1]);
        if (second != null && second >= 16 && second <= 31) return true;
      }
    }
    return false;
  }

  static String _sanitizeHost(String host) {
    final trimmed = host.trim();
    final withoutTrailingSlash = trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
    final uri = Uri.tryParse(withoutTrailingSlash);

    if (uri == null || uri.scheme.isEmpty || uri.host.isEmpty) {
      throw ArgumentError('Configuration API invalide.');
    }

    if (!kDebugMode && uri.scheme != 'https' && !_isLocalDevHost(uri.host)) {
      throw ArgumentError('Configuration API invalide.');
    }

    return withoutTrailingSlash;
  }

  static String get resolvedHost {
    if (apiBaseUrlOverride.trim().isNotEmpty) {
      return _sanitizeHost(apiBaseUrlOverride);
    }
    if (webBaseUrl.trim().isNotEmpty) {
      return _sanitizeHost(webBaseUrl);
    }
    return _sanitizeHost(_defaultHost);
  }

  static String get baseUrl => '$resolvedHost/api/v1';

  // ── Liens publics (partage & deep links) ────────────────────────────────
  /// Schéma custom des deep links de l'app (baara://…).
  /// Doit rester identique à AndroidManifest.xml (`android:scheme`) et à
  /// Info.plist (`CFBundleURLSchemes`) : les trois sont lus séparément.
  static const String deepLinkScheme = 'baara';

  /// Base du site web public. L'API et le site partagent le même hôte
  /// ([productionBaseUrl] en prod, Laravel :8000 en dev). Le retrait d'un éventuel
  /// préfixe `api.` reste par sécurité si un hôte dédié est fourni via
  /// --dart-define.
  static String get siteBaseUrl {
    final uri = Uri.tryParse(resolvedHost);
    if (uri == null) return resolvedHost;
    if (uri.host.startsWith('api.')) {
      return uri.replace(host: uri.host.substring(4)).toString();
    }
    return resolvedHost;
  }

  /// URL web publique du profil d'un membre (parité web : `/profil/{id}`).
  static String webProfileUrl(String id) => '$siteBaseUrl/profil/$id';

  /// donc les hôtes locaux vers [resolvedHost] (le MÊME hôte que l'API), et on

  static String? resolveMediaUrl(String? url) {
    if (url == null) return null;
    final u = url.trim();
    if (u.isEmpty) return null;
    if (u.startsWith('/')) return '$resolvedHost$u';
    final uri = Uri.tryParse(u);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return u;
    const localHosts = {'127.0.0.1', 'localhost', '10.0.2.2', '0.0.0.0'};
    if (localHosts.contains(uri.host)) {
      final base = Uri.parse(resolvedHost);
      return uri
          .replace(scheme: base.scheme, host: base.host, port: base.port)
          .toString();
    }
    return u;
  }

  static List<String> get baseUrlCandidates {
    // IMPORTANT : l'hôte CORRECT pour la plateforme doit être en PREMIER.
    // Sur émulateur Android, 127.0.0.1 = l'émulateur lui-même (mort) ; le bon
    // hôte est 10.0.2.2. Le mettre en tête évite ~3,5 s de retry/backoff sur
    // un localhost injoignable à chaque requête à froid (= « lent partout »).
    final hosts = <String>[
      if (apiBaseUrlOverride.trim().isNotEmpty)
        _sanitizeHost(apiBaseUrlOverride),
      if (webBaseUrl.trim().isNotEmpty) _sanitizeHost(webBaseUrl),
      _sanitizeHost(_defaultHost),
      // Replis (uniquement si le défaut échoue) : iOS sim / desktop → 127.0.0.1.
      if (kDebugMode) 'http://10.0.2.2:8000',
      if (kDebugMode) 'http://127.0.0.1:8000',
    ];

    final uniqueHosts = <String>[];
    for (final host in hosts) {
      if (!uniqueHosts.contains(host)) {
        uniqueHosts.add(host);
      }
    }

    return uniqueHosts.map((host) => '$host/api/v1').toList(growable: false);
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const int maxMultipartFiles = 10;
  static const int maxMultipartBytes = 20 * 1024 * 1024;

  static const String loginPhone = '/auth/login/phone';
  static const String loginEmail = '/auth/login/email';
  static const String loginGoogle = '/auth/login/google';
  static const String register = '/auth/register';
  static const String otpVerify = '/auth/otp/verify';
  static const String otpResend = '/auth/otp/resend';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String me = '/auth/me';
  static const String logout = '/auth/logout';
  // Verification de l'email (authentifie) : envoi + validation d'un code.
  static const String emailSendVerification = '/auth/email/send-verification';
  static const String emailVerify = '/auth/email/verify';
  static const String logoutAll = '/auth/logout-all';
  static const String changePassword = '/auth/change-password';

  /// Versions de l'app (mise à jour proposée ou obligatoire), public.
  static const String appVersion = '/app/version';

  /// Suppression définitive du compte (DELETE).
  static const String account = '/account';
  static const String authRefresh = '/auth/refresh';
  static const String profile = '/profile';
  static const String profileAvatar = '/profile/avatar';
  // Vidéo de présentation candidat (~30 s) : fichier sur disque, chemin en base.
  static const String profilePresentationVideo = '/profile/presentation-video';
  static const String profilePreferences = '/profile/preferences';
  static const String profilePortfolio = '/profile/portfolio';
  static String profilePortfolioItem(String id) => '/profile/portfolio/$id';
  // Sections de CV « legacy » (CvSection). Redondant avec le CV-builder, qui
  // est la source utilisee par l'app — expose ici pour la parite avec le web.
  static const String profileCv = '/profile/cv';
  static const String profileCvBuilder = '/profile/cv-builder';
  // Rendu d'apercu cote serveur. L'app affiche l'apercu depuis `profileCvBuilder`
  // (donnees brutes) ; cet endpoint reste disponible si un rendu serveur est voulu.
  static const String profileCvBuilderPreview = '/profile/cv-builder/preview';
  static const String profileCvBuilderDownload = '/profile/cv-builder/download';
  // Apercu PDF : filigrane si le modele premium n'est pas debloque, alors que
  // `download` refuse (402). Les deux flux sont volontairement distincts.
  static const String profileCvBuilderPreviewPdf =
      '/profile/cv-builder/preview-pdf';
  static const String profileCvBuilderSelectTemplate =
      '/profile/cv-builder/select-template';
  // Catalogue des modeles de CV (source unique partagee avec le web) et achat
  // des modeles premium. cf. CvBuilderApiController@templates / @purchaseTemplate.
  static const String profileCvBuilderTemplates = '/profile/cv-builder/templates';
  static String profileCvBuilderPurchaseTemplate(String template) =>
      '/profile/cv-builder/templates/$template/purchase';
  // Assistant conversationnel CV-builder (miroir mobile du web
  // /mon-cv/assistant/message). cf. CvBuilderApiController@assistant.
  static const String profileCvBuilderAssistant =
      '/profile/cv-builder/assistant';
  // Import CV : analyze (parse PDF→fields stateless) + apply (persist).
  // L'endpoint legacy `/profile/cv/upload` n'existe pas côté backend.
  static const String profileCvImportAnalyze =
      '/profile/cv-builder/import/analyze';
  static const String profileCvImportImprove =
      '/profile/cv-builder/import/improve';
  static const String profileCvImportApply = '/profile/cv-builder/import/apply';
  // Telecharge en PDF le CV importe/ameliore AVANT de l'appliquer au profil :
  // body {improved: {...}}. Repond des octets, pas du JSON.
  static const String profileCvImportDownload =
      '/profile/cv-builder/import/download';

  // Documents (diplomes, certificats, lettres) - synchro web
  static const String profileDocuments = '/profile/documents';
  static String profileDocument(String id) => '/profile/documents/$id';
  static String profileDocumentDownload(String id) =>
      '/profile/documents/$id/download';

  // Certificats de formation Baara obtenus
  static const String profileCertificates = '/profile/certificates';

  static const String offers = '/offers';
  static const String offersFeatured = '/offers/featured/list';
  static const String offersSaved = '/offers/saved/list';
  static String offerSavePath(String id) => '/offers/$id/save';
  // NB : les routes backend POST /offers/{id}/match|apply|swipe sont TOUTES des
  // alias de OfferApiController@match, qui **crée une candidature**. Aucun
  // helper n'est exposé ici volontairement : on candidate via [applications]
  // (POST /applications), et il n'existe aucun endpoint de score par offre.
  static const String applications = '/applications';
  static String application(String id) => '/applications/$id';
  // Entretiens a venir pour le candidat connecte (widget "Mes entretiens").
  // Le payload inclut la geolocalisation entreprise + deep links itineraire +
  // QR de convocation. cf. ApplicationApiController@upcomingInterviews.
  static const String applicationsInterviewsUpcoming =
      '/applications/interviews/upcoming';

  // ── Pipeline entretien candidat (invitation -> reponse) ───────────────────
  // Liste / detail / reponse (accept|decline|reschedule). cf. InterviewApiController.
  static const String applicationsInterviews = '/applications/interviews';
  static String applicationInterview(String id) =>
      '/applications/interviews/$id';
  static String applicationInterviewRespond(String id) =>
      '/applications/interviews/$id/respond';

  // ── Offres d'emploi formelles (apres entretien) ───────────────────────────
  // Liste / detail / reponse (accept|negotiate|refuse). cf. JobProposalApiController.
  static const String jobProposals = '/applications/job-proposals';
  static String jobProposal(String id) => '/applications/job-proposals/$id';
  static String jobProposalRespond(String id) =>
      '/applications/job-proposals/$id/respond';
  // Le .ics d'un entretien est fourni prêt à l'emploi par le backend
  // (`icsUrl` sur UpcomingInterview) — pas de helper d'URL à construire ici.
  static const String trainings = '/trainings';
  // Formations suivies par le candidat. Renvoie un paginator d'INSCRIPTIONS
  // (progression, certificat) avec la formation imbriquee en resume — pas une
  // liste de formations. cf. TrainingApiController@enrolled.
  static const String trainingsEnrolled = '/trainings/enrolled/list';
  static String trainingEnroll(String id) => '/trainings/$id/enroll';
  static String trainingPay(String id) => '/trainings/$id/pay';
  static String trainingProgress(String id) => '/trainings/$id/progress';
  static String trainingReview(String id) => '/trainings/$id/review';

  // Quiz : le tirage, la correction et la surveillance sont cotes serveur
  // (les bonnes reponses ne descendent jamais dans l'app).
  // cf. QuizApiController (index / start / submit / incident).
  static String quizzesOfModule(String moduleId) => '/quizzes/module/$moduleId';
  static String quizStart(String quizId) => '/quizzes/$quizId/start';
  static String quizSubmit(String quizId) => '/quizzes/$quizId/submit';
  static String quizIncident(String quizId) => '/quizzes/$quizId/incidents';
  static const String sectors = '/offers/sectors/list';

  // Dashboard candidat — miroir JSON de /espace-candidat (web).
  static const String candidateDashboard = '/candidate/dashboard';

  // Recherches sauvegardées / alertes emploi. CRUD (index/store/update/destroy).
  // Le cron backend `alerts:dispatch` notifie les nouvelles offres correspondantes.
  static const String savedSearches = '/saved-searches';
  static String savedSearch(String id) => '/saved-searches/$id';

  // Concours Fonction Publique (FP)
  static const String contests = '/contests';
  static String contest(String id) => '/contests/$id';
  static String contestSave(String id) => '/contests/$id/save';
  static String contestUnsave(String id) => '/contests/$id/save';

  // Stats publiques pour la home / landing.
  static const String statsPublic = '/stats/public';

  // ── IA cross-cutting ──────────────────────────────────────
  // Endpoints qui ne sont ni purement profil ni purement offre.
  // CV-builder IA reste sous /profile/cv-builder/* (intentionnel).
  static const String aiProfileScore = '/ai/profile/score';
  static const String aiCvAudit = '/ai/cv/audit';
  static const String aiCvAdapt = '/ai/cv/adapt';
  // Persiste l'adaptation IA du CV pour une offre (POST /ai/cv/adapt/apply).
  static const String aiCvAdaptApply = '/ai/cv/adapt/apply';
  // Réécriture IA d'une section/du CV (POST /ai/cv/rewrite).
  static const String aiCvRewrite = '/ai/cv/rewrite';
  static const String aiCoverLetter = '/ai/cover-letter/generate';
  static const String aiMatchFeed = '/ai/match/feed';
  static const String aiChatSend = '/ai/chat/send';
  // Feedback 👍/👎 sur une reponse du chat IA (POST /ai/chat/feedback).
  static const String aiChatFeedback = '/ai/chat/feedback';
  static const String aiChatSessions = '/ai/chat/sessions';
  static String aiChatSession(String id) => '/ai/chat/sessions/$id';

  // Backend Laravel monte la messagerie sous /messages (cf. MessageApiController).
  static const String conversations = '/messages';
  // Démarre (ou rouvre) une conversation directe : body {user_id}. Statut
  // 'accepted' si les deux sont connectés, sinon 'pending' (demande de message).
  static const String messagesStart = '/messages/start';
  static String conversation(String id) => '/messages/$id';
  static String conversationSend(String id) => '/messages/$id/send';
  static String conversationUpload(String id) => '/messages/$id/upload';
  static String conversationRead(String id) => '/messages/$id/read';
  // Cluster B — messagerie temps réel.
  static String messageTyping(String conversationId) =>
      '/messages/$conversationId/typing';
  static String messageReact(String messageId) => '/messages/$messageId/react';
  // Wave 2 — réponses suggérées IA pour une conversation → {suggestions:[3], fallback}.
  // Peut renvoyer 502 (« assistant indisponible ») → fallback UX silencieux.
  static String messageSuggestions(String conversationId) =>
      '/messages/$conversationId/suggestions';
  // Accepter / refuser une demande de message (seul le destinataire le peut).
  // Refuser supprime la conversation et son message côté serveur.
  static String conversationAccept(String conversationId) =>
      '/messages/$conversationId/accept';
  static String conversationDecline(String conversationId) =>
      '/messages/$conversationId/decline';

  static const String notifications = '/notifications';
  static String notification(String id) => '/notifications/$id';
  static String notificationRead(String id) => '/notifications/$id/read';
  static const String notificationsReadAll = '/notifications/read-all';
  // PUT cet endpoint au boot pour enregistrer/refresh le token FCM du
  // device courant cote backend (cf. NotificationApiController@updateFcmToken).
  static const String notificationsFcmToken = '/notifications/fcm-token';

  // ─────────── Communauté / réseau professionnel ───────────
  // Backend : Api/V1/CommunityApiController, préfixe /community.
  static const String communityFeed = '/community/feed';
  // Explore : posts publics tendance, même forme paginée que le feed.
  static const String communityExplore = '/community/explore';
  static const String communitySuggestions = '/community/suggestions';

  /// Accroches IA pour le top des suggestions « personnes à suivre »
  /// (`data: { insights: [{ user_id, name, reason, insight, ai }] }`).
  static const String communitySuggestionsInsight =
      '/community/suggestions/insight';
  static const String communitySearch = '/community/search';
  static const String communityPosts = '/community/posts';
  static String communityPost(String id) => '/community/posts/$id';
  static String communityPostReact(String id) => '/community/posts/$id/react';
  static String communityPostRepost(String id) => '/community/posts/$id/repost';
  static String communityPostReport(String id) => '/community/posts/$id/report';
  static String communityPostComments(String id) =>
      '/community/posts/$id/comments';
  static String communityComment(String id) => '/community/comments/$id';
  // Réaction (toggle) sur un commentaire : body {type?} (défaut 'like')
  // → {reactions_count, my_reaction}.
  static String communityCommentReact(String id) =>
      '/community/comments/$id/react';
  // ── Wave 2 — Contenu riche (sondages, enregistrés, aperçu de lien) ────────
  // Voter à un sondage (toggle) : body {option_ids:[...]} → poll mis à jour.
  static String communityPollVote(String id) => '/community/polls/$id/vote';
  // Enregistrer (POST) / retirer (DELETE) une publication → {is_saved}.
  static String communityPostSave(String id) => '/community/posts/$id/save';
  // Publications enregistrées (paginé, même forme que le feed).
  static const String communitySaved = '/community/saved';
  // Aperçu live d'un lien pour le composer : ?url= → {url,title,description,image}.
  static const String communityLinkPreview = '/community/link-preview';
  // Édition (PUT) d'une publication / d'un commentaire par son auteur.
  static String communityPostUpdate(String id) => '/community/posts/$id';
  static String communityCommentUpdate(String id) => '/community/comments/$id';
  // Fil d'un hashtag : même forme paginée que le feed + clé `tag`.
  static String communityHashtag(String tag) =>
      '/community/hashtag/${Uri.encodeComponent(tag)}';
  // Hashtags tendance : data:[{tag,count}].
  static const String communityTrendingHashtags =
      '/community/trending-hashtags';
  // Autocomplétion @mentions : data:[{id,name,avatar_url,headline}] (max 8).
  static const String communityMentionables = '/community/mentionables';
  // ── Wave 2 — Assistant IA (Mistral). Toutes peuvent renvoyer 502 (« indispo »).
  // Compose : aide à la rédaction d'une publication ({draft, action}).
  static const String communityAiCompose = '/community/ai/compose';
  // Résumé IA d'une publication existante → {summary}.
  static String communityPostSummarize(String id) =>
      '/community/posts/$id/summarize';
  // Traduction IA d'une publication ({lang}) → {translation, lang}.
  static String communityPostTranslate(String id) =>
      '/community/posts/$id/translate';

  static String communityUserFollow(String id) => '/community/users/$id/follow';
  static String communityUserConnect(String id) =>
      '/community/users/$id/connect';
  static const String communityConnections = '/community/connections';
  static String communityConnectionRespond(String id) =>
      '/community/connections/$id/respond';
  static String communityUser(String id) => '/community/users/$id';
  // Publications d'un membre (mur de profil façon Facebook), paginé.
  static String communityUserPosts(String id) => '/community/users/$id/posts';
  // Abonnés / connexions d'un membre (listes paginées, stats cliquables).
  static String communityUserFollowers(String id) =>
      '/community/users/$id/followers';
  static String communityUserConnections(String id) =>
      '/community/users/$id/connections';
  // Cluster D — Graphe social & sécurité.
  // Blocage d'un membre : POST pour bloquer, DELETE pour débloquer (même chemin).
  // Bloquer retire aussi connexion + follow côté serveur → {is_blocked: bool}.
  static String communityUserBlock(String id) => '/community/users/$id/block';
  // « Qui a vu mon profil » : {viewers:[...], total}.
  static const String communityProfileViews = '/community/profile-views';
  // Compétences du profil. POST {name} crée ; liste exposée via le profil user.
  static const String communitySkills = '/community/skills';
  // Suppression d'une compétence (DELETE) sur son propre profil.
  static String communitySkill(String id) => '/community/skills/$id';
  // Recommandation (endorse) d'une compétence : POST + DELETE → compteur.
  static String communitySkillEndorse(String id) =>
      '/community/skills/$id/endorse';

  // Stories éphémères (24 h). Backend : Api/V1/StoryApiController.
  static const String stories = '/stories';
  static String storyView(String id) => '/stories/$id/view';
  static String storyReact(String id) => '/stories/$id/react';
  static String storyReply(String id) => '/stories/$id/reply';
  static String storyViewers(String id) => '/stories/$id/viewers';
  static String story(String id) => '/stories/$id';

  // ─────────── Temps réel (Laravel Reverb / protocole Pusher) ───────────
  // Endpoint d'auth des canaux privés (Sanctum) : POST {socket_id, channel_name}
  // + Bearer token. cf. routes/api.php → api.v1.broadcasting.auth.
  static String get broadcastingAuthUrl => '$baseUrl/broadcasting/auth';

  // Clé applicative Reverb (= REVERB_APP_KEY backend). Fournir via
  // --dart-define=REVERB_APP_KEY=... (obligatoire pour le temps réel).
  static const String reverbAppKey = String.fromEnvironment(
    'REVERB_APP_KEY',
    defaultValue: '',
  );

  // Hôte du daemon Reverb. Vide => dérivé de l'hôte API (même machine que
  // Laravel), ce qui gère automatiquement 10.0.2.2 (émulateur) vs 127.0.0.1.
  static const String _reverbHostOverride = String.fromEnvironment(
    'REVERB_HOST',
    defaultValue: '',
  );

  static String get reverbHost {
    if (_reverbHostOverride.trim().isNotEmpty) {
      return _reverbHostOverride.trim();
    }
    final uri = Uri.tryParse(resolvedHost);
    return uri?.host ?? '127.0.0.1';
  }

  // Port : 8080 en dev (daemon `php artisan reverb:start`), 443 en prod (wss
  // derrière un proxy TLS). Surcharge possible via --dart-define=REVERB_PORT.
  static const int _reverbPortOverride =
      int.fromEnvironment('REVERB_PORT', defaultValue: 0);

  static int get reverbPort {
    if (_reverbPortOverride > 0) return _reverbPortOverride;
    return kDebugMode ? 8080 : 443;
  }

  // TLS désactivé en dev (ws), activé en prod (wss).
  static const bool _reverbTlsOverride =
      bool.fromEnvironment('REVERB_TLS', defaultValue: false);

  static bool get reverbUseTls => _reverbTlsOverride || !kDebugMode;

  // Formulaire web Laravel pour l'inscription entreprise.
  // Emulateur Android -> 10.0.2.2 redirige vers le localhost PC.
  static String get companyRegisterWebUrl =>
      '$resolvedHost/entreprise/inscription';

  /// Portail employeur / recruteur (connexion web).
  static String get companyPortalWebUrl => '$resolvedHost/entreprise/connexion';

  static Map<String, String> get jsonHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// Header standard pour l'idempotence (middleware Laravel `EnsureIdempotency`).
  static const String idempotencyKeyHeader = 'Idempotency-Key';

  static Map<String, String> authHeaders(String token) => {
        ...jsonHeaders,
        'Authorization': 'Bearer $token',
      };

  static Map<String, String> authHeadersWithoutContentType(String token) => {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };
}
