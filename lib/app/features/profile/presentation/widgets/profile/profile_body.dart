import 'package:flutter/material.dart';

import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_dimens.dart';
import 'package:baara/app/core/theme/app_motion.dart';
import 'package:baara/app/core/theme/app_shapes.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/app/core/widgets/widgets.dart';
import '../../../domain/entities/profile.dart';
import '../../pages/settings_screen.dart';
import '../presentation_video_card.dart';
import 'profile_contact_card.dart';
import 'profile_documents_strip.dart';
import 'profile_hero.dart';
import 'profile_recruiter_view.dart';
import 'profile_sections_to_complete.dart';
import 'profile_streak_card.dart';

class ProfileBody extends StatefulWidget {
  const ProfileBody({super.key, required this.profile});

  final Profile profile;

  @override
  State<ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<ProfileBody> {
  int _segment = 0;

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final isCandidate = profile.userType == 'candidate';

    if (!isCandidate) return ProfileMyView(profile: profile);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: ProfileViewToggle(
            selected: _segment,
            onChanged: (i) {
              AppHaptics.tap();
              setState(() => _segment = i);
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AnimatedSwitcher(
          duration: AppMotion.medium,
          switchInCurve: AppMotion.emphasizedDecelerate,
          switchOutCurve: AppMotion.emphasizedAccelerate,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.02),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: _segment == 0
              ? KeyedSubtree(
                  key: const ValueKey('profile-ma-vue'),
                  child: ProfileMyView(profile: profile),
                )
              : KeyedSubtree(
                  key: const ValueKey('profile-vue-recruteur'),
                  child: ProfileRecruiterView(profile: profile),
                ),
        ),
      ],
    );
  }
}

class ProfileViewToggle extends StatelessWidget {
  const ProfileViewToggle({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final int selected;
  final ValueChanged<int> onChanged;

  static const _labels = ['Ma Vue', 'Vue Recruteur'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: AppShapes.pill,
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final segWidth = (c.maxWidth - 8) / 2;
          return Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                alignment: selected == 0
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Container(
                  width: segWidth,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: AppShapes.pill,
                    boxShadow: AppColors.lightShadow,
                  ),
                ),
              ),
              Row(
                children: List.generate(2, (i) {
                  final active = i == selected;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(i),
                      child: Center(
                        child: Text(
                          _labels[i],
                          style: AppTextStyles.labelLg.copyWith(
                            color: active
                                ? AppColors.primaryAccent
                                : AppColors.hintColor,
                            fontWeight:
                                active ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ProfileMyView extends StatelessWidget {
  const ProfileMyView({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final isCandidate = profile.userType == 'candidate';
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          child: ProfileStreakCard(),
        ),
        if (isCandidate) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: ProfileSectionsToComplete(profile: profile),
          ),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: ProfileContactCard(profile: profile),
        ),
        if (isCandidate) ...[
          const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: PresentationVideoCard(),
          ),
        ],
        const SizedBox(height: 18),
        const ProfileDocumentsStrip(),
        const SizedBox(height: 18),
        const ProfileCertificatesStrip(),
        const SizedBox(height: 6),
        const SettingsBody(),
      ],
    );
  }
}

class ProfileLoadedView extends StatelessWidget {
  const ProfileLoadedView({
    super.key,
    required this.profile,
    required this.onRefresh,
  });

  final Profile profile;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return AppRefreshIndicator(
      color: AppColors.primaryAccent,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          ProfileHero(profile: profile),
          const SizedBox(height: 8),
          ProfileBody(profile: profile),
        ],
      ),
    );
  }
}
