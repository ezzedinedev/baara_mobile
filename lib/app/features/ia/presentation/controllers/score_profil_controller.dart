import 'package:get/get.dart';

import '../../../../data/models/ai_models.dart';
import '../../../../data/repositories/ai_repository.dart';
import '../../../../core/utils/user_facing_error.dart';

/// Charge le score de profil intelligent (POST /ai/profile/score) et expose
/// un état observable (loading / erreur / data) pour l'écran.
class ScoreProfilController extends GetxController {
  ScoreProfilController(this._repository);

  final AiRepository _repository;

  final isLoading = true.obs;
  final errorMessage = RxnString();
  final Rxn<AiProfileScore> score = Rxn<AiProfileScore>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      score.value = await _repository.profileScore();
    } catch (e) {
      errorMessage.value = userFacingError(e);
    } finally {
      isLoading.value = false;
    }
  }
}
