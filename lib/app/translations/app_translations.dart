import 'dart:ui' show Locale;

import 'package:get/get.dart';


class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'fr_FR': _fr,
        'en_US': _en,
      };
}

/// Switch helper pour basculer la langue partout. Persiste implicitement via
/// `HomeProfilePreferences` quand le user change le picker.
void applyAppLocale(String langCode) {
  switch (langCode.toLowerCase()) {
    case 'en':
    case 'en_us':
      Get.updateLocale(const Locale('en', 'US'));
      break;
    case 'fr':
    case 'fr_fr':
    default:
      Get.updateLocale(const Locale('fr', 'FR'));
  }
}

const Map<String, String> _fr = {
  // ── Bottom nav ────────────────────────────────────────────
  'nav.home': 'Accueil',
  'nav.messages': 'Messages',
  'nav.offers': 'Offres',
  'nav.opportunities': 'Opportunités',
  'nav.network': 'Communauté',
  'nav.trainings': 'Formations',
  'nav.tracking': 'Suivi',
  'nav.profile': 'Profil',

  // ── Common buttons / actions ──────────────────────────────
  'common.cancel': 'Annuler',
  'common.confirm': 'Confirmer',
  'common.save': 'Enregistrer',
  'common.delete': 'Supprimer',
  'common.continue': 'Continuer',
  'common.back': 'Retour',
  'common.retry': 'Réessayer',
  'common.refresh': 'Actualiser',
  'common.search': 'Rechercher',
  'common.filter': 'Filtrer',
  'common.loading': 'Chargement...',
  'common.see_all': 'Tout voir',
  'common.see_more': 'Voir plus',
  'common.send': 'Envoyer',
  'common.edit': 'Modifier',
  'common.share': 'Partager',
  'common.copy': 'Copier',
  'common.close': 'Fermer',
  'common.done': 'Terminé',
  'common.next': 'Suivant',
  'common.previous': 'Précédent',
  'common.yes': 'Oui',
  'common.no': 'Non',
  'common.empty': 'Vide',
  'common.unavailable': 'Non disponible',

  // ── Greeting / accueil ────────────────────────────────────
  'home.greeting': 'Bonjour 👋',
  'home.greeting_morning': 'Bonjour',
  'home.greeting_afternoon': 'Bon après-midi',
  'home.greeting_evening': 'Bonsoir',
  'home.greeting_fallback': 'bienvenue',
  'home.welcome': 'Bienvenue',
  'home.for_you': 'Pour toi',
  'home.suggestions_unavailable':
      'Suggestions indisponibles pour le moment.',
  'home.quick_applications': 'Candidatures',
  'home.quick_applications_caption': 'Suivre mes envois',
  'home.quick_cv': 'Mon CV',
  'home.quick_documents': 'Documents',
  'home.quick_portfolio': 'Portfolio',
  'home.hero_badge': 'POUR VOUS',
  'home.hero_title': 'Trouvez votre\nprochaine opportunité',
  'home.hero_cta': 'Explorer les offres',
  'home.section_offers': 'Swipe des offres',
  'home.section_offers_action': 'Liste',
  'home.section_trainings': 'Formations disponibles',
  'home.section_trainings_action': 'Tout voir',

  // ── Offers / candidatures ─────────────────────────────────
  'offers.title': 'Offres d\'emploi',
  'offers.subtitle': 'Découvrez les opportunités qui vous correspondent.',
  'offers.search_hint': 'Rechercher une offre, entreprise...',
  'offers.empty_title': 'Aucune offre disponible',
  'offers.empty_subtitle':
      'Repassez plus tard, de nouvelles opportunités sont publiées régulièrement.',
  'offers.apply': 'Postuler',
  'offers.applied': 'Candidature envoyée',
  'offers.save': 'Sauvegarder',
  'offers.unsave': 'Retirer des favoris',
  'offers.match_score': 'Score de match',
  'offers.deadline': 'Clôture le',
  'offers.remote': 'Remote',
  'applications.title': 'Mes candidatures',
  'applications.subtitle': 'Suivez le statut de chaque postulat envoyé.',
  'applications.empty_all': 'Aucune candidature',
  'applications.empty_all_sub':
      'Postulez à vos premières offres pour les voir ici.',
  'applications.empty_filtered': 'Aucune candidature dans ce statut',
  'applications.empty_filtered_sub':
      'Changez ou retirez le filtre pour voir plus de candidatures.',
  'applications.status.new': 'Nouvelle',
  'applications.status.shortlisted': 'Présélectionnée',
  'applications.status.evaluation': 'En évaluation',
  'applications.status.interview': 'Entretien',
  'applications.status.offer': 'Offre reçue',
  'applications.status.rejected': 'Rejetée',
  'applications.status.withdrawn': 'Retirée',
  'applications.filter.all': 'Toutes',
  'applications.filter_title': 'Filtrer par statut',
  'applications.tab.applied': 'Postulées',
  'applications.tab.saved': 'Favoris',
  'applications.saved.empty': 'Aucune offre en favori',
  'applications.saved.empty_sub':
      'Touchez le cœur sur une offre pour la retrouver ici.',
  'applications.saved.remove': 'Retirer des favoris',
  'applications.saved.removed_toast': 'Retirée des favoris',

  // ── Trainings ─────────────────────────────────────────────
  'trainings.title': 'Formations',
  'trainings.subtitle':
      'Boostez vos compétences avec nos parcours sélectionnés.',
  'trainings.search_hint': 'Rechercher une formation, organisme...',
  'trainings.empty_title': 'Aucune formation disponible',
  'trainings.empty_subtitle':
      'De nouvelles formations seront publiées prochainement.',
  'trainings.enroll': 'Suivre la formation',
  'trainings.continue': 'Commencer maintenant',
  'trainings.review': 'Revoir la formation',
  'trainings.no_lessons': 'Aucune leçon disponible',
  'trainings.lessons_count': '@count leçon(s)',
  'trainings.modules': 'modules',
  'trainings.enrolled': 'inscrits',
  'trainings.free': 'Gratuit',
  'trainings.certified': 'Certifié',
  'trainings.tab_videos': 'Vidéos',
  'trainings.tab_description': 'Description',
  'trainings.progress': 'Progression',
  'trainings.progress_done': '@done sur @total leçon(s) terminée(s)',

  // ── Messaging ─────────────────────────────────────────────
  'messages.title': 'Messages',
  'messages.subtitle': 'Échangez avec les recruteurs et suivez vos pistes.',
  'messages.search_hint': 'Rechercher un contact, un message...',
  'messages.unread': '@count non lu',
  'messages.unread_plural': '@count non lus',
  'messages.up_to_date': 'Tout est à jour',
  'messages.empty': 'Aucune conversation',
  'messages.empty_sub': 'Vos échanges avec les recruteurs apparaîtront ici.',
  'messages.compose_hint': 'Écrire un message...',
  'messages.online': 'En ligne',
  'messages.offline': 'Hors ligne',
  'messages.encryption_notice':
      'Vos échanges sont chiffrés de bout en bout. Personne en dehors de cette conversation, pas même JobAway, ne peut les lire.',
  'messages.section.today': "Aujourd'hui",
  'messages.section.yesterday': 'Hier',
  'messages.section.this_week': 'Cette semaine',
  'messages.section.older': 'Plus ancien',
  'messages.filter.all': 'Tous',
  'messages.filter.unread': 'Non lus',
  'messages.filter.recruiters': 'Recruteurs',

  // ── Notifications ─────────────────────────────────────────
  'notifs.title': 'Notifications',
  'notifs.subtitle':
      'Suivez vos opportunités, messages et relances en un coup d\'œil.',
  'notifs.filter.all': 'Toutes',
  'notifs.filter.unread': 'Non lues',
  'notifs.filter.read': 'Lues',
  'notifs.empty_all': 'Aucune notification',
  'notifs.empty_all_sub':
      'Les nouvelles opportunités, messages et relances apparaîtront ici.',
  'notifs.empty_unread': 'Tout est lu',
  'notifs.empty_unread_sub':
      'Vous êtes à jour. Les nouvelles notifications non lues apparaîtront ici.',
  'notifs.empty_read': 'Aucune notification lue',
  'notifs.empty_read_sub': 'Vos notifications archivées apparaîtront ici.',
  'notifs.section.today': "AUJOURD'HUI",
  'notifs.section.yesterday': 'HIER',
  'notifs.section.this_week': 'CETTE SEMAINE',
  'notifs.section.older': 'PLUS ANCIEN',
  'notifs.time.now': 'Maintenant',
  'notifs.time.min': 'min',
  'notifs.time.hour': 'h',
  'notifs.time.day': 'j',
  'notifs.time.week': 'sem',
  'notifs.category.profile': 'Profil',
  'notifs.category.message': 'Message',
  'notifs.category.offer': 'Offre',
  'notifs.category.training': 'Formation',
  'notifs.category.portfolio': 'Portfolio',
  'notifs.seed.welcome.title': 'Profil candidat',
  'notifs.seed.welcome.body':
      'Completez votre CV et votre portfolio pour etre visible.',
  'notifs.seed.messages.title': 'Messages recruteurs',
  'notifs.seed.messages.body': 'Vous avez des conversations a consulter.',
  'notifs.seed.portfolio.title': 'Portfolio',
  'notifs.seed.portfolio.body':
      'Les entreprises peuvent consulter les projets publics.',

  // ── Profile ───────────────────────────────────────────────
  'profile.title': 'Profil',
  'profile.subtitle': 'Mettez en valeur votre parcours et votre savoir-faire.',
  'profile.my_applications': 'Mes candidatures',
  'profile.my_cv': 'Mon CV',
  'profile.my_portfolio': 'Mon portfolio',
  'profile.preferences': 'Préférences',
  'profile.language': 'Langue',
  'profile.theme': 'Thème',
  'profile.theme_light': 'Clair',
  'profile.theme_dark': 'Sombre',
  'profile.lang_fr': 'Français',
  'profile.lang_en': 'English',
  'profile.logout': 'Se déconnecter',
  'profile.logout_confirm_title': 'Se déconnecter ?',
  'profile.logout_confirm_msg':
      'Vous devrez vous reconnecter pour accéder à votre compte.',

  // ── Auth ──────────────────────────────────────────────────
  'auth.signin': 'Se connecter',
  'auth.signup': 'S\'inscrire',
  'auth.email': 'Adresse email',
  'auth.password': 'Mot de passe',
  'auth.forgot': 'Mot de passe oublié ?',
  'auth.no_account': 'Vous n\'avez pas de compte ?',
  'auth.has_account': 'Vous avez déjà un compte ?',

  // ── Errors / generic ──────────────────────────────────────
  'error.network':
      'Connexion au service impossible. Vérifiez votre réseau et réessayez.',
  'error.unauthorized':
      'Votre session a expiré. Connectez-vous pour continuer.',
  'error.forbidden': 'Vous n\'avez pas les droits pour cette action.',
  'error.server': 'Une erreur serveur est survenue. Notre équipe est prévenue.',
  'error.generic': 'Une erreur est survenue. Réessayez.',
};

const Map<String, String> _en = {
  // ── Bottom nav ────────────────────────────────────────────
  'nav.home': 'Home',
  'nav.messages': 'Messages',
  'nav.offers': 'Jobs',
  'nav.opportunities': 'Opportunities',
  'nav.network': 'Community',
  'nav.trainings': 'Courses',
  'nav.tracking': 'Tracking',
  'nav.profile': 'Profile',

  // ── Common buttons / actions ──────────────────────────────
  'common.cancel': 'Cancel',
  'common.confirm': 'Confirm',
  'common.save': 'Save',
  'common.delete': 'Delete',
  'common.continue': 'Continue',
  'common.back': 'Back',
  'common.retry': 'Retry',
  'common.refresh': 'Refresh',
  'common.search': 'Search',
  'common.filter': 'Filter',
  'common.loading': 'Loading...',
  'common.see_all': 'See all',
  'common.see_more': 'See more',
  'common.send': 'Send',
  'common.edit': 'Edit',
  'common.share': 'Share',
  'common.copy': 'Copy',
  'common.close': 'Close',
  'common.done': 'Done',
  'common.next': 'Next',
  'common.previous': 'Previous',
  'common.yes': 'Yes',
  'common.no': 'No',
  'common.empty': 'Empty',
  'common.unavailable': 'Unavailable',

  // ── Greeting / home ───────────────────────────────────────
  'home.greeting': 'Hello 👋',
  'home.greeting_morning': 'Good morning',
  'home.greeting_afternoon': 'Good afternoon',
  'home.greeting_evening': 'Good evening',
  'home.greeting_fallback': 'welcome',
  'home.welcome': 'Welcome',
  'home.for_you': 'For you',
  'home.suggestions_unavailable': 'Suggestions unavailable right now.',
  'home.quick_applications': 'Applications',
  'home.quick_applications_caption': 'Track my submissions',
  'home.quick_cv': 'My resume',
  'home.quick_documents': 'Documents',
  'home.quick_portfolio': 'Portfolio',
  'home.hero_badge': 'FOR YOU',
  'home.hero_title': 'Find your\nnext opportunity',
  'home.hero_cta': 'Browse jobs',
  'home.section_offers': 'Swipe jobs',
  'home.section_offers_action': 'List',
  'home.section_trainings': 'Available courses',
  'home.section_trainings_action': 'See all',

  // ── Offers / applications ─────────────────────────────────
  'offers.title': 'Job openings',
  'offers.subtitle': 'Discover the opportunities that match your profile.',
  'offers.search_hint': 'Search a job, company...',
  'offers.empty_title': 'No jobs available',
  'offers.empty_subtitle':
      'Check back later — new opportunities are posted regularly.',
  'offers.apply': 'Apply',
  'offers.applied': 'Application sent',
  'offers.save': 'Save',
  'offers.unsave': 'Remove from favorites',
  'offers.match_score': 'Match score',
  'offers.deadline': 'Closes on',
  'offers.remote': 'Remote',
  'applications.title': 'My applications',
  'applications.subtitle': 'Track the status of every application you sent.',
  'applications.empty_all': 'No applications yet',
  'applications.empty_all_sub': 'Apply to your first jobs to see them here.',
  'applications.empty_filtered': 'No applications in this status',
  'applications.empty_filtered_sub':
      'Change or clear the filter to see more applications.',
  'applications.status.new': 'New',
  'applications.status.shortlisted': 'Shortlisted',
  'applications.status.evaluation': 'Under review',
  'applications.status.interview': 'Interview',
  'applications.status.offer': 'Offer received',
  'applications.status.rejected': 'Rejected',
  'applications.status.withdrawn': 'Withdrawn',
  'applications.filter.all': 'All',
  'applications.filter_title': 'Filter by status',
  'applications.tab.applied': 'Applied',
  'applications.tab.saved': 'Saved',
  'applications.saved.empty': 'No saved offers yet',
  'applications.saved.empty_sub': 'Tap the heart on an offer to find it here.',
  'applications.saved.remove': 'Remove from favorites',
  'applications.saved.removed_toast': 'Removed from favorites',

  // ── Trainings ─────────────────────────────────────────────
  'trainings.title': 'Courses',
  'trainings.subtitle': 'Boost your skills with our curated learning paths.',
  'trainings.search_hint': 'Search a course, provider...',
  'trainings.empty_title': 'No courses available',
  'trainings.empty_subtitle': 'New courses will be published soon.',
  'trainings.enroll': 'Enroll',
  'trainings.continue': 'Start now',
  'trainings.review': 'Review course',
  'trainings.no_lessons': 'No lessons available',
  'trainings.lessons_count': '@count lesson(s)',
  'trainings.modules': 'modules',
  'trainings.enrolled': 'enrolled',
  'trainings.free': 'Free',
  'trainings.certified': 'Certified',
  'trainings.tab_videos': 'Videos',
  'trainings.tab_description': 'Description',
  'trainings.progress': 'Progress',
  'trainings.progress_done': '@done of @total lesson(s) completed',

  // ── Messaging ─────────────────────────────────────────────
  'messages.title': 'Messages',
  'messages.subtitle': 'Chat with recruiters and follow up on your leads.',
  'messages.search_hint': 'Search a contact, a message...',
  'messages.unread': '@count unread',
  'messages.unread_plural': '@count unread',
  'messages.up_to_date': "You're all caught up",
  'messages.empty': 'No conversations',
  'messages.empty_sub': 'Your chats with recruiters will appear here.',
  'messages.compose_hint': 'Write a message...',
  'messages.online': 'Online',
  'messages.offline': 'Offline',
  'messages.encryption_notice':
      'Your messages are end-to-end encrypted. No one outside this conversation, not even JobAway, can read them.',
  'messages.section.today': 'Today',
  'messages.section.yesterday': 'Yesterday',
  'messages.section.this_week': 'This week',
  'messages.section.older': 'Older',
  'messages.filter.all': 'All',
  'messages.filter.unread': 'Unread',
  'messages.filter.recruiters': 'Recruiters',

  // ── Notifications ─────────────────────────────────────────
  'notifs.title': 'Notifications',
  'notifs.subtitle':
      'Track your opportunities, messages and follow-ups at a glance.',
  'notifs.filter.all': 'All',
  'notifs.filter.unread': 'Unread',
  'notifs.filter.read': 'Read',
  'notifs.empty_all': 'No notifications',
  'notifs.empty_all_sub':
      'New opportunities, messages and follow-ups will appear here.',
  'notifs.empty_unread': "You're all caught up",
  'notifs.empty_unread_sub':
      'You\'re up to date. New unread notifications will appear here.',
  'notifs.empty_read': 'No read notifications',
  'notifs.empty_read_sub': 'Your archived notifications will appear here.',
  'notifs.section.today': 'TODAY',
  'notifs.section.yesterday': 'YESTERDAY',
  'notifs.section.this_week': 'THIS WEEK',
  'notifs.section.older': 'OLDER',
  'notifs.time.now': 'Just now',
  'notifs.time.min': 'min',
  'notifs.time.hour': 'h',
  'notifs.time.day': 'd',
  'notifs.time.week': 'w',
  'notifs.category.profile': 'Profile',
  'notifs.category.message': 'Message',
  'notifs.category.offer': 'Job',
  'notifs.category.training': 'Course',
  'notifs.category.portfolio': 'Portfolio',
  'notifs.seed.welcome.title': 'Candidate profile',
  'notifs.seed.welcome.body': 'Complete your CV and portfolio to stand out.',
  'notifs.seed.messages.title': 'Recruiter messages',
  'notifs.seed.messages.body': 'You have conversations to check.',
  'notifs.seed.portfolio.title': 'Portfolio',
  'notifs.seed.portfolio.body': 'Companies can browse your public projects.',

  // ── Profile ───────────────────────────────────────────────
  'profile.title': 'Profile',
  'profile.subtitle': 'Showcase your background and your skills.',
  'profile.my_applications': 'My applications',
  'profile.my_cv': 'My CV',
  'profile.my_portfolio': 'My portfolio',
  'profile.preferences': 'Preferences',
  'profile.language': 'Language',
  'profile.theme': 'Theme',
  'profile.theme_light': 'Light',
  'profile.theme_dark': 'Dark',
  'profile.lang_fr': 'Français',
  'profile.lang_en': 'English',
  'profile.logout': 'Sign out',
  'profile.logout_confirm_title': 'Sign out?',
  'profile.logout_confirm_msg':
      'You\'ll need to sign in again to access your account.',

  // ── Auth ──────────────────────────────────────────────────
  'auth.signin': 'Sign in',
  'auth.signup': 'Sign up',
  'auth.email': 'Email address',
  'auth.password': 'Password',
  'auth.forgot': 'Forgot your password?',
  'auth.no_account': "Don't have an account?",
  'auth.has_account': 'Already have an account?',

  // ── Errors / generic ──────────────────────────────────────
  'error.network':
      'Cannot reach the service. Check your connection and try again.',
  'error.unauthorized': 'Your session expired. Sign in again to continue.',
  'error.forbidden': "You don't have permission for this action.",
  'error.server': 'A server error occurred. Our team has been notified.',
  'error.generic': 'Something went wrong. Try again.',
};
