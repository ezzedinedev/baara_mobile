import 'package:flutter_test/flutter_test.dart';
import 'package:baara/app/core/network/api_provider.dart';
import 'package:baara/app/features/notifications/data/repositories/notification_repository_impl.dart';

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
  }) async {
    return _response;
  }

  @override
  Future<Map<String, dynamic>> deleteJson(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    return _response;
  }
}

void main() {
  group('NotificationRepositoryImpl', () {
    test('getNotifications propage un échec au lieu de renvoyer une liste vide',
        () {
      final repo = NotificationRepositoryImpl(
        apiProvider: _FakeApiProvider({
          'success': false,
          'message': 'Service indisponible',
          'statusCode': 503,
        }),
      );

      expect(() => repo.getNotifications(), throwsA(isA<ApiException>()));
    });

    test('getNotifications propage un 4xx même si `success` est absent', () {
      final repo = NotificationRepositoryImpl(
        apiProvider: _FakeApiProvider({'statusCode': 401}),
      );

      expect(() => repo.getNotifications(), throwsA(isA<ApiException>()));
    });

    test('getNotifications parse items, has_more et unread_count', () async {
      final repo = NotificationRepositoryImpl(
        apiProvider: _FakeApiProvider({
          'success': true,
          'data': {
            'items': [
              {'id': '1', 'title': 'Nouvelle offre', 'is_read': false},
            ],
            'has_more': true,
            'unread_count': 4,
          },
        }),
      );

      final page = await repo.getNotifications();
      expect(page.items, hasLength(1));
      expect(page.hasMore, isTrue);
      expect(page.unreadCount, 4);
    });

    test('getNotifications rend une page vide sur une réponse valide vide',
        () async {
      final repo = NotificationRepositoryImpl(
        apiProvider: _FakeApiProvider({
          'success': true,
          'data': {'items': [], 'has_more': false, 'unread_count': 0},
        }),
      );

      final page = await repo.getNotifications();
      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
      expect(page.unreadCount, 0);
    });

    // Ces écritures alimentent un rollback optimiste côté controller : si elles
    // n'échouent pas, le rollback ne se déclenche jamais et l'UI ment.
    test('markAsRead lève quand le backend refuse', () {
      final repo = NotificationRepositoryImpl(
        apiProvider: _FakeApiProvider({'success': false, 'statusCode': 500}),
      );

      expect(() => repo.markAsRead('1'), throwsA(isA<ApiException>()));
    });

    test('markAllAsRead lève quand le backend refuse', () {
      final repo = NotificationRepositoryImpl(
        apiProvider: _FakeApiProvider({'success': false, 'statusCode': 500}),
      );

      expect(() => repo.markAllAsRead(), throwsA(isA<ApiException>()));
    });

    test('delete lève quand le backend refuse', () {
      final repo = NotificationRepositoryImpl(
        apiProvider: _FakeApiProvider({'success': false, 'statusCode': 403}),
      );

      expect(() => repo.delete('1'), throwsA(isA<ApiException>()));
    });
  });
}
