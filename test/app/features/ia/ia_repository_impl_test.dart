import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jobaway/app/core/network/api_provider.dart';
import 'package:jobaway/app/features/ia/data/repositories/ia_repository_impl.dart';

void main() {
  group('IaRepositoryImpl', () {
    test('chatSessions handles list response correctly', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {'id': 's1', 'title': 'Session 1'},
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final provider = ApiProvider(client: client, interceptors: const []);
      final repo = IaRepositoryImpl(apiProvider: provider);

      final sessions = await repo.chatSessions();
      expect(sessions, hasLength(1));
      expect(sessions.first['id'], 's1');
      provider.dispose();
    });

    test('cvAudit throws ApiException on failure', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'CV manquant',
          }),
          422,
          headers: {'content-type': 'application/json'},
        );
      });
      final provider = ApiProvider(client: client, interceptors: const []);
      final repo = IaRepositoryImpl(apiProvider: provider);

      expect(() => repo.cvAudit(), throwsA(isA<ApiException>()));
      provider.dispose();
    });
  });
}
