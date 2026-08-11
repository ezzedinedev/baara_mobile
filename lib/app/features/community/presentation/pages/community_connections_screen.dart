import 'package:flutter/material.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:baara/app/core/theme/app_colors.dart';
import 'package:baara/app/core/theme/app_dimens.dart';
import 'package:baara/app/core/theme/app_motion.dart';
import 'package:baara/app/core/theme/app_shapes.dart';
import 'package:baara/app/core/utils/haptics.dart';
import 'package:baara/app/core/widgets/widgets.dart';
import 'package:baara/routes/app_routes.dart';
import '../controllers/community_controller.dart';
import '../widgets/network_user_tile.dart';
import 'suggestions_screen.dart';


class CommunityConnectionsScreen extends StatefulWidget {
  const CommunityConnectionsScreen({super.key});

  @override
  State<CommunityConnectionsScreen> createState() =>
      _CommunityConnectionsScreenState();
}

class _CommunityConnectionsScreenState
    extends State<CommunityConnectionsScreen> {
  final _controller = Get.find<CommunityController>();

  @override
  void initState() {
    super.initState();
    _controller.loadPendingConnections();
  }

  @override
  Widget build(BuildContext context) {
    return SankSheetScaffold(
      title: 'Demandes de connexion',
      actions: [
        AppIconButton(
          icon: AppIcons.network,
          tooltip: 'Personnes à suivre',
          onBrandHeader: true,
          onTap: () {
            AppHaptics.tap();
            Get.to<void>(() => const SuggestionsScreen());
          },
        ),
      ],
      body: Obx(() {
        if (_controller.isLoadingConnections.value &&
            _controller.pendingConnections.isEmpty &&
            _controller.connectionsErrorMessage.value == null) {
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: 7,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, __) => const MessageTileSkeleton(),
          );
        }
        if (_controller.connectionsErrorMessage.value != null &&
            _controller.pendingConnections.isEmpty) {
          return ErrorStateView(
            message: _controller.connectionsErrorMessage.value!,
            illustration: const ErrorIllustration(),
            onRetry: _controller.loadPendingConnections,
          );
        }
        if (_controller.pendingConnections.isEmpty) {
          return AppRefreshIndicator(
            color: AppColors.primaryAccent,
            onRefresh: _controller.loadPendingConnections,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 80),
                EmptyState(
                  illustration: EmptyPeopleIllustration(),
                  title: 'Aucune demande',
                  subtitle:
                      'Vous n\'avez pas de demande de connexion en attente.',
                ),
              ],
            ),
          );
        }
        return AppRefreshIndicator(
          color: AppColors.primaryAccent,
          onRefresh: _controller.loadPendingConnections,
          child: AnimationLimiter(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: _controller.pendingConnections.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, i) {
                final req = _controller.pendingConnections[i];
                return AnimationConfiguration.staggeredList(
                  position: i,
                  duration: AppMotion.medium,
                  child: SlideAnimation(
                    verticalOffset: AppMotion.listSlideOffset,
                    curve: AppMotion.emphasizedDecelerate,
                    child: FadeInAnimation(
                      curve: AppMotion.emphasizedDecelerate,
                      child: NetworkUserTile(
                        user: req.user,
                        onTap: () => Get.toNamed(
                          AppRoutes.communityProfile
                              .replaceFirst(':id', req.user.id),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _RespondButton(
                              icon: AppIcons.closeSquare,
                              color: AppColors.errorAccent,
                              tooltip: 'Refuser',
                              onTap: () => _respond(req.connectionId, false),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _RespondButton(
                              icon: AppIcons.tickSquare,
                              color: AppColors.primaryAccent,
                              filled: true,
                              tooltip: 'Accepter',
                              onTap: () => _respond(req.connectionId, true),
                            ),
                          ],
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

  Future<void> _respond(String connectionId, bool accept) async {
    AppHaptics.tap();
    await _controller.respondToConnection(connectionId, accept);
  }
}


class _RespondButton extends StatelessWidget {
  const _RespondButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
    this.filled = false,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: PressScale(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: filled ? 0.14 : 0.0),
            borderRadius: AppShapes.squircleRadius(AppRadius.sm),
            border: Border.all(
              color: color.withValues(alpha: filled ? 0.4 : 0.3),
            ),
          ),
          child: Icon(icon, size: 19, color: color),
        ),
      ),
    );
  }
}
