import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:opportune_bf/app/core/network/api_provider.dart';
import 'package:opportune_bf/app/core/services/offline_apply_queue.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PendingApply', () {
    test('round-trips through JSON', () {
      final apply = PendingApply(
        offerId: '42',
        offerTitle: 'Dev Flutter',
        company: 'Opportune',
        logoUrl: 'https://cdn/logo.png',
        screeningAnswers: const {'q1': 'oui'},
        queuedAt: DateTime.utc(2026, 1, 15, 10),
      );

      final restored = PendingApply.fromJson(apply.toJson());
      expect(restored?.offerId, '42');
      expect(restored?.offerTitle, 'Dev Flutter');
      expect(restored?.company, 'Opportune');
      expect(restored?.screeningAnswers, {'q1': 'oui'});
    });

    test('returns null for invalid JSON', () {
      expect(PendingApply.fromJson({}), isNull);
    });
  });

  group('OfflineApplyQueue', () {
    late OfflineApplyQueue queue;

    setUp(() {
      Get.testMode = true;
      queue = OfflineApplyQueue(ApiProvider(interceptors: const []));
    });

    tearDown(() {
      queue.onClose();
      Get.reset();
    });

    test('enqueue deduplicates by offer id', () async {
      final apply = PendingApply(
        offerId: '1',
        offerTitle: 'A',
        company: 'B',
        queuedAt: DateTime.now(),
      );
      await queue.enqueue(apply);
      await queue.enqueue(apply);
      expect(queue.pending.length, 1);
      expect(queue.contains('1'), isTrue);
    });

    test('remove clears pending item', () async {
      await queue.enqueue(PendingApply(
        offerId: '9',
        offerTitle: 'X',
        company: 'Y',
        queuedAt: DateTime.now(),
      ));
      await queue.remove('9');
      expect(queue.pending, isEmpty);
    });
  });
}
