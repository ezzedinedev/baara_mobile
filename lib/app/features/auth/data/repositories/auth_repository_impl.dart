import 'package:jobaway/app/core/network/api_provider.dart';
import 'package:jobaway/app/core/constants/api_constants.dart';
import 'package:jobaway/app/core/services/auth_token_store.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final ApiProvider _apiProvider;
  final AuthTokenStore _tokenStore = const AuthTokenStore();

  AuthRepositoryImpl({required ApiProvider apiProvider})
      : _apiProvider = apiProvider;

  @override
  Future<User> loginWithEmail(String email, String password) async {
    final response = await _apiProvider.postJson(ApiConstants.loginEmail, {
      'email': email,
      'password': password,
      'device_name': ApiConstants.authDeviceName,
      'user_type': 'candidate',
    });

    if (response['success'] == true) {
      final token = _extractToken(response);
      if (token != null) {
        await _tokenStore.saveSession(token: token, userType: 'candidate');
      }
      return UserModel.fromJson(response['data']['user'] ?? response['data']);
    }
    throw Exception(response['message'] ?? 'Login failed');
  }

  @override
  Future<User> loginWithPhone(String phone, String password) async {
    final response = await _apiProvider.postJson(ApiConstants.loginPhone, {
      'phone': phone,
      'password': password, // comptes app = mot de passe (PIN legacy en repli)
      'device_name': ApiConstants.authDeviceName,
      'user_type': 'candidate',
    });

    if (response['success'] == true) {
      final token = _extractToken(response);
      if (token != null) {
        await _tokenStore.saveSession(token: token, userType: 'candidate');
      }
      return UserModel.fromJson(response['data']['user'] ?? response['data']);
    }
    throw Exception(response['message'] ?? 'Login failed');
  }

  @override
  Future<User> loginWithGoogle(String idToken, {String? email}) async {
    final response = await _apiProvider.postJson(ApiConstants.loginGoogle, {
      'id_token': idToken,
      'user_type': 'candidate',
      'device_name': ApiConstants.authDeviceName,
      if (email != null) 'email': email,
    });

    if (response['success'] == true) {
      final token = _extractToken(response);
      if (token != null) {
        await _tokenStore.saveSession(token: token, userType: 'candidate');
      }
      return UserModel.fromJson(response['data']['user'] ?? response['data']);
    }
    throw Exception(response['message'] ?? 'Google Login failed');
  }

  @override
  Future<void> register(Map<String, dynamic> userData) async {
    final response =
        await _apiProvider.postJson(ApiConstants.register, userData);
    if (response['success'] != true) {
      final validation = ApiValidationException.tryFrom(response);
      if (validation != null) throw validation;
      throw Exception(response['message'] ?? 'Registration failed');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _apiProvider.postJson(ApiConstants.logout, {});
    } finally {
      await _tokenStore.clearSession();
    }
  }

  @override
  Future<void> verifyOtp({required String phone, required String otp}) async {
    final response = await _apiProvider.postJson(ApiConstants.otpVerify, {
      'phone': phone,
      'otp': otp,
    });
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Code de vérification invalide.');
    }
  }

  @override
  Future<void> resendOtp(String phone) async {
    final response = await _apiProvider.postJson(ApiConstants.otpResend, {
      'phone': phone,
    });
    if (response['success'] != true) {
      throw Exception(response['message'] ?? "Impossible d'envoyer le code.");
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    final response =
        await _apiProvider.postJson(ApiConstants.emailSendVerification, {});
    if (response['success'] != true) {
      throw Exception(
          response['message'] ?? "Impossible d'envoyer le code par email.");
    }
  }

  @override
  Future<void> verifyEmail(String code) async {
    final response = await _apiProvider.postJson(ApiConstants.emailVerify, {
      'code': code,
    });
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Code invalide ou expiré.');
    }
  }

  @override
  Future<void> forgotPassword({String? phone, String? email}) async {
    final response = await _apiProvider.postJson(ApiConstants.forgotPassword, {
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
    });
    if (response['success'] != true) {
      final validation = ApiValidationException.tryFrom(response);
      if (validation != null) throw validation;
      throw Exception(response['message'] ?? "Impossible d'envoyer le code.");
    }
  }

  @override
  Future<void> resetPassword({
    String? phone,
    String? email,
    required String otp,
    required String password,
  }) async {
    final response = await _apiProvider.postJson(ApiConstants.resetPassword, {
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
      'otp': otp,
      'password': password,
      'password_confirmation': password,
    });
    if (response['success'] != true) {
      final validation = ApiValidationException.tryFrom(response);
      if (validation != null) throw validation;
      throw Exception(response['message'] ?? 'Réinitialisation impossible.');
    }
  }

  @override
  Future<User?> getMe() async {
    try {
      final response = await _apiProvider.getJson(ApiConstants.me);
      if (response['success'] == true && response['data'] != null) {
        return UserModel.fromJson(response['data']);
      }
    } catch (_) {}
    return null;
  }

  String? _extractToken(Map<String, dynamic> data) {
    final payload = data['data'];
    if (payload is Map<String, dynamic>) {
      final token = payload['token'];
      if (token is String && token.isNotEmpty) return token;
    }
    final token = data['token'];
    if (token is String && token.isNotEmpty) return token;
    return null;
  }
}
