import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:share_plus/share_plus.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_motion.dart';
import 'package:opportune_bf/app/core/theme/app_shapes.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/theme/app_theme_controller.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import 'package:opportune_bf/app/features/notifications/presentation/widgets/notification_preferences_sheet.dart';
import 'package:opportune_bf/routes/app_routes.dart';

import 'package:opportune_bf/app/features/offers/presentation/controllers/offer_controller.dart';
import '../controllers/profile_controller.dart';
import '../controllers/settings_controller.dart';

/// Paramètres — liste groupée style iOS Réglages : en-tête simple, cartes
/// groupées, icônes carrées arrondies colorées, lignes-titres + sous-lignes.
///
/// Règle d'affordance unifiée :
/// - **chevron** → ouvre une page ou une feuille de choix ;
/// - **interrupteur inline** → bascule binaire instantanée.
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
                icon: IconlyLight.profile,
                color: AppColors.categoryBlue,
                title: 'Informations personnelles',
                subtitle: 'Gérez les détails de votre compte',
                onTap: () {
                  AppHaptics.tap();
                  Get.toNamed(AppRoutes.profileEdit);
                },
              ),
              _HeaderRow(
                icon: IconlyLight.work,
                color: AppColors.categoryPurple,
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
                  icon: IconlyLight.paper,
                  color: AppColors.successDark,
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
          const SectionLabel('Abonnement'),
          _Group(
            rows: [
              _HeaderRow(
                icon: IconlyLight.wallet,
                color: AppColors.categoryPurple,
                title: 'Mon abonnement',
                subtitle: 'Forfait, avantages et facturation',
                onTap: () {
                  AppHaptics.tap();
                  Get.toNamed(AppRoutes.subscription);
                },
              ),
            ],
          ),
          const SectionLabel('Préférences'),
          _Group(
            rows: [
              Obx(
                () => _HeaderRow(
                  icon: IconlyLight.notification,
                  color: AppColors.categoryOrange,
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
                  icon: IconlyLight.show,
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
              // Pas d'Obx : Get.locale n'est pas un observable .obs ; changer la
              // langue déclenche déjà un rebuild global via GetMaterialApp.
              _HeaderRow(
                icon: IconlyLight.message,
                color: AppColors.categoryBlue,
                title: 'Langue',
                subtitle: 'Langue de l\'application',
                valueLabel:
                    Get.locale?.languageCode == 'en' ? 'English' : 'Français',
                onTap: () => _pickLanguage(context, settings),
              ),
            ],
          ),
          const SectionLabel('Communauté & réseau'),
          _Group(
            rows: [
              _HeaderRow(
                icon: IconlyLight.discovery,
                color: AppColors.primary,
                title: 'Mon fil communauté',
                subtitle: 'Publications et professionnels à suivre',
                onTap: () {
                  AppHaptics.tap();
                  Get.toNamed(AppRoutes.community);
                },
              ),
              _HeaderRow(
                icon: IconlyLight.show,
                color: AppColors.categoryCyan,
                title: 'Vues de profil',
                subtitle: 'Qui a consulté votre profil',
                onTap: () {
                  AppHaptics.tap();
                  Get.toNamed(AppRoutes.communityProfileViews);
                },
              ),
              Obx(
                () => _HeaderRow(
                  icon: IconlyLight.unlock,
                  color: AppColors.categoryPurple,
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
                  icon: IconlyLight.activity,
                  color: AppColors.secondary,
                  title: 'Activité du réseau',
                  subtitle: 'Abonnés, mentions et publications',
                  trailing: Switch.adaptive(
                    value: settings.networkActivity.value,
                    activeThumbColor: AppColors.onPrimary,
                    activeTrackColor: AppColors.successSwitch,
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
              _HeaderRow(
                icon: IconlyLight.shield_done,
                color: AppColors.categoryGray,
                title: 'Confidentialité',
                subtitle: 'Vos données et leur partage',
                onTap: () => _showPrivacy(context),
              ),
              _HeaderRow(
                icon: IconlyLight.password,
                color: AppColors.categoryBlue,
                title: 'Changer le mot de passe',
                subtitle: 'Protégez l\'accès à votre compte',
                onTap: () {
                  AppHaptics.tap();
                  Get.toNamed(AppRoutes.forgotPassword);
                },
              ),
              _HeaderRow(
                icon: Icons.devices_other_rounded,
                color: AppColors.categoryOrange,
                title: 'Déconnexion tous appareils',
                subtitle: 'Ferme les sessions ouvertes ailleurs',
                onTap: () => _confirmLogoutAll(context),
              ),
              _HeaderRow(
                icon: Icons.support_agent_rounded,
                color: AppColors.categoryCyan,
                title: 'Aide et support',
                subtitle: 'Posez vos questions à l\'assistant',
                onTap: () {
                  AppHaptics.tap();
                  Get.toNamed(AppRoutes.iaChatbot);
                },
              ),
              _HeaderRow(
                icon: IconlyLight.info_circle,
                color: AppColors.categoryBlue,
                title: 'À propos',
                subtitle: 'OpporTune BF',
                valueLabel: 'v1.0.0',
                onTap: () => _showAbout(context),
              ),
            ],
          ),
          const SectionLabel('Autres'),
          _Group(
            rows: [
              _HeaderRow(
                icon: Icons.share_rounded,
                color: AppColors.primary,
                title: 'Partager l\'application',
                subtitle: 'Invitez vos proches sur OpporTune',
                onTap: _shareApp,
              ),
              _HeaderRow(
                icon: IconlyLight.logout,
                color: AppColors.error,
                title: 'Se déconnecter',
                titleColor: AppColors.errorAccent,
                hideChevron: true,
                onTap: () => _confirmLogout(context),
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
                      activeTrackColor: AppColors.successSwitch,
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

  Future<void> _pickLanguage(
    BuildContext context,
    SettingsController settings,
  ) async {
    AppHaptics.tap();
    final current = Get.locale?.languageCode == 'en' ? 'en' : 'fr';
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
            _sheetTitle('Langue'),
            const SizedBox(height: AppSpacing.sm),
            _choiceTile(
              ctx,
              icon: Icons.language_rounded,
              label: 'Français',
              selected: current == 'fr',
              onTap: () {
                settings.setLanguage('fr');
                Navigator.of(ctx).pop();
              },
            ),
            _choiceTile(
              ctx,
              icon: Icons.language_rounded,
              label: 'English',
              selected: current == 'en',
              onTap: () {
                settings.setLanguage('en');
                Navigator.of(ctx).pop();
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  /// Feuille de choix de visibilité du profil communauté (Public / Mes
  /// connexions) — même pattern que les autres sélecteurs de préférences.
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
                icon: IconlyLight.user,
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
                    IconlyLight.tick_square,
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
      icon: IconlyLight.lock,
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
      'Découvre OpporTune BF — la plateforme emploi, formations et '
      'opportunités d\'Afrique de l\'Ouest. Télécharge l\'app et trouve ta '
      'prochaine opportunité !',
      subject: 'OpporTune BF',
    );
  }

  Future<void> _showAbout(BuildContext context) async {
    AppHaptics.tap();
    await showConfirmSheet(
      context: context,
      icon: IconlyLight.info_circle,
      iconColor: AppColors.primaryAccent,
      title: 'OpporTune BF',
      message:
          'Version 1.0.0\n\nLa plateforme emploi, formations et opportunités '
          'd\'Afrique de l\'Ouest.',
      confirmLabel: 'Fermer',
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showConfirmSheet(
      context: context,
      icon: IconlyLight.logout,
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
              if (!hideChevron)
                Icon(IconlyLight.arrow_right_2,
                    color: AppColors.outlineVariant),
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
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppShapes.squircleRadius(AppRadius.xs),
      ),
      child: Icon(icon, color: AppColors.onPrimary, size: 19),
    );
  }
}
