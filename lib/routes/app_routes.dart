abstract class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const landing = '/bienvenue';
  static const profileSelection = '/profil';
  static const registerProfile = '/inscription/profil';
  static const register = '/inscription/step1';
  static const candidateLogin = '/connexion/candidat';
  static const recruiterLogin = '/connexion/recruteur';
  static const otpVerification = '/verification';
  static const home = '/accueil';
  static const profile = '/profile';
  static const profileEdit = '/profile/edit';
  static const profilePreferences = '/profile/preferences';
  static const profileCv = '/profile/cv';
  static const profileCvBuilder = '/profile/cv-builder';
  static const profileCvAssistant = '/profile/cv-builder/assistant';
  static const profileCvManual = '/profile/cv-builder/manual';
  static const profileCvImport = '/profile/cv-builder/import';
  static const profileCvPreview = '/profile/cv-builder/preview';
  static const profilePortfolio = '/profile/portfolio';
  static const profilePortfolioEdit = '/profile/portfolio/edit';
  static const offers = '/offres';
  static const offerDetail = '/offres/:id';
  static const myApplications = '/offres/mes-candidatures';
  static const trainings = '/formations';
  static const trainingDetail = '/formations/:id';
  static const messages = '/messages';
  static const conversation = '/messages/:id';
  static const notifications = '/notifications';
  static const settings = '/settings';
  static const error404 = '/404';
}