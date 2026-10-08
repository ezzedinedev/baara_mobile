import 'package:baara/app/core/constants/app_features.dart';
import 'package:flutter/material.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_dimens.dart';
import 'package:baara/app/core/theme/app_motion.dart';
import 'package:baara/app/core/theme/app_shapes.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/services/biometric_service.dart';
import 'package:baara/app/core/services/fcm_service.dart';
import 'package:baara/app/core/services/offline_apply_queue.dart';
import 'package:baara/app/core/services/review_prompt_service.dart';
import 'package:baara/app/core/theme/app_theme_controller.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/app/core/widgets/widgets.dart';
import 'package:baara/app/features/notifications/presentation/widgets/notification_preferences_sheet.dart';
import 'package:baara/routes/app_routes.dart';

import 'package:baara/app/features/offers/presentation/controllers/offer_controller.dart';
import '../controllers/profile_controller.dart';
import '../controllers/settings_controller.dart';
import '../widgets/delete_account_sheet.dart';

/// Paramètres — liste groupée style iOS Réglages : en-tête simple, cartes
/// groupées, icônes carrées arrondies colorées, lignes-titres + sous-lignes.
///
/// Règle d'affordance unifiée :
/// - **chevron** → ouvre une page ou une feuille de choix ;
/// - **interrupteur inline** → bascule binaire instantanée.
/// Version réelle de l'app (pubspec), lue une seule fois.
final Future<String> _appVersion =
    PackageInfo.fromPlatform().then((info) => info.version);

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLow,
      body: Column(
        children: [
          AppSubHeader(title: 'Paramètres', onBack: () => Get.back<void>()),
          const Expanded(
            child: SingleChildScrollView(child: SettingsBody()),
          ),
        ],
      ),
    );
  }
}

/// Corps des réglages (Compte / Préférences / Sécurité / À propos / …).
/// Réutilisable : écran Paramètres autonome ET intégré sous le hero du Profil.
/// L'état vit dans [SettingsController] (réactif + persisté), plus de `setState`.
class SettingsBody extends StatelessWidget {
  const SettingsBody({super.key});

  @override
  Widget build(BuildContext context) {
    // Résilience : selon le point d'entrée (shell à onglets, route dédiée…),
    // le controller peut ne pas avoir été enregistré par un binding — on le
    // crée à la volée tant que ProfileController est disponible.
    final settings = Get.isRegistered<SettingsController>()
        ? Get.find<SettingsController>()
        : Get.put(SettingsController(Get.find<ProfileController>()));
    final theme = Get.find<AppThemeController>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionLabel('Compte'),
          _Group(
            rows: [
              _HeaderRow(
                icon: AppIcons.profile,
                color: AppColors.primaryAccent,
                title: 'Informations personnelles',
                subtitle: 'Gérez les détails de votre compte',
                onTap: () {
                  AppHaptics.tap();
                  Get.toNamed(AppRoutes.profileEdit);
                },
              ),
              _HeaderRow(
                icon: AppIcons.work,
                color: AppColors.primaryAccent,
                title: 'Expériences & formations',
                subtitle: 'Votre parcours et vos diplômes',
                onTap: () {
                  AppHaptics.tap();
                  Get.toNamed(AppRoutes.profileParcours);
                },
              ),
              // Badge = nombre réel de candidatures envoyées (compteur vivant).
              Obx(() {
                final count = Get.isRegistered<OfferController>()
                    ? Get.find<OfferController>().appliedOfferIds.length
                    : 0;
                return _HeaderRow(
                  icon: AppIcons.paper,
                  color: AppColors.primaryAccent,
                  title: 'Mes candidatures',
                  subtitle: 'Suivez l\'état de vos postulations',
                  badge: count,
                  onTap: () {
                    AppHaptics.tap();
                    Get.toNamed(AppRoutes.myApplications);
                  },
                );
              }),
            ],
          ),
          const _EmailVerifyBanner(),
          // Abonnement : pas encore commercialisé, et tout achat de contenu
          // numérique est désactivé dans la version stores (AppFeatures).
          if (AppFeatures.inAppPurchases) ...[
            const SectionLabel('Abonnement'),
            _Group(
              rows: [
                _HeaderRow(
                  icon: AppIcons.wallet,
                  color: AppColors.primaryAccent,
                  title: 'Mon abonnement',
                  subtitle: 'Forfait, avantages et facturation',
                  onTap: () {
                    AppHaptics.tap();
                    Get.toNamed(AppRoutes.subscription);
                  },
                ),
              ],
            ),
          ],
          const SectionLabel('Préférences'),
          _Group(
            rows: [
              if (Get.isRegistered<FcmService>())
                Obx(() {
                  final fcm = Get.find<FcmService>();
                  final granted = fcm.pushPermissionGranted.value;
                  final denied = granted == false;
                  return _HeaderRow(
                    icon: AppIcons.notificationFilled,
                    color: denied
                        ? AppColors.warningAccent
                        : AppColors.primaryAccent,
                    title: 'Notifications push',
                    subtitle: denied
                        ? 'Autorisez Baara dans les réglages système'
                        : 'Alertes candidatures, messages et offres',
                    valueLabel: granted == null
                        ? null
                        : (granted ? 'Activées' : 'Désactivées'),
                    onTap: () async {
                      AppHaptics.tap();
                      if (granted == true) {
                        await fcm.openNotificationSettings();
                      } else {
                        // Android 13+ rapporte « refusé » tant qu'on n'a
                        // jamais demandé : on tente d'abord la fenêtre
                        // système, et les réglages seulement si Android ne
                        // l'affiche plus (refus définitif).
                        final asked = Stopwatch()..start();
                        await fcm.activateAfterLogin();
                        // Réponse instantanée = aucune fenêtre affichée.
                        if (fcm.pushPermissionGranted.value != true &&
                            asked.elapsedMilliseconds < 400) {
                          await fcm.openNotificationSettings();
                        }
                      }
                      await fcm.refreshPermissionStatus();
                    },
                  );
                }),
              Obx(
                () => _HeaderRow(
                  icon: AppIcons.bell,
                  color: AppColors.primaryAccent,
                  title: 'Notifications',
                  subtitle: 'Offres, messages et suivi des candidatures',
                  valueLabel: settings.notificationsEnabled.value
                      ? 'Activées'
                      : 'Désactivées',
                  onTap: () => showNotificationPreferencesSheet(context),
                ),
              ),
              Obx(
                () => _HeaderRow(
                  icon: AppIcons.show,
                  color: AppColors.primary,
                  title: 'Apparence',
                  subtitle: 'Système, clair ou sombre',
                  valueLabel: theme.themeSource.value == 'system'
                      ? 'Système'
                      : theme.themeSource.value == 'dark'
                          ? 'Sombre'
                          : 'Clair',
                  onTap: () => _pickAppearance(context, settings, theme),
                ),
              ),
              // Pas de choix de langue : seul l'accueil est traduit en anglais,
              // proposer « English » laissait le reste de l'app en français.
            ],
          ),
          const SectionLabel('Communauté & réseau'),
          _Group(
            rows: [
              _HeaderRow(
                icon: AppIcons.discovery,
                color: AppColors.primary,
                title: 'Mon fil communauté',
                subtitle: 'Publications et professionnels à suivre',
                onTap: () {
                  AppHaptics.tap();
                  Get.toNamed(AppRoutes.community);
                },
              ),
              _HeaderRow(
                icon: AppIcons.show,
                color: AppColors.primaryAccent,
                title: 'Vues de profil',
                subtitle: 'Qui a consulté votre profil',
                onTap: () {
                  AppHaptics.tap();
                  Get.toNamed(AppRoutes.communityProfileViews);
                },
              ),
              Obx(
                () => _HeaderRow(
                  icon: AppIcons.unlock,
                  color: AppColors.primaryAccent,
                  title: 'Visibilité du profil',
                  subtitle: 'Qui peut voir votre profil',
                  valueLabel: settings.profileVisibility.value == 'connections'
                      ? 'Mes connexions'
                      : 'Public',
                  onTap: () => _pickVisibility(context, settings),
                ),
              ),
              Obx(
                () => _HeaderRow(
                  icon: AppIcons.activity,
                  color: AppColors.secondary,
                  title: 'Activité du réseau',
                  subtitle: 'Abonnés, mentions et publications',
                  trailing: Switch.adaptive(
                    value: settings.networkActivity.value,
                    activeThumbColor: AppColors.onPrimary,
                    activeTrackColor: AppColors.primaryMedium,
                    onChanged: (v) {
                      AppHaptics.tap();
                      settings.setNetworkActivity(v);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SectionLabel('Sécurité & aides'),
          _Group(
            rows: [
              Obx(() {
                if (!Get.isRegistered<BiometricService>()) {
                  return const SizedBox.shrink();
                }
                final bio = Get.find<BiometricService>();
                if (!bio.canUseBiometrics.value) {
                  return const SizedBox.shrink();
                }
                return _HeaderRow(
                  icon: Icons.fingerprint_rounded,
                  color: AppColors.primaryAccent,
                  title: 'Verrouillage de l\'app',
                  subtitle: 'Empreinte, visage ou code à l\'ouverture',
                  trailing: Switch.adaptive(
                    value: bio.isEnabled.value,
                    activeThumbColor: AppColors.onPrimary,
                    activeTrackColor: AppColors.primaryMedium,
                    onChanged: (v) async {
                      AppHaptics.tap();
                      if (!v) {
                        await bio.setEnabled(false);
                        AppToast.info('Verrouillage désactivé');
                        return;
                      }
                      final ok = await bio.enableWithConfirmation();
                      if (ok) {
                        AppToast.success(
                          'Verrouillage activé',
                          'Baara vous le demandera à chaque ouverture.',
                        );
                      } else if (bio.deviceHasNoLock) {
                        AppToast.error(
                          'Aucun verrouillage sur ce téléphone',
                          'Ajoutez d\'abord un code, un schéma ou une '
                              'empreinte dans les réglages du téléphone.',
                        );
                      } else {
                        AppToast.error(
                          'Verrouillage non activé',
                          'L\'identification n\'a pas abouti.',
                        );
                      }
                    },
                  ),
                );
              }),
              Obx(() {
                if (!Get.isRegistered<OfflineApplyQueue>()) {
                  return const SizedBox.shrink();
                }
                final pending = Get.find<OfflineApplyQueue>().pending.length;
                if (pending <= 0) return const SizedBox.shrink();
                return _HeaderRow(
                  icon: Icons.cloud_upload_outlined,
                  color: AppColors.primaryAccent,
                  title: 'Candidatures en attente',
                  subtitle:
                      '$pending en file — appuyez pour réessayer l\'envoi',
                  badge: pending,
                  onTap: () {
                    AppHaptics.tap();
                    Get.find<OfflineApplyQueue>().flush();
                  },
                );
              }),
              _HeaderRow(
                icon: AppIcons.shieldDone,
                color: AppColors.categoryGray,
                title: 'Confidentialité',
                subtitle: 'Vos données et leur partage',
                onTap: () => _showPrivacy(context),
              ),
              _HeaderRow(
                icon: AppIcons.password,
                color: AppColors.primaryAccent,
                title: 'Changer le mot de passe',
                subtitle: 'Protégez l\'accès à votre compte',
                onTap: () {
                  AppHaptics.tap();
                  // Code envoyé à l'adresse du compte : pré-remplie.
                  final email = Get.isRegistered<ProfileController>()
                      ? Get.find<ProfileController>().profile.value?.email
                      : null;
                  Get.toNamed(
                    AppRoutes.forgotPassword,
                    arguments: (email ?? '').isEmpty ? null : {'email': email},
                  );
                },
              ),
              _HeaderRow(
                icon: Icons.devices_other_rounded,
                color: AppColors.primaryAccent,
                title: 'Déconnexion tous appareils',
                subtitle: 'Ferme les sessions ouvertes ailleurs',
                onTap: () => _confirmLogoutAll(context),
              ),
              _HeaderRow(
                icon: Icons.support_agent_rounded,
                color: AppColors.primaryAccent,
                title: 'Aide et support',
                subtitle: 'Posez vos questions à l\'assistant',
                onTap: () {
                  AppHaptics.tap();
                  Get.toNamed(AppRoutes.iaChatbot);
                },
              ),
              FutureBuilder<String>(
                future: _appVersion,
                builder: (context, snap) => _HeaderRow(
                  icon: AppIcons.info,
                  color: AppColors.primaryAccent,
                  title: 'À propos',
                  subtitle: 'Baara',
                  valueLabel: snap.hasData ? 'v${snap.data}' : null,
                  onTap: () => _showAbout(context),
                ),
              ),
            ],
          ),
          const SectionLabel('Autres'),
          _Group(
            rows: [
              _HeaderRow(
                icon: Icons.share_rounded,
                color: AppColors.primaryAccent,
                title: 'Partager l\'application',
                subtitle: 'Invitez vos proches sur Baara',
                onTap: _shareApp,
              ),
              _HeaderRow(
                icon: AppIcons.star,
                color: AppColors.primaryAccent,
                title: 'Noter l\'application',
                subtitle: 'Votre avis compte pour la communauté',
                onTap: _rateApp,
              ),
              _HeaderRow(
                icon: AppIcons.logout,
                color: AppColors.error,
                title: 'Se déconnecter',
                titleColor: AppColors.errorAccent,
                hideChevron: true,
                onTap: () => _confirmLogout(context),
              ),
              _HeaderRow(
                icon: AppIcons.delete,
                color: AppColors.error,
                title: 'Supprimer mon compte',
                subtitle: 'Efface définitivement vos données',
                titleColor: AppColors.errorAccent,
                hideChevron: true,
                onTap: () => showDeleteAccountSheet(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Feuille de choix d'apparence (Clair / Sombre) — cohérente avec la feuille
  /// Langue : un chevron sur la ligne ouvre bien un sélecteur (plus de bascule
  /// silencieuse cachée derrière un chevron trompeur).
  Future<void> _pickAppearance(
    BuildContext context,
    SettingsController settings,
    AppThemeController theme,
  ) async {
    AppHaptics.tap();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetHandle(),
              const SizedBox(height: AppSpacing.lg),
              _sheetTitle('Apparence'),
              const SizedBox(height: AppSpacing.sm),
              Obx(() => _choiceTile(
                    ctx,
                    icon: Icons.brightness_auto_rounded,
                    label: 'Système',
                    selected: theme.themeSource.value == 'system',
                    onTap: () {
                      settings.setThemeSource('system');
                    },
                  )),
              Obx(() => _choiceTile(
                    ctx,
                    icon: Icons.light_mode_rounded,
                    label: 'Clair',
                    selected: theme.themeSource.value == 'light',
                    onTap: () {
                      settings.setThemeSource('light');
                    },
                  )),
              Obx(() => _choiceTile(
                    ctx,
                    icon: Icons.dark_mode_rounded,
                    label: 'Sombre',
                    selected: theme.themeSource.value == 'dark',
                    onTap: () {
                      settings.setThemeSource('dark');
                    },
                  )),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Divider(height: 1, color: AppColors.outlineVariant),
              ),
              const SizedBox(height: AppSpacing.md),
              // Noir intense (AMOLED) — actif uniquement en sombre. En clair on
              // grise la ligne et on affiche un hint explicatif.
              Obx(() {
                final dark = theme.isDarkMode.value;
                return Opacity(
                  opacity: dark ? 1 : 0.45,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      secondary: _SquareIcon(
                        icon: Icons.contrast_rounded,
                        color: AppColors.categoryGray,
                      ),
                      title: Text(
                        'Noir intense (AMOLED)',
                        style: AppTextStyles.titleMd
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        dark
                            ? 'Fonds en vrai noir, idéal écrans OLED'
                            : 'Disponible en mode sombre',
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.hintColor, fontSize: 12),
                      ),
                      value: dark && theme.amoled.value,
                      activeThumbColor: AppColors.onPrimary,
                      activeTrackColor: AppColors.primaryMedium,
                      onChanged: dark
                          ? (v) {
                              AppHaptics.tap();
                              settings.setAmoled(v);
                            }
                          : null,
                    ),
                  ),
                );
              }),
              const SizedBox(height: AppSpacing.md),
              // Sélecteur d'accent — pastilles de presets, sélection en anneau.
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Text(
                    'Couleur d\'accent',
                    style: AppTextStyles.titleMd
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Obx(() {
                  final current = theme.accentSeed.value.toARGB32();
                  return Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      for (final preset in AppColors.accentPresets)
                        _AccentDot(
                          color: preset,
                          selected: preset.toARGB32() == current,
                          onTap: () {
                            AppHaptics.tap();
                            settings.setAccent(preset);
                          },
                        ),
                    ],
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickVisibility(
    BuildContext context,
    SettingsController settings,
  ) async {
    AppHaptics.tap();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHandle(),
            const SizedBox(height: AppSpacing.lg),
            _sheetTitle('Visibilité du profil'),
            const SizedBox(height: AppSpacing.sm),
            Obx(
              () => _choiceTile(
                ctx,
                icon: Icons.public_rounded,
                label: 'Public',
                selected: settings.profileVisibility.value != 'connections',
                onTap: () {
                  settings.setProfileVisibility('public');
                  Navigator.of(ctx).pop();
                },
              ),
            ),
            Obx(
              () => _choiceTile(
                ctx,
                icon: AppIcons.network,
                label: 'Mes connexions',
                selected: settings.profileVisibility.value == 'connections',
                onTap: () {
                  settings.setProfileVisibility('connections');
                  Navigator.of(ctx).pop();
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _sheetTitle(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Text(text,
              style:
                  AppTextStyles.titleLg.copyWith(fontWeight: FontWeight.w800)),
        ),
      );

  Widget _choiceTile(
    BuildContext ctx, {
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Material(
        color: selected
            ? AppColors.primaryAccent.withValues(alpha: 0.10)
            : Colors.transparent,
        borderRadius: AppShapes.squircleRadius(AppRadius.sm),
        child: InkWell(
          onTap: () {
            AppHaptics.tap();
            onTap();
          },
          borderRadius: AppShapes.squircleRadius(AppRadius.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withValues(alpha: 0.12),
                    borderRadius: AppShapes.squircleRadius(AppRadius.xs),
                  ),
                  child: Icon(icon, color: AppColors.primaryAccent, size: 18),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(label, style: AppTextStyles.titleMd),
                ),
                if (selected)
                  Icon(
                    AppIcons.tickSquare,
                    color: AppColors.primaryAccent,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showPrivacy(BuildContext context) async {
    AppHaptics.tap();
    await showConfirmSheet(
      context: context,
      icon: AppIcons.lock,
      iconColor: AppColors.categoryGray,
      title: 'Confidentialité',
      message:
          'Vos données (CV, candidatures, messages) ne sont partagées qu\'avec '
          'les recruteurs des offres auxquelles vous postulez. Vous gardez le '
          'contrôle et pouvez demander la suppression de votre compte à tout moment.',
      confirmLabel: 'Compris',
    );
  }

  /// Partage natif de l'application (feuille système iOS/Android).
  Future<void> _shareApp() async {
    AppHaptics.tap();
    await Share.share(
      'Découvre Baara — la plateforme emploi, formations et '
      'opportunités d\'Afrique de l\'Ouest. Télécharge l\'app et trouve ta '
      'prochaine opportunité !',
      subject: 'Baara',
    );
  }

  Future<void> _rateApp() async {
    AppHaptics.tap();
    await ReviewPromptService.instance.maybeShowPrompt(force: true);
  }

  Future<void> _showAbout(BuildContext context) async {
    AppHaptics.tap();
    final version = await _appVersion;
    if (!context.mounted) return;
    await showConfirmSheet(
      context: context,
      icon: AppIcons.info,
      iconColor: AppColors.primaryAccent,
      title: 'Baara',
      message:
          'Version $version\n\nLa plateforme emploi, formations et opportunités '
          'd\'Afrique de l\'Ouest.',
      confirmLabel: 'Fermer',
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showConfirmSheet(
      context: context,
      icon: AppIcons.logout,
      iconColor: AppColors.errorAccent,
      title: 'Se déconnecter ?',
      message: 'Vous devrez vous reconnecter pour accéder à votre compte.',
      confirmLabel: 'Se déconnecter',
      isDestructive: true,
    );
    if (confirmed == true) {
      AppHaptics.confirm();
      final controller = Get.isRegistered<ProfileController>()
          ? Get.find<ProfileController>()
          : null;
      await controller?.logout();
    }
  }

  Future<void> _confirmLogoutAll(BuildContext context) async {
    final confirmed = await showConfirmSheet(
      context: context,
      icon: Icons.devices_other_rounded,
      iconColor: AppColors.errorAccent,
      title: 'Déconnecter tous les appareils ?',
      message:
          'Toutes les sessions seront fermées. Vous devrez vous reconnecter sur cet appareil.',
      confirmLabel: 'Déconnecter partout',
      isDestructive: true,
    );
    if (confirmed == true) {
      AppHaptics.confirm();
      final controller = Get.isRegistered<ProfileController>()
          ? Get.find<ProfileController>()
          : null;
      await controller?.logoutAll();
    }
  }
}

/// Encart d'appel à l'action « vérifiez votre email ».
///
/// N'apparaît que si l'utilisateur a une adresse email non encore vérifiée.
/// Réactif : dès que la vérification aboutit (retour de l'écran de code), le
/// profil se rafraîchit et l'encart disparaît.
class _EmailVerifyBanner extends StatelessWidget {
  const _EmailVerifyBanner();

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ProfileController>()) return const SizedBox.shrink();
    final controller = Get.find<ProfileController>();

    return Obx(() {
      final profile = controller.profile.value;
      final show = profile != null &&
          profile.email.isNotEmpty &&
          !profile.isEmailVerified;
      if (!show) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: PressScale(
          onTap: () async {
            AppHaptics.tap();
            final verified = await Get.toNamed<bool>(
              AppRoutes.emailVerification,
              arguments: {'email': profile.email},
            );
            if (verified == true) {
              // Rafraîchit le profil : l'encart se retire de lui-même.
              controller.loadProfile();
            }
          },
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: ShapeDecoration(
              color: AppColors.warningAccent.withValues(alpha: 0.10),
              shape: AppShapes.cardBordered(
                AppColors.warningAccent.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Icon(AppIcons.messageFilled,
                    size: 22, color: AppColors.warningAccent),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vérifiez votre email',
                        style: AppTextStyles.titleMd.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.titleColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Confirmez ${profile.email} pour sécuriser votre compte.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.bodyColor),
                      ),
                    ],
                  ),
                ),
                ListNavChevron(
                  size: 18,
                  color: AppColors.warningAccent,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// Carte de groupe (arrondie) contenant des lignes séparées par des divisions
/// fines — comme un groupe de la liste iOS Réglages.
class _Group extends StatelessWidget {
  const _Group({required this.rows});
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      decoration: ShapeDecoration(
        color: AppColors.surfaceCard,
        shape: AppShapes.cardBordered(AppColors.outlineVariant),
        shadows: [
          ...AppColors.lightShadow,
          ...AppColors.ambientShadow,
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: i == 0 ? 60 : 18,
                endIndent: 0,
                color: AppColors.outlineVariant.withValues(alpha: 0.35),
              ),
          ],
        ],
      ),
    );
  }
}

/// Ligne-titre : icône carrée colorée + titre fort + (toggle | valeur | chevron).
class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.trailing,
    this.valueLabel,
    this.onTap,
    this.titleColor,
    this.hideChevron = false,
    this.badge = 0,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final String? valueLabel;
  final VoidCallback? onTap;
  final Color? titleColor;
  final bool hideChevron;

  /// Compteur affiché en pastille (ex. candidatures en cours). 0 = masqué.
  final int badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _SquareIcon(icon: icon, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleMd.copyWith(
                      color: titleColor ?? AppColors.titleColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.hintColor, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else ...[
              if (badge > 0)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  constraints: const BoxConstraints(minWidth: 22),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge > 99 ? '99+' : '$badge',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              if (valueLabel != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(valueLabel!,
                      style: AppTextStyles.bodyMd
                          .copyWith(color: AppColors.hintColor)),
                ),
              if (!hideChevron) const ListNavChevron(),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pastille de couleur d'accent (preset). Sélection mise en évidence par un
/// anneau ; tap → applique l'accent (live, via le ThemeController).
class _AccentDot extends StatelessWidget {
  const _AccentDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: selected ? AppColors.titleColor : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: selected ? AppColors.lightShadow : null,
        ),
        child: selected
            ? const Icon(Icons.check_rounded,
                color: AppColors.onPrimary, size: 22)
            : null,
      ),
    );
  }
}

/// Icône carrée arrondie colorée (style app iOS Réglages).
class _SquareIcon extends StatelessWidget {
  const _SquareIcon({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      // Pastille teintée : la couleur garde son sens (marque, alerte,
      // danger) sans transformer la liste en mosaïque de carrés vifs.
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppShapes.squircleRadius(AppRadius.xs),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}
