import 'dart:typed_data';

import '../../../data/providers/api_provider.dart';
import '../../../core/constants/api_constants.dart';
import '../models/profile_model.dart';

class ProfileRepository {
  const ProfileRepository({required ApiProvider apiProvider})
      : _apiProvider = apiProvider;

  final ApiProvider _apiProvider;

  Future<ProfileModel> getProfile() async {
    final response = await _apiProvider.getJson(ApiConstants.profile);
    if (response['success'] == true && response['data'] != null) {
      return ProfileModel.fromJson(response['data']);
    }
    throw Exception('Failed to load profile');
  }

  Future<ProfileModel> updateProfile(Map<String, dynamic> data) async {
    final response = await _apiProvider.putJson(ApiConstants.profile, data);
    if (response['success'] == true && response['data'] != null) {
      return ProfileModel.fromJson(response['data']);
    }
    throw Exception('Failed to update profile');
  }

  Future<ProfileModel> updateAvatar(String filePath, Uint8List bytes) async {
    final response = await _apiProvider.sendMultipart(
      ApiConstants.profileAvatar,
      method: 'POST',
      files: [
        ApiMultipartFile(field: 'avatar', bytes: bytes, filename: filePath)
      ],
    );
    if (response['success'] == true && response['data'] != null) {
      return ProfileModel.fromJson(response['data']);
    }
    throw Exception('Failed to upload avatar');
  }

  Future<bool> deleteAccount() async {
    final response =
        await _apiProvider.deleteJson('${ApiConstants.profile}/delete');
    return response['success'] == true;
  }
}

class CvRepository {
  const CvRepository({required ApiProvider apiProvider})
      : _apiProvider = apiProvider;

  final ApiProvider _apiProvider;

  Future<List<CvModel>> getCvs() async {
    final response = await _apiProvider.getJson(ApiConstants.profileCv);
    return _parseListResponse(response);
  }

  Future<CvModel> uploadCv(String fileName, Uint8List bytes) async {
    final response = await _apiProvider.sendMultipart(
      ApiConstants.profileCvUpload,
      method: 'POST',
      files: [ApiMultipartFile(field: 'cv', bytes: bytes, filename: fileName)],
    );
    if (response['success'] == true && response['data'] != null) {
      return CvModel.fromJson(response['data']);
    }
    throw Exception('Failed to upload CV');
  }

  Future<bool> deleteCv(String cvId) async {
    final response =
        await _apiProvider.deleteJson('${ApiConstants.profileCv}/$cvId');
    return response['success'] == true;
  }

  Future<bool> setDefaultCv(String cvId) async {
    final response = await _apiProvider.postJson(
      '${ApiConstants.profileCv}/$cvId/set-default',
      {},
    );
    return response['success'] == true;
  }

  List<CvModel> _parseListResponse(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is List) {
      return data.map((e) => CvModel.fromJson(e)).toList();
    }
    return [];
  }
}

class PortfolioRepository {
  const PortfolioRepository({required ApiProvider apiProvider})
      : _apiProvider = apiProvider;

  final ApiProvider _apiProvider;

  Future<List<PortfolioProjectModel>> getProjects() async {
    final response = await _apiProvider.getJson(ApiConstants.profilePortfolio);
    return _parseListResponse(response);
  }

  Future<PortfolioProjectModel> createProject(Map<String, dynamic> data) async {
    final response = await _apiProvider.postJson(
      ApiConstants.profilePortfolio,
      data,
    );
    if (response['success'] == true && response['data'] != null) {
      return PortfolioProjectModel.fromJson(response['data']);
    }
    throw Exception('Failed to create project');
  }

  Future<PortfolioProjectModel> updateProject(
      String projectId, Map<String, dynamic> data) async {
    final response = await _apiProvider.putJson(
      '${ApiConstants.profilePortfolio}/$projectId',
      data,
    );
    if (response['success'] == true && response['data'] != null) {
      return PortfolioProjectModel.fromJson(response['data']);
    }
    throw Exception('Failed to update project');
  }

  Future<bool> deleteProject(String projectId) async {
    final response = await _apiProvider.deleteJson(
      '${ApiConstants.profilePortfolio}/$projectId',
    );
    return response['success'] == true;
  }

  Future<PortfolioProjectModel> uploadProjectImages(
    String projectId,
    List<ApiMultipartFile> images,
  ) async {
    final response = await _apiProvider.sendMultipart(
      '${ApiConstants.profilePortfolio}/$projectId/images',
      method: 'POST',
      files: images,
    );
    if (response['success'] == true && response['data'] != null) {
      return PortfolioProjectModel.fromJson(response['data']);
    }
    throw Exception('Failed to upload images');
  }

  List<PortfolioProjectModel> _parseListResponse(
      Map<String, dynamic> response) {
    final data = response['data'];
    if (data is List) {
      return data.map((e) => PortfolioProjectModel.fromJson(e)).toList();
    }
    return [];
  }
}

class SettingsRepository {
  const SettingsRepository({required ApiProvider apiProvider})
      : _apiProvider = apiProvider;

  final ApiProvider _apiProvider;

  Future<SettingsModel> getSettings() async {
    final response = await _apiProvider.getJson(ApiConstants.settings);
    if (response['success'] == true && response['data'] != null) {
      return SettingsModel.fromJson(response['data']);
    }
    return const SettingsModel(
      notificationsEnabled: true,
      emailNotifications: true,
      smsNotifications: false,
      pushNotifications: true,
      language: 'fr',
      theme: 'light',
      isPrivateProfile: false,
    );
  }

  Future<SettingsModel> updateSettings(SettingsModel settings) async {
    final response = await _apiProvider.putJson(
      ApiConstants.settings,
      settings.toJson(),
    );
    if (response['success'] == true && response['data'] != null) {
      return SettingsModel.fromJson(response['data']);
    }
    throw Exception('Failed to update settings');
  }

  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    final response = await _apiProvider.postJson(
      '${ApiConstants.settings}/password',
      {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPasswordConfirmation,
      },
    );
    return response['success'] == true;
  }
}
