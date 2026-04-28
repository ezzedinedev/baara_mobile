import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../routes/app_routes.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../data/models/application_model.dart';

/// Affiche le bon retour utilisateur pour chaque issue d'une candidature.
/// Appelé après `OffersController.applyToOffer(...)` depuis n'importe quel écran.
///
/// Cas gérés :
/// - succès : snackbar verte avec statut + score de match s'il est calculé
/// - noCv : dialog qui redirige vers la création de CV
/// - alreadyApplied : snackbar info
/// - deadlinePassed / offerNotActive / invalidOffer : snackbar bloquante
/// - unauthorized / notCandidate : snackbar d'accès refusé
/// - network / unknown : snackbar d'erreur technique
Future<void> handleApplyResult(BuildContext context, ApplyResult result) async {
  if (result.isSuccess) {
    final app = result.application!;
    final scorePart = app.aiMatchScore != null
        ? ' · Score de match ${app.aiMatchScore!.toStringAsFixed(0)}%'
        : '';
    AppToast.success(
      'Candidature envoyée',
      'Statut : ${app.status.label}$scorePart',
    );
    return;
  }

  final reason = result.reason!;
  final message = result.message ?? 'Erreur lors de la candidature.';

  switch (reason) {
    case ApplyFailureReason.noCv:
      await _showNoCvDialog(context);
      break;

    case ApplyFailureReason.alreadyApplied:
      _info(
        'Candidature existante',
        'Vous avez déjà postulé à cette offre.',
      );
      break;

    case ApplyFailureReason.deadlinePassed:
      _block(
        'Date limite dépassée',
        'La date limite de candidature pour cette offre est passée.',
      );
      break;

    case ApplyFailureReason.offerNotActive:
      _block(
        'Offre indisponible',
        'Cette offre n\'est plus active.',
      );
      break;

    case ApplyFailureReason.invalidOffer:
      _block('Offre invalide', message);
      break;

    case ApplyFailureReason.unauthorized:
      _block(
        'Connexion requise',
        'Connectez-vous pour postuler à une offre.',
      );
      break;

    case ApplyFailureReason.notCandidate:
      _block(
        'Accès refusé',
        'Seuls les comptes candidat peuvent postuler.',
      );
      break;

    case ApplyFailureReason.network:
      _block(
        'Connexion impossible',
        'Vérifiez votre connexion internet et réessayez.',
      );
      break;

    case ApplyFailureReason.unknown:
      _block('Erreur', message);
      break;
  }
}

Future<void> _showNoCvDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceIconSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('CV manquant', style: AppTextStyles.titleLg),
          ),
        ],
      ),
      content: Text(
        'Vous avez besoin d\'un CV pour postuler à une offre. '
        'Créez-le manuellement ou avec l\'aide de l\'assistant IA.',
        style: AppTextStyles.bodyMd.copyWith(
          color: AppColors.bodyColor,
          height: 1.45,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            AppHaptics.tap();
            Navigator.of(dialogContext).maybePop();
          },
          child: Text(
            'Plus tard',
            style: AppTextStyles.buttonLg.copyWith(color: AppColors.bodyColor),
          ),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
          icon: const Icon(Icons.auto_awesome_rounded, size: 18),
          label: const Text('Créer mon CV'),
          onPressed: () {
            AppHaptics.tap();
            Navigator.of(dialogContext).maybePop();
            // Route vers la landing CV builder (choix Assistant IA /
            // Manuel / Import) plutôt que vers la liste de CV vide.
            Get.toNamed(AppRoutes.profileCvBuilder);
          },
        ),
      ],
    ),
  );
}

void _info(String title, String message) {
  AppToast.warning(title, message);
}

void _block(String title, String message) {
  AppToast.error(title, message);
}
