import '../../core/constants/api_constants.dart';
import '../../core/network/api_provider.dart';

class AuthRepository {
  const AuthRepository({required ApiProvider apiProvider})
      : _apiProvider = apiProvider;

  final ApiProvider _apiProvider;

  Future<Map<String, dynamic>> loginWithEmail({
    required String email,
    required String password,
    required String userType,
    String? fcmToken,
  }) {
    return _apiProvider.postJson(
      ApiConstants.loginEmail,
      {
        'email': email,
        'password': password,
        'device_name': ApiConstants.authDeviceName,
        'user_type': userType,
        // Enregistre le token push dès le login (parité backend) : le device
        // reçoit les notifs sans attendre l'appel séparé à /notifications/fcm-token.
        if (fcmToken != null && fcmToken.isNotEmpty) 'fcm_token': fcmToken,
      },
    );
  }

  Future<Map<String, dynamic>> loginWithPhone({
    required String phone,
    required String pin,
    required String userType,
    String? fcmToken,
  }) {
    return _apiProvider.postJson(
      ApiConstants.loginPhone,
      {
        'phone': phone,
        'pin': pin,
        'user_type': userType,
        'device_name': ApiConstants.authDeviceName,
        if (fcmToken != null && fcmToken.isNotEmpty) 'fcm_token': fcmToken,
      },
    );
  }

  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
    required String userType,
    // Optionnels (parité backend AuthApiController@register).
    String? candidateKind, // 'student' | 'professional'
    String? educationLevel,
    String? pin, // alternative au mot de passe (4 chiffres)
    String? fcmToken,
  }) {
    return _apiProvider.postJson(
      ApiConstants.register,
      {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'user_type': userType,
        'device_name': ApiConstants.authDeviceName,
        if (candidateKind != null && candidateKind.isNotEmpty)
          'candidate_kind': candidateKind,
        if (educationLevel != null && educationLevel.isNotEmpty)
          'education_level': educationLevel,
        if (pin != null && pin.isNotEmpty) 'pin': pin,
        if (fcmToken != null && fcmToken.isNotEmpty) 'fcm_token': fcmToken,
      },
    );
  }

  Future<Map<String, dynamic>> getCurrentUser() {
    return _apiProvider.getJson(ApiConstants.me);
  }

  Future<Map<String, dynamic>> logout() {
    return _apiProvider.postJson(ApiConstants.logout, {});
  }

  /// Revoke tous les tokens Sanctum de l'utilisateur (toutes sessions /
  /// tous devices). A appeler depuis l'ecran "Securite" pour permettre
  /// a un user qui pense son compte compromis de tout fermer d'un coup.
  Future<Map<String, dynamic>> logoutAll() {
    return _apiProvider.postJson(ApiConstants.logoutAll, {});
  }
}

class OfferRepository {
  const OfferRepository({required ApiProvider apiProvider})
      : _apiProvider = apiProvider;

  final ApiProvider _apiProvider;

  Future<Map<String, dynamic>> getOffers({
    int page = 1,
    int perPage = 20,
    String? search,
    String? sector,
    String? sectorId,
    String? contractType,
    String? city,
    String? region,
    bool? isRemote,
    int? salaryMin,
    String? sort,
  }) {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (search != null && search.isNotEmpty) 'search': search,
      if (sector != null) 'sector': sector,
      if (sectorId != null) 'sector_id': sectorId,
      if (contractType != null) 'contract_type': contractType,
      if (city != null) 'city': city,
      if (region != null) 'region': region,
      if (isRemote == true) 'is_remote': 1,
      if (salaryMin != null && salaryMin > 0) 'salary_min': salaryMin,
      if (sort != null && sort.isNotEmpty) 'sort': sort,
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
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
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
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
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
}
