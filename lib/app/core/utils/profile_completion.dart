import 'package:flutter/material.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:baara/routes/app_routes.dart';

import '../../features/profile/domain/entities/profile.dart';

/// Item de la checklist complétion profil (libellé, état, route d'édition).
class ProfileCompletionItem {
  const ProfileCompletionItem({
    required this.label,
    required this.icon,
    required this.done,
    required this.route,
  });

  final String label;
  final IconData icon;
  final bool done;
  final String route;
}

/// Checklist unifiée (accueil + profil) — ordre = priorité recruteur.
List<ProfileCompletionItem> profileCompletionItems(
  Profile profile, {
  bool hasDocuments = false,
}) {
  final hasCvContent = profile.experiences.isNotEmpty ||
      profile.educations.isNotEmpty ||
      profile.skills.isNotEmpty ||
      (profile.desiredRole ?? '').trim().isNotEmpty;

  return [
    ProfileCompletionItem(
      label: 'Photo de profil',
      icon: AppIcons.personFilled,
      done: (profile.avatarUrl ?? '').trim().isNotEmpty,
      route: AppRoutes.profileEdit,
    ),
    ProfileCompletionItem(
      label: 'Titre professionnel',
      icon: AppIcons.network,
      done: (profile.headline ?? '').trim().isNotEmpty,
      route: AppRoutes.profileEdit,
    ),
    ProfileCompletionItem(
      label: 'Ville',
      icon: AppIcons.location,
      done: profile.city.trim().isNotEmpty,
      route: AppRoutes.profileEdit,
    ),
    ProfileCompletionItem(
      label: 'Téléphone',
      icon: AppIcons.call,
      done: profile.phone.trim().isNotEmpty,
      route: AppRoutes.profileEdit,
    ),
    ProfileCompletionItem(
      label: 'Bio',
      icon: AppIcons.document,
      done: (profile.bio ?? '').trim().isNotEmpty,
      route: AppRoutes.profileEdit,
    ),
    ProfileCompletionItem(
      label: 'Compétences',
      icon: AppIcons.star,
      done: profile.skills.isNotEmpty,
      route: AppRoutes.profileParcours,
    ),
    ProfileCompletionItem(
      label: 'Expériences',
      icon: AppIcons.work,
      done: profile.experiences.isNotEmpty,
      route: AppRoutes.profileParcours,
    ),
    ProfileCompletionItem(
      label: 'Formations',
      icon: Icons.school_outlined,
      done: profile.educations.isNotEmpty,
      route: AppRoutes.profileParcours,
    ),
    ProfileCompletionItem(
      label: 'CV à jour',
      icon: AppIcons.document,
      done: hasCvContent,
      route: AppRoutes.profileCv,
    ),
    ProfileCompletionItem(
      label: 'Vidéo de présentation',
      icon: AppIcons.video,
      done: (profile.presentationVideoUrl ?? '').trim().isNotEmpty,
      route: AppRoutes.profile,
    ),
    ProfileCompletionItem(
      label: 'Documents',
      icon: AppIcons.folder,
      done: hasDocuments,
      route: AppRoutes.profileDocuments,
    ),
  ];
}

/// Pourcentage local (0–100). Si le backend marque le profil complet → 100.
int profileCompletionPercent(
  Profile profile, {
  bool hasDocuments = false,
}) {
  if (profile.isProfileComplete) return 100;
  final items = profileCompletionItems(profile, hasDocuments: hasDocuments);
  if (items.isEmpty) return 0;
  final filled = items.where((i) => i.done).length;
  return ((filled / items.length) * 100).round().clamp(0, 99);
}

List<ProfileCompletionItem> profileCompletionMissing(
  Profile profile, {
  int limit = 3,
  bool hasDocuments = false,
}) {
  return profileCompletionItems(profile, hasDocuments: hasDocuments)
      .where((i) => !i.done)
      .take(limit)
      .toList();
}

bool profileNeedsCompletion(
  Profile profile, {
  bool hasDocuments = false,
}) =>
    !profile.isProfileComplete &&
    profileCompletionPercent(profile, hasDocuments: hasDocuments) < 100;
