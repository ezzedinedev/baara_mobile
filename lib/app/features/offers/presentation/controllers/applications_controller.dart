import 'package:get/get.dart';

import '../../../../core/utils/user_facing_error.dart';
import '../../data/models/application_model.dart';
import '../../data/models/upcoming_interview_model.dart';
import '../../domain/repositories/i_offer_repository.dart';

/// Charge la liste des candidatures du candidat connecté
/// (GET /applications) et les entretiens à venir
/// (GET /applications/interviews/upcoming), et expose un état observable.
class ApplicationsController extends GetxController {
  ApplicationsController(this._repository);

  final IOfferRepository _repository;

  final applications = <ApplicationModel>[].obs;
  final upcomingInterviews = <UpcomingInterview>[].obs;
  final isLoading = true.obs;
  final errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final results = await Future.wait([
        _repository.getMyApplications(),
        _repository.getUpcomingInterviews(),
      ]);
      applications.assignAll(results[0] as List<ApplicationModel>);
      upcomingInterviews.assignAll(results[1] as List<UpcomingInterview>);
    } catch (e) {
      errorMessage.value = userFacingError(e);
    } finally {
      isLoading.value = false;
    }
  }
}
