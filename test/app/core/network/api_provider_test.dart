import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opportune_bf/app/core/network/api_provider.dart';

void main() {
  group('ApiProvider', () {
    test('getJson attaches bearer token from provider', () async {
      final client = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer test-token');
        return http.Response(
          jsonEncode({'success': true, 'data': {'id': 1}}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final provider = ApiProvider(
        client: client,
        interceptors: const [],
        tokenProvider: () async => 'test-token',
      );

      final result = await provider.getJson('/me');
      expect(result['success'], isTrue);
      expect(result['data'], {'id': 1});
      provider.dispose();
    });

    test('retries on 503 then succeeds', () async {
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        if (calls == 1) {
          return http.Response('{}', 503);
        }
        return http.Response(
          jsonEncode({'success': true, 'data': 'ok'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final provider = ApiProvider(
        client: client,
        interceptors: const [],
        retryPolicy: const RetryPolicy(maxRetries: 2, baseDelay: Duration.zero),
      );

      final result = await provider.getJson('/offers');
      expect(calls, 2);
      expect(result['success'], isTrue);
      provider.dispose();
    });

    test('throws ApiException on invalid endpoint scheme', () async {
      final provider = ApiProvider(interceptors: const []);
      expect(
        () => provider.getJson('ftp://bad-host/test'),
        throwsA(isA<ApiException>()),
      );
      provider.dispose();
    });
  });
}
