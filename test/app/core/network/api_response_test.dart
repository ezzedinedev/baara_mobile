import 'package:flutter_test/flutter_test.dart';
import 'package:baara/app/core/network/api_response.dart';

void main() {
  group('ApiResponse', () {
    test('ensureSuccess throws ApiException on HTTP error', () {
      expect(
        () => ApiResponse.ensureSuccess({
          'statusCode': 500,
          'success': false,
          'message': 'Erreur serveur',
        }),
        throwsA(isA<Exception>()),
      );
    });

    test('ensureSuccess throws on success=false', () {
      expect(
        () => ApiResponse.ensureSuccess({
          'success': false,
          'message': 'Non autorisé',
        }),
        throwsA(isA<Exception>()),
      );
    });

    test('ensureSuccess passes on success=true', () {
      expect(
        () => ApiResponse.ensureSuccess({'success': true}),
        returnsNormally,
      );
    });

    // Les routes qui n'utilisent pas l'enveloppe ApiController (entretiens,
    // offres d'emploi) répondent `{'data': ...}` en 200, sans `success` : les
    // traiter comme un échec casserait ces écrans alors que l'appel a réussi.
    test('ensureSuccess passes on HTTP 200 without a success field', () {
      expect(
        () => ApiResponse.ensureSuccess({
          'statusCode': 200,
          'data': [1, 2],
        }),
        returnsNormally,
      );
    });

    test('ensureSuccess still throws on 4xx without a success field', () {
      expect(
        () => ApiResponse.ensureSuccess({'statusCode': 401}),
        throwsA(isA<Exception>()),
      );
    });

    test('ensureSuccess throws when neither success nor statusCode is present',
        () {
      expect(
        () => ApiResponse.ensureSuccess(const {}),
        throwsA(isA<Exception>()),
      );
    });

    test('ensureSuccess throws on explicit success=false despite HTTP 200', () {
      expect(
        () => ApiResponse.ensureSuccess({
          'statusCode': 200,
          'success': false,
          'message': 'Refusé',
        }),
        throwsA(isA<Exception>()),
      );
    });

    test('hasMorePages reads Laravel pagination metadata', () {
      expect(
        ApiResponse.hasMorePages(
          {'current_page': 1, 'last_page': 3, 'has_more': true},
          pageSize: 20,
          itemCount: 20,
        ),
        isTrue,
      );
      expect(
        ApiResponse.hasMorePages(
          {'current_page': 3, 'last_page': 3},
          pageSize: 20,
          itemCount: 5,
        ),
        isFalse,
      );
    });

    test('hasMorePages falls back to page size', () {
      expect(
        ApiResponse.hasMorePages(null, pageSize: 20, itemCount: 20),
        isTrue,
      );
      expect(
        ApiResponse.hasMorePages(null, pageSize: 20, itemCount: 5),
        isFalse,
      );
    });

    test('extractList supports items and nested data', () {
      expect(ApiResponse.extractList([1, 2]), [1, 2]);
      expect(ApiResponse.extractList({'items': [3]}), [3]);
      expect(ApiResponse.extractList({'data': [4]}), [4]);
    });
  });
}
