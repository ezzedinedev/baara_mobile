import '../../features/profile/domain/entities/profile.dart';

/// Étape 1 onboarding : au moins un signal que le profil a été enrichi.
bool onboardingProfileStepDone(Profile profile) {
  return (profile.headline ?? '').trim().isNotEmpty ||
      (profile.avatarUrl ?? '').trim().isNotEmpty ||
      (profile.bio ?? '').trim().isNotEmpty ||
      profile.skills.isNotEmpty ||
      profile.city.trim().isNotEmpty;
}

/// Étape 2 onboarding : contenu CV / parcours exploitable pour candidater.
bool onboardingCvStepDone(Profile profile) {
  return profile.experiences.isNotEmpty ||
      profile.educations.isNotEmpty ||
      profile.skills.isNotEmpty ||
      (profile.desiredRole ?? '').trim().isNotEmpty;
}
