import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_motion.dart';
import 'package:opportune_bf/app/core/theme/app_shapes.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/utils/user_facing_error.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import 'package:opportune_bf/routes/app_routes.dart';
import '../../domain/entities/network_user.dart';
import '../../domain/entities/skill.dart';
import '../controllers/community_controller.dart';

/// Profil public d'un membre du réseau. Charge `GET /community/users/{id}` :
/// en-tête (avatar, nom, rôle, bio), statistiques, actions Suivre / Se
/// connecter (état optimiste), blocage, état verrouillé (confidentialité) et
/// section Compétences avec recommandations.
class CommunityProfileScreen extends StatefulWidget {
  const CommunityProfileScreen({super.key});

  @override
  State<CommunityProfileScreen> createState() => _CommunityProfileScreenState();
}

class _CommunityProfileScreenState extends State<CommunityProfileScreen> {
  final _controller = Get.find<CommunityController>();
  final _scrollCtrl = ScrollController();
  late final String _userId;

  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _error = false;
  bool _isFollowing = false;
  String _connectionStatus = 'none';
  bool _connecting = false;

  // Cluster D
  bool _hasBlocked = false; // l'utilisateur courant a bloqué ce membre
  bool _isLocked = false; // profil 'connections' et non connecté
  bool _isSelf = false;
  bool _blocking = false;
  final _skills = <Skill>[].obs;
  final _addingSkill = false.obs;

  @override
  void initState() {
    super.initState();
    _userId = Get.parameters['id'] ?? '';
    _load();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
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
        _isSelf = data['is_self'] == true;
        _isFollowing = data['is_following'] == true;
        _connectionStatus = data['connection_status']?.toString() ?? 'none';
        _hasBlocked = data['has_blocked'] == true;
        _isLocked = data['is_locked'] == true;
        _skills.assignAll(
          (data['skills'] as List? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map((j) => Skill.fromJson(j))
              .where((s) => s.id.isNotEmpty)
              .toList(),
        );
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
        isSelf: _isSelf,
        isFollowing: _isFollowing,
        connectionStatus: _connectionStatus,
      );

  Future<void> _toggleFollow() async {
    AppHaptics.tap();
    setState(() => _isFollowing = !_isFollowing);
    await _controller
        .toggleFollow(_asUser().copyWith(isFollowing: !_isFollowing));
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

  // ── Blocage ────────────────────────────────────────────────────────────
  Future<void> _toggleBlock() async {
    if (_blocking) return;
    final willBlock = !_hasBlocked;
    final name = _profile?['full_name']?.toString() ?? 'ce membre';
    if (willBlock) {
      final confirmed = await showConfirmSheet(
        context: context,
        icon: IconlyLight.shield_fail,
        iconColor: AppColors.errorAccent,
        title: 'Bloquer $name ?',
        message:
            'Vous ne verrez plus ses publications et il ne pourra plus vous '
            'contacter. Votre connexion et votre abonnement seront retirés.',
        confirmLabel: 'Bloquer',
        isDestructive: true,
      );
      if (confirmed != true) return;
    }

    AppHaptics.confirm();
    // Optimiste.
    setState(() {
      _blocking = true;
      _hasBlocked = willBlock;
      if (willBlock) {
        _isFollowing = false;
        _connectionStatus = 'none';
      }
    });
    try {
      final isBlocked =
          await _controller.setBlocked(_userId, blocked: willBlock);
      if (!mounted) return;
      setState(() {
        _hasBlocked = isBlocked;
        _blocking = false;
      });
      AppToast.success(
        isBlocked ? 'Membre bloqué' : 'Membre débloqué',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasBlocked = !willBlock; // rollback
        _blocking = false;
      });
      AppToast.error('Action impossible', userFacingError(e));
    }
  }

  void _openMenu() {
    AppHaptics.tap();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: AppShapes.sheet,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHandle(),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: Icon(
                _hasBlocked ? IconlyLight.unlock : IconlyLight.shield_fail,
                color: AppColors.errorAccent,
              ),
              title: Text(
                _hasBlocked ? 'Débloquer' : 'Bloquer',
                style: AppTextStyles.titleMd.copyWith(
                  color: AppColors.errorAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _toggleBlock();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile?['full_name']?.toString() ?? 'Profil';
    return SankSheetScaffold(
      title: name,
      actions: [
        if (!_loading && !_error && !_isSelf)
          AppIconButton(
            icon: IconlyLight.more_circle,
            onTap: _openMenu,
            onBrandHeader: true,
          ),
      ],
      body: _loading
          ? const _ProfileSkeleton()
          : _error
              ? ErrorStateView(
                  message: 'Profil indisponible.',
                  illustration: const ErrorIllustration(),
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
      controller: _scrollCtrl,
      padding: EdgeInsets.zero,
      children: [
        // ── MESH HERO BLOCK (parallax au scroll) ─────────────────────────
        ParallaxHeader(
          controller: _scrollCtrl,
          child: RevealOnMount(
            offsetY: 0,
            child: _meshHeroBlock(name, role, profile),
          ),
        ),
        // ── Contenu sous le hero ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bloqué → bannière + uniquement « Débloquer ».
              if (_hasBlocked && !_isSelf)
                _blockedBanner()
              else ...[
                _actionRow(),
                const SizedBox(height: AppSpacing.xl),
                _statsCard(profile),
                if (_isLocked && !_isSelf)
                  _lockedState()
                else ...[
                  if (bio.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _aboutCard(bio),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  _skillsSection(),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Bloc HERO mesh (avatar + nom + rôle) ──────────────────────────────
  Widget _meshHeroBlock(
      String name, String role, Map<String, dynamic> profile) {
    return Container(
      // fond mesh doux de marque, dark-aware
      decoration: BoxDecoration(gradient: AppColors.meshBrand),
      foregroundDecoration: BoxDecoration(gradient: AppColors.meshBrandGlow),
      child: ClipRRect(
        // coins squircle uniquement en bas pour prolonger le SankSheetScaffold
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.xxl * 1.7),
          bottomRight: Radius.circular(AppRadius.xxl * 1.7),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.xl),
          child: Column(
            children: [
              // Avatar à anneau dégradé
              RevealOnMount(
                offsetY: 12,
                child: _heroAvatar(name, profile['avatar_url']?.toString()),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Nom — displayHero réduit pour tenir dans l'espace
              RevealOnMount(
                delay: AppMotion.stagger,
                offsetY: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.displayHero.copyWith(
                          fontSize: 26,
                          color: AppColors.titleColor,
                        ),
                      ),
                    ),
                    if (profile['user_type']?.toString() == 'admin') ...[
                      const SizedBox(width: 6),
                      Icon(IconlyBold.shield_done,
                          size: 20, color: AppColors.verified),
                    ],
                  ],
                ),
              ),
              if (role.isNotEmpty) ...[
                const SizedBox(height: 6),
                RevealOnMount(
                  delay: AppMotion.stagger * 2,
                  offsetY: 8,
                  child: Text(
                    role,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMd
                        .copyWith(color: AppColors.hintColor),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Avatar héros : halo dégradé doux + anneau de marque ───────────────────
  Widget _heroAvatar(String name, String? avatarUrl) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryMedium.withValues(alpha: 0.9),
              AppColors.secondary.withValues(alpha: 0.9),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.22),
              blurRadius: 28,
              spreadRadius: 1,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceCard,
          ),
          // Hero lié depuis la tuile membre (recherche / connexions). Tag par
          // utilisateur, unique sur cet écran (un seul avatar de profil).
          child: Hero(
            tag: 'community-avatar-$_userId',
            child: BrandAvatar(
              seed: _userId,
              label: name,
              size: 108,
              imageUrl: avatarUrl,
            ),
          ),
        ),
      ),
    );
  }

  // ── Carte « À propos » squircle ──────────────────────────────────────────
  Widget _aboutCard(String bio) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppShapes.cardRadius,
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: AppColors.ambientShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('À propos',
              style:
                  AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.sm),
          Text(bio,
              style: AppTextStyles.bodyMd
                  .copyWith(color: AppColors.bodyColor, height: 1.5)),
        ],
      ),
    );
  }

  // ── État verrouillé (profil confidentiel) ────────────────────────────────
  Widget _lockedState() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: AppShapes.cardRadius,
          border: Border.all(color: AppColors.outlineVariant),
          boxShadow: AppColors.ambientShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surfaceIconSoft,
                borderRadius: AppShapes.squircleRadius(AppRadius.lg),
              ),
              child: Icon(IconlyLight.lock,
                  size: 32, color: AppColors.primaryAccent),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Profil confidentiel',
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.titleLg.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Ce membre réserve son profil à ses connexions. Connectez-vous '
              'pour voir ses publications et ses compétences.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd
                  .copyWith(color: AppColors.bodyColor, height: 1.45),
            ),
            if (_connectionStatus == 'none') ...[
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _connecting ? null : _connect,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: ContinuousRectangleBorder(
                      borderRadius: AppShapes.squircleRadius(AppRadius.md),
                    ),
                  ),
                  icon: const Icon(IconlyLight.add_user, size: 18),
                  label: Text(
                    _connecting ? '…' : 'Se connecter',
                    style: AppTextStyles.buttonMd,
                  ),
                ),
              ),
            ] else if (_connectionStatus == 'pending_sent') ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Demande de connexion envoyée.',
                style:
                    AppTextStyles.bodySm.copyWith(color: AppColors.hintColor),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Bannière membre bloqué ───────────────────────────────────────────────
  Widget _blockedBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppShapes.cardRadius,
        border: Border.all(color: AppColors.errorAccent.withValues(alpha: 0.2)),
        boxShadow: AppColors.ambientShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.errorAccent.withValues(alpha: 0.12),
              borderRadius: AppShapes.squircleRadius(AppRadius.lg),
            ),
            child: Icon(IconlyLight.shield_fail,
                size: 30, color: AppColors.errorAccent),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Membre bloqué',
            style: AppTextStyles.titleLg.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Vous ne verrez plus ses publications. Débloquez-le pour interagir '
            'à nouveau.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd
                .copyWith(color: AppColors.bodyColor, height: 1.45),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _blocking ? null : _toggleBlock,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.errorAccent,
                side: BorderSide(
                    color: AppColors.errorAccent.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: ContinuousRectangleBorder(
                  borderRadius: AppShapes.squircleRadius(AppRadius.md),
                ),
              ),
              icon: const Icon(IconlyLight.unlock, size: 18),
              label: Text(
                _blocking ? '…' : 'Débloquer',
                style: AppTextStyles.titleMd.copyWith(
                  color: AppColors.errorAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Rangée de boutons d'action (style fiche contact) ──────────────────
  Widget _actionRow() {
    final canFollow = !_isSelf;
    return Row(
      children: [
        Expanded(
          child: _ContactAction(
            icon: _isFollowing ? IconlyLight.tick_square : IconlyLight.add_user,
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
          icon: IconlyLight.message,
          label: 'Répondre',
          onTap: () => Get.toNamed(AppRoutes.communityConnections),
        );
      default:
        final canConnect = !_isSelf;
        return _ContactAction(
          icon: IconlyLight.add_user,
          label: _connecting ? '…' : 'Connecter',
          onTap: _connecting || !canConnect ? null : _connect,
        );
    }
  }

  Widget _statsCard(Map<String, dynamic> p) {
    int n(String k) => (p[k] as num?)?.toInt() ?? 0;
    Widget stat(int value, String label) => Expanded(
          child: Column(
            children: [
              AnimatedCount(
                value: value,
                builder: (_, v) => Text(
                  '$v',
                  style: AppTextStyles.heroNumber.copyWith(
                    fontSize: 22,
                    color: AppColors.primaryAccent,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.hintColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
    Widget divider() => Container(
          width: 1,
          height: 30,
          color: AppColors.outlineVariant.withValues(alpha: 0.7),
        );
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppShapes.cardRadius,
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          ...AppColors.ambientShadow,
          ...AppColors.lightShadow,
        ],
      ),
      child: Row(
        children: [
          stat(n('posts_count'), 'Publications'),
          divider(),
          stat(n('followers_count'), 'Abonnés'),
          divider(),
          stat(n('connections_count'), 'Connexions'),
        ],
      ),
    );
  }

  // ── Section Compétences + recommandations ────────────────────────────────
  Widget _skillsSection() {
    return Obx(() {
      final skills = _skills;
      if (skills.isEmpty && !_isSelf) {
        return const SizedBox.shrink();
      }
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: AppShapes.cardRadius,
          border: Border.all(color: AppColors.outlineVariant),
          boxShadow: AppColors.ambientShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(IconlyLight.star,
                    size: 18, color: AppColors.primaryAccent),
                const SizedBox(width: AppSpacing.sm),
                Text('Compétences',
                    style: AppTextStyles.titleMd
                        .copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (skills.isEmpty)
              Text(
                'Aucune compétence pour le moment. Ajoutez-en pour valoriser '
                'votre profil.',
                style:
                    AppTextStyles.bodySm.copyWith(color: AppColors.hintColor),
              )
            else
              ...skills.map(_skillTile),
            if (_isSelf) ...[
              const SizedBox(height: AppSpacing.sm),
              _addSkillRow(),
            ],
          ],
        ),
      );
    });
  }

  Widget _skillTile(Skill skill) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          borderRadius: AppShapes.squircleRadius(AppRadius.md),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(skill.name,
                      style: AppTextStyles.titleMd
                          .copyWith(fontWeight: FontWeight.w700)),
                  if (skill.endorsementsCount > 0) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(IconlyBold.heart,
                            size: 11, color: AppColors.primaryAccent),
                        const SizedBox(width: 4),
                        Text(
                          '${skill.endorsementsCount} '
                          'recommandation${skill.endorsementsCount > 1 ? 's' : ''}',
                          style: AppTextStyles.bodySm
                              .copyWith(color: AppColors.hintColor),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (_isSelf)
              PressScale(
                onTap: () => _removeSkill(skill),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(IconlyLight.close_square,
                      size: 18, color: AppColors.hintColor),
                ),
              )
            else
              _EndorseButton(
                endorsed: skill.endorsedByMe,
                onTap: () => _toggleEndorse(skill),
              ),
          ],
        ),
      ),
    );
  }

  Widget _addSkillRow() {
    final controller = TextEditingController();
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            textInputAction: TextInputAction.done,
            style: AppTextStyles.bodyMd,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Ajouter une compétence',
              hintStyle:
                  AppTextStyles.bodyMd.copyWith(color: AppColors.hintColor),
              filled: true,
              fillColor: AppColors.surfaceLow,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: AppShapes.squircleRadius(AppRadius.md),
                borderSide: BorderSide(color: AppColors.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppShapes.squircleRadius(AppRadius.md),
                borderSide: BorderSide(color: AppColors.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppShapes.squircleRadius(AppRadius.md),
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
            onSubmitted: (v) => _addSkill(v, controller),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Obx(
          () => IconButton(
            onPressed: _addingSkill.value
                ? null
                : () => _addSkill(controller.text, controller),
            icon: _addingSkill.value
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation(AppColors.primaryAccent),
                    ),
                  )
                : Icon(IconlyLight.plus, color: AppColors.primaryAccent),
          ),
        ),
      ],
    );
  }

  Future<void> _addSkill(String name, TextEditingController c) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || _addingSkill.value) return;
    AppHaptics.tap();
    _addingSkill.value = true;
    final skill = await _controller.addSkill(trimmed);
    _addingSkill.value = false;
    if (skill != null) {
      _skills.add(skill);
      c.clear();
    } else {
      AppToast.error(
          'Ajout impossible', _controller.errorMessage.value ?? 'Réessayez.');
    }
  }

  Future<void> _removeSkill(Skill skill) async {
    AppHaptics.tap();
    final index = _skills.indexWhere((s) => s.id == skill.id);
    if (index < 0) return;
    final backup = _skills[index];
    _skills.removeAt(index); // optimiste
    final ok = await _controller.removeSkill(skill.id);
    if (!ok) {
      _skills.insert(index, backup); // rollback
      AppToast.error('Suppression impossible',
          _controller.errorMessage.value ?? 'Réessayez.');
    }
  }

  Future<void> _toggleEndorse(Skill skill) async {
    AppHaptics.tap();
    final index = _skills.indexWhere((s) => s.id == skill.id);
    if (index < 0) return;
    final backup = _skills[index];
    final willEndorse = !skill.endorsedByMe;
    // Optimiste.
    _skills[index] = backup.copyWith(
      endorsedByMe: willEndorse,
      endorsementsCount:
          (backup.endorsementsCount + (willEndorse ? 1 : -1)).clamp(0, 1 << 30),
    );
    final updated =
        await _controller.endorseSkill(skill.id, endorse: willEndorse);
    final idx = _skills.indexWhere((s) => s.id == skill.id);
    if (idx < 0) return;
    if (updated != null) {
      _skills[idx] = backup.copyWith(
        endorsedByMe: updated.endorsedByMe,
        endorsementsCount: updated.endorsementsCount,
      );
    } else {
      _skills[idx] = backup; // rollback
      AppToast.error(
          'Action impossible', _controller.errorMessage.value ?? 'Réessayez.');
    }
  }
}

/// Squelette de chargement du profil : avatar + nom + barre de stats + carte.
class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
      child: Column(
        children: [
          SizedBox(height: AppSpacing.sm),
          Center(child: SkeletonBox(height: 108, width: 108, radius: 54)),
          SizedBox(height: AppSpacing.lg),
          Center(child: SkeletonBox(height: 18, width: 160)),
          SizedBox(height: AppSpacing.sm),
          Center(child: SkeletonBox(height: 12, width: 110)),
          SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(child: SkeletonBox(height: 46, radius: 14)),
              SizedBox(width: AppSpacing.md),
              Expanded(child: SkeletonBox(height: 46, radius: 14)),
              SizedBox(width: AppSpacing.md),
              Expanded(child: SkeletonBox(height: 46, radius: 14)),
            ],
          ),
          SizedBox(height: AppSpacing.xl),
          SkeletonBox(height: 78, width: double.infinity, radius: 16),
          SizedBox(height: AppSpacing.lg),
          SkeletonBox(height: 140, width: double.infinity, radius: 16),
        ],
      ),
    );
  }
}

/// Pastille « Recommander » / « Recommandé » (toggle endorse).
class _EndorseButton extends StatelessWidget {
  const _EndorseButton({required this.endorsed, required this.onTap});

  final bool endorsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
        decoration: BoxDecoration(
          color: endorsed
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.surfaceLow,
          borderRadius: AppShapes.pill,
          border: Border.all(
            color: endorsed
                ? AppColors.primary.withValues(alpha: 0.5)
                : AppColors.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              endorsed ? IconlyBold.heart : IconlyLight.heart,
              size: 14,
              color: endorsed ? AppColors.primaryAccent : AppColors.hintColor,
            ),
            const SizedBox(width: 6),
            Text(
              endorsed ? 'Recommandé' : 'Recommander',
              style: AppTextStyles.labelMd.copyWith(
                color: endorsed ? AppColors.primaryAccent : AppColors.bodyColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
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
        ? AppColors.primaryAccent
        : enabled
            ? AppColors.primaryDark
            : AppColors.hintColor;
    return PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primaryAccent.withValues(alpha: 0.12)
              : AppColors.surfaceLow,
          borderRadius: AppShapes.squircleRadius(AppRadius.md),
          border: Border.all(
            color: active
                ? AppColors.primaryAccent.withValues(alpha: 0.4)
                : AppColors.outlineVariant,
          ),
          boxShadow: AppColors.lightShadow,
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
