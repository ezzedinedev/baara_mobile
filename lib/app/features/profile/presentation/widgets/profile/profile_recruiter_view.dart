import 'package:flutter/material.dart';

import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_dimens.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:baara/app/core/theme/app_shapes.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import '../../../domain/entities/profile.dart';

class ProfileRecruiterView extends StatelessWidget {
  const ProfileRecruiterView({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final hasContent = (profile.bio ?? '').trim().isNotEmpty ||
        profile.skills.isNotEmpty ||
        profile.experiences.isNotEmpty ||
        profile.educations.isNotEmpty ||
        profile.languages.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: ShapeDecoration(
              color: AppColors.categoryBlue.withValues(alpha: 0.10),
              shape: AppShapes.squircle(AppRadius.lg),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(AppIcons.show, size: 20, color: AppColors.categoryBlue),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Voici comment votre profil apparaît aux recruteurs',
                        style: AppTextStyles.titleMd
                            .copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Seules les sections complétées sont visibles pour les entreprises.',
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.bodyColor, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (!hasContent)
            const ProfileRecruiterEmpty()
          else ...[
            if ((profile.bio ?? '').trim().isNotEmpty)
              ProfileRecruiterCard(
                title: 'À propos',
                child: Text(
                  profile.bio!,
                  style: AppTextStyles.bodyMd
                      .copyWith(color: AppColors.bodyColor, height: 1.5),
                ),
              ),
            if (profile.skills.isNotEmpty)
              ProfileRecruiterCard(
                title: 'Compétences',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in profile.skills)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color:
                              AppColors.primaryAccent.withValues(alpha: 0.10),
                          borderRadius: AppShapes.pill,
                        ),
                        child: Text(
                          s,
                          style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.primaryAccent,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
              ),
            if (profile.experiences.isNotEmpty)
              ProfileRecruiterCard(
                title: 'Expériences',
                child: Column(
                  children: [
                    for (final e in profile.experiences)
                      ProfileRecruiterLine(
                        icon: AppIcons.work,
                        title: e.title,
                        subtitle: e.company,
                      ),
                  ],
                ),
              ),
            if (profile.educations.isNotEmpty)
              ProfileRecruiterCard(
                title: 'Education',
                child: Column(
                  children: [
                    for (final e in profile.educations)
                      ProfileRecruiterLine(
                        icon: Icons.school_outlined,
                        title: e.degree,
                        subtitle: e.institution,
                      ),
                  ],
                ),
              ),
            if (profile.languages.isNotEmpty)
              ProfileRecruiterCard(
                title: 'Langues',
                child: Column(
                  children: [
                    for (final l in profile.languages)
                      ProfileRecruiterLine(
                        icon: Icons.translate_rounded,
                        title: l.name,
                        subtitle: l.level,
                      ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class ProfileRecruiterEmpty extends StatelessWidget {
  const ProfileRecruiterEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: ShapeDecoration(
        color: AppColors.surfaceCard,
        shape: AppShapes.cardBordered(AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(AppIcons.profile, size: 36, color: AppColors.hintColor),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Votre profil public est encore vide',
            textAlign: TextAlign.center,
            style: AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Complétez vos sections dans « Ma Vue » pour apparaître auprès des recruteurs.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.hintColor),
          ),
        ],
      ),
    );
  }
}

class ProfileRecruiterCard extends StatelessWidget {
  const ProfileRecruiterCard({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: ShapeDecoration(
        color: AppColors.surfaceCard,
        shape: AppShapes.cardBordered(AppColors.outlineVariant),
        shadows: AppColors.lightShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class ProfileRecruiterLine extends StatelessWidget {
  const ProfileRecruiterLine({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withValues(alpha: 0.10),
              borderRadius: AppShapes.squircleRadius(AppRadius.sm),
            ),
            child: Icon(icon, size: 17, color: AppColors.primaryAccent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMd
                      .copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                if (subtitle.trim().isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySm
                        .copyWith(color: AppColors.hintColor),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
