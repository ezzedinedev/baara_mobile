import 'package:http/http.dart' as http;
import 'package:opportune_bf/app/core/network/api_provider.dart';
import 'package:opportune_bf/app/core/constants/api_constants.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/i_profile_repository.dart';
import '../models/profile_model.dart';

class ProfileRepositoryImpl implements IProfileRepository {
  final ApiProvider _apiProvider;

  ProfileRepositoryImpl({required ApiProvider apiProvider})
      : _apiProvider = apiProvider;

  @override
  Future<Profile> getProfile() async {
    final response = await _apiProvider.getJson(ApiConstants.profile);
    if (response['success'] == true && response['data'] != null) {
      return ProfileModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to load profile');
  }

  @override
  Future<Profile> updateProfile(Map<String, dynamic> data) async {
    final response = await _apiProvider.putJson(ApiConstants.profile, data);
    if (response['success'] == true && response['data'] != null) {
      return ProfileModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to update profile');
  }

  @override
  Future<Profile> updateAvatar(String filePath, List<int> bytes) async {
    final response = await _apiProvider.multipartPost(
      ApiConstants.profileAvatar,
      fields: {},
      files: [
        http.MultipartFile.fromBytes('avatar', bytes, filename: 'avatar.jpg'),
      ],
    );

    if (response['success'] == true && response['data'] != null) {
      return ProfileModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to update avatar');
  }

  @override
  Future<void> updatePreferences(Map<String, dynamic> prefs) async {
    final response =
        await _apiProvider.putJson(ApiConstants.profilePreferences, prefs);
    if (response['success'] != true) {
      throw Exception(
          response['message'] ?? 'Échec de la mise à jour des préférences.');
    }
  }

  @override
  Future<void> logout() async {
    await _apiProvider.postJson(ApiConstants.logout, {});
  }
}
