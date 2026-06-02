import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';

abstract class ApiInterceptor {
  void onRequest(http.BaseRequest request);
  void onResponse(http.Response response);
  void onError(Exception error);
}

class LoggingInterceptor implements ApiInterceptor {
  @override
  void onRequest(http.BaseRequest request) {
    // ignore: avoid_print
    print('API Request: ${request.method} ${request.url}');
  }

  @override
  void onResponse(http.Response response) {
    // ignore: avoid_print
    print('API Response: ${response.statusCode} ${response.request?.url}');
  }

  @override
  void onError(Exception error) {
    // ignore: avoid_print
    print('API Error: $error');
  }
}

class RetryPolicy {
  final int maxRetries;
  final Duration baseDelay;
  final List<int> retryableStatusCodes;

  const RetryPolicy({
    this.maxRetries = 3,
    this.baseDelay = const Duration(milliseconds: 500),
    this.retryableStatusCodes = const [408, 429, 500, 502, 503, 504],
  });

  bool shouldRetry(int statusCode, int attempt) {
    return attempt < maxRetries && retryableStatusCodes.contains(statusCode);
  }

  Duration getDelay(int attempt) {
    return baseDelay * (1 << attempt);
  }
}

class ApiMultipartFile {
  const ApiMultipartFile({
    required this.field,
    required this.bytes,
    required this.filename,
  });

  final String field;
  final Uint8List bytes;
  final String filename;
}

class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.endpoint,
    this.previous,
  });

  final String message;
  final int? statusCode;
  final String? endpoint;
  final Exception? previous;

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

class ApiProvider {
  ApiProvider({
    http.Client? client,
    List<ApiInterceptor>? interceptors,
    RetryPolicy? retryPolicy,
    Future<String?> Function()? tokenProvider,
    Future<String?> Function()? tokenRefresher,
    void Function()? onAuthFailed,
  })  : _client = client ?? http.Client(),
        _interceptors = interceptors ?? [LoggingInterceptor()],
        _retryPolicy = retryPolicy ?? const RetryPolicy(),
        _tokenProvider = tokenProvider,
        _tokenRefresher = tokenRefresher,
        _onAuthFailed = onAuthFailed;

  final http.Client _client;
  final List<ApiInterceptor> _interceptors;
  final RetryPolicy _retryPolicy;
  Future<String?> Function()? _tokenProvider;
  /// Callback appelé sur 401 pour tenter un refresh de token.
  /// Doit retourner le nouveau token (ou null si échec → déconnexion).
  final Future<String?> Function()? _tokenRefresher;
  /// Callback appelé quand le refresh échoue : laisser le shell logger
  /// l'utilisateur out + router vers landing.
  final void Function()? _onAuthFailed;
  /// Lock pour éviter plusieurs refresh concurrents (toutes les requêtes
  /// 401 simultanées attendent le même refresh).
  Future<String?>? _ongoingRefresh;
  String? _lastWorkingBaseUrl;

  void setTokenProvider(Future<String?> Function()? provider) {
    _tokenProvider = provider;
  }

  Future<Map<String, String>> _withAuth(Map<String, String> headers) async {
    final hasAuth = headers.keys.any((k) => k.toLowerCase() == 'authorization');
    if (hasAuth || _tokenProvider == null) return headers;
    try {
      final token = await _tokenProvider!.call();
      if (token == null || token.trim().isEmpty) return headers;
      return {...headers, 'Authorization': 'Bearer $token'};
    } catch (_) {
      return headers;
    }
  }

  void addInterceptor(ApiInterceptor interceptor) {
    _interceptors.add(interceptor);
  }

  void removeInterceptor(ApiInterceptor interceptor) {
    _interceptors.remove(interceptor);
  }

  Uri _buildUri(String baseUrl, String endpoint) {
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final url = '$baseUrl$cleanEndpoint';
    final uri = Uri.parse(url);

    if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
      return uri;
    }

    if (uri.scheme.isEmpty || !['http', 'https'].contains(uri.scheme)) {
      throw ApiException(
        message: 'Invalid endpoint scheme',
        endpoint: endpoint,
      );
    }

    if (uri.host.contains(':')) {
      final parts = uri.host.split(':');
      final port = int.tryParse(parts[1]);
      if (port != null && (port < 1 || port > 65535)) {
        throw ApiException(
          message: 'Invalid port in endpoint',
          endpoint: endpoint,
        );
      }
    }

    return uri;
  }

  Future<Map<String, dynamic>> getJson(
    String endpoint, {
    Map<String, String>? headers,
  }) {
    return _sendJsonRequest(
      method: 'GET',
      endpoint: endpoint,
      headers: headers ?? const {'Accept': 'application/json'},
    );
  }

  /// GET authentifié renvoyant le corps binaire brut (ex: PDF généré serveur).
  /// Bascule sur les base-URL candidates en cas d'erreur réseau ; une réponse
  /// HTTP non-2xx est renvoyée telle quelle via [ApiException].
  Future<Uint8List> getBytes(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final candidateBaseUrls = _orderedBaseUrls();
    Exception? lastError;

    for (final baseUrl in candidateBaseUrls) {
      try {
        final uri = _buildUri(baseUrl, endpoint);
        final request = http.Request('GET', uri);
        final authedHeaders =
            await _withAuth(headers ?? const {'Accept': 'application/pdf'});
        request.headers.addAll(authedHeaders);

        _notifyRequest(request);
        final streamed = await _client
            .send(request)
            .timeout(ApiConstants.connectTimeout);
        final response = await http.Response.fromStream(streamed)
            .timeout(ApiConstants.receiveTimeout);
        _notifyResponse(response);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          _lastWorkingBaseUrl = baseUrl;
          return response.bodyBytes;
        }
        throw ApiException(
          message: 'Téléchargement impossible (HTTP ${response.statusCode}).',
          statusCode: response.statusCode,
          endpoint: endpoint,
        );
      } on ApiException {
        rethrow;
      } on Exception catch (e) {
        lastError = e;
        _notifyError(e);
      }
    }

    throw ApiException(
      message: 'Téléchargement impossible.',
      endpoint: endpoint,
      previous: lastError,
    );
  }

  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> payload, {
    Map<String, String>? headers,
  }) {
    return _sendJsonRequest(
      method: 'POST',
      endpoint: endpoint,
      headers: headers ?? ApiConstants.jsonHeaders,
      body: payload,
    );
  }

  Future<Map<String, dynamic>> putJson(
    String endpoint,
    Map<String, dynamic> payload, {
    Map<String, String>? headers,
  }) {
    return _sendJsonRequest(
      method: 'PUT',
      endpoint: endpoint,
      headers: headers ?? ApiConstants.jsonHeaders,
      body: payload,
    );
  }

  Future<Map<String, dynamic>> deleteJson(
    String endpoint, {
    Map<String, String>? headers,
  }) {
    return _sendJsonRequest(
      method: 'DELETE',
      endpoint: endpoint,
      headers: headers ?? const {'Accept': 'application/json'},
    );
  }

  Future<Map<String, dynamic>> multipartPost(
    String endpoint, {
    required Map<String, String> fields,
    required List<http.MultipartFile> files,
    Map<String, String>? headers,
  }) async {
    final candidateBaseUrls = _orderedBaseUrls();
    Exception? lastError;

    for (final baseUrl in candidateBaseUrls) {
      try {
        final uri = _buildUri(baseUrl, endpoint);
        final request = http.MultipartRequest('POST', uri);
        final mergedHeaders = await _withAuth({
          'Accept': 'application/json',
          ...?headers,
        });
        request.headers.addAll(mergedHeaders);
        request.fields.addAll(fields);
        request.files.addAll(files);

        _notifyRequest(request);
        final streamedResponse = await request.send().timeout(ApiConstants.connectTimeout);
        final response = await http.Response.fromStream(streamedResponse).timeout(ApiConstants.receiveTimeout);
        _notifyResponse(response);
        
        _lastWorkingBaseUrl = baseUrl;
        return _parseResponse(response);
      } catch (e) {
        lastError = e as Exception;
      }
    }
    throw ApiException(message: 'Multipart upload failed', endpoint: endpoint, previous: lastError);
  }

  Future<Map<String, dynamic>> sendMultipart(
    String endpoint, {
    required String method,
    Map<String, String>? headers,
    Map<String, String>? fields,
    List<ApiMultipartFile> files = const [],
  }) async {
    final candidateBaseUrls = _orderedBaseUrls();
    Exception? lastError;

    for (final baseUrl in candidateBaseUrls) {
      try {
        final uri = _buildUri(baseUrl, endpoint);
        final request = http.MultipartRequest(method, uri);

        final mergedHeaders = await _withAuth({
          'Accept': 'application/json',
          ...?headers,
        });
        request.headers.addAll(mergedHeaders);

        if (fields != null) {
          for (final entry in fields.entries) {
            request.fields[entry.key] = entry.value;
          }
        }

        for (final file in files) {
          if (file.bytes.length > ApiConstants.maxMultipartBytes) {
            throw ApiException(
              message:
                  'File size exceeds ${ApiConstants.maxMultipartBytes} bytes',
              endpoint: endpoint,
            );
          }
          request.files.add(
            http.MultipartFile.fromBytes(
              file.field,
              file.bytes,
              filename: file.filename,
            ),
          );
        }

        if (request.files.length > ApiConstants.maxMultipartFiles) {
          throw ApiException(
            message: 'Maximum ${ApiConstants.maxMultipartFiles} files allowed',
            endpoint: endpoint,
          );
        }

        _notifyRequest(request);

        final streamedResponse = await request.send().timeout(
              ApiConstants.connectTimeout,
              onTimeout: () => throw TimeoutException('Connection timeout'),
            );

        final response = await http.Response.fromStream(streamedResponse)
            .timeout(ApiConstants.receiveTimeout);

        _notifyResponse(response);

        _lastWorkingBaseUrl = baseUrl;
        return _parseResponse(response);
      } on Exception catch (e) {
        lastError = e;
        _notifyError(e);
      }
    }

    throw ApiException(
      message:
          'Unable to connect to API. Tried: ${candidateBaseUrls.join(', ')}',
      endpoint: endpoint,
      previous: lastError,
    );
  }

  Future<Map<String, dynamic>> _sendJsonRequest({
    required String method,
    required String endpoint,
    required Map<String, String> headers,
    Map<String, dynamic>? body,
    bool afterRefresh = false,
  }) async {
    final candidateBaseUrls = _orderedBaseUrls();
    Exception? lastError;

    for (int attempt = 0; attempt < candidateBaseUrls.length; attempt++) {
      final baseUrl = candidateBaseUrls[attempt];

      for (int retryAttempt = 0;
          retryAttempt <= _retryPolicy.maxRetries;
          retryAttempt++) {
        try {
          final uri = _buildUri(baseUrl, endpoint);
          final request = http.Request(method, uri);
          final authedHeaders = await _withAuth(headers);
          request.headers.addAll(authedHeaders);

          if (body != null) {
            request.body = jsonEncode(body);
          }

          _notifyRequest(request);

          final streamedResponse = await _client.send(request).timeout(
                ApiConstants.connectTimeout,
                onTimeout: () => throw TimeoutException('Connection timeout'),
              );

          final response = await http.Response.fromStream(streamedResponse)
              .timeout(ApiConstants.receiveTimeout);

          _notifyResponse(response);

          // 401 = token expiré ou invalide. Si on a un refresher et qu'on
          // n'a pas déjà tenté → un seul refresh + retry. Sinon on rend la
          // 401 au caller (qui peut router vers login).
          if (response.statusCode == 401 &&
              !afterRefresh &&
              _tokenRefresher != null &&
              _isAuthenticatedEndpoint(endpoint)) {
            final refreshed = await _refreshTokenOnce();
            if (refreshed != null && refreshed.isNotEmpty) {
              return _sendJsonRequest(
                method: method,
                endpoint: endpoint,
                headers: headers,
                body: body,
                afterRefresh: true,
              );
            }
            // Refresh échoué : on prévient le shell pour déconnecter,
            // puis on retourne quand même la 401 au caller.
            _onAuthFailed?.call();
          }

          if (_retryPolicy.shouldRetry(response.statusCode, retryAttempt)) {
            await Future.delayed(_retryPolicy.getDelay(retryAttempt));
            continue;
          }

          _lastWorkingBaseUrl = baseUrl;
          return _parseResponse(response);
        } on TimeoutException {
          if (retryAttempt < _retryPolicy.maxRetries) {
            await Future.delayed(_retryPolicy.getDelay(retryAttempt));
            continue;
          }
          rethrow;
        } on Exception catch (e) {
          lastError = e;
          _notifyError(e);

          if (retryAttempt < _retryPolicy.maxRetries && _isNetworkError(e)) {
            await Future.delayed(_retryPolicy.getDelay(retryAttempt));
            continue;
          }
        }
      }
    }

    throw ApiException(
      message: 'Unable to connect to API',
      endpoint: endpoint,
      previous: lastError,
    );
  }

  bool _isNetworkError(Exception e) {
    return e is TimeoutException ||
        e.toString().contains('SocketException') ||
        e.toString().contains('HandshakeException');
  }

  /// Retourne true si l'endpoint est censé être appelé avec un Bearer.
  /// Inutile de tenter un refresh sur les endpoints publics (login, register,
  /// otp, offers public, etc.) — un 401 dessus signale autre chose.
  bool _isAuthenticatedEndpoint(String endpoint) {
    final e = endpoint.toLowerCase();
    if (e.contains('/auth/login') ||
        e.contains('/auth/register') ||
        e.contains('/auth/otp') ||
        e.contains('/auth/refresh')) {
      return false;
    }
    // Le reste qui passe par /api/v1/ est généralement protégé.
    return true;
  }

  /// Lance UN SEUL refresh à la fois ; les requêtes 401 simultanées
  /// attendent le même résultat (évite N appels concurrents à /auth/refresh).
  Future<String?> _refreshTokenOnce() {
    final ongoing = _ongoingRefresh;
    if (ongoing != null) return ongoing;

    final task = () async {
      try {
        return await _tokenRefresher!.call();
      } catch (_) {
        return null;
      } finally {
        _ongoingRefresh = null;
      }
    }();
    _ongoingRefresh = task;
    return task;
  }

  List<String> _orderedBaseUrls() {
    final candidates = <String>[
      if (_lastWorkingBaseUrl != null) _lastWorkingBaseUrl!,
      ...ApiConstants.baseUrlCandidates,
    ];

    final unique = <String>[];
    for (final url in candidates) {
      if (!unique.contains(url)) {
        unique.add(url);
      }
    }
    return unique;
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    final dynamic body = response.body.isEmpty ? {} : jsonDecode(response.body);
    if (body is Map<String, dynamic>) {
      return {
        'statusCode': response.statusCode,
        ...body,
      };
    }

    return {
      'statusCode': response.statusCode,
      'success': false,
      'message': 'Unexpected server response',
      'data': body,
    };
  }

  void _notifyRequest(http.BaseRequest request) {
    for (final interceptor in _interceptors) {
      interceptor.onRequest(request);
    }
  }

  void _notifyResponse(http.Response response) {
    for (final interceptor in _interceptors) {
      interceptor.onResponse(response);
    }
  }

  void _notifyError(Exception error) {
    for (final interceptor in _interceptors) {
      interceptor.onError(error);
    }
  }

  void dispose() {
    _client.close();
  }
}
