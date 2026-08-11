import 'package:flutter_test/flutter_test.dart';
import 'package:baara/app/core/network/api_provider.dart';

void main() {
  group('RetryPolicy', () {
    const policy = RetryPolicy();

    test('retries transient status codes within maxRetries', () {
      expect(policy.shouldRetry(429, 0), isTrue);
      expect(policy.shouldRetry(503, 1), isTrue);
      expect(policy.shouldRetry(503, 2), isFalse);
    });

    test('does not retry deterministic server errors', () {
      expect(policy.shouldRetry(500, 0), isFalse);
      expect(policy.shouldRetry(400, 0), isFalse);
    });

    test('exponential backoff delay', () {
      expect(policy.getDelay(0), const Duration(milliseconds: 400));
      expect(policy.getDelay(1), const Duration(milliseconds: 800));
      expect(policy.getDelay(2), const Duration(milliseconds: 1600));
    });
  });
}
