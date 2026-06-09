import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import 'package:opportune_bf/routes/app_routes.dart';
import '../../domain/entities/network_user.dart';
import '../controllers/community_controller.dart';
import '../widgets/network_user_tile.dart';

/// Recherche de membres du réseau (`GET /community/search?type=people`).
class CommunitySearchScreen extends StatefulWidget {
  const CommunitySearchScreen({super.key});

  @override
  State<CommunitySearchScreen> createState() => _CommunitySearchScreenState();
}

class _CommunitySearchScreenState extends State<CommunitySearchScreen> {
  final _controller = Get.find<CommunityController>();
  final _input = TextEditingController();

  final _results = <NetworkUser>[];
  bool _loading = false;
  bool _searched = false;

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
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleFollow(int index) async {
    AppHaptics.tap();
    final user = _results[index];
    setState(() => _results[index] =
        user.copyWith(isFollowing: !user.isFollowing));
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
            TextField(
              controller: _input,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: 'Nom ou prénom d\'un membre…',
                prefixIcon:
                    Icon(Icons.search_rounded, color: AppColors.hintColor),
                suffixIcon: IconButton(
                  icon: Icon(Icons.arrow_forward_rounded,
                      color: AppColors.primary),
                  onPressed: () => _search(_input.text),
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
      return const Center(child: CircularProgressIndicator());
    }
    if (!_searched) {
      return Center(
        child: Text(
          'Cherchez des membres par nom.',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.hintColor),
        ),
      );
    }
    if (_results.isEmpty) {
      return const Center(
        child: EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Aucun membre',
          subtitle: 'Aucun résultat pour cette recherche.',
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, i) {
        final user = _results[i];
        return NetworkUserTile(
          user: user,
          onTap: () => Get.toNamed(
            AppRoutes.communityProfile.replaceFirst(':id', user.id),
          ),
          trailing: user.isSelf
              ? null
              : TextButton(
                  onPressed: () => _toggleFollow(i),
                  child: Text(user.isFollowing ? 'Suivi' : 'Suivre'),
                ),
        );
      },
    );
  }
}
