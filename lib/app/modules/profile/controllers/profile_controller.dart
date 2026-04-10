import 'dart:typed_data';

import 'package:get/get.dart';

import '../../../data/providers/api_provider.dart' as api;
import '../repositories/profile_repository.dart';
import '../models/profile_model.dart';

class ProfileController extends GetxController {
  ProfileController({api.ApiProvider? apiProvider}) {
    final provider = apiProvider ?? Get.find<api.ApiProvider>();
    _profileRepo = ProfileRepository(apiProvider: provider);
    _cvRepo = CvRepository(apiProvider: provider);
    _portfolioRepo = PortfolioRepository(apiProvider: provider);
    _settingsRepo = SettingsRepository(apiProvider: provider);
  }

  late final ProfileRepository _profileRepo;
  late final CvRepository _cvRepo;
  late final PortfolioRepository _portfolioRepo;
  late final SettingsRepository _settingsRepo;

  final profile = Rxn<ProfileModel>();
  final cvs = <CvModel>[].obs;
  final portfolioProjects = <PortfolioProjectModel>[].obs;
  final settings = Rxn<SettingsModel>();

  final isLoadingProfile = false.obs;
  final isLoadingCvs = false.obs;
  final isLoadingPortfolio = false.obs;
  final isLoadingSettings = false.obs;
  final isUploading = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  Future<void> loadProfile() async {
    isLoadingProfile.value = true;
    errorMessage.value = '';

    try {
      profile.value = await _profileRepo.getProfile();
    } catch (e) {
      errorMessage.value = _friendlyError(e);
    } finally {
      isLoadingProfile.value = false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    isLoadingProfile.value = true;
    errorMessage.value = '';

    try {
      profile.value = await _profileRepo.updateProfile(data);
      return true;
    } catch (e) {
      errorMessage.value = _friendlyError(e);
      return false;
    } finally {
      isLoadingProfile.value = false;
    }
  }

  Future<bool> updateAvatar(String filePath, Uint8List bytes) async {
    isUploading.value = true;
    errorMessage.value = '';

    try {
      profile.value = await _profileRepo.updateAvatar(filePath, bytes);
      return true;
    } catch (e) {
      errorMessage.value = 'Erreur lors de la mise a jour de l\'avatar.';
      return false;
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> loadCvs() async {
    isLoadingCvs.value = true;

    try {
      cvs.value = await _cvRepo.getCvs();
    } catch (e) {
      errorMessage.value = _friendlyError(e);
    } finally {
      isLoadingCvs.value = false;
    }
  }

  Future<bool> uploadCv(String fileName, Uint8List bytes) async {
    isUploading.value = true;

    try {
      final cv = await _cvRepo.uploadCv(fileName, bytes);
      cvs.insert(0, cv);
      return true;
    } catch (e) {
      errorMessage.value = 'Erreur lors de l\'upload du CV.';
      return false;
    } finally {
      isUploading.value = false;
    }
  }

  Future<bool> deleteCv(String cvId) async {
    try {
      final success = await _cvRepo.deleteCv(cvId);
      if (success) {
        cvs.removeWhere((c) => c.id == cvId);
      }
      return success;
    } catch (e) {
      errorMessage.value = 'Erreur lors de la suppression du CV.';
      return false;
    }
  }

  Future<bool> setDefaultCv(String cvId) async {
    try {
      final success = await _cvRepo.setDefaultCv(cvId);
      if (success) {
        cvs.value = cvs
            .map((c) => CvModel(
                  id: c.id,
                  fileName: c.fileName,
                  fileUrl: c.fileUrl,
                  fileSize: c.fileSize,
                  uploadedAt: c.uploadedAt,
                  isDefault: c.id == cvId,
                ))
            .toList();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<void> loadPortfolio() async {
    isLoadingPortfolio.value = true;

    try {
      portfolioProjects.value = await _portfolioRepo.getProjects();
    } catch (e) {
      errorMessage.value = _friendlyError(e);
    } finally {
      isLoadingPortfolio.value = false;
    }
  }

  Future<bool> createProject(Map<String, dynamic> data) async {
    try {
      final project = await _portfolioRepo.createProject(data);
      portfolioProjects.insert(0, project);
      return true;
    } catch (e) {
      errorMessage.value = 'Erreur lors de la creation du projet.';
      return false;
    }
  }

  Future<bool> updateProject(
      String projectId, Map<String, dynamic> data) async {
    try {
      final project = await _portfolioRepo.updateProject(projectId, data);
      final index = portfolioProjects.indexWhere((p) => p.id == projectId);
      if (index != -1) {
        portfolioProjects[index] = project;
      }
      return true;
    } catch (e) {
      errorMessage.value = 'Erreur lors de la mise a jour du projet.';
      return false;
    }
  }

  Future<bool> deleteProject(String projectId) async {
    try {
      final success = await _portfolioRepo.deleteProject(projectId);
      if (success) {
        portfolioProjects.removeWhere((p) => p.id == projectId);
      }
      return success;
    } catch (e) {
      errorMessage.value = 'Erreur lors de la suppression du projet.';
      return false;
    }
  }

  Future<bool> uploadProjectImages(
      String projectId, List<Uint8List> images, List<String> names) async {
    try {
      final files = List.generate(
        images.length,
        (i) => api.ApiMultipartFile(
            field: 'images', bytes: images[i], filename: names[i]),
      );
      final project =
          await _portfolioRepo.uploadProjectImages(projectId, files);
      final index = portfolioProjects.indexWhere((p) => p.id == projectId);
      if (index != -1) {
        portfolioProjects[index] = project;
      }
      return true;
    } catch (e) {
      errorMessage.value = 'Erreur lors de l\'upload des images.';
      return false;
    }
  }

  Future<void> loadSettings() async {
    isLoadingSettings.value = true;

    try {
      settings.value = await _settingsRepo.getSettings();
    } catch (e) {
      settings.value = const SettingsModel(
        notificationsEnabled: true,
        emailNotifications: true,
        smsNotifications: false,
        pushNotifications: true,
        language: 'fr',
        theme: 'light',
        isPrivateProfile: false,
      );
    } finally {
      isLoadingSettings.value = false;
    }
  }

  Future<bool> updateSettings(SettingsModel newSettings) async {
    try {
      settings.value = await _settingsRepo.updateSettings(newSettings);
      return true;
    } catch (e) {
      errorMessage.value = 'Erreur lors de la mise a jour des parametres.';
      return false;
    }
  }

  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    try {
      return await _settingsRepo.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        newPasswordConfirmation: newPasswordConfirmation,
      );
    } catch (e) {
      errorMessage.value = 'Erreur lors de la mise a jour du mot de passe.';
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    try {
      return await _profileRepo.deleteAccount();
    } catch (e) {
      errorMessage.value = 'Erreur lors de la suppression du compte.';
      return false;
    }
  }

  @override
  Future<void> refresh() async {
    await Future.wait([
      loadProfile(),
      loadCvs(),
      loadPortfolio(),
      loadSettings(),
    ]);
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('Unable to connect')) {
      return 'Connexion impossible.';
    }
    return 'Erreur de chargement.';
  }
}
