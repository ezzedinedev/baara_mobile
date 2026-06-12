import '../../../offers/data/models/application_model.dart';

class ApplyResult {
  final ApplicationModel application;
  final bool isMatch;
  final int score;

  const ApplyResult({
    required this.application,
    required this.isMatch,
    required this.score,
  });
}
