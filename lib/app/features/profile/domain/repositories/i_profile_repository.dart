import '../entities/profile.dart';

abstract class IProfileRepository {
  Future<Profile> getProfile();
  Future<Profile> updateProfile(Map<String, dynamic> data);
  Future<Profile> updateAvatar(String filePath, List<int> bytes);

  /// Met à jour les préférences (notifications, thème, langue, densité…).
  /// PUT /profile/preferences — n'envoyer que les champs modifiés.
  Future<void> updatePreferences(Map<String, dynamic> prefs);

  /// Visibilité du profil communauté : PUT /profile {profile_visibility}.
  /// 'public' | 'connections'. Retourne le profil mis à jour.
  Future<Profile> setProfileVisibility(String visibility);

  Future<void> logout();
}
