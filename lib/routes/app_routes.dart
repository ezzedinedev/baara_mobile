abstract class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const landing = '/bienvenue';
  static const profileSelection = '/profil';
  static const registerProfile = '/inscription/profil';
  static const register = '/inscription/step1';
  static const candidateLogin = '/connexion/candidat';
  static const recruiterLogin = '/connexion/recruteur';
  static const home = '/accueil';
  static const profile = '/profile';
  static const profileEdit = '/profile/edit';
  static const profilePreferences = '/profile/preferences';
  static const offers = '/offres';
  static const offerDetail = '/offres/:id';
  static const trainings = '/formations';
  static const trainingDetail = '/formations/:id';
  static const messages = '/messages';
  static const conversation = '/messages/:id';
  static const notifications = '/notifications';
  static const settings = '/settings';
}