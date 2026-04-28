import 'package:get/get.dart';

import '../../../../routes/app_routes.dart';

enum ProfileType { jobseeker, student, recruiter }

class ProfileSelectionController extends GetxController {
  final Rx<ProfileType?> selected = Rx<ProfileType?>(null);

  bool get canContinue => selected.value != null;

  void select(ProfileType type) {
    selected.value = type;
  }

  void onContinue() {
    if (!canContinue) {
      return;
    }

    switch (selected.value!) {
      case ProfileType.jobseeker:
      case ProfileType.student:
        Get.toNamed(AppRoutes.candidateLogin);
      case ProfileType.recruiter:
        Get.toNamed(AppRoutes.recruiterLogin);
    }
  }
}
