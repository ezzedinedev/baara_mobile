import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:share_plus/share_plus.dart';

import 'package:opportune_bf/app/core/constants/api_constants.dart';
import 'package:opportune_bf/app/core/network/api_provider.dart';
import 'package:opportune_bf/app/core/theme/app_colors.dart';
import 'package:opportune_bf/app/core/theme/app_dimens.dart';
import 'package:opportune_bf/app/core/theme/app_motion.dart';
import 'package:opportune_bf/app/core/theme/app_shapes.dart';
import 'package:opportune_bf/app/core/theme/app_text_styles.dart';
import 'package:opportune_bf/app/core/utils/haptics.dart';
import 'package:opportune_bf/app/core/utils/user_facing_error.dart';
import 'package:opportune_bf/app/core/widgets/widgets.dart';
import 'package:opportune_bf/routes/app_routes.dart';
import 'package:opportune_bf/app/features/messaging/data/repositories/messaging_repository_impl.dart';
import 'package:opportune_bf/app/features/messaging/presentation/controllers/messages_controller.dart';
import '../../domain/entities/network_user.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/skill.dart';
import '../controllers/community_controller.dart';
import '../widgets/post_card.dart';
import '../widgets/comment_sheet.dart';
import '../widgets/report_sheet.dart';
import 'compose_post_screen.dart';

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
    _scrollCtrl.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  /// Pagination du mur de publications : déclenche le chargement de la page
  /// suivante avant d'atteindre tout en bas de la liste.
  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 400) {
      _controller.loadMoreUserPosts(_userId);
    }
  }

  /// Rechargement complet (skeleton + reset). [silent] = pull-to-refresh :
  /// on garde le contenu visible (pas de skeleton), l'anneau de marque suffit.
  Future<void> _load({bool silent = false}) async {
    setState(() {
      if (!silent) _loading = true;
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
      // Mur de publications (façon Facebook) : chargé seulement si le profil
      // est consultable (ni bloqué, ni verrouillé pour un non-connecté).
      if (!_hasBlocked && !(_isLocked && !_isSelf)) {
        _controller.loadUserPosts(_userId);
      }
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

  Future<void> _share() async {
    AppHaptics.tap();
    final name = _profile?['full_name']?.toString() ?? 'Ce membre';
    final url = ApiConstants.webProfileUrl(_userId);
    await Share.share(
      'Découvrez le profil de $name sur OpporTune.\n$url',
      subject: 'Profil de $name — OpporTune',
    );
  }

  Widget _content() {
    final profile = _profile ?? const {};
    final name = profile['full_name']?.toString() ?? 'Membre';
    final role = profile['role']?.toString() ?? '';
    final bio = profile['bio']?.toString() ?? '';
    return AppRefreshIndicator(
      onRefresh: () => _load(silent: true),
      child: ListView(
        controller: _scrollCtrl,
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
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
                  _mediaSection(),
                  const SizedBox(height: AppSpacing.lg),
                  _publicationsSection(),
                ],
              ],
            ],
          ),
        ),
        ],
      ),
    );
  }

  // ── Mur de publications (façon Facebook) ─────────────────────────────────
  Widget _publicationsSection() {
    return Obx(() {
      final loading = _controller.profilePostsLoading.value;
      final error = _controller.profilePostsError.value;
      final items = _controller.profilePosts;
      final loadingMore = _controller.profilePostsLoadingMore.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(
                left: AppSpacing.xs, bottom: AppSpacing.md),
            child: Row(
              children: [
                Icon(IconlyBold.document,
                    size: 18, color: AppColors.primaryAccent),
                const SizedBox(width: AppSpacing.sm),
                Text('Publications',
                    style: AppTextStyles.titleMd
                        .copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          if (loading)
            const _PostsSkeleton()
          else if (error != null)
            _postsError(error)
          else if (items.isEmpty)
            _postsEmpty()
          else ...[
            for (final post in items)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: _profilePostCard(post),
              ),
            if (loadingMore)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation(AppColors.primaryAccent),
                    ),
                  ),
                ),
              ),
          ],
        ],
      );
    });
  }

  // ── Section Médias (grille photos, façon Facebook « Photos ») ────────────
  Widget _mediaSection() {
    return Obx(() {
      // Images extraites des publications déjà chargées (max 6 en aperçu).
      // La grille charge la miniature ; le visionneur ouvre l'image pleine.
      final items = <({String thumb, String full})>[
        for (final p in _controller.profilePosts)
          for (final m in p.images)
            if (m.url != null && m.url!.isNotEmpty)
              (thumb: m.previewUrl ?? m.url!, full: m.url!),
      ];
      if (items.isEmpty) return const SizedBox.shrink();
      final preview = items.take(6).toList();
      final extra = items.length - preview.length;
      final fullUrls = items.map((e) => e.full).toList();

      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg),
        child: Container(
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
                  Icon(IconlyBold.image,
                      size: 18, color: AppColors.primaryAccent),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Médias',
                      style: AppTextStyles.titleMd
                          .copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                children: [
                  for (var i = 0; i < preview.length; i++)
                    _mediaThumb(
                      preview[i].thumb,
                      // Sur la dernière vignette, overlay « +N ».
                      overlayMore: (i == preview.length - 1 && extra > 0)
                          ? extra
                          : 0,
                      onTap: () => _openMediaViewer(fullUrls, i),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _mediaThumb(String url, {int overlayMore = 0, VoidCallback? onTap}) {
    return PressScale(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: AppShapes.squircleRadius(AppRadius.sm),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              ApiConstants.resolveMediaUrl(url) ?? '',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.surfaceLow,
                alignment: Alignment.center,
                child: Icon(Icons.broken_image_outlined,
                    color: AppColors.hintColor, size: 20),
              ),
            ),
            if (overlayMore > 0)
              Container(
                color: Colors.black.withValues(alpha: 0.45),
                alignment: Alignment.center,
                child: Text(
                  '+$overlayMore',
                  style: AppTextStyles.titleLg.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openMediaViewer(List<String> urls, int initialIndex) {
    AppHaptics.tap();
    Navigator.of(context).push<void>(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) =>
            _MediaViewer(urls: urls, initialIndex: initialIndex),
      ),
    );
  }

  Widget _profilePostCard(Post post) {
    final isOwn = post.author?.isSelf == true || _isSelf;
    return PostCard(
      post: post,
      onReact: (type) => _controller.toggleProfileReaction(post.id, type),
      onVote: (optionId) => _controller.votePoll(post.id, optionId),
      onSave: () => _controller.toggleSave(post.id),
      onComment: () => showCommentSheet(context, _controller, post),
      onRepost: () => _controller.repost(post.id),
      // On est déjà sur le profil de l'auteur : pas de suivi ni de navigation.
      onFollow: null,
      onTapAuthor: null,
      onReport: isOwn ? null : () => showReportSheet(context, _controller, post.id),
      onEdit: isOwn ? () => _editPost(post) : null,
      onDelete: isOwn ? () => _deletePost(post.id) : null,
    );
  }

  void _editPost(Post post) {
    AppHaptics.tap();
    Get.to<void>(
      () => ComposePostScreen(editing: post),
      fullscreenDialog: true,
      transition: Transition.downToUp,
    );
  }

  void _deletePost(String postId) {
    showAdaptiveDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog.adaptive(
        title: const Text('Supprimer'),
        content: const Text('Supprimer cette publication ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _controller.deletePost(postId);
            },
            child:
                Text('Supprimer', style: TextStyle(color: AppColors.errorAccent)),
          ),
        ],
      ),
    );
  }

  Widget _postsEmpty() {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppShapes.cardRadius,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceIconSoft,
              borderRadius: AppShapes.squircleRadius(AppRadius.lg),
            ),
            child: Icon(IconlyLight.document,
                size: 28, color: AppColors.primaryAccent),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _isSelf
                ? 'Vous n’avez pas encore publié'
                : 'Aucune publication',
            textAlign: TextAlign.center,
            style: AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _isSelf
                ? 'Partagez une actualité avec votre réseau.'
                : 'Ce membre n’a rien publié pour le moment.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.hintColor),
          ),
        ],
      ),
    );
  }

  Widget _postsError(String message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppShapes.cardRadius,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.bodyColor),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton.icon(
            onPressed: () => _controller.loadUserPosts(_userId),
            icon: const Icon(IconlyLight.arrow_right_circle, size: 18),
            label: const Text('Réessayer'),
          ),
        ],
      ),
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
    // Sur son propre profil : un seul CTA « Modifier le profil ».
    if (_isSelf) {
      return Row(
        children: [
          Expanded(
            child: _ContactAction(
              icon: IconlyLight.edit,
              label: 'Modifier le profil',
              active: true,
              onTap: () {
                AppHaptics.tap();
                Get.toNamed(AppRoutes.profileEdit);
              },
            ),
          ),
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
        if (!_isSelf) ...[
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _ContactAction(
              icon: IconlyLight.chat,
              label: 'Message',
              onTap: _openConversation,
            ),
          ),
        ],
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

  /// Démarre (ou rouvre) une conversation directe avec ce membre puis ouvre le
  /// fil. Réutilise le MessagesController s'il est en mémoire (il met à jour sa
  /// liste de conversations), sinon passe par le repository directement.
  Future<void> _openConversation() async {
    AppHaptics.tap();
    String? convId;
    if (Get.isRegistered<MessagesController>()) {
      final conv =
          await Get.find<MessagesController>().startConversationWith(_userId);
      convId = conv?.id;
    } else {
      try {
        final repo =
            MessagingRepositoryImpl(apiProvider: Get.find<ApiProvider>());
        final conv = await repo.startConversation(_userId);
        convId = conv.id;
      } catch (_) {
        convId = null;
      }
    }
    if (convId != null && convId.isNotEmpty) {
      Get.toNamed(AppRoutes.conversation.replaceFirst(':id', convId));
    } else {
      AppToast.error(
          'Messagerie', 'Impossible de démarrer la conversation.');
    }
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

  /// Ouvre la liste paginée des abonnés / connexions du membre.
  void _openNetworkList(String mode) {
    AppHaptics.tap();
    final name = _profile?['full_name']?.toString();
    Get.toNamed(
      AppRoutes.communityNetwork.replaceFirst(':id', _userId),
      arguments: {'mode': mode, 'name': name},
    );
  }

  /// Fait défiler jusqu'au mur de publications (tap sur le compteur).
  void _scrollToPosts() {
    AppHaptics.tap();
    if (!_scrollCtrl.hasClients) return;
    _scrollCtrl.animateTo(
      _scrollCtrl.position.maxScrollExtent,
      duration: AppMotion.medium,
      curve: AppMotion.emphasizedDecelerate,
    );
  }

  Widget _statsCard(Map<String, dynamic> p) {
    int n(String k) => (p[k] as num?)?.toInt() ?? 0;
    Widget stat(int value, String label, {VoidCallback? onTap}) => Expanded(
          child: PressScale(
            onTap: onTap,
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
          stat(n('posts_count'), 'Publications', onTap: _scrollToPosts),
          divider(),
          stat(n('followers_count'), 'Abonnés',
              onTap: () => _openNetworkList('followers')),
          divider(),
          stat(n('connections_count'), 'Connexions',
              onTap: () => _openNetworkList('connections')),
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

/// Visionneuse plein écran des médias (swipe horizontal + pinch-to-zoom).
class _MediaViewer extends StatefulWidget {
  const _MediaViewer({required this.urls, required this.initialIndex});

  final List<String> urls;
  final int initialIndex;

  @override
  State<_MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<_MediaViewer> {
  late final PageController _pageCtrl;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageCtrl,
            itemCount: widget.urls.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: Image.network(
                  ApiConstants.resolveMediaUrl(widget.urls[i]) ?? '',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white.withValues(alpha: 0.6),
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
          // Bouton fermer + compteur.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                  if (widget.urls.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: AppShapes.pill,
                      ),
                      child: Text(
                        '${_index + 1} / ${widget.urls.length}',
                        style: AppTextStyles.labelMd.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Squelette du mur de publications (2 cartes fantômes).
class _PostsSkeleton extends StatelessWidget {
  const _PostsSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget card() => Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: AppShapes.cardRadius,
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SkeletonBox(height: 42, width: 42, radius: 21),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(height: 12, width: 120),
                        SizedBox(height: 6),
                        SkeletonBox(height: 10, width: 80),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md),
              SkeletonBox(height: 12, width: double.infinity),
              SizedBox(height: 6),
              SkeletonBox(height: 12, width: 220),
            ],
          ),
        );
    return Column(children: [card(), card()]);
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
