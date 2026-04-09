import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';

class ApiProvider {
  ApiProvider({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String endpoint) => Uri.parse('${ApiConstants.baseUrl}$endpoint');

  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> payload, {
    Map<String, String>? headers,
  }) async {
    final response = await _client
        .post(
          _uri(endpoint),
          headers: headers ?? ApiConstants.jsonHeaders,
          body: jsonEncode(payload),
        )
        .timeout(ApiConstants.connectTimeout);

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
      'message': 'Réponse serveur inattendue.',
      'data': body,
    };
  }
}
