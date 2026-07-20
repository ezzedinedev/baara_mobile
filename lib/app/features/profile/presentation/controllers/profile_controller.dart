import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jobaway/app/core/services/auth_token_store.dart';
import 'package:jobaway/app/core/theme/app_theme_controller.dart';
import 'package:jobaway/app/core/services/realtime_service.dart';
import 'package:jobaway/app/core/utils/user_facing_error.dart';
import 'package:jobaway/app/core/widgets/common/app_toast.dart';
import 'package:jobaway/routes/app_routes.dart';
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

  /// URL de la vidéo de présentation, source de vérité pour la carte vidéo.
  /// Mise à jour directement à l'upload/suppression pour éviter un re-fetch.
  final presentationVideoUrl = RxnString();
  final isUploadingVideo = false.obs;

  // Stubs for UI compatibility
  final cvs = <dynamic>[].obs;
  final portfolioProjects = <dynamic>[].obs;
  final trainingCertificates = <Map<String, dynamic>>[].obs;

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
      presentationVideoUrl.value = profile.value?.presentationVideoUrl;
      await loadCertificates();
      _applyServerTheme();
    } catch (e) {
      errorMessage.value = "Erreur de chargement du profil";
    } finally {
      isLoading.value = false;
      isLoadingProfile.value = false;
    }
  }

  // Legacy method names for UI compatibility
  Future<void> loadProfile() => fetchProfile();

  Future<void> loadCertificates() async {
    try {
      trainingCertificates.assignAll(await _repository.getCertificates());
    } catch (_) {
      trainingCertificates.clear();
    }
  }

  /// Applique le thème enregistré côté serveur (`preferences.apparence.theme`)
  /// dès que le profil est chargé → le dark mode suit l'utilisateur d'un
  /// appareil à l'autre. No-op si déjà aligné (cf. [AppThemeController]).
  void _applyServerTheme() {
    final p = profile.value;
    if (p == null || !Get.isRegistered<AppThemeController>()) return;
    Get.find<AppThemeController>().syncFromServer(p.themePref);
  }

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

  /// Sélectionne une vidéo (galerie) ≤ 30 s / 15 Mo et l'envoie comme vidéo de
  /// présentation (POST /profile/presentation-video, champ `video`). Le fichier
  /// vit sur disque côté serveur ; la base ne stocke que le chemin.
  Future<void> pickAndUploadPresentationVideo() async {
    if (isUploadingVideo.value) return;

    final XFile? picked;
    try {
      picked = await ImagePicker().pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 30),
      );
    } catch (_) {
      AppToast.error('Galerie inaccessible', 'Vérifiez les autorisations.');
      return;
    }
    if (picked == null) return; // annulé

    isUploadingVideo.value = true;
    try {
      final bytes = await picked.readAsBytes();
      // Garde-fou taille : le serveur refuse > 15 Mo, on évite l'upload inutile.
      if (bytes.length > 15 * 1024 * 1024) {
        AppToast.error('Vidéo trop lourde', 'Choisissez une vidéo ≤ 15 Mo.');
        return;
      }
      final filename =
          picked.name.isNotEmpty ? picked.name : 'presentation.mp4';
      final url = await _repository.uploadPresentationVideo(bytes, filename);
      presentationVideoUrl.value = url;
      AppToast.success('Vidéo de présentation mise à jour');
    } catch (e) {
      AppToast.error('Échec de l\'envoi', userFacingError(e));
    } finally {
      isUploadingVideo.value = false;
    }
  }

  /// Supprime la vidéo de présentation (DELETE /profile/presentation-video).
  Future<void> deletePresentationVideo() async {
    if (isUploadingVideo.value) return;
    isUploadingVideo.value = true;
    try {
      await _repository.deletePresentationVideo();
      presentationVideoUrl.value = null;
      AppToast.success('Vidéo supprimée');
    } catch (e) {
      AppToast.error('Suppression impossible', userFacingError(e));
    } finally {
      isUploadingVideo.value = false;
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

  final isSavingVisibility = false.obs;

  /// Change la visibilité du profil communauté ('public' | 'connections').
  /// Persiste via PUT /profile et rafraîchit l'état local. Retourne `true`
  /// en cas de succès (le caller gère son état optimiste).
  Future<bool> setProfileVisibility(String visibility) async {
    try {
      isSavingVisibility.value = true;
      profile.value = await _repository.setProfileVisibility(visibility);
      return true;
    } catch (e) {
      AppToast.error('Visibilité non enregistrée', userFacingError(e));
      return false;
    } finally {
      isSavingVisibility.value = false;
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

  Future<void> logoutAll() async {
    if (Get.isRegistered<RealtimeService>()) {
      await Get.find<RealtimeService>().stop();
    }
    try {
      await _repository.logoutAll();
    } catch (_) {}
    await const AuthTokenStore().clearSession();
    Get.offAllNamed(AppRoutes.profileSelection);
  }
}
