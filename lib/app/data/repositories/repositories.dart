import '../providers/api_provider.dart';
import '../../core/constants/api_constants.dart';

class AuthRepository {
  const AuthRepository({required ApiProvider apiProvider})
      : _apiProvider = apiProvider;

  final ApiProvider _apiProvider;

  Future<Map<String, dynamic>> loginWithEmail({
    required String email,
    required String password,
    required String userType,
  }) {
    return _apiProvider.postJson(
      ApiConstants.loginEmail,
      {
        'email': email,
        'password': password,
        'device_name': ApiConstants.authDeviceName,
        'user_type': userType,
      },
    );
  }

  Future<Map<String, dynamic>> loginWithPhone({
    required String phone,
    required String pin,
  }) {
    return _apiProvider.postJson(
      ApiConstants.loginPhone,
      {
        'phone': phone,
        'pin': pin,
        'device_name': ApiConstants.authDeviceName,
      },
    );
  }

  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String country,
    required String password,
    required String passwordConfirmation,
    required String userType,
    required String candidateProfileType,
  }) {
    return _apiProvider.postJson(
      ApiConstants.register,
      {
        'name': '$firstName $lastName',
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'country': country,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'user_type': userType,
        'candidate_profile_type': candidateProfileType,
        'device_name': ApiConstants.authDeviceName,
      },
    );
  }

  Future<Map<String, dynamic>> getCurrentUser() {
    return _apiProvider.getJson(ApiConstants.me);
  }

  Future<Map<String, dynamic>> logout() {
    return _apiProvider.postJson(ApiConstants.logout, {});
  }
}

class OfferRepository {
  const OfferRepository({required ApiProvider apiProvider})
      : _apiProvider = apiProvider;

  final ApiProvider _apiProvider;

  Future<Map<String, dynamic>> getOffers({
    int page = 1,
    int perPage = 20,
    String? sector,
    String? contractType,
    String? location,
  }) {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (sector != null) 'sector': sector,
      if (contractType != null) 'contract_type': contractType,
      if (location != null) 'location': location,
    };
    return _apiProvider.getJson(
      '${ApiConstants.offers}?${_encodeParams(queryParams)}',
    );
  }

  Future<Map<String, dynamic>> getFeaturedOffers() {
    return _apiProvider.getJson(ApiConstants.offersFeatured);
  }

  Future<Map<String, dynamic>> getSavedOffers() {
    return _apiProvider.getJson(ApiConstants.offersSaved);
  }

  String _encodeParams(Map<String, dynamic> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
  }
}

class TrainingRepository {
  const TrainingRepository({required ApiProvider apiProvider})
      : _apiProvider = apiProvider;

  final ApiProvider _apiProvider;

  Future<Map<String, dynamic>> getTrainings({
    int page = 1,
    int perPage = 20,
    String? sector,
    String? level,
    String? format,
  }) {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (sector != null) 'sector': sector,
      if (level != null) 'level': level,
      if (format != null) 'format': format,
    };
    final query = queryParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
    return _apiProvider.getJson('${ApiConstants.trainings}?$query');
  }
}

class ProfileRepository {
  const ProfileRepository({required ApiProvider apiProvider})
      : _apiProvider = apiProvider;

  final ApiProvider _apiProvider;

  Future<Map<String, dynamic>> getProfile() {
    return _apiProvider.getJson(ApiConstants.profile);
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) {
    return _apiProvider.putJson(ApiConstants.profile, data);
  }

  Future<Map<String, dynamic>> uploadAvatar(String filePath) {
    return _apiProvider.sendMultipart(
      ApiConstants.profileAvatar,
      method: 'POST',
      fields: {'avatar': filePath},
    );
  }

  Future<Map<String, dynamic>> uploadCv(String filePath) {
    return _apiProvider.sendMultipart(
      ApiConstants.profileCvUpload,
      method: 'POST',
      fields: {'cv': filePath},
    );
  }
}