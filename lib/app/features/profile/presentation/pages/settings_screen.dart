import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/theme/app_theme_controller.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import 'package:opportune_bf/app/translations/app_translations.dart';
import 'package:opportune_bf/routes/app_routes.dart';

import '../controllers/profile_controller.dart';

/// Paramètres — liste groupée style iOS Réglages : barre simple "Retour /
/// Paramètres", cartes blanches groupées, icônes carrées arrondies colorées,
/// lignes-titres + sous-lignes, valeurs à droite, toggles inline.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLow,
      body: Column(
        children: const [
          _TopBar(),
          Expanded(child: SingleChildScrollView(child: SettingsBody())),
        ],
      ),
    );
  }
}

/// Corps des réglages (Compte / Préférences / Sécurité / À propos / …).
/// Réutilisable : écran Paramètres autonome ET intégré sous le hero du Profil.
class SettingsBody extends StatefulWidget {
  const SettingsBody({super.key});

  @override
  State<SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends State<SettingsBody> {
  bool _notifications = true;
  bool _networkActivity = false;

  // Préférences de notification granulaires (clés backend existantes).
  final _notifPrefs = <String, bool>{
    'offer_updates': true,
    'application_updates': true,
    'match_alerts': true,
    'message_alerts': true,
    'training_updates': true,
  };

  /// Persiste une préférence côté backend (PUT /profile/preferences).
  Future<bool> _persistPref(Map<String, dynamic> prefs) async {
    final controller = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : null;
    if (controller == null) return false;
    return controller.updatePreferences(prefs);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<AppThemeController>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
                // Tout sur un seul écran, mais regroupé par thème (libellés
                // non cliquables) pour un classement clair.
                const _GroupLabel('Compte'),
                _Group(
                  rows: [
                    _HeaderRow(
                      icon: Icons.person_rounded,
                      color: AppColors.categoryBlue,
                      title: 'Informations personnelles',
                      onTap: () {
                        AppHaptics.tap();
                        Get.toNamed(AppRoutes.profileEdit);
                      },
                    ),
                    _HeaderRow(
                      icon: Icons.work_rounded,
                      color: AppColors.categoryPurple,
                      title: 'Expériences & formations',
                      onTap: () {
                        AppHaptics.tap();
                        Get.toNamed(AppRoutes.profileParcours);
                      },
                    ),
                    _HeaderRow(
                      icon: Icons.folder_rounded,
                      color: AppColors.categoryCyan,
                      title: 'Mes documents',
                      onTap: () {
                        AppHaptics.tap();
                        Get.toNamed(AppRoutes.profileDocuments);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const _GroupLabel('Préférences'),
                _Group(
                  rows: [
                    _HeaderRow(
                      icon: Icons.notifications_rounded,
                      color: AppColors.categoryOrange,
                      title: 'Notifications',
                      valueLabel: _notifications ? 'Activées' : 'Désactivées',
                      onTap: () => _openNotifications(context),
                    ),
                    Obx(
                      () => _HeaderRow(
                        icon: Icons.brush_rounded,
                        color: AppColors.primary,
                        title: 'Apparence',
                        valueLabel: theme.isDarkMode.value ? 'Sombre' : 'Clair',
                        onTap: () {
                          AppHaptics.tap();
                          final next = !theme.isDarkMode.value;
                          theme.setDarkMode(next);
                          _persistPref({'theme': next ? 'dark' : 'light'});
                        },
                      ),
                    ),
                    _HeaderRow(
                      icon: Icons.language_rounded,
                      color: AppColors.categoryBlue,
                      title: 'Langue',
                      valueLabel: Get.locale?.languageCode == 'en'
                          ? 'English'
                          : 'Français',
                      onTap: () => _pickLanguage(context),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const _GroupLabel('Communauté & réseau'),
                _Group(
                  rows: [
                    _HeaderRow(
                      icon: Icons.groups_rounded,
                      color: AppColors.primary,
                      title: 'Mon fil communauté',
                      onTap: () {
                        AppHaptics.tap();
                        Get.toNamed(AppRoutes.community);
                      },
                    ),
                    _HeaderRow(
                      icon: Icons.diversity_3_rounded,
                      color: AppColors.secondary,
                      title: 'Activité du réseau',
                      subtitle: 'Abonnés, mentions et publications',
                      trailing: Switch.adaptive(
                        value: _networkActivity,
                        activeThumbColor: AppColors.onPrimary,
                        activeTrackColor: AppColors.successSwitch,
                        onChanged: (v) async {
                          AppHaptics.tap();
                          setState(() => _networkActivity = v);
                          final ok = await _persistPref({'team_activity': v});
                          if (!ok && mounted) {
                            setState(() => _networkActivity = !v);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const _GroupLabel('Sécurité & confidentialité'),
                _Group(
                  rows: [
                    _HeaderRow(
                      icon: Icons.lock_rounded,
                      color: AppColors.categoryGray,
                      title: 'Confidentialité',
                      onTap: () => _showPrivacy(context),
                    ),
                    _HeaderRow(
                      icon: Icons.shield_rounded,
                      color: AppColors.categoryBlue,
                      title: 'Changer le mot de passe',
                      onTap: () {
                        AppHaptics.tap();
                        Get.toNamed(AppRoutes.forgotPassword);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const _GroupLabel('À propos'),
                _Group(
                  rows: [
                    _HeaderRow(
                      icon: Icons.info_rounded,
                      color: AppColors.categoryBlue,
                      title: 'Version',
                      valueLabel: 'v1.0.0',
                      onTap: () => _showAbout(context),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _Group(
                  rows: [
                    _HeaderRow(
                      icon: Icons.logout_rounded,
                      color: AppColors.error,
                      title: 'Se déconnecter',
                      titleColor: AppColors.error,
                      hideChevron: true,
                      onTap: () => _confirmLogout(context),
                    ),
                  ],
                ),
              ],
            ),
          );
  }

  /// Feuille de notifications granulaire — un interrupteur maître + les
  /// canaux (offres, candidatures, suggestions IA, messages, formations).
  /// Chaque bascule persiste immédiatement via PUT /profile/preferences.
  Future<void> _openNotifications(BuildContext context) async {
    AppHaptics.tap();
    const channels = <String, ({IconData icon, Color color, String label})>{
      'offer_updates': (icon: Icons.work_outline_rounded, color: AppColors.categoryBlue, label: 'Nouvelles offres'),
      'application_updates': (icon: Icons.assignment_turned_in_outlined, color: AppColors.successDark, label: 'Suivi des candidatures'),
      'match_alerts': (icon: Icons.auto_awesome_rounded, color: AppColors.secondary, label: 'Suggestions IA'),
      'message_alerts': (icon: Icons.chat_bubble_outline_rounded, color: AppColors.primary, label: 'Messages'),
      'training_updates': (icon: Icons.school_outlined, color: AppColors.categoryOrange, label: 'Formations'),
    };

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Notifications',
                    style: AppTextStyles.titleLg
                        .copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Activer les notifications',
                      style: AppTextStyles.titleMd
                          .copyWith(fontWeight: FontWeight.w700)),
                  value: _notifications,
                  activeThumbColor: AppColors.onPrimary,
                  activeTrackColor: AppColors.successSwitch,
                  onChanged: (v) async {
                    AppHaptics.tap();
                    setSheet(() => _notifications = v);
                    setState(() => _notifications = v);
                    final ok = await _persistPref({'notifications_enabled': v});
                    if (!ok) {
                      setSheet(() => _notifications = !v);
                      if (mounted) setState(() => _notifications = !v);
                    }
                  },
                ),
                const Divider(height: 1),
                for (final entry in channels.entries)
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    secondary: _SquareIcon(
                        icon: entry.value.icon, color: entry.value.color),
                    title: Text(entry.value.label,
                        style: AppTextStyles.titleMd
                            .copyWith(fontWeight: FontWeight.w600)),
                    value: _notifications && (_notifPrefs[entry.key] ?? true),
                    activeThumbColor: AppColors.onPrimary,
                    activeTrackColor: AppColors.successSwitch,
                    onChanged: !_notifications
                        ? null
                        : (v) async {
                            AppHaptics.tap();
                            setSheet(() => _notifPrefs[entry.key] = v);
                            setState(() => _notifPrefs[entry.key] = v);
                            final ok = await _persistPref({entry.key: v});
                            if (!ok) {
                              setSheet(() => _notifPrefs[entry.key] = !v);
                              if (mounted) {
                                setState(() => _notifPrefs[entry.key] = !v);
                              }
                            }
                          },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickLanguage(BuildContext context) async {
    AppHaptics.tap();
    final current = Get.locale?.languageCode == 'en' ? 'en' : 'fr';
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Langue',
                    style: AppTextStyles.titleLg
                        .copyWith(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 8),
            _langTile(ctx, label: 'Français', code: 'fr', current: current),
            _langTile(ctx, label: 'English', code: 'en', current: current),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _langTile(
    BuildContext ctx, {
    required String label,
    required String code,
    required String current,
  }) {
    final selected = current == code;
    return ListTile(
      leading: const Icon(Icons.language_rounded, color: AppColors.primary),
      title: Text(label, style: AppTextStyles.titleMd),
      trailing: selected
          ? const Icon(Icons.check_rounded, color: AppColors.primary)
          : null,
      onTap: () {
        AppHaptics.tap();
        applyAppLocale(code);
        _persistPref({'language': code});
        Navigator.of(ctx).pop();
        if (mounted) setState(() {});
      },
    );
  }

  Future<void> _showPrivacy(BuildContext context) async {
    AppHaptics.tap();
    await showConfirmSheet(
      context: context,
      icon: Icons.lock_rounded,
      iconColor: AppColors.categoryGray,
      title: 'Confidentialité',
      message:
          'Vos données (CV, candidatures, messages) ne sont partagées qu\'avec '
          'les recruteurs des offres auxquelles vous postulez. Vous gardez le '
          'contrôle et pouvez demander la suppression de votre compte à tout moment.',
      confirmLabel: 'Compris',
    );
  }

  Future<void> _showAbout(BuildContext context) async {
    AppHaptics.tap();
    await showConfirmSheet(
      context: context,
      icon: Icons.info_rounded,
      iconColor: AppColors.primary,
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
      icon: Icons.logout_rounded,
      iconColor: AppColors.error,
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
}

/// Barre supérieure simple : "‹ Retour" à gauche, titre centré.
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(12, topPad + 6, 12, 10),
      color: AppColors.surfaceLow,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: AppBackButton(onTap: () => Get.back<void>()),
          ),
          Text('Paramètres',
              style: AppTextStyles.titleLg
                  .copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

/// Libellé de section (non cliquable) au-dessus d'un groupe de réglages.
class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.labelSm.copyWith(
          color: AppColors.hintColor,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

/// Carte de groupe (blanche, arrondie) contenant des lignes séparées par
/// des divisions fines — comme un groupe de la liste iOS Réglages.
class _Group extends StatelessWidget {
  const _Group({required this.rows});
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.lightShadow,
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

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
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
              if (valueLabel != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(valueLabel!,
                      style: AppTextStyles.bodyMd
                          .copyWith(color: AppColors.hintColor)),
                ),
              if (!hideChevron)
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.outlineVariant),
            ],
          ],
        ),
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
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: AppColors.onPrimary, size: 19),
    );
  }
}
