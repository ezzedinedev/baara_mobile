import 'dart:typed_data';

import 'package:get/get.dart';

import '../../../core/network/api_provider.dart' as api;
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
    // Optimistic update : on retire de la liste immédiatement pour un retour
    // instantané, puis rollback si le serveur refuse.
    final removedIndex =
        portfolioProjects.indexWhere((p) => p.id == projectId);
    if (removedIndex == -1) {
      return false;
    }
    final removedProject = portfolioProjects[removedIndex];
    portfolioProjects.removeAt(removedIndex);

    try {
      final success = await _portfolioRepo.deleteProject(projectId);
      if (!success) {
        // Rollback : remettre le projet à sa position d'origine.
        portfolioProjects.insert(removedIndex, removedProject);
        errorMessage.value = 'Suppression refusée par le serveur.';
      }
      return success;
    } catch (e) {
      portfolioProjects.insert(removedIndex, removedProject);
      errorMessage.value = 'Erreur lors de la suppression du projet.';
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
        smsEnabled: false,
        language: 'fr',
        theme: 'light',
        density: 'normal',
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
