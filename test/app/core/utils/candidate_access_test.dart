import 'package:flutter_test/flutter_test.dart';
import 'package:baara/app/core/utils/candidate_access.dart';

void main() {
  group('CandidateAccess', () {
    test('allows candidate user type', () {
      expect(CandidateAccess.isAllowed('candidate'), isTrue);
      expect(CandidateAccess.isAllowed('Candidate'), isTrue);
    });

    test('blocks employer and recruiter types', () {
      expect(CandidateAccess.isAllowed('employer'), isFalse);
      expect(CandidateAccess.isAllowed('recruiter'), isFalse);
      expect(CandidateAccess.isAllowed('admin'), isFalse);
      expect(CandidateAccess.isAllowed(null), isFalse);
    });
  });
}
