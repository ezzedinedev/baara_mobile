import 'dart:typed_data';

import '../../../../core/network/api_provider.dart';
import '../../../../core/constants/api_constants.dart';
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

}

/// TODO refonte CV : le backend ne gere PAS un multi-CV. Il y a un seul

class CvRepository {
  const CvRepository({required ApiProvider apiProvider})
      : _apiProvider = apiProvider;

  final ApiProvider _apiProvider;

  Future<List<CvModel>> getCvs() async {
    final response = await _apiProvider.getJson(ApiConstants.profileCv);
    return _parseListResponse(response);
  }

  /// Lance l'analyse stateless d'un PDF de CV via /profile/cv-builder/import/analyze.
  /// Le backend renvoie `{filename, chars, extracted_preview, extracted_text, analysis}`
  /// — donc ce mapping `CvModel.fromJson` est best-effort et incomplet
  /// jusqu'a ce que le module soit reconstruit autour du flow analyze→apply.
  Future<CvModel> uploadCv(String fileName, Uint8List bytes) async {
    final response = await _apiProvider.sendMultipart(
      ApiConstants.profileCvImportAnalyze,
      method: 'POST',
      files: [
        ApiMultipartFile(field: 'cv_file', bytes: bytes, filename: fileName),
      ],
    );
    if (response['success'] == true && response['data'] != null) {
      return CvModel.fromJson(response['data']);
    }
    throw Exception('Failed to analyze CV');
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

  List<PortfolioProjectModel> _parseListResponse(
      Map<String, dynamic> response) {
    final data = response['data'];
    if (data is List) {
      return data.map((e) => PortfolioProjectModel.fromJson(e)).toList();
    }
    return [];
  }
}

/// Backend : il n'y a pas d'endpoint `/settings` dedie. Les preferences
/// utilisateur sont sous `PUT /profile/preferences` ; la lecture se fait via
/// `GET /profile` (les preferences sont incluses dans la reponse).
///
/// Le changement de mot de passe n'a pas d'endpoint API V1 — a ajouter cote
/// Laravel si on veut l'exposer. La methode `updatePassword` a ete retiree.
class SettingsRepository {
  const SettingsRepository({required ApiProvider apiProvider})
      : _apiProvider = apiProvider;

  final ApiProvider _apiProvider;

  Future<SettingsModel> getSettings() async {
    final response = await _apiProvider.getJson(ApiConstants.profile);
    if (response['success'] == true && response['data'] != null) {
      final data = response['data'];
      final prefs = data is Map ? data['preferences'] : null;
      if (prefs is Map<String, dynamic>) {
        return SettingsModel.fromJson(prefs);
      }
    }
    return const SettingsModel(
      notificationsEnabled: true,
      smsEnabled: false,
      language: 'fr',
      theme: 'light',
      density: 'normal',
    );
  }

  Future<SettingsModel> updateSettings(SettingsModel settings) async {
    final response = await _apiProvider.putJson(
      ApiConstants.profilePreferences,
      settings.toJson(),
    );
    if (response['success'] == true && response['data'] != null) {
      final data = response['data'];
      final prefs = data is Map ? data['preferences'] : null;
      if (prefs is Map<String, dynamic>) {
        return SettingsModel.fromJson(prefs);
      }
    }
    throw Exception('Failed to update preferences');
  }
}
