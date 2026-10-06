import 'package:flutter_test/flutter_test.dart';
import 'package:baara/app/core/network/api_provider.dart';
import 'package:baara/app/features/community/data/repositories/community_repository_impl.dart';

class _FakeApiProvider extends ApiProvider {
  _FakeApiProvider(this._response);

  final Map<String, dynamic> _response;

  @override
  Future<Map<String, dynamic>> getJson(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    return _response;
  }

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> payload, {
    Map<String, String>? headers,
    String? idempotencyKey,
    bool idempotent = true,
  }) async {
    return _response;
  }

  @override
  Future<Map<String, dynamic>> deleteJson(
    String endpoint, {
    Map<String, String>? headers,
    String? idempotencyKey,
    bool idempotent = true,
  }) async {
    return _response;
  }
}

CommunityRepositoryImpl _repoFailing([int statusCode = 503]) {
  return CommunityRepositoryImpl(
    apiProvider: _FakeApiProvider({
      'success': false,
      'message': 'Service indisponible',
      'statusCode': statusCode,
    }),
  );
}

void main() {
  group('CommunityRepositoryImpl — lectures', () {
    // Le bug historique : une erreur API se traduisait par `data == null`, donc
    // un feed vide silencieux impossible à distinguer d'un vrai feed vide.
    test('getFeed propage un échec au lieu de rendre un fil vide', () {
      expect(() => _repoFailing().getFeed(), throwsA(isA<ApiException>()));
    });

    test('getExplore propage un échec', () {
      expect(() => _repoFailing().getExplore(), throwsA(isA<ApiException>()));
    });

    test('getFeed propage un 4xx même si `success` est absent', () {
      final repo = CommunityRepositoryImpl(
        apiProvider: _FakeApiProvider({'statusCode': 401}),
      );

      expect(() => repo.getFeed(), throwsA(isA<ApiException>()));
    });

    test('getFeed parse items et pagination sur une réponse valide', () async {
      final repo = CommunityRepositoryImpl(
        apiProvider: _FakeApiProvider({
          'success': true,
          'data': {
            'items': [
              {'id': '1', 'body': 'Bonjour'},
            ],
            'current_page': 2,
            'last_page': 3,
            'has_more': true,
          },
        }),
      );

      final page = await repo.getFeed(page: 2);
      expect(page.items, hasLength(1));
      expect(page.currentPage, 2);
      expect(page.hasMore, isTrue);
    });

    test('getFeed rend un fil vide sur une réponse valide vide', () async {
      final repo = CommunityRepositoryImpl(
        apiProvider: _FakeApiProvider({
          'success': true,
          'data': {'items': [], 'current_page': 1, 'has_more': false},
        }),
      );

      final page = await repo.getFeed();
      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
    });

    test('getComments propage un échec', () {
      expect(() => _repoFailing().getComments('1'),
          throwsA(isA<ApiException>()));
    });

    test('getConnections propage un échec', () {
      expect(() => _repoFailing().getConnections(),
          throwsA(isA<ApiException>()));
    });

    test('getStories propage un échec', () {
      expect(() => _repoFailing().getStories(), throwsA(isA<ApiException>()));
    });

    test('getSuggestions propage un échec', () {
      expect(
          () => _repoFailing().getSuggestions(), throwsA(isA<ApiException>()));
    });
  });

  group('CommunityRepositoryImpl — écritures', () {
    // Ces appels pilotent des mises à jour optimistes : sans exception, le
    // rollback du controller ne se déclenche jamais.
    test('react lève quand le backend refuse', () {
      expect(() => _repoFailing(500).react('1', 'like'),
          throwsA(isA<ApiException>()));
    });

    test('follow lève quand le backend refuse', () {
      expect(() => _repoFailing(500).follow('1'), throwsA(isA<ApiException>()));
    });

    test('unfollow lève quand le backend refuse', () {
      expect(
          () => _repoFailing(500).unfollow('1'), throwsA(isA<ApiException>()));
    });

    test('connect lève quand le backend refuse', () {
      expect(
          () => _repoFailing(403).connect('1'), throwsA(isA<ApiException>()));
    });

    test('respondConnection lève quand le backend refuse', () {
      expect(() => _repoFailing(500).respondConnection('1', accept: true),
          throwsA(isA<ApiException>()));
    });

    test('toggleSave lève quand le backend refuse', () {
      expect(() => _repoFailing(500).toggleSave('1', save: true),
          throwsA(isA<ApiException>()));
    });

    test('deletePost lève quand le backend refuse', () {
      expect(
          () => _repoFailing(403).deletePost('1'), throwsA(isA<ApiException>()));
    });

    test('addComment lève quand le backend refuse', () {
      expect(() => _repoFailing(422).addComment('1', 'salut'),
          throwsA(isA<ApiException>()));
    });

    test('toggleSave rend is_saved sur une réponse valide', () async {
      final repo = CommunityRepositoryImpl(
        apiProvider: _FakeApiProvider({
          'success': true,
          'data': {'is_saved': true},
        }),
      );

      expect(await repo.toggleSave('1', save: true), isTrue);
    });
  });
}
