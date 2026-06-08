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
    defaultValue: 'https://api.opportunebf.com',
  );

  static const String authDeviceName = 'opportune-mobile';

  static String get _defaultHost {
    if (!kDebugMode) {
      return productionBaseUrl;
    }

    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }

    return 'http://127.0.0.1:8000';
  }


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
    
    if (!kDebugMode &&
        uri.scheme != 'https' &&
        !_isLocalDevHost(uri.host)) {
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
    final hosts = <String>[
      if (apiBaseUrlOverride.trim().isNotEmpty)
        _sanitizeHost(apiBaseUrlOverride),
      if (webBaseUrl.trim().isNotEmpty) _sanitizeHost(webBaseUrl),
      if (kDebugMode && defaultTargetPlatform == TargetPlatform.android)
        'http://127.0.0.1:8000',
      _sanitizeHost(_defaultHost),
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
  static const String logoutAll = '/auth/logout-all';
  static const String authRefresh = '/auth/refresh';
  static const String profile = '/profile';
  static const String profileAvatar = '/profile/avatar';
  static const String profilePreferences = '/profile/preferences';
  static const String profileCv = '/profile/cv';
  static const String profilePortfolio = '/profile/portfolio';
  static String profilePortfolioItem(String id) => '/profile/portfolio/$id';
  static const String profileCvBuilder = '/profile/cv-builder';
  static const String profileCvBuilderPreview = '/profile/cv-builder/preview';
  static const String profileCvBuilderDownload = '/profile/cv-builder/download';
  static const String profileCvBuilderSelectTemplate =
      '/profile/cv-builder/select-template';
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
  static const String profileCvImportApply =
      '/profile/cv-builder/import/apply';
  static const String profileCvImportDownload =
      '/profile/cv-builder/import/download';

  // Documents (diplomes, certificats, lettres) - synchro web
  static const String profileDocuments = '/profile/documents';
  static String profileDocument(String id) => '/profile/documents/$id';
  static String profileDocumentDownload(String id) =>
      '/profile/documents/$id/download';

  // Certificats de formation OpporTune obtenus
  static const String profileCertificates = '/profile/certificates';

  static const String offers = '/offers';
  static const String offersFeatured = '/offers/featured/list';
  static const String offersSaved = '/offers/saved/list';
  static String offerSavePath(String id) => '/offers/$id/save';
  static String offerMatch(String id) => '/offers/$id/match';
  static String offerApply(String id) => '/offers/$id/apply';
  static String offerSwipe(String id) => '/offers/$id/swipe';
  static const String applications = '/applications';
  static String application(String id) => '/applications/$id';
  // Entretiens a venir pour le candidat connecte (widget "Mes entretiens").
  // Le payload inclut la geolocalisation entreprise + deep links itineraire +
  // QR de convocation. cf. ApplicationApiController@upcomingInterviews.
  static const String applicationsInterviewsUpcoming =
      '/applications/interviews/upcoming';
  // URL web absolue (hors /api/v1) pour telecharger le .ics d'un entretien.
  // Authentification Sanctum ne s'applique pas — la route web utilise le
  // middleware auth standard. On ouvre dans un browser tab.
  static String interviewIcsWebUrl(String applicationId) =>
      '$resolvedHost/candidatures/$applicationId/interview.ics';
  static const String trainings = '/trainings';
  // /trainings/enrolled (legacy) collisionnait avec /trainings/{training}.
  // La vraie route backend est /trainings/enrolled/list.
  static const String trainingsEnrolled = '/trainings/enrolled/list';
  static String trainingEnroll(String id) => '/trainings/$id/enroll';
  static String trainingPay(String id) => '/trainings/$id/pay';
  static String trainingProgress(String id) => '/trainings/$id/progress';
  static String trainingReview(String id) => '/trainings/$id/review';
  static const String sectors = '/offers/sectors/list';

  // Dashboard candidat — miroir JSON de /espace-candidat (web).
  static const String candidateDashboard = '/candidate/dashboard';

  // Concours Fonction Publique (FP)
  static const String contests = '/contests';
  static String contest(String id) => '/contests/$id';
  static String contestSave(String id) => '/contests/$id/save';

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
  static const String aiChatSessions = '/ai/chat/sessions';
  static String aiChatSession(String id) => '/ai/chat/sessions/$id';

  // Backend Laravel monte la messagerie sous /messages (cf. MessageApiController).
  static const String conversations = '/messages';
  static String conversation(String id) => '/messages/$id';
  static String conversationSend(String id) => '/messages/$id/send';
  static String conversationRead(String id) => '/messages/$id/read';

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
  static const String communitySuggestions = '/community/suggestions';
  static const String communitySearch = '/community/search';
  static const String communityPosts = '/community/posts';
  static String communityPost(String id) => '/community/posts/$id';
  static String communityPostReact(String id) => '/community/posts/$id/react';
  static String communityPostRepost(String id) => '/community/posts/$id/repost';
  static String communityPostReport(String id) => '/community/posts/$id/report';
  static String communityPostComments(String id) => '/community/posts/$id/comments';
  static String communityComment(String id) => '/community/comments/$id';
  static String communityUserFollow(String id) => '/community/users/$id/follow';
  static String communityUserConnect(String id) => '/community/users/$id/connect';
  static const String communityConnections = '/community/connections';
  static String communityConnectionRespond(String id) =>
      '/community/connections/$id/respond';
  static String communityUser(String id) => '/community/users/$id';

  // ─────────── Temps réel (Laravel Reverb / protocole Pusher) ───────────
  // Endpoint d'auth des canaux privés (Sanctum) : POST {socket_id, channel_name}
  // + Bearer token. cf. routes/api.php → api.v1.broadcasting.auth.
  static String get broadcastingAuthUrl => '$baseUrl/broadcasting/auth';

  // Clé applicative Reverb (= REVERB_APP_KEY backend). À surcharger en prod via
  // --dart-define=REVERB_APP_KEY=...  (défaut = clé de dev locale).
  static const String reverbAppKey = String.fromEnvironment(
    'REVERB_APP_KEY',
    defaultValue: 'r2isgakfkwfkjt14gupd',
  );

  // Hôte du daemon Reverb. Vide => dérivé de l'hôte API (même machine que
  // Laravel), ce qui gère automatiquement 10.0.2.2 (émulateur) vs 127.0.0.1.
  static const String _reverbHostOverride = String.fromEnvironment(
    'REVERB_HOST',
    defaultValue: '',
  );

  static String get reverbHost {
    if (_reverbHostOverride.trim().isNotEmpty) return _reverbHostOverride.trim();
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

  static Map<String, String> get jsonHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static Map<String, String> authHeaders(String token) => {
        ...jsonHeaders,
        'Authorization': 'Bearer $token',
      };

  static Map<String, String> authHeadersWithoutContentType(String token) => {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };
}
