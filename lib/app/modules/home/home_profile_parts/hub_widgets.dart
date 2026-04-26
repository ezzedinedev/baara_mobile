part of '../home_profile_tab.dart';

/// Hero du profil — avatar centré + pill Édit + nom + ID + badge membre.
/// Inspiré du mockup demandé : minimaliste, focalisé sur l'identité.
class _ProfileHubHeader extends StatelessWidget {
  const _ProfileHubHeader({
    required this.profile,
    required this.isUploadingAvatar,
    required this.onLogout,
    required this.onEditAvatar,
    required this.onEditProfile,
  });

  final HomeUserProfile profile;
  final bool isUploadingAvatar;
  final VoidCallback onLogout;
  final VoidCallback onEditAvatar;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        WavyContentHeader(
          title: 'profile.title'.tr,
          subtitle: 'profile.subtitle'.tr,
          height: 220,
          showLeading: false,
          gradient: AppColors.heroProfileGradient,
          actions: [
            WavyHeaderActionButton(
              icon: Icons.logout_rounded,
              onTap: () {
                AppHaptics.tap();
                onLogout();
              },
            ),
          ],
        ),
        Transform.translate(
          offset: const Offset(0, -50),
          child: Column(
            children: [
              _AvatarWithEdit(
                profile: profile,
                isUploadingAvatar: isUploadingAvatar,
                onEditAvatar: onEditAvatar,
                onEditProfile: onEditProfile,
              ),
              const SizedBox(height: 14),
              Text(
                profile.fullName,
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineLg.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (profile.id.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'ID : ${profile.id}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.bodyColor,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              _MemberBadge(isVerified: profile.isVerified),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvatarWithEdit extends StatelessWidget {
  const _AvatarWithEdit({
    required this.profile,
    required this.isUploadingAvatar,
    required this.onEditAvatar,
    required this.onEditProfile,
  });

  final HomeUserProfile profile;
  final bool isUploadingAvatar;
  final VoidCallback onEditAvatar;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceIconSoft,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  width: 2,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: profile.hasAvatar
                  ? CachedNetworkImage(
                      imageUrl: profile.avatarUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.person_rounded,
                        color: AppColors.primary,
                        size: 56,
                      ),
                    )
                  : const Icon(
                      Icons.person_rounded,
                      color: AppColors.primary,
                      size: 56,
                    ),
            ),
            GestureDetector(
              onTap: () {
                AppHaptics.tap();
                onEditAvatar();
              },
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.surfaceCard,
                    width: 2,
                  ),
                ),
                child: isUploadingAvatar
                    ? const Padding(
                        padding: EdgeInsets.all(7),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            AppColors.onPrimary,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.photo_camera_rounded,
                        color: AppColors.onPrimary,
                        size: 16,
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            AppHaptics.tap();
            onEditProfile();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.surfaceIconSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.edit_rounded,
                  color: AppColors.primary,
                  size: 13,
                ),
                const SizedBox(width: 5),
                Text(
                  'Éditer',
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MemberBadge extends StatelessWidget {
  const _MemberBadge({required this.isVerified});
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    final label = isVerified ? 'Membre vérifié' : 'Membre standard';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isVerified
            ? AppColors.successSoftAlt
            : AppColors.warningSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified
                ? Icons.verified_rounded
                : Icons.workspace_premium_rounded,
            color: isVerified ? AppColors.verified : AppColors.warning,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(
              color: isVerified ? AppColors.verified : AppColors.warning,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section de paramètres : titre + liste de [_SettingsItem].
class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.children,
    this.title = 'Paramètres',
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: AppTextStyles.titleLg.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.18),
              ),
            ),
            child: Column(
              children: _intersperse(children),
            ),
          ),
        ],
      ),
    );
  }

  /// Insère un séparateur fin entre chaque item.
  List<Widget> _intersperse(List<Widget> items) {
    final result = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      result.add(items[i]);
      if (i < items.length - 1) {
        result.add(Container(
          height: 1,
          margin: const EdgeInsets.only(left: 56),
          color: AppColors.outlineVariant.withValues(alpha: 0.14),
        ));
      }
    }
    return result;
  }
}

/// Item d'un menu de paramètres : icône colorée + label + valeur/chevron.
class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                AppHaptics.tap();
                onTap!();
              },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.titleMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.titleColor,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.hintColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Trailing texte gris (ex: "Français", "Clair") pour [_SettingsItem].
class _SettingsTrailingText extends StatelessWidget {
  const _SettingsTrailingText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.bodySm.copyWith(
        color: AppColors.bodyColor,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// Bottom sheet pour ajuster les notifications (basé sur les toggles existants).
class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet({
    required this.preferences,
    required this.manager,
    required this.onChanged,
  });

  final HomeProfilePreferences preferences;
  final HomeProfileManager manager;
  final ValueChanged<HomeProfilePreferences> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceHighest,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Text('Notifications', style: AppTextStyles.titleLg),
          const SizedBox(height: 14),
          Obx(() => _PreferencesCard(
                preferences: manager.preferences.value,
                isBusy: manager.isSavingPreferences.value,
                onChanged: onChanged,
              )),
        ],
      ),
    );
  }
}

/// Bottom sheet générique pour piquer une valeur dans un Map<key, label>.
class _ChoiceSheet extends StatelessWidget {
  const _ChoiceSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String title;
  final Map<String, String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceHighest,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Text(title, style: AppTextStyles.titleLg),
          const SizedBox(height: 14),
          ...options.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ChoiceTile(
                label: entry.value,
                selected: selected == entry.key,
                onTap: () => onSelected(entry.key),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.surfaceSelected
              : AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.outlineVariant.withValues(alpha: 0.22),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.titleMd.copyWith(
                  color: selected
                      ? AppColors.primary
                      : AppColors.titleColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? AppColors.primary
                      : AppColors.outlineVariant,
                  width: selected ? 6.5 : 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal "Profil mis à jour" — affichée après un `Save Change` réussi.
/// Reproduit le mockup : check icon centré, titre, message, bouton OK.
Future<void> showProfileUpdatedDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: AppColors.onDark.withValues(alpha: 0.62),
    builder: (ctx) => Dialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SuccessCheckPulse(),
            const SizedBox(height: 18),
            Text(
              'Profil mis à jour',
              style: AppTextStyles.headlineMd.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Félicitations 🎉, votre profil a bien été enregistré.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.bodyColor,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                onPressed: () {
                  AppHaptics.tap();
                  Navigator.of(ctx).pop();
                },
                child: Text(
                  'Merci',
                  style: AppTextStyles.buttonLg.copyWith(
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SuccessCheckPulse extends StatefulWidget {
  @override
  State<_SuccessCheckPulse> createState() => _SuccessCheckPulseState();
}

class _SuccessCheckPulseState extends State<_SuccessCheckPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
      ),
      child: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          color: AppColors.surfaceIconSoft,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.32),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.check_rounded,
            color: AppColors.onPrimary,
            size: 30,
          ),
        ),
      ),
    );
  }
}
