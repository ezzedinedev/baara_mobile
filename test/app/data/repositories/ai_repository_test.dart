import 'package:flutter_test/flutter_test.dart';
import 'package:opportune_bf/app/core/network/api_provider.dart';
import 'package:opportune_bf/app/data/repositories/ai_repository.dart';

class MockApiProvider extends ApiProvider {
  Map<String, dynamic>? mockResponse;
  
  @override
  Future<Map<String, dynamic>> postJson(String endpoint, Map<String, dynamic> payload, {Map<String, String>? headers}) async {
    return mockResponse!;
  }

  @override
  Future<Map<String, dynamic>> getJson(String endpoint, {Map<String, String>? headers}) async {
    return mockResponse!;
  }
}

void main() {
  late AiRepository repository;
  late MockApiProvider mockApi;

  setUp(() {
    mockApi = MockApiProvider();
    repository = AiRepository(apiProvider: mockApi);
  });

  group('AiRepository', () {
    test('chatSessions handles list response correctly', () async {
      mockApi.mockResponse = {
        'success': true,
        'data': [
          {'id': 's1', 'title': 'Session 1'}
        ]
      };

      final result = await repository.chatSessions();
      expect(result, isA<List<Map<String, dynamic>>>());
      expect(result.first['id'], 's1');
    });

    test('throws ApiException on failure', () async {
      mockApi.mockResponse = {
        'success': false,
        'message': 'Error LLM',
        'statusCode': 500
      };

      expect(() => repository.cvAudit(), throwsA(isA<ApiException>()));
    });
  });
}
