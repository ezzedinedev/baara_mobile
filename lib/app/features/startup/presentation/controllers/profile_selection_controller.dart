import 'package:get/get.dart';
import 'package:jobaway/routes/app_routes.dart';

/// Types de profil disponibles à l'inscription MOBILE. Le recrutement
/// (entreprise) se fait exclusivement sur la plateforme web → plus d'option
/// recruteur ici.
enum ProfileType { jobseeker, student }

class ProfileSelectionController extends GetxController {
  final Rx<ProfileType?> selected = Rx<ProfileType?>(null);

  bool get canContinue => selected.value != null;

  void select(ProfileType type) {
    selected.value = type;
  }

  void onContinue() {
    if (!canContinue) return;
    // Les deux profils candidats mènent au formulaire d'inscription.
    Get.toNamed(AppRoutes.register);
  }
}
