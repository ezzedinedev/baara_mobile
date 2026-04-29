part of '../home_profile_tab.dart';

// ignore: unused_element
class _ContactGrid extends StatelessWidget {
  const _ContactGrid({required this.profile});

  final HomeUserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _InfoTileCard(
                icon: Icons.mail_outline_rounded,
                color: AppColors.categoryBlue,
                title: 'Email',
                value: profile.email.isEmpty ? 'Non renseigne' : profile.email,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoTileCard(
                icon: Icons.phone_in_talk_outlined,
                color: AppColors.successDark,
                title: 'Telephone',
                value: profile.phone.isEmpty ? 'Non renseigne' : profile.phone,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _InfoTileCard(
                icon: Icons.pin_drop_outlined,
                color: AppColors.categoryOrangeDeep,
                title: 'Ville',
                value: profile.city.isEmpty ? 'Non renseignee' : profile.city,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoTileCard(
                icon: Icons.map_outlined,
                color: AppColors.categoryPurple,
                title: 'Region',
                value:
                    profile.region.isEmpty ? 'Non renseignee' : profile.region,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoTileCard extends StatelessWidget {
  const _InfoTileCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 12),
          Text(title, style: AppTextStyles.bodySm),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.titleMd.copyWith(color: AppColors.primaryDark),
          ),
        ],
      ),
    );
  }
}

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard({
    required this.preferences,
    required this.isBusy,
    required this.onChanged,
  });

  final HomeProfilePreferences preferences;
  final bool isBusy;
  final ValueChanged<HomeProfilePreferences> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        children: [
          _PreferenceSwitchRow(
            icon: IconlyLight.notification,
            color: AppColors.categoryOrange,
            title: 'Notifications',
            subtitle: 'Alertes, messages et mises a jour',
            value: preferences.notificationsEnabled,
            isBusy: isBusy,
            onChanged: (value) =>
                onChanged(preferences.copyWith(notificationsEnabled: value)),
          ),
          const SizedBox(height: 8),
          _PreferenceSwitchRow(
            icon: IconlyLight.bookmark,
            color: AppColors.categoryBlue,
            title: 'Nouvelles offres',
            subtitle: 'Offres ciblees selon votre profil',
            value: preferences.offerUpdates,
            isBusy: isBusy || !preferences.notificationsEnabled,
            onChanged: (value) =>
                onChanged(preferences.copyWith(offerUpdates: value)),
          ),
          const SizedBox(height: 8),
          _PreferenceSwitchRow(
            icon: IconlyLight.chat,
            color: AppColors.successDark,
            title: 'Messages recruteurs',
            subtitle: 'Conversations et relances',
            value: preferences.messageAlerts,
            isBusy: isBusy || !preferences.notificationsEnabled,
            onChanged: (value) =>
                onChanged(preferences.copyWith(messageAlerts: value)),
          ),
          const SizedBox(height: 8),
          _PreferenceSwitchRow(
            icon: IconlyLight.paper,
            color: AppColors.categoryPurple,
            title: 'Formations',
            subtitle: 'Parcours et certifications',
            value: preferences.trainingUpdates,
            isBusy: isBusy || !preferences.notificationsEnabled,
            onChanged: (value) =>
                onChanged(preferences.copyWith(trainingUpdates: value)),
          ),
          const SizedBox(height: 10),
          _ChoiceRow(
            // Iconly n'a pas d'icone "globe" — fallback sur Material
            // public_outlined (cercle de meridiens) qui reste tres proche
            // visuellement des outlines Iconly et coherent avec les autres.
            icon: Icons.public_outlined,
            color: AppColors.categoryCyan,
            title: 'profile.language'.tr,
            subtitle: 'Choisissez la langue d\'affichage',
            options: {
              'fr': 'profile.lang_fr'.tr,
              'en': 'profile.lang_en'.tr,
            },
            selected: preferences.language,
            isBusy: isBusy,
            onSelected: (value) {
              // Switch live l'UI (Get.updateLocale) puis persiste la pref.
              applyAppLocale(value);
              onChanged(preferences.copyWith(language: value));
            },
          ),
          const SizedBox(height: 10),
          _ChoiceRow(
            // Iconly n'a pas d'icone "contraste/theme" → on utilise show
            // (œil) qui evoque l'aspect visuel/affichage. Pas parfait mais
            // proche stylistiquement des autres outlines Iconly.
            icon: IconlyLight.show,
            color: AppColors.categoryGray,
            title: 'profile.theme'.tr,
            subtitle: 'Preference synchronisee',
            options: {
              'light': 'profile.theme_light'.tr,
              'dark': 'profile.theme_dark'.tr,
            },
            selected: preferences.theme,
            isBusy: isBusy,
            onSelected: (value) =>
                onChanged(preferences.copyWith(theme: value)),
          ),
        ],
      ),
    );
  }
}

class _PreferenceSwitchRow extends StatelessWidget {
  const _PreferenceSwitchRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.isBusy,
    required this.onChanged,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final bool isBusy;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _SquareIconBadge(icon: icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleMd),
                Text(subtitle, style: AppTextStyles.bodySm),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: isBusy ? null : onChanged,
            activeThumbColor: AppColors.onPrimary,
            activeTrackColor: AppColors.primaryMedium,
          ),
        ],
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selected,
    required this.isBusy,
    required this.onSelected,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Map<String, String> options;
  final String selected;
  final bool isBusy;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(18),
      ),
      // Layout vertical : icone + (titre/sous-titre + chips dessous).
      // Avant, les chips et le titre etaient cote-a-cote dans un Row →
      // sur ecran etroit, le Wrap des chips prenait toute la largeur
      // naturelle et ecrasait l'Expanded du titre a 10px → titre rendu
      // 1 caractere par ligne (vertical).
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SquareIconBadge(icon: icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleMd),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySm,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: options.entries
                      .map(
                        (entry) => ChoiceChip(
                          label: Text(entry.value),
                          selected: selected == entry.key,
                          onSelected:
                              isBusy ? null : (_) => onSelected(entry.key),
                          selectedColor: color.withValues(alpha: 0.16),
                          labelStyle: AppTextStyles.bodySm.copyWith(
                            color: selected == entry.key
                                ? color
                                : AppColors.bodyColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

