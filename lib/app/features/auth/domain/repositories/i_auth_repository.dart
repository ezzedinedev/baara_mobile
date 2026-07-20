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

  // Vérification de l'email (utilisateur connecté). Le code part par email.
  Future<void> sendEmailVerification();
  Future<void> verifyEmail(String code);

  // Réinitialisation du mot de passe par OTP. Identification par email OU
  // téléphone (au moins l'un des deux). Le code part toujours par email.
  Future<void> forgotPassword({String? phone, String? email});
  Future<void> resetPassword({
    String? phone,
    String? email,
    required String otp,
    required String password,
  });
}
