part of '../home_training_flow.dart';

class _EmptyLessonsBlock extends StatelessWidget {
  const _EmptyLessonsBlock({required this.formation});

  final HomeFormationPreview formation;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.menu_book_outlined,
            color: AppColors.hintColor,
            size: 42,
          ),
          const SizedBox(height: 10),
          Text(
            'Aucune lecon disponible',
            style: AppTextStyles.titleMd,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            formation.description,
            style: AppTextStyles.bodySm,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

Color _lessonColor(HomeTrainingLesson lesson) {
  if (lesson.isVideo) {
    return AppColors.categoryPurpleDeep;
  }
  if (lesson.isPdf) {
    return AppColors.errorBright;
  }
  if (lesson.isImage) {
    return AppColors.successDark;
  }
  return AppColors.categoryCyan;
}

Future<bool> _openLessonAsset(HomeTrainingLesson lesson) async {
  final url = lesson.assetUrl.trim();
  if (url.isEmpty) {
    AppToast.warning(
      'Contenu indisponible',
      'Aucun fichier n\'est encore attache a cette lecon.',
    );
    return false;
  }

  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) {
    AppToast.error(
      'Lien invalide',
      'Le lien du fichier est mal forme. Contactez le support.',
    );
    return false;
  }

  // Tentative en mode in-app browser pour videos / PDFs / images.
  try {
    final inApp = await launchUrl(
      uri,
      mode: LaunchMode.inAppBrowserView,
      webViewConfiguration: const WebViewConfiguration(
        enableJavaScript: true,
        enableDomStorage: true,
      ),
    );
    if (inApp) return true;
  } on Exception {
    // Ignore et tente l'ouverture externe ci-dessous.
  }

  try {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (opened) return true;
  } on Exception {
    // Echec aussi en externe — on retombe sur le toast.
  }

  AppToast.error(
    'Ouverture impossible',
    'Aucune application sur cet appareil ne peut ouvrir ce fichier.',
  );
  return false;
}
