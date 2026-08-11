import 'package:http/http.dart' as http;
import 'package:baara/app/core/network/api_provider.dart';
import 'package:baara/app/core/network/api_response.dart';
import 'package:baara/app/core/constants/api_constants.dart';
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
    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible de charger votre profil.');
    return ProfileModel.fromJson(ApiResponse.dataMap(response));
  }

  @override
  Future<Profile> updateProfile(Map<String, dynamic> data) async {
    final response = await _apiProvider.putJson(ApiConstants.profile, data);
    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible de mettre à jour votre profil.');
    return ProfileModel.fromJson(ApiResponse.dataMap(response));
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
    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible de mettre à jour votre photo.');
    return ProfileModel.fromJson(ApiResponse.dataMap(response));
  }

  @override
  Future<String?> uploadPresentationVideo(
      List<int> bytes, String filename) async {
    final response = await _apiProvider.multipartPost(
      ApiConstants.profilePresentationVideo,
      fields: {},
      files: [
        http.MultipartFile.fromBytes('video', bytes, filename: filename),
      ],
    );
    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible d\'envoyer votre vidéo de présentation.');
    return ApiResponse.dataMap(response)['presentation_video_url'] as String?;
  }

  @override
  Future<void> deletePresentationVideo() async {
    final response =
        await _apiProvider.deleteJson(ApiConstants.profilePresentationVideo);
    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible de supprimer votre vidéo.');
  }

  @override
  Future<void> updatePreferences(Map<String, dynamic> prefs) async {
    final response =
        await _apiProvider.putJson(ApiConstants.profilePreferences, prefs);
    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible de mettre à jour vos préférences.');
  }

  @override
  Future<Profile> setProfileVisibility(String visibility) async {
    final response = await _apiProvider.putJson(
      ApiConstants.profile,
      {'profile_visibility': visibility},
    );
    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible de changer la visibilité de votre profil.');
    return ProfileModel.fromJson(ApiResponse.dataMap(response));
  }

  @override
  Future<List<Map<String, dynamic>>> getCertificates() async {
    final response =
        await _apiProvider.getJson(ApiConstants.profileCertificates);
    ApiResponse.ensureSuccess(response,
        fallback: 'Impossible de charger vos certificats.');
    return ApiResponse.extractList(response['data'])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// Révoque le token côté serveur. Peut légitimement échouer (token déjà
  /// expiré → 401) : l'appelant (ProfileController) vide la session locale et
  /// navigue quoi qu'il arrive, la déconnexion n'est donc jamais bloquée ici.
  @override
  Future<void> logout() async {
    final response = await _apiProvider.postJson(ApiConstants.logout, {});
    ApiResponse.ensureSuccess(response, fallback: 'Déconnexion impossible.');
  }

  /// Même contrat que [logout], sur l'ensemble des appareils.
  @override
  Future<void> logoutAll() async {
    final response = await _apiProvider.postJson(ApiConstants.logoutAll, {});
    ApiResponse.ensureSuccess(response, fallback: 'Déconnexion impossible.');
  }
}
