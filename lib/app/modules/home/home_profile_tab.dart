import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../translations/app_translations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme_controller.dart';
import '../../core/utils/haptics.dart';
import '../../core/network/api_provider.dart';
import '../../../routes/app_routes.dart';
import '../../core/widgets/widgets.dart';
import 'home_controller.dart';
import 'home_profile_manager.dart';
import 'home_profile_models.dart';


part 'home_profile_parts/header_widgets.dart';
part 'home_profile_parts/contact_prefs.dart';
part 'home_profile_parts/cv_widgets.dart';
part 'home_profile_parts/portfolio_widgets.dart';
part 'home_profile_parts/shared_utils.dart';
part 'home_profile_parts/hub_widgets.dart';
part 'home_profile_parts/form_widgets.dart';
part 'home_profile_parts/cv_editor.dart';
part 'home_profile_parts/portfolio_editor.dart';

class _PendingUploadFile {
  const _PendingUploadFile({
    required this.name,
    required this.bytes,
  });

  final String name;
  final Uint8List bytes;
}

class HomeProfileTab extends StatelessWidget {
  HomeProfileTab({
    required this.controller,
    super.key,
  });

  final HomeController controller;
  final ImagePicker _imagePicker = ImagePicker();

  HomeProfileManager get _manager => controller.profileManager;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_manager.isLoadingProfile.value &&
          _manager.profile.value.id.isEmpty &&
          _manager.profileLoadError.value.isEmpty) {
        return const PageSkeleton(rowCount: 4);
      }

      final profile = _manager.profile.value;
      final prefs = _manager.preferences.value;
      final themeController = Get.find<AppThemeController>();

      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _manager.loadAll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 130),
          children: [
            _ProfileHubHeader(
              profile: profile,
              isUploadingAvatar: _manager.isUploadingAvatar.value,
              onLogout: () => _confirmLogout(context),
              onEditAvatar: () => _pickAvatar(context),
              onEditProfile: () => Get.toNamed(AppRoutes.profileEdit),
            ),
            if (_manager.profileLoadError.value.isNotEmpty &&
                profile.id.isEmpty) ...[
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _InlineMessageCard(
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  message: _manager.profileLoadError.value,
                  actionLabel: 'Recharger',
                  onAction: _manager.loadProfile,
                ),
              ),
            ],
            const SizedBox(height: 24),
            _SettingsSection(
              children: [
                _SettingsItem(
                  icon: IconlyLight.send,
                  iconColor: AppColors.categoryBlue,
                  label: 'Mes candidatures',
                  onTap: () => Get.toNamed(AppRoutes.myApplications),
                ),
                _SettingsItem(
                  icon: IconlyLight.document,
                  iconColor: AppColors.primary,
                  label: 'Mon CV',
                  onTap: () {
                    Get.toNamed(AppRoutes.profileCvBuilder);
                  },
                ),
                _SettingsItem(
                  icon: IconlyLight.work,
                  iconColor: AppColors.categoryPurple,
                  label: 'Mon portfolio',
                  onTap: () {
                    Get.toNamed(AppRoutes.profilePortfolio);
                  },
                ),
                _SettingsItem(
                  icon: IconlyLight.notification,
                  iconColor: AppColors.categoryOrange,
                  label: 'Notifications',
                  trailing: _SettingsTrailingText(
                    prefs.notificationsEnabled ? 'Activées' : 'Désactivées',
                  ),
                  onTap: () => _openNotificationsSheet(context, prefs),
                ),
                _SettingsItem(
                  icon: IconlyLight.discovery,
                  iconColor: AppColors.categoryCyan,
                  label: 'Langue',
                  trailing: _SettingsTrailingText(
                    prefs.language == 'en' ? 'English' : 'Français',
                  ),
                  onTap: () => _openLanguageSheet(context, prefs),
                ),
                _SettingsItem(
                  icon: Icons.contrast_rounded,
                  iconColor: AppColors.categoryGray,
                  label: 'Thème',
                  trailing: _SettingsTrailingText(
                    themeController.isDarkMode.value ? 'Sombre' : 'Clair',
                  ),
                  onTap: () => _openThemeSheet(context, prefs),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SettingsSection(
              title: 'Aide & légal',
              children: [
                _SettingsItem(
                  icon: IconlyLight.info_circle,
                  iconColor: AppColors.categoryPink,
                  label: 'Aide & support',
                  onTap: () => _showInfoSnackbar(
                    'Aide & support',
                    'Contactez-nous à support@opportunebf.com',
                  ),
                ),
                _SettingsItem(
                  icon: IconlyLight.paper,
                  iconColor: AppColors.categoryGray,
                  label: 'Conditions générales',
                  onTap: () => _showInfoSnackbar(
                    'Conditions',
                    'Document à venir.',
                  ),
                ),
                _SettingsItem(
                  icon: IconlyLight.shield_done,
                  iconColor: AppColors.categoryBlue,
                  label: 'Politique de confidentialité',
                  onTap: () => _showInfoSnackbar(
                    'Confidentialité',
                    'Document à venir.',
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  // ────────────────────────────────────────────────────────
  // Hub helpers (logout, sheets, info)
  // ────────────────────────────────────────────────────────

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showConfirmSheet(
      context: context,
      icon: Icons.logout_rounded,
      iconColor: AppColors.error,
      title: 'Se déconnecter ?',
      message: 'Vous devrez vous reconnecter pour accéder à votre compte.',
      confirmLabel: 'Se déconnecter',
      isDestructive: true,
    );
    if (confirmed == true) {
      AppHaptics.confirm();
      await controller.logout();
    }
  }

  void _showInfoSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surfaceCard,
      colorText: AppColors.titleColor,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
    );
  }

  Future<void> _openNotificationsSheet(
    BuildContext context,
    HomeProfilePreferences prefs,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => _NotificationsSheet(
        preferences: prefs,
        manager: _manager,
        onChanged: _savePreferences,
      ),
    );
  }

  Future<void> _openLanguageSheet(
    BuildContext context,
    HomeProfilePreferences prefs,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => _ChoiceSheet(
        title: 'Langue de l\'application',
        options: const {'fr': 'Français', 'en': 'English'},
        selected: prefs.language,
        onSelected: (value) {
          AppHaptics.tap();
          _savePreferences(prefs.copyWith(language: value));
          Navigator.of(sheetCtx).pop();
        },
      ),
    );
  }

  Future<void> _openThemeSheet(
    BuildContext context,
    HomeProfilePreferences prefs,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => _ChoiceSheet(
        title: 'Apparence',
        options: const {'light': 'Clair', 'dark': 'Sombre'},
        selected: prefs.theme,
        onSelected: (value) {
          AppHaptics.tap();
          _savePreferences(prefs.copyWith(theme: value));
          Navigator.of(sheetCtx).pop();
        },
      ),
    );
  }

  Future<void> _pickAvatar(BuildContext context) async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1600,
      );
      if (image == null) {
        return;
      }

      await _manager.uploadAvatar(image);
      Get.snackbar(
        'Profil',
        'Photo de profil mise a jour.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on Exception catch (error) {
      _showError(error);
    }
  }

  // ignore: unused_element
  Future<void> _pickCvFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'doc', 'docx'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        throw Exception('Impossible de lire le fichier selectionne.');
      }

      await _manager.uploadCvFile(
        bytes: bytes,
        filename: file.name.isEmpty ? 'cv.pdf' : file.name,
      );
      Get.snackbar(
        'CV',
        'CV importe avec succes.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on Exception catch (error) {
      _showError(error);
    }
  }

  Future<void> _savePreferences(HomeProfilePreferences nextPreferences) async {
    // Synchronise immédiatement le thème de l'app avec le choix utilisateur
    // (sans attendre la réponse serveur — sinon décalage visible).
    if (Get.isRegistered<AppThemeController>()) {
      final themeController = Get.find<AppThemeController>();
      final wantsDark = nextPreferences.theme == 'dark';
      if (themeController.isDarkMode.value != wantsDark) {
        await themeController.setDarkMode(wantsDark);
      }
    }

    try {
      await _manager.savePreferences(nextPreferences);
    } on Exception catch (error) {
      _showError(error);
    }
  }

  // ignore: unused_element
  Future<void> _removeCvSection(HomeCvSection section) async {
    final updated = _manager.cvSections
        .where((entry) => entry.id != section.id)
        .toList(growable: true);

    try {
      await _manager.saveCv(updated);
      Get.snackbar(
        'CV',
        'Section supprimee.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on Exception catch (error) {
      _showError(error);
    }
  }

  // ignore: unused_element
  Future<void> _deletePortfolioItem(HomePortfolioItem item) async {
    try {
      await _manager.deletePortfolioItem(item);
      Get.snackbar(
        'Portfolio',
        'Projet supprime.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on Exception catch (error) {
      _showError(error);
    }
  }

  // ignore: unused_element
  Future<void> _openExternal(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null) {
      _showError(Exception('URL invalide.'));
      return;
    }

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showError(Exception('Impossible d\'ouvrir ce lien.'));
    }
  }

  Future<DateTime?> _pickDate(
    BuildContext context, {
    DateTime? initialDate,
  }) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      locale: const Locale('fr', 'FR'),
      initialDate: initialDate ?? now,
      firstDate: DateTime(1990),
      lastDate: DateTime(now.year + 5),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Champ requis';
    }
    return null;
  }

  List<String> _splitCommaList(String raw) {
    return raw
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  List<String> _splitLines(String raw) {
    return raw
        .split(RegExp(r'\r\n|\r|\n'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'Choisir';
    }
    return DateFormat('dd/MM/yyyy').format(value);
  }

  void _showError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    Get.snackbar(
      'Erreur',
      message.isEmpty ? 'Une erreur est survenue.' : message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.errorSoft,
      colorText: AppColors.errorStrong,
    );
  }
}

class _CvFieldLabels {
  const _CvFieldLabels({
    required this.title,
    required this.organization,
    required this.description,
    required this.missions,
    required this.achievements,
    required this.level,
    required this.mention,
    required this.link,
    required this.current,
  });

  final String title;
  final String organization;
  final String description;
  final String missions;
  final String achievements;
  final String level;
  final String mention;
  final String link;
  final String current;
}

class _PortfolioFieldLabels {
  const _PortfolioFieldLabels({
    required this.addTitle,
    required this.editTitle,
    required this.title,
    required this.description,
    required this.results,
    required this.link,
    required this.stack,
    required this.mediaUrls,
    required this.visibilityTitle,
    required this.visibilitySubtitle,
    required this.filesTitle,
    required this.emptyFiles,
  });

  final String addTitle;
  final String editTitle;
  final String title;
  final String description;
  final String results;
  final String link;
  final String stack;
  final String mediaUrls;
  final String visibilityTitle;
  final String visibilitySubtitle;
  final String filesTitle;
  final String emptyFiles;
}

