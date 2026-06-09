import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:opportune_bf/app/core/services/auth_token_store.dart';
import 'package:opportune_bf/app/core/services/realtime_service.dart';
import 'package:opportune_bf/app/core/utils/user_facing_error.dart';
import 'package:opportune_bf/app/core/widgets/common/app_toast.dart';
import 'package:opportune_bf/routes/app_routes.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/i_profile_repository.dart';

class ProfileController extends GetxController {
  final IProfileRepository _repository;

  ProfileController(this._repository);

  final profile = Rxn<Profile>();
  final isLoading = false.obs;
  final isLoadingProfile = false.obs; // Compatibility with UI
  final isUploadingAvatar = false.obs;
  final errorMessage = RxnString();

  // Stubs for UI compatibility
  final cvs = <dynamic>[].obs;
  final portfolioProjects = <dynamic>[].obs;
  final trainingCertificates = <dynamic>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    try {
      isLoading.value = true;
      isLoadingProfile.value = true;
      errorMessage.value = null;
      profile.value = await _repository.getProfile();
    } catch (e) {
      errorMessage.value = "Erreur de chargement du profil";
    } finally {
      isLoading.value = false;
      isLoadingProfile.value = false;
    }
  }

  // Legacy method names for UI compatibility
  Future<void> loadProfile() => fetchProfile();

  /// Sélectionne une image en galerie et l'envoie comme nouvel avatar
  /// (POST /profile/avatar, champ `avatar`, ≤ 2 Mo).
  Future<void> pickAndUploadAvatar() async {
    if (isUploadingAvatar.value) return;

    final XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } catch (_) {
      AppToast.error('Galerie inaccessible', 'Vérifiez les autorisations.');
      return;
    }
    if (picked == null) return; // annulé

    isUploadingAvatar.value = true;
    try {
      final bytes = await picked.readAsBytes();
      profile.value = await _repository.updateAvatar(picked.path, bytes);
      AppToast.success('Photo de profil mise à jour');
    } catch (e) {
      AppToast.error('Échec de l\'envoi', userFacingError(e));
    } finally {
      isUploadingAvatar.value = false;
    }
  }

  final isSavingProfile = false.obs;

  /// Met à jour le profil (PUT /profile) et rafraîchit l'état local.
  /// Retourne `true` en cas de succès.
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      isSavingProfile.value = true;
      profile.value = await _repository.updateProfile(data);
      return true;
    } catch (e) {
      AppToast.error('Profil non mis à jour', userFacingError(e));
      return false;
    } finally {
      isSavingProfile.value = false;
    }
  }

  final isSavingPreferences = false.obs;

  /// Persiste une (ou plusieurs) préférence(s) côté backend
  /// (PUT /profile/preferences). Retourne `true` en cas de succès.
  Future<bool> updatePreferences(Map<String, dynamic> prefs) async {
    try {
      isSavingPreferences.value = true;
      await _repository.updatePreferences(prefs);
      return true;
    } catch (e) {
      AppToast.error('Préférences non enregistrées', userFacingError(e));
      return false;
    } finally {
      isSavingPreferences.value = false;
    }
  }

  Future<void> logout() async {
    if (Get.isRegistered<RealtimeService>()) {
      await Get.find<RealtimeService>().stop();
    }
    try {
      await _repository.logout();
    } catch (_) {}
    await const AuthTokenStore().clearSession();
    Get.offAllNamed(AppRoutes.profileSelection);
  }
}
