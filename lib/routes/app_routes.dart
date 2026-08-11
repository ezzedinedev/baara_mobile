abstract class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const landing = '/bienvenue';
  static const profileSelection = '/profil';
  static const registerProfile = '/inscription/profil';
  static const register = '/inscription/step1';
  static const candidateLogin = '/connexion/candidat';
  static const otpVerification = '/verification';
  static const emailVerification = '/verification-email';
  static const forgotPassword = '/mot-de-passe-oublie';
  static const forgotPasswordReset = '/mot-de-passe-oublie/reinitialiser';
  static const onboarding = '/onboarding';
  static const home = '/accueil';
  static const profile = '/profile';
  static const profileEdit = '/profile/edit';
  static const profileParcours = '/profile/parcours';
  static const profileDocuments = '/profile/documents';
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
  static const alerts = '/offres/alertes';
  static const trainings = '/formations';
  static const trainingDetail = '/formations/:id';
  static const trainingPlayer = '/formations/:id/parcours';
  // `:id` = identifiant du quiz. Le tirage, le chronometre et la correction sont
  // cotes serveur (cf. QuizApiController).
  static const trainingQuiz = '/formations/quiz/:id';
  static const messages = '/messages';
  static const conversation = '/messages/:id';
  static const community = '/communaute';
  static const communityProfile = '/communaute/membre/:id';
  // Listes Abonnés / Connexions d'un membre (mode passé via Get.arguments).
  static const communityNetwork = '/communaute/membre/:id/reseau';
  static const communitySearch = '/communaute/recherche';
  static const communityConnections = '/communaute/connexions';
  static const communityProfileViews = '/communaute/vues-profil';
  static const notifications = '/notifications';
  static const notificationSettings = '/notifications/preferences';
  static const settings = '/settings';
  static const subscription = '/abonnement';
  static const streak = '/serie';
  // IA
  static const iaScoreProfil = '/ia/score-profil';
  static const iaChatbot = '/ia/chatbot';
  static const iaAuditCv = '/ia/audit-cv';
  // Match
  static const offerMatch = '/offres/match';
  static const error404 = '/404';
}
