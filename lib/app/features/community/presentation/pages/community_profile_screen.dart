import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:get/get.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import 'package:opportune_bf/routes/app_routes.dart';
import '../../domain/entities/network_user.dart';
import '../controllers/community_controller.dart';

/// Profil public d'un membre du réseau. Charge `GET /community/users/{id}` :
/// en-tête (avatar, nom, rôle, bio), statistiques, et actions Suivre / Se
/// connecter (avec état optimiste).
class CommunityProfileScreen extends StatefulWidget {
  const CommunityProfileScreen({super.key});

  @override
  State<CommunityProfileScreen> createState() => _CommunityProfileScreenState();
}

class _CommunityProfileScreenState extends State<CommunityProfileScreen> {
  final _controller = Get.find<CommunityController>();
  late final String _userId;

  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _error = false;
  bool _isFollowing = false;
  String _connectionStatus = 'none';
  bool _connecting = false;

  @override
  void initState() {
    super.initState();
    _userId = Get.parameters['id'] ?? '';
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final data = await _controller.fetchUserProfile(_userId);
      if (!mounted) return;
      setState(() {
        _profile = data;
        _isFollowing = data['is_following'] == true;
        _connectionStatus = data['connection_status']?.toString() ?? 'none';
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

  NetworkUser _asUser() => NetworkUser(
        id: _userId,
        firstName: _profile?['first_name']?.toString() ?? '',
        lastName: _profile?['last_name']?.toString() ?? '',
        fullName: _profile?['full_name']?.toString() ?? 'Membre',
        userType: _profile?['user_type']?.toString() ?? 'candidate',
        role: _profile?['role']?.toString() ?? '',
        avatarUrl: _profile?['avatar_url']?.toString(),
        isSelf: _profile?['is_self'] == true,
        isFollowing: _isFollowing,
        connectionStatus: _connectionStatus,
      );

  Future<void> _toggleFollow() async {
    AppHaptics.tap();
    setState(() => _isFollowing = !_isFollowing);
    await _controller.toggleFollow(_asUser().copyWith(isFollowing: !_isFollowing));
  }

  Future<void> _connect() async {
    if (_connecting || _connectionStatus != 'none') return;
    setState(() => _connecting = true);
    final ok = await _controller.connectUser(_asUser());
    if (!mounted) return;
    setState(() {
      _connecting = false;
      if (ok) _connectionStatus = 'pending_sent';
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile?['full_name']?.toString() ?? 'Profil';
    return SankSheetScaffold(
      title: name,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error
              ? ErrorStateView(
                  message: 'Profil indisponible.',
                  onRetry: _load,
                )
              : _content(),
    );
  }

  void _share() {
    final name = _profile?['full_name']?.toString() ?? 'Ce membre';
    Clipboard.setData(
        ClipboardData(text: 'Découvrez le profil de $name sur OpporTune.'));
    AppToast.success('Copié', 'Le profil a été copié dans le presse-papier.');
  }

  Widget _content() {
    final profile = _profile ?? const {};
    final name = profile['full_name']?.toString() ?? 'Membre';
    final role = profile['role']?.toString() ?? '';
    final bio = profile['bio']?.toString() ?? '';
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
      children: [
        const SizedBox(height: AppSpacing.sm),
        // En-tête type fiche contact (WhatsApp/Telegram) : grand avatar rond,
        // nom, sous-titre (rôle/headline).
        Center(
          child: BrandAvatar(
            seed: _userId,
            label: name,
            size: 112,
            imageUrl: profile['avatar_url']?.toString(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineMd
                    .copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            if (profile['user_type']?.toString() == 'admin') ...[
              const SizedBox(width: 6),
              const Icon(Icons.verified_rounded,
                  size: 20, color: AppColors.verified),
            ],
          ],
        ),
        if (role.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            role,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.hintColor),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        _actionRow(),
        const SizedBox(height: AppSpacing.xl),
        _statsCard(profile),
        if (bio.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('À propos',
                    style: AppTextStyles.titleMd
                        .copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: AppSpacing.sm),
                Text(bio,
                    style: AppTextStyles.bodyMd
                        .copyWith(color: AppColors.bodyColor, height: 1.5)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Rangée de boutons d'action (style fiche contact) ──────────────────
  Widget _actionRow() {
    final canFollow = _profile?['is_self'] != true;
    return Row(
      children: [
        Expanded(
          child: _ContactAction(
            icon: _isFollowing
                ? Icons.check_rounded
                : Icons.person_add_alt_1_rounded,
            label: _isFollowing ? 'Suivi' : 'Suivre',
            active: _isFollowing,
            onTap: canFollow ? _toggleFollow : null,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: _connectAction()),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ContactAction(
            icon: Icons.ios_share_rounded,
            label: 'Partager',
            onTap: _share,
          ),
        ),
      ],
    );
  }

  Widget _connectAction() {
    switch (_connectionStatus) {
      case 'connected':
        return const _ContactAction(
          icon: Icons.how_to_reg_rounded,
          label: 'Connecté',
          active: true,
          onTap: null,
        );
      case 'pending_sent':
        return const _ContactAction(
          icon: Icons.hourglass_empty_rounded,
          label: 'Envoyée',
          onTap: null,
        );
      case 'pending_received':
        return _ContactAction(
          icon: Icons.mark_email_unread_rounded,
          label: 'Répondre',
          onTap: () => Get.toNamed(AppRoutes.communityConnections),
        );
      default:
        final canConnect = _profile?['is_self'] != true;
        return _ContactAction(
          icon: Icons.group_add_rounded,
          label: _connecting ? '…' : 'Connecter',
          onTap: _connecting || !canConnect ? null : _connect,
        );
    }
  }

  Widget _statsCard(Map<String, dynamic> p) {
    int n(String k) => (p[k] as num?)?.toInt() ?? 0;
    Widget stat(String value, String label) => Expanded(
          child: Column(
            children: [
              Text(value,
                  style: AppTextStyles.titleLg
                      .copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySm
                      .copyWith(color: AppColors.hintColor)),
            ],
          ),
        );
    return AppCard(
      child: Row(
        children: [
          stat('${n('posts_count')}', 'Publications'),
          stat('${n('followers_count')}', 'Abonnés'),
          stat('${n('connections_count')}', 'Connexions'),
        ],
      ),
    );
  }
}

/// Bouton d'action carré arrondi (icône + label) — inspiré des fiches contact
/// WhatsApp / Telegram, adapté au design system (AppColors).
class _ContactAction extends StatelessWidget {
  const _ContactAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = active
        ? AppColors.primary
        : enabled
            ? AppColors.primaryDark
            : AppColors.hintColor;
    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              AppHaptics.tap();
              onTap!();
            },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: active
                ? AppColors.primary.withValues(alpha: 0.35)
                : AppColors.outlineVariant,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelMd.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
