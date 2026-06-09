import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import 'package:opportune_bf/routes/app_routes.dart';
import '../controllers/community_controller.dart';
import '../widgets/network_user_tile.dart';

/// Demandes de connexion entrantes (`GET /community/connections`) à accepter
/// ou refuser.
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
      body: Obx(() {
        if (_controller.isLoadingConnections.value &&
            _controller.pendingConnections.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_controller.pendingConnections.isEmpty) {
          return const Center(
            child: EmptyState(
              icon: Icons.people_outline_rounded,
              title: 'Aucune demande',
              subtitle: 'Vous n\'avez pas de demande de connexion en attente.',
            ),
          );
        }
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _controller.loadPendingConnections,
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: _controller.pendingConnections.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, i) {
              final req = _controller.pendingConnections[i];
              return NetworkUserTile(
                user: req.user,
                onTap: () => Get.toNamed(
                  AppRoutes.communityProfile.replaceFirst(':id', req.user.id),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Refuser',
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.error),
                      onPressed: () => _respond(req.connectionId, false),
                    ),
                    IconButton(
                      tooltip: 'Accepter',
                      icon: const Icon(Icons.check_circle_rounded,
                          color: AppColors.primary),
                      onPressed: () => _respond(req.connectionId, true),
                    ),
                  ],
                ),
              );
            },
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
