import 'package:flutter/material.dart';

import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:baara/app/features/offers/data/models/application_model.dart';

/// Libellé, couleur et icône d'un statut de candidature. Partagé par l'écran
/// Candidatures et l'onglet Suivi, pour qu'un même statut se lise pareil
/// partout.
///
/// Les couleurs suivent la progression : envoyée (neutre, en attente),
/// présélectionnée (marque), entretien (vert de réussite, l'étape la plus
/// positive), non retenue (rouge). L'icône porte aussi le sens, pour ne pas
/// dépendre de la couleur seule.
class ApplicationStatusStyle {
  const ApplicationStatusStyle(this.label, this.color, this.icon);

  final String label;
  final Color color;
  final IconData icon;

  static ApplicationStatusStyle of(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.newApp:
        return ApplicationStatusStyle(
            'Envoyée', AppColors.bodyColor, AppIcons.send);
      case ApplicationStatus.shortlisted:
        return ApplicationStatusStyle(
            'Présélectionnée', AppColors.primaryAccent, AppIcons.starFilled);
      case ApplicationStatus.interview:
        return ApplicationStatusStyle(
            'Entretien', AppColors.successAccent, AppIcons.calendar);
      case ApplicationStatus.rejected:
        return ApplicationStatusStyle('Non retenue', AppColors.errorAccent,
            Icons.do_not_disturb_on_rounded);
    }
  }
}
