import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';

import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_dimens.dart';
import 'package:baara/app/core/theme/app_motion.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/app/core/utils/user_facing_error.dart';
import 'package:baara/app/core/widgets/widgets.dart';
import 'package:baara/routes/app_routes.dart';
import '../../domain/entities/network_user.dart';
import '../../domain/repositories/i_community_repository.dart';
import '../controllers/community_controller.dart';
import '../widgets/network_user_tile.dart';

/// Liste paginée des **abonnés** OU des **connexions** d'un membre — ouverte en
/// tapant les compteurs du profil (stats cliquables, façon Facebook). Le mode
/// (`followers` | `connections`) et le nom du membre arrivent via
/// `Get.arguments` ; l'id via le paramètre de route `:id`.
class CommunityNetworkListScreen extends StatefulWidget {
  const CommunityNetworkListScreen({super.key});

  @override
  State<CommunityNetworkListScreen> createState() =>
      _CommunityNetworkListScreenState();
}

class _CommunityNetworkListScreenState
    extends State<CommunityNetworkListScreen> {
  final _controller = Get.find<CommunityController>();
  final _scrollCtrl = ScrollController();

  late final String _userId;
  late final bool _isFollowersMode;

  final _users = <NetworkUser>[].obs;
  final _loading = true.obs;
  final _loadingMore = false.obs;
  final _hasMore = false.obs;
  final _error = RxnString();
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _userId = Get.parameters['id'] ?? '';
    final args = Get.arguments;
    final mode = (args is Map ? args['mode']?.toString() : null) ?? 'followers';
    _isFollowersMode = mode != 'connections';
    _scrollCtrl.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  String get _title => _isFollowersMode ? 'Abonnés' : 'Connexions';

  Future<NetworkUserPage> _fetch(int page) => _isFollowersMode
      ? _controller.fetchFollowers(_userId, page: page)
      : _controller.fetchUserConnections(_userId, page: page);

  Future<void> _load() async {
    _loading.value = true;
    _error.value = null;
    _page = 1;
    try {
      final res = await _fetch(1);
      _users.assignAll(res.items);
      _hasMore.value = res.hasMore;
    } catch (e) {
      _error.value = userFacingError(e);
    } finally {
      _loading.value = false;
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore.value || _loading.value || !_hasMore.value) return;
    _loadingMore.value = true;
    try {
      final res = await _fetch(_page + 1);
      _page += 1;
      _users.addAll(res.items);
      _hasMore.value = res.hasMore;
    } catch (_) {
      // Échec silencieux : l'utilisateur peut réessayer en scrollant.
    } finally {
      _loadingMore.value = false;
    }
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 400) _loadMore();
  }

  void _toggleFollow(NetworkUser user) {
    AppHaptics.tap();
    final i = _users.indexWhere((u) => u.id == user.id);
    if (i < 0) return;
    // Optimiste sur la tuile locale ; le contrôleur gère l'appel réseau et son
    // propre rollback sur les autres listes (fil, suggestions).
    _users[i] = _users[i].copyWith(isFollowing: !user.isFollowing);
    _controller.toggleFollow(user);
  }

  @override
  Widget build(BuildContext context) {
    return SankSheetScaffold(
      title: _title,
      body: Obx(() {
        if (_loading.value && _users.isEmpty) {
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: 7,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, __) => const MessageTileSkeleton(),
          );
        }
        if (_error.value != null && _users.isEmpty) {
          return ErrorStateView(
            message: 'Liste indisponible.',
            illustration: const ErrorIllustration(),
            onRetry: _load,
          );
        }
        if (_users.isEmpty) {
          return Center(
            child: EmptyState(
              illustration: const EmptyPeopleIllustration(),
              title: _isFollowersMode ? 'Aucun abonné' : 'Aucune connexion',
              subtitle: _isFollowersMode
                  ? 'Ce membre n’a pas encore d’abonnés.'
                  : 'Ce membre n’a pas encore de connexions.',
            ),
          );
        }
        return AppRefreshIndicator(
          color: AppColors.primaryAccent,
          onRefresh: _load,
          child: AnimationLimiter(
            child: ListView.separated(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(AppSpacing.lg),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _users.length + 1,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, i) {
                if (i == _users.length) return _footer();
                final user = _users[i];
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
                          AppRoutes.communityProfile
                              .replaceFirst(':id', user.id),
                        ),
                        trailing: user.isSelf
                            ? null
                            : FollowPillButton(
                                following: user.isFollowing,
                                onTap: () => _toggleFollow(user),
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }),
    );
  }

  Widget _footer() {
    return Obx(() {
      if (!_loadingMore.value) return const SizedBox(height: AppSpacing.sm);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: AppLoader(size: 22, strokeWidth: 2),
          ),
        ),
      );
    });
  }
}
