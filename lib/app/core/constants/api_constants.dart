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
      // Emulateur Android -> localhost PC via 10.0.2.2
      return 'http://10.0.2.2:8000';
    }

    return 'http://127.0.0.1:8000';
  }

  static String _sanitizeHost(String host) {
    final trimmed = host.trim();
    final withoutTrailingSlash = trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
    final uri = Uri.tryParse(withoutTrailingSlash);

    if (uri == null ||
        uri.scheme.isEmpty ||
        uri.host.isEmpty ||
        (!kDebugMode && uri.scheme != 'https')) {
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

  static List<String> get baseUrlCandidates {
    final hosts = <String>[
      if (apiBaseUrlOverride.trim().isNotEmpty)
        _sanitizeHost(apiBaseUrlOverride),
      if (webBaseUrl.trim().isNotEmpty) _sanitizeHost(webBaseUrl),
      _sanitizeHost(_defaultHost),
      if (kDebugMode) 'http://127.0.0.1:8000',
      if (kDebugMode) 'http://10.0.2.2:8000',
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
  static const String profile = '/profile';
  static const String profileAvatar = '/profile/avatar';
  static const String profilePreferences = '/profile/preferences';
  static const String profileCv = '/profile/cv';
  static const String profilePortfolio = '/profile/portfolio';
  static const String profileCvBuilder = '/profile/cv-builder';
  static const String profileCvBuilderPreview = '/profile/cv-builder/preview';
  static const String profileCvBuilderDownload = '/profile/cv-builder/download';
  static const String profileCvBuilderSelectTemplate =
      '/profile/cv-builder/select-template';
  // Import CV : analyze (parse PDF→fields stateless) + apply (persist).
  // L'endpoint legacy `/profile/cv/upload` n'existe pas côté backend.
  static const String profileCvImportAnalyze =
      '/profile/cv-builder/import/analyze';
  static const String profileCvImportApply =
      '/profile/cv-builder/import/apply';

  static const String offers = '/offers';
  static const String offersFeatured = '/offers/featured/list';
  static const String offersSaved = '/offers/saved/list';
  static const String applications = '/applications';
  static const String trainings = '/trainings';
  static const String sectors = '/offers/sectors/list';

  // Backend Laravel monte la messagerie sous /messages (cf. MessageApiController).
  static const String conversations = '/messages';
  static const String notifications = '/notifications';

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
