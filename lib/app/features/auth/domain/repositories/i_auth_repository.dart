import '../entities/user.dart';

abstract class IAuthRepository {
  Future<User> loginWithEmail(String email, String password);
  Future<User> loginWithPhone(String phone, String password);
  Future<User> loginWithGoogle(String idToken, {String? email});
  Future<void> register(Map<String, dynamic> userData);
  Future<void> logout();
  Future<User?> getMe();

  // Vérification du numéro (post-inscription) — clé = téléphone.
  Future<void> verifyOtp({required String phone, required String otp});
  Future<void> resendOtp(String phone);

  // Réinitialisation du mot de passe par OTP — clé = téléphone.
  Future<void> forgotPassword(String phone);
  Future<void> resetPassword({
    required String phone,
    required String otp,
    required String password,
  });
}
