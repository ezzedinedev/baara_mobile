import 'package:flutter_test/flutter_test.dart';
import 'package:baara/app/core/network/api_provider.dart';
import 'package:baara/app/features/offers/data/repositories/offer_repository_impl.dart';
import 'package:baara/app/features/offers/domain/repositories/i_offer_repository.dart';

class _FakeApiProvider extends ApiProvider {
  _FakeApiProvider(this._handler);

  final Future<Map<String, dynamic>> Function(String endpoint) _handler;

  @override
  Future<Map<String, dynamic>> getJson(
    String endpoint, {
    Map<String, String>? headers,
  }) {
    return _handler(endpoint);
  }
}

void main() {
  group('OfferRepositoryImpl', () {
    test('getOffers propagates API failures', () async {
      final repo = OfferRepositoryImpl(
        apiProvider: _FakeApiProvider((_) async => {
              'success': false,
              'message': 'Erreur réseau',
              'statusCode': 503,
            }),
      );

      expect(() => repo.getOffers(), throwsA(isA<ApiException>()));
    });

    test('getOffers parses pagination metadata', () async {
      final repo = OfferRepositoryImpl(
        apiProvider: _FakeApiProvider((_) async => {
              'success': true,
              'data': {
                'items': [
                  {
                    'id': '1',
                    'title': 'Dev',
                    'company_name': 'ACME',
                    'location': 'Ouaga',
                  },
                ],
                'current_page': 1,
                'last_page': 2,
                'has_more': true,
              },
            }),
      );

      final page = await repo.getOffers(page: 1, perPage: 20);
      expect(page, isA<OfferPage>());
      expect(page.items, hasLength(1));
      expect(page.hasMore, isTrue);
      expect(page.currentPage, 1);
    });

    // InterviewApiController / JobProposalApiController n'héritent pas de
    // l'enveloppe `ApiController::success()` : ils répondent `{'data': ...}` en
    // HTTP 200, sans champ `success`. Exiger `success == true` faisait échouer
    // ces quatre routes alors que l'appel avait réussi.
    test('getInterviews accepte une réponse 200 sans champ success', () async {
      final repo = OfferRepositoryImpl(
        apiProvider: _FakeApiProvider((_) async => {
              'statusCode': 200,
              'data': <dynamic>[],
            }),
      );

      expect(await repo.getInterviews(), isEmpty);
    });

    test('getJobProposals accepte une réponse 200 sans champ success',
        () async {
      final repo = OfferRepositoryImpl(
        apiProvider: _FakeApiProvider((_) async => {
              'statusCode': 200,
              'data': <dynamic>[],
            }),
      );

      expect(await repo.getJobProposals(), isEmpty);
    });

    test('getInterviews propage tout de même un 500', () {
      final repo = OfferRepositoryImpl(
        apiProvider: _FakeApiProvider((_) async => {'statusCode': 500}),
      );

      expect(() => repo.getInterviews(), throwsA(isA<ApiException>()));
    });

    test('getOffers returns empty page on valid empty response', () async {
      final repo = OfferRepositoryImpl(
        apiProvider: _FakeApiProvider((_) async => {
              'success': true,
              'data': {
                'items': [],
                'current_page': 1,
                'last_page': 1,
                'has_more': false,
              },
            }),
      );

      final page = await repo.getOffers();
      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
    });
  });
}
