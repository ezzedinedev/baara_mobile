import '../entities/profile.dart';

abstract class IProfileRepository {
  Future<Profile> getProfile();
  Future<Profile> updateProfile(Map<String, dynamic> data);
  Future<Profile> updateAvatar(String filePath, List<int> bytes);

  /// Envoie la vidéo de présentation (~30 s). POST /profile/presentation-video,
  /// champ multipart `video`. Retourne la nouvelle URL exposée par le serveur.
  Future<String?> uploadPresentationVideo(List<int> bytes, String filename);

  /// Supprime la vidéo de présentation. DELETE /profile/presentation-video.
  Future<void> deletePresentationVideo();

  /// Met à jour les préférences (notifications, thème, langue, densité…).
  /// PUT /profile/preferences — n'envoyer que les champs modifiés.
  Future<void> updatePreferences(Map<String, dynamic> prefs);

  /// Visibilité du profil communauté : PUT /profile {profile_visibility}.
  /// 'public' | 'connections'. Retourne le profil mis à jour.
  Future<Profile> setProfileVisibility(String visibility);

  Future<List<Map<String, dynamic>>> getCertificates();

  Future<void> logout();

  Future<void> logoutAll();

  /// Supprime définitivement le compte. [confirmation] = mot de passe, ou
  /// « SUPPRIMER » pour un compte créé avec Google (le serveur vérifie ce qui
  /// s'applique au compte).
  Future<void> deleteAccount(String confirmation);
}
