import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/theme/app_theme_controller.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import 'package:opportune_bf/routes/app_routes.dart';

import '../controllers/profile_controller.dart';

/// Paramètres — liste groupée style iOS Réglages : barre simple "Retour /
/// Paramètres", cartes blanches groupées, icônes carrées arrondies colorées,
/// lignes-titres + sous-lignes, valeurs à droite, toggles inline.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;

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

    return Scaffold(
      backgroundColor: AppColors.surfaceLow,
      body: Column(
        children: [
          const _TopBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              children: [
                // ── Compte ──────────────────────────────────────────────
                _Group(
                  rows: [
                    _HeaderRow(
                      icon: Icons.person_rounded,
                      color: AppColors.categoryBlue,
                      title: 'Compte',
                      onTap: () {
                        AppHaptics.tap();
                        Get.toNamed(AppRoutes.profileEdit);
                      },
                    ),
                    _SubRow(
                      label: 'Informations personnelles',
                      onTap: () {
                        AppHaptics.tap();
                        Get.toNamed(AppRoutes.profileEdit);
                      },
                    ),
                  ],
                ),

                // ── Notifications ───────────────────────────────────────
                _Group(
                  rows: [
                    _HeaderRow(
                      icon: Icons.notifications_rounded,
                      color: AppColors.categoryOrange,
                      title: 'Notifications',
                      trailing: Switch.adaptive(
                        value: _notifications,
                        activeThumbColor: AppColors.onPrimary,
                        activeTrackColor: AppColors.successSwitch,
                        onChanged: (v) async {
                          AppHaptics.tap();
                          setState(() => _notifications = v);
                          final ok =
                              await _persistPref({'notifications_enabled': v});
                          if (!ok && mounted) {
                            setState(() => _notifications = !v);
                          }
                        },
                      ),
                    ),
                    _SubRow(
                      label: 'Alerte sons et vibrations',
                      onTap: () => AppHaptics.tap(),
                    ),
                    _SubRow(
                      label: 'Notifications par e-mail',
                      onTap: () => AppHaptics.tap(),
                    ),
                  ],
                ),

                // ── Confidentialité ─────────────────────────────────────
                _Group(
                  rows: [
                    _HeaderRow(
                      icon: Icons.lock_rounded,
                      color: AppColors.categoryGray,
                      title: 'Confidentialité',
                      onTap: () => AppHaptics.tap(),
                    ),
                    _SubRow(
                      label: 'Gestion de la confidentialité',
                      onTap: () => AppHaptics.tap(),
                    ),
                  ],
                ),

                // ── Apparence ───────────────────────────────────────────
                Obx(
                  () => _Group(
                    rows: [
                      _HeaderRow(
                        icon: Icons.brush_rounded,
                        color: AppColors.primary,
                        title: 'Apparence',
                        valueLabel:
                            theme.isDarkMode.value ? 'Sombre' : 'Clair',
                        onTap: () {
                          AppHaptics.tap();
                          final next = !theme.isDarkMode.value;
                          theme.setDarkMode(next);
                          _persistPref({'theme': next ? 'dark' : 'light'});
                        },
                      ),
                    ],
                  ),
                ),

                // ── Langue ──────────────────────────────────────────────
                _Group(
                  rows: [
                    _HeaderRow(
                      icon: Icons.language_rounded,
                      color: AppColors.categoryBlue,
                      title: 'Langue',
                      valueLabel: 'Français',
                      onTap: () => AppHaptics.tap(),
                    ),
                    _SubRow(
                      label: 'Langue de l\'application',
                      onTap: () => AppHaptics.tap(),
                    ),
                  ],
                ),

                // ── Sécurité ────────────────────────────────────────────
                _Group(
                  rows: [
                    _HeaderRow(
                      icon: Icons.shield_rounded,
                      color: AppColors.categoryBlue,
                      title: 'Sécurité',
                      onTap: () => AppHaptics.tap(),
                    ),
                    _SubRow(
                      label: 'Changer le mot de passe',
                      onTap: () => AppHaptics.tap(),
                    ),
                  ],
                ),

                // ── À propos ────────────────────────────────────────────
                _Group(
                  rows: [
                    _HeaderRow(
                      icon: Icons.info_rounded,
                      color: AppColors.categoryBlue,
                      title: 'À propos',
                      valueLabel: 'v1.0.0',
                      onTap: () => AppHaptics.tap(),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Déconnexion ─────────────────────────────────────────
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
          ),
        ],
      ),
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
      padding: EdgeInsets.fromLTRB(4, topPad + 6, 4, 10),
      color: AppColors.surfaceLow,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                AppHaptics.tap();
                Get.back<void>();
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              label: Text('Retour',
                  style: AppTextStyles.titleMd
                      .copyWith(color: AppColors.primary)),
            ),
          ),
          Text('Paramètres',
              style: AppTextStyles.titleLg
                  .copyWith(fontWeight: FontWeight.w800)),
        ],
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
    this.trailing,
    this.valueLabel,
    this.onTap,
    this.titleColor,
    this.hideChevron = false,
  });

  final IconData icon;
  final Color color;
  final String title;
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
              child: Text(
                title,
                style: AppTextStyles.titleMd.copyWith(
                  color: titleColor ?? AppColors.titleColor,
                  fontWeight: FontWeight.w800,
                ),
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

/// Sous-ligne (indentée sous une ligne-titre) : label + valeur/chevron.
class _SubRow extends StatelessWidget {
  const _SubRow({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 15, 14, 15),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: AppTextStyles.bodyMd
                      .copyWith(color: AppColors.titleColor)),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.outlineVariant),
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
