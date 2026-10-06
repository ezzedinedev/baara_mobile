import 'package:flutter/material.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';

import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_dimens.dart';
import 'package:baara/app/core/theme/app_motion.dart';
import 'package:baara/app/core/theme/app_shapes.dart';
import 'package:baara/app/core/theme/app_text_styles.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/app/core/utils/user_facing_error.dart';
import 'package:baara/app/core/widgets/widgets.dart';
import 'package:baara/routes/app_routes.dart';
import '../../domain/entities/network_user.dart';
import '../../domain/repositories/i_community_repository.dart';
import '../controllers/community_controller.dart';
import '../widgets/network_user_tile.dart';
import 'hashtag_feed_screen.dart';

/// Recherche de membres du réseau (`GET /community/search?type=people`).
class CommunitySearchScreen extends StatefulWidget {
  const CommunitySearchScreen({super.key, this.initialQuery});

  /// Pré-remplit le champ et lance la recherche (ex. depuis un @mention).
  final String? initialQuery;

  @override
  State<CommunitySearchScreen> createState() => _CommunitySearchScreenState();
}

class _CommunitySearchScreenState extends State<CommunitySearchScreen> {
  final _controller = Get.find<CommunityController>();
  final _input = TextEditingController();

  final _results = <NetworkUser>[];
  final _trending = <TrendingHashtag>[];
  bool _loading = false;
  bool _searched = false;
  String? _errorMessage;
  String? _lastQuery;

  @override
  void initState() {
    super.initState();
    _loadTrending();
    final q = widget.initialQuery?.trim() ?? '';
    if (q.isNotEmpty) {
      _input.text = q;
      WidgetsBinding.instance.addPostFrameCallback((_) => _search(q));
    }
  }

  Future<void> _loadTrending() async {
    final list = await _controller.loadTrendingHashtags();
    if (!mounted) return;
    setState(() {
      _trending
        ..clear()
        ..addAll(list);
    });
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    final query = q.trim();
    if (query.length < 2) return;
    setState(() {
      _loading = true;
      _searched = true;
      _errorMessage = null;
      _lastQuery = query;
    });
    try {
      final res = await _controller.searchPeople(query);
      if (!mounted) return;
      setState(() {
        _results
          ..clear()
          ..addAll(res);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = userFacingError(e);
        _results.clear();
      });
    }
  }

  Future<void> _toggleFollow(int index) async {
    AppHaptics.tap();
    final user = _results[index];
    setState(
        () => _results[index] = user.copyWith(isFollowing: !user.isFollowing));
    await _controller.toggleFollow(user);
  }

  @override
  Widget build(BuildContext context) {
    return SankSheetScaffold(
      title: 'Rechercher',
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
        child: Column(
          children: [
            // Champ de recherche squircle
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: AppShapes.squircleRadius(AppRadius.md),
                border: Border.all(color: AppColors.outlineVariant),
                boxShadow: AppColors.lightShadow,
              ),
              child: TextField(
                controller: _input,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onSubmitted: _search,
                style: AppTextStyles.bodyMd,
                decoration: InputDecoration(
                  hintText: 'Nom ou prénom d\'un membre…',
                  hintStyle:
                      AppTextStyles.bodyMd.copyWith(color: AppColors.hintColor),
                  prefixIcon:
                      Icon(AppIcons.search, color: AppColors.hintColor),
                  suffixIcon: IconButton(
                    icon: Icon(AppIcons.actionForward,
                        color: AppColors.primaryAccent),
                    onPressed: () => _search(_input.text),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppShapes.squircleRadius(AppRadius.md),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppShapes.squircleRadius(AppRadius.md),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppShapes.squircleRadius(AppRadius.md),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return ListView.separated(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        itemCount: 7,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, __) => const MessageTileSkeleton(),
      );
    }
    if (!_searched) {
      return _trendingSection();
    }
    if (_errorMessage != null) {
      return ErrorStateView(
        message: _errorMessage!,
        illustration: const ErrorIllustration(),
        onRetry: () async {
          final q = _lastQuery ?? _input.text;
          if (q.trim().length >= 2) await _search(q);
        },
      );
    }
    if (_results.isEmpty) {
      return const Center(
        child: EmptyState(
          illustration: NoResultsIllustration(),
          title: 'Aucun membre',
          subtitle: 'Aucun résultat pour cette recherche.',
        ),
      );
    }
    return AnimationLimiter(
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        itemCount: _results.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, i) {
          final user = _results[i];
          return AnimationConfiguration.staggeredList(
            position: i,
            duration: AppMotion.medium,
            child: SlideAnimation(
              verticalOffset: AppMotion.listSlideOffset,
              curve: AppMotion.emphasizedDecelerate,
              child: FadeInAnimation(
                curve: AppMotion.emphasizedDecelerate,
                child: NetworkUserTile(
                  user: user,
                  onTap: () => Get.toNamed(
                    AppRoutes.communityProfile.replaceFirst(':id', user.id),
                  ),
                  trailing: user.isSelf
                      ? null
                      : FollowPillButton(
                          following: user.isFollowing,
                          onTap: () => _toggleFollow(i),
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Section « Tendances » (champ vide) ────────────────────────────────────
  Widget _trendingSection() {
    if (_trending.isEmpty) {
      return Center(
        child: Text(
          'Cherchez des membres par nom.',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.hintColor),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: [
        Row(
          children: [
            Icon(AppIcons.chart, size: 18, color: AppColors.primaryAccent),
            const SizedBox(width: 8),
            Text(
              'Tendances',
              style: AppTextStyles.titleMd.copyWith(
                color: AppColors.titleColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final t in _trending) _trendingChip(t),
          ],
        ),
      ],
    );
  }

  Widget _trendingChip(TrendingHashtag t) {
    return PressScale(
      onTap: () {
        AppHaptics.tap();
        Get.to<void>(() => HashtagFeedScreen(tag: t.tag));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          // pill pour les chips tendances — cohérent avec FollowPillButton
          borderRadius: AppShapes.pill,
          border: Border.all(color: AppColors.outlineVariant),
          boxShadow: AppColors.lightShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '#${t.tag}',
              style: AppTextStyles.labelLg.copyWith(
                color: AppColors.primaryAccent,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (t.count > 0) ...[
              const SizedBox(width: 6),
              Text(
                '${t.count}',
                style:
                    AppTextStyles.bodySm.copyWith(color: AppColors.hintColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
