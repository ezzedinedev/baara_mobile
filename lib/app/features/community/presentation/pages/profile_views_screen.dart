import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/utils/relative_time.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import 'package:opportune_bf/routes/app_routes.dart';
import '../../domain/entities/profile_viewer.dart';
import '../controllers/community_controller.dart';

/// « Qui a vu mon profil » — liste des membres ayant consulté le profil de
/// l'utilisateur courant (avatar, nom, headline, « il y a … ») avec total en
/// tête, pull-to-refresh, et états vide/erreur.
class ProfileViewsScreen extends StatefulWidget {
  const ProfileViewsScreen({super.key});

  @override
  State<ProfileViewsScreen> createState() => _ProfileViewsScreenState();
}

class _ProfileViewsScreenState extends State<ProfileViewsScreen> {
  final _controller = Get.find<CommunityController>();

  bool _loading = true;
  bool _error = false;
  ProfileViewsResult _result = const ProfileViewsResult(viewers: [], total: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = false;
      });
    }
    try {
      final res = await _controller.fetchProfileViews();
      if (!mounted) return;
      setState(() {
        _result = res;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SankSheetScaffold(
      title: 'Vues de profil',
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) {
      return ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, __) =>
            const SkeletonBox(height: 64, radius: AppRadius.md),
      );
    }
    if (_error) {
      return ErrorStateView(
        message: 'Impossible de charger les vues de profil.',
        illustration: const ErrorIllustration(),
        onRetry: _load,
      );
    }
    if (_result.viewers.isEmpty) {
      return AppRefreshIndicator(
        color: AppColors.primaryAccent,
        onRefresh: _load,
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: const EmptyState(
                illustration: EmptyPeopleIllustration(),
                title: 'Aucune vue pour le moment',
                subtitle: 'Quand des membres consulteront votre profil, ils '
                    'apparaîtront ici.',
              ),
            ),
          ],
        ),
      );
    }

    return AppRefreshIndicator(
      color: AppColors.primaryAccent,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
        itemCount: _result.viewers.length + 1,
        separatorBuilder: (_, i) => i == 0
            ? const SizedBox(height: AppSpacing.md)
            : Divider(
                height: 1,
                indent: 64,
                color: AppColors.outlineVariant,
              ),
        itemBuilder: (context, i) {
          if (i == 0) return _header();
          return _viewerTile(_result.viewers[i - 1]);
        },
      ),
    );
  }

  Widget _header() {
    final total = _result.total;
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(IconlyLight.show, color: AppColors.primaryAccent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$total personne${total > 1 ? 's' : ''}',
                  style: AppTextStyles.titleLg
                      .copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  'ont vu votre profil',
                  style:
                      AppTextStyles.bodySm.copyWith(color: AppColors.hintColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _viewerTile(ProfileViewer viewer) {
    final name = viewer.fullName.isEmpty ? 'Membre' : viewer.fullName;
    return PressScale(
      onTap: () {
        AppHaptics.tap();
        Get.toNamed(
          AppRoutes.communityProfile.replaceFirst(':id', viewer.id),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            BrandAvatar(
              seed: viewer.id,
              label: name,
              size: 48,
              imageUrl: viewer.avatarUrl,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleMd
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  if ((viewer.headline ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      viewer.headline!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.hintColor),
                    ),
                  ],
                ],
              ),
            ),
            if (viewer.viewedAt != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Text(
                relativeTimeFr(viewer.viewedAt),
                style:
                    AppTextStyles.labelSm.copyWith(color: AppColors.hintColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
