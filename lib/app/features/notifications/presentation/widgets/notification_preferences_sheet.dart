import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import 'package:jobaway/app/core/theme/app_colors.dart';
import 'package:jobaway/app/core/theme/app_dimens.dart';
import 'package:jobaway/app/core/theme/app_shapes.dart';
import 'package:jobaway/app/core/theme/app_text_styles.dart';
import 'package:jobaway/app/core/utils/haptics.dart';
import 'package:jobaway/app/core/widgets/widgets.dart';
import 'package:jobaway/app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:jobaway/app/features/profile/presentation/controllers/settings_controller.dart';

/// Catalogue des canaux de notification (clés = clés backend de
/// [SettingsController.notifChannels]). Source unique partagée par l'écran
/// Paramètres et l'écran Notifications.
const _channels = <String, ({IconData icon, Color color, String label})>{
  'offer_updates': (
    icon: IconlyLight.work,
    color: AppColors.categoryBlue,
    label: 'Nouvelles offres'
  ),
  'application_updates': (
    icon: IconlyLight.paper,
    color: AppColors.successDark,
    label: 'Suivi des candidatures'
  ),
  'match_alerts': (
    icon: Icons.auto_awesome_rounded,
    color: AppColors.secondary,
    label: 'Suggestions IA'
  ),
  'message_alerts': (
    icon: IconlyLight.message,
    color: AppColors.primary,
    label: 'Messages'
  ),
  'training_updates': (
    icon: Icons.school_outlined,
    color: AppColors.categoryOrange,
    label: 'Formations'
  ),
};

/// Feuille de préférences de notifications — un interrupteur maître + un canal
/// par type d'alerte. Chaque bascule persiste via [SettingsController] (local +
/// backend `PUT /profile/preferences`). Réutilisée par Paramètres et par le
/// bouton engrenage de l'écran Notifications.
Future<void> showNotificationPreferencesSheet(BuildContext context) async {
  AppHaptics.tap();
  final settings = Get.isRegistered<SettingsController>()
      ? Get.find<SettingsController>()
      : Get.put(SettingsController(Get.find<ProfileController>()));

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceCard,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            const SizedBox(height: AppSpacing.lg),
            Text('Notifications',
                style: AppTextStyles.titleLg
                    .copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Choisissez les alertes que vous souhaitez recevoir.',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.hintColor),
            ),
            const SizedBox(height: AppSpacing.md),
            Obx(
              () => SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text('Activer les notifications',
                    style: AppTextStyles.titleMd
                        .copyWith(fontWeight: FontWeight.w700)),
                value: settings.notificationsEnabled.value,
                activeThumbColor: AppColors.onPrimary,
                activeTrackColor: AppColors.successSwitch,
                onChanged: (v) {
                  AppHaptics.tap();
                  settings.setNotificationsEnabled(v);
                },
              ),
            ),
            Divider(height: 1, color: AppColors.outlineVariant),
            for (final entry in _channels.entries)
              Obx(
                () => SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  secondary: _SquareIcon(
                      icon: entry.value.icon, color: entry.value.color),
                  title: Text(entry.value.label,
                      style: AppTextStyles.titleMd
                          .copyWith(fontWeight: FontWeight.w600)),
                  value: settings.notificationsEnabled.value &&
                      (settings.notifPrefs[entry.key] ?? true),
                  activeThumbColor: AppColors.onPrimary,
                  activeTrackColor: AppColors.successSwitch,
                  onChanged: !settings.notificationsEnabled.value
                      ? null
                      : (v) {
                          AppHaptics.tap();
                          settings.setChannel(entry.key, v);
                        },
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// Icône carrée arrondie colorée (style iOS Réglages).
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
