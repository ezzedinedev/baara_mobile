part of '../home_profile_tab.dart';

// ignore: unused_element
class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.22),
          ),
        ),
        child: Icon(icon, color: AppColors.primaryDark),
      ),
    );
  }
}

// ignore: unused_element
class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.profile,
    required this.isUploadingAvatar,
    required this.onEditAvatar,
  });

  final HomeUserProfile profile;
  final bool isUploadingAvatar;
  final VoidCallback onEditAvatar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.profileGradientTop,
            AppColors.profileGradientMid,
            AppColors.profileGradientBottom,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.22),
        ),
        boxShadow: AppColors.ambientShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AvatarEditor(
                imageUrl: profile.avatarUrl,
                isLoading: isUploadingAvatar,
                onEdit: onEditAvatar,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.fullName,
                      style: AppTextStyles.headlineLg.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.referenceLabel,
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.hintColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _VerificationPill(isVerified: profile.isVerified),
                  ],
                ),
              ),
            ],
          ),
          if (profile.headline.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              profile.headline,
              style: AppTextStyles.titleLg.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
          ],
          if (profile.summary.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              profile.summary,
              style: AppTextStyles.bodyMd.copyWith(height: 1.5),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetaChip(
                icon: Icons.calendar_month_rounded,
                color: AppColors.categoryBlue,
                label: 'Membre depuis',
                value: profile.memberSinceLabel,
              ),
              _MetaChip(
                icon: Icons.location_on_outlined,
                color: AppColors.successDark,
                label: 'Localisation',
                value: profile.locationLabel.isEmpty
                    ? 'Non renseignee'
                    : profile.locationLabel,
              ),
            ],
          ),
          if (profile.skills.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.skills
                  .take(8)
                  .map(
                    (skill) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard.withValues(alpha: 0.80),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        skill,
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}

class _AvatarEditor extends StatelessWidget {
  const _AvatarEditor({
    required this.imageUrl,
    required this.isLoading,
    required this.onEdit,
  });

  final String imageUrl;
  final bool isLoading;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(26),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: imageUrl.trim().isEmpty
                ? const Icon(
                    Icons.person_rounded,
                    size: 42,
                    color: AppColors.primary,
                  )
                : CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.person_rounded,
                      size: 42,
                      color: AppColors.primary,
                    ),
                  ),
          ),
        ),
        Positioned(
          top: -2,
          right: -2,
          child: Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: AppColors.successDark,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          right: -4,
          bottom: -4,
          child: GestureDetector(
            onTap: isLoading ? null : onEdit,
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.categoryPurple,
                    AppColors.categoryPurpleDeep,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppColors.onPrimary),
                      ),
                    )
                  : const Icon(
                      Icons.photo_camera_outlined,
                      size: 18,
                      color: AppColors.onPrimary,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VerificationPill extends StatelessWidget {
  const _VerificationPill({required this.isVerified});

  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    final color = isVerified ? AppColors.verified : AppColors.bodyColor;
    final background =
        isVerified ? AppColors.successSoftAlt : AppColors.surfaceLow;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.verified_rounded : Icons.shield_outlined,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            isVerified ? 'Verifie' : 'Non verifie',
            style: AppTextStyles.bodySm.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.bodySm),
              Text(
                value,
                style: AppTextStyles.titleMd.copyWith(
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

