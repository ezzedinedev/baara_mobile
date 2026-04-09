class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://127.0.0.1:8000/api/v1';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const String loginPhone = '/auth/login/phone';
  static const String loginEmail = '/auth/login/email';
  static const String loginGoogle = '/auth/google';
  static const String register = '/auth/register';
  static const String otpVerify = '/auth/otp/verify';
  static const String otpResend = '/auth/otp/resend';
  static const String me = '/auth/me';
  static const String logout = '/auth/logout';
  static const String logoutAll = '/auth/logout-all';

  static const String offers = '/offers';
  static const String offersFeatured = '/offers/featured/list';
  static const String offersSaved = '/offers/saved/list';
  static const String sectors = '/offers/sectors/list';
  static const String publicStats = '/stats/public';

  static Map<String, String> get jsonHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static Map<String, String> authHeaders(String token) => {
        ...jsonHeaders,
        'Authorization': 'Bearer $token',
      };
}
