import 'package:get/get.dart';
import 'package:baara/app/core/network/api_provider.dart';
import 'package:baara/app/core/utils/user_facing_error.dart';
import 'package:baara/app/core/widgets/widgets.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/network_user.dart';
import '../../domain/entities/community_comment.dart';
import '../../domain/entities/connection_request.dart';
import '../../domain/entities/skill.dart';
import '../../domain/entities/profile_viewer.dart';
import '../../domain/repositories/i_community_repository.dart';

class CommunityController extends GetxController {
  final ICommunityRepository _repository;
  CommunityController(this._repository);

  final posts = <Post>[].obs;
  final suggestions = <NetworkUser>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final isPublishing = false.obs;
  final hasMore = false.obs;
  final errorMessage = RxnString();
  final activeType = RxnString(); // null = Tout
  // Onglet du feed intelligent : foryou | recent | connections.
  final feedTab = 'foryou'.obs;

  int _page = 1;

  @override
  void onInit() {
    super.onInit();
    loadFeed();
    loadSuggestions();
    // Charge les demandes de connexion en attente dès le départ pour que le
    // badge de l'onglet Réseau soit exact sans avoir à ouvrir l'écran dédié.
    loadPendingConnections();
  }

  Future<void> loadFeed({String? type}) async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      activeType.value = type;
      _page = 1;
      final result = await _repository.getFeed(
        tab: feedTab.value,
        type: type,
        page: 1,
      );
      posts.assignAll(result.items);
      hasMore.value = result.hasMore;
    } catch (e) {
      errorMessage.value = userFacingError(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Change d'onglet (Pour vous / Récent / Connexions) et recharge le fil.
  Future<void> changeTab(String tab) async {
    if (feedTab.value == tab) return;
    feedTab.value = tab;
    await loadFeed(type: activeType.value);
  }

  Future<void> refreshFeed() => loadFeed(type: activeType.value);

  Future<void> loadMore() async {
    if (isLoadingMore.value || isLoading.value || !hasMore.value) return;
    try {
      isLoadingMore.value = true;
      final result = await _repository.getFeed(
        tab: feedTab.value,
        type: activeType.value,
        page: _page + 1,
      );
      _page += 1;
      posts.addAll(result.items);
      hasMore.value = result.hasMore;
    } catch (_) {
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> loadSuggestions() async {
    try {
      suggestions.assignAll(await _repository.getSuggestions());
      // Les accroches IA arrivent ensuite, sans bloquer l'affichage de la liste.
      loadSuggestionInsights();
    } catch (_) {}
  }

  /// Charge les accroches IA (#3) et les fusionne dans [suggestions]. Non
  /// bloquant (la liste est déjà affichée), échec silencieux.
  Future<void> loadSuggestionInsights() async {
    if (suggestions.isEmpty) return;
    try {
      final insights = await _repository.getSuggestionInsights();
      if (insights.isEmpty) return;
      final byId = {
        for (final i in insights)
          if (i.insight != null) i.userId: i.insight!,
      };
      for (var i = 0; i < suggestions.length; i++) {
        final text = byId[suggestions[i].id];
        if (text != null) {
          suggestions[i] = suggestions[i].copyWith(insight: text);
        }
      }
    } catch (_) {}
  }

  // ── Explore (posts publics tendance) ──────────────────────────────────────
  final explorePosts = <Post>[].obs;
  final exploreLoading = false.obs;
  final exploreLoadingMore = false.obs;
  final exploreHasMore = false.obs;
  int _explorePage = 1;

  Future<void> loadExplore() async {
    try {
      exploreLoading.value = true;
      _explorePage = 1;
      final result = await _repository.getExplore(page: 1);
      explorePosts.assignAll(result.items);
      exploreHasMore.value = result.hasMore;
    } catch (e) {
      errorMessage.value = userFacingError(e);
    } finally {
      exploreLoading.value = false;
    }
  }

  Future<void> loadMoreExplore() async {
    if (exploreLoadingMore.value ||
        exploreLoading.value ||
        !exploreHasMore.value) {
      return;
    }
    try {
      exploreLoadingMore.value = true;
      final result = await _repository.getExplore(page: _explorePage + 1);
      _explorePage += 1;
      explorePosts.addAll(result.items);
      exploreHasMore.value = result.hasMore;
    } catch (_) {
    } finally {
      exploreLoadingMore.value = false;
    }
  }

  /// Publie une nouvelle publication et l'ajoute en tête du fil.
  Future<bool> publish({
    required String body,
    String category = 'general',
    String visibility = 'public',
    List<String> mediaPaths = const [],
    PollDraft? poll,
  }) async {
    // Un sondage seul (sans texte) est une publication valable.
    if (body.trim().isEmpty && mediaPaths.isEmpty && poll == null) return false;
    try {
      isPublishing.value = true;
      final post = await _repository.createPost(
        body: body,
        category: category,
        visibility: visibility,
        mediaPaths: mediaPaths,
        poll: poll,
      );
      posts.insert(0, post);
      return true;
    } catch (e) {
      errorMessage.value = userFacingError(e);
      return false;
    } finally {
      isPublishing.value = false;
    }
  }

  // ── Wave 2 — Sondages ─────────────────────────────────────────────────────
  /// Vote (toggle) à un sondage. Optimiste sur les listes [posts] ET
  /// [explorePosts] ET [savedPosts], puis réalignement sur la réponse serveur,
  /// rollback intégral en cas d'échec.
  Future<void> votePoll(String postId, String optionId) async {
    final lists = [posts, explorePosts, savedPosts, profilePosts];
    // Sauvegarde pour rollback (le post peut être présent dans plusieurs listes).
    final backups = <RxList<Post>, Post>{};
    PostPoll? optimistic;
    bool hadPoll = false;

    for (final list in lists) {
      final idx = list.indexWhere((p) => p.id == postId);
      if (idx < 0) continue;
      final post = list[idx];
      final poll = post.poll;
      if (poll == null || poll.isClosed) continue;
      hadPoll = true;
      backups[list] = post;
      optimistic ??= _applyVoteLocally(poll, optionId);
      list[idx] = post.copyWith(poll: optimistic);
    }
    if (!hadPoll) return;

    try {
      final updated = await _repository.votePoll(
        // L'API attend l'id du sondage, pas du post.
        backups.values.first.poll!.id,
        _resolveVoteSelection(backups.values.first.poll!, optionId),
      );
      for (final list in lists) {
        final idx = list.indexWhere((p) => p.id == postId);
        if (idx >= 0) list[idx] = list[idx].copyWith(poll: updated);
      }
    } catch (e) {
      backups.forEach((list, original) {
        final idx = list.indexWhere((p) => p.id == postId);
        if (idx >= 0) list[idx] = original; // rollback
      });
      errorMessage.value = userFacingError(e);
    }
  }

  /// Calcule l'état optimiste d'un sondage après tap sur [optionId].
  PostPoll _applyVoteLocally(PostPoll poll, String optionId) {
    final tapped = poll.options.firstWhere(
      (o) => o.id == optionId,
      orElse: () => poll.options.first,
    );
    final willSelect = !tapped.votedByMe;
    var total = poll.totalVotes;
    final myVotes = List<String>.from(poll.myVotes);

    final options = poll.options.map((o) {
      if (!poll.multiple) {
        // Choix unique : une seule option cochée à la fois.
        if (o.id == optionId) {
          return o.copyWith(
            votedByMe: willSelect,
            votesCount: willSelect ? o.votesCount + 1 : o.votesCount - 1,
          );
        }
        // Si on sélectionne une nouvelle option, l'ancienne se décoche.
        if (willSelect && o.votedByMe) {
          return o.copyWith(votedByMe: false, votesCount: o.votesCount - 1);
        }
        return o;
      }
      // Choix multiples : toggle l'option tapée uniquement.
      if (o.id == optionId) {
        return o.copyWith(
          votedByMe: willSelect,
          votesCount: willSelect ? o.votesCount + 1 : o.votesCount - 1,
        );
      }
      return o;
    }).toList();

    if (!poll.multiple) {
      total = willSelect && myVotes.isEmpty ? total + 1 : total;
      if (!willSelect) total -= 1;
      myVotes
        ..clear()
        ..addAll(willSelect ? [optionId] : const []);
    } else {
      total += willSelect ? 1 : -1;
      if (willSelect) {
        myVotes.add(optionId);
      } else {
        myVotes.remove(optionId);
      }
    }

    return poll.copyWith(
      options: options,
      totalVotes: total < 0 ? 0 : total,
      myVotes: myVotes,
    );
  }

  /// Détermine le payload `option_ids` envoyé au serveur (toggle / exclusif).
  List<String> _resolveVoteSelection(PostPoll poll, String optionId) {
    final tapped = poll.options.firstWhere(
      (o) => o.id == optionId,
      orElse: () => poll.options.first,
    );
    final willSelect = !tapped.votedByMe;
    if (!poll.multiple) {
      return willSelect ? [optionId] : const [];
    }
    final selected =
        poll.options.where((o) => o.votedByMe).map((o) => o.id).toSet();
    if (willSelect) {
      selected.add(optionId);
    } else {
      selected.remove(optionId);
    }
    return selected.toList();
  }

  // ── Wave 2 — Enregistrer (signet) ─────────────────────────────────────────
  /// Enregistre/retire une publication. Optimiste sur toutes les listes ; retire
  /// le post de [savedPosts] s'il est désenregistré. Rollback sur échec.
  Future<void> toggleSave(String postId) async {
    final lists = [posts, explorePosts, savedPosts, profilePosts];
    bool? willSave;
    final backups = <RxList<Post>, Post>{};
    Post? removedFromSaved;
    int removedIndex = -1;

    for (final list in lists) {
      final idx = list.indexWhere((p) => p.id == postId);
      if (idx < 0) continue;
      final post = list[idx];
      willSave ??= !post.isSaved;
      backups[list] = post;
      list[idx] = post.copyWith(isSaved: willSave);
    }
    if (willSave == null) return;

    // Si on retire, le post quitte la liste « Enregistrés ».
    if (!willSave) {
      removedIndex = savedPosts.indexWhere((p) => p.id == postId);
      if (removedIndex >= 0) {
        removedFromSaved = savedPosts[removedIndex];
        savedPosts.removeAt(removedIndex);
      }
    }

    try {
      await _repository.toggleSave(postId, save: willSave);
    } catch (e) {
      backups.forEach((list, original) {
        final idx = list.indexWhere((p) => p.id == postId);
        if (idx >= 0) list[idx] = original; // rollback in-place
      });
      if (removedFromSaved != null) {
        savedPosts.insert(
          removedIndex.clamp(0, savedPosts.length),
          removedFromSaved,
        );
      }
      errorMessage.value = userFacingError(e);
    }
  }

  // ── Wave 2 — Publications enregistrées ────────────────────────────────────
  final savedPosts = <Post>[].obs;
  final savedLoading = false.obs;
  final savedLoadingMore = false.obs;
  final savedHasMore = false.obs;
  final savedError = RxnString();
  int _savedPage = 1;

  Future<void> loadSaved() async {
    try {
      savedLoading.value = true;
      savedError.value = null;
      _savedPage = 1;
      final result = await _repository.getSaved(page: 1);
      savedPosts.assignAll(result.items);
      savedHasMore.value = result.hasMore;
    } catch (e) {
      savedError.value = userFacingError(e);
    } finally {
      savedLoading.value = false;
    }
  }

  Future<void> loadMoreSaved() async {
    if (savedLoadingMore.value || savedLoading.value || !savedHasMore.value) {
      return;
    }
    try {
      savedLoadingMore.value = true;
      final result = await _repository.getSaved(page: _savedPage + 1);
      _savedPage += 1;
      savedPosts.addAll(result.items);
      savedHasMore.value = result.hasMore;
    } catch (_) {
    } finally {
      savedLoadingMore.value = false;
    }
  }

  // ── Wave 2 — Aperçu de lien (composer) ────────────────────────────────────
  Future<PostLinkPreview?> fetchLinkPreview(String url) async {
    try {
      return await _repository.fetchLinkPreview(url);
    } catch (_) {
      return null;
    }
  }

  /// Réaction optimiste avec gestion fine de [Post.myReaction] et
  /// [Post.reactionsBreakdown]. Règles :
  /// - même type que la réaction courante → on la retire (toggle off) ;
  /// - aucun type courant → on ajoute ;
  /// - type différent → on échange (l'ancien -1, le nouveau +1, total stable).
  /// Rollback intégral sur échec réseau.
  Future<void> toggleReaction(String postId, String type) =>
      _toggleReactionIn(posts, postId, type);

  /// Même réaction optimiste, appliquée à la liste Explore.
  Future<void> toggleExploreReaction(String postId, String type) =>
      _toggleReactionIn(explorePosts, postId, type);

  Future<void> _toggleReactionIn(
      RxList<Post> list, String postId, String type) async {
    final index = list.indexWhere((p) => p.id == postId);
    if (index < 0) return;
    final current = list[index];
    final previous = current.myReaction;

    final breakdown = Map<String, int>.from(current.reactionsBreakdown);
    int count = current.reactionsCount;
    String? nextReaction;

    if (previous == type) {
      // Toggle off.
      breakdown[type] = ((breakdown[type] ?? 1) - 1).clamp(0, 1 << 30);
      count = (count - 1).clamp(0, 1 << 30);
      nextReaction = null;
    } else if (previous == null) {
      // Nouvelle réaction.
      breakdown[type] = (breakdown[type] ?? 0) + 1;
      count = count + 1;
      nextReaction = type;
    } else {
      // Échange : ancien -1, nouveau +1 (total inchangé).
      breakdown[previous] = ((breakdown[previous] ?? 1) - 1).clamp(0, 1 << 30);
      breakdown[type] = (breakdown[type] ?? 0) + 1;
      nextReaction = type;
    }

    list[index] = current.copyWith(
      isLiked: nextReaction != null,
      reactionsCount: count,
      reactionsBreakdown: breakdown,
      myReaction: nextReaction,
      clearMyReaction: nextReaction == null,
    );

    try {
      final res = await _repository.react(postId, type);
      final serverCount = (res['reactions_count'] as num?)?.toInt();
      if (serverCount != null) {
        final idx = list.indexWhere((p) => p.id == postId);
        if (idx >= 0) {
          list[idx] = list[idx].copyWith(reactionsCount: serverCount);
        }
      }
    } catch (_) {
      final idx = list.indexWhere((p) => p.id == postId);
      if (idx >= 0) list[idx] = current; // rollback intégral
    }
  }

  /// Édition optimiste d'une publication (remplace le post localement, rollback).
  Future<bool> editPost(String id, String body) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return false;
    // Le post peut figurer dans plusieurs listes (fil, explore, enregistrés,
    // mur de profil) : édition optimiste partout, rollback intégral sur échec.
    final lists = [posts, explorePosts, savedPosts, profilePosts];
    final backups = <RxList<Post>, Post>{};
    for (final list in lists) {
      final idx = list.indexWhere((p) => p.id == id);
      if (idx < 0) continue;
      backups[list] = list[idx];
      list[idx] = list[idx].copyWith(
        body: trimmed,
        isEdited: true,
        editedAt: DateTime.now(),
      );
    }
    try {
      final updated = await _repository.updatePost(id, trimmed);
      for (final list in lists) {
        final idx = list.indexWhere((p) => p.id == id);
        if (idx >= 0) list[idx] = updated;
      }
      return true;
    } catch (e) {
      backups.forEach((list, original) {
        final idx = list.indexWhere((p) => p.id == id);
        if (idx >= 0) list[idx] = original; // rollback
      });
      errorMessage.value = userFacingError(e);
      return false;
    }
  }

  /// Édite un commentaire (utilisé par la feuille de commentaires).
  Future<CommunityComment?> editComment(String id, String body) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return null;
    try {
      return await _repository.updateComment(id, trimmed);
    } catch (e) {
      errorMessage.value = userFacingError(e);
      return null;
    }
  }

  // ── Hashtags & mentions ───────────────────────────────────────────────────
  final trendingHashtags = <TrendingHashtag>[].obs;

  /// Charge (et met en cache) les hashtags tendance.
  Future<List<TrendingHashtag>> loadTrendingHashtags() async {
    try {
      final list = await _repository.getTrendingHashtags();
      trendingHashtags.assignAll(list);
      return list;
    } catch (_) {
      return trendingHashtags;
    }
  }

  /// Autocomplétion @mentions (sans état persistant : appel direct).
  Future<List<Mentionable>> fetchMentionables(String q) async {
    final query = q.trim();
    if (query.isEmpty) return const [];
    try {
      return await _repository.getMentionables(query);
    } catch (_) {
      return const [];
    }
  }

  // ── Wave 2 — Assistant IA (composer + résumé + traduction) ───────────────
  /// Message doux pour une indisponibilité de l'assistant IA (502). Pour les
  /// autres erreurs, on retombe sur [userFacingError] (jamais de détail brut).
  String aiError(Object e) {
    final code = e is ApiException ? e.statusCode : null;
    if (code == 502 || code == 503 || code == 504) {
      return 'Assistant indisponible pour le moment. Réessayez dans un instant.';
    }
    return userFacingError(e);
  }

  /// Aide à la rédaction. Retourne le résultat IA ou `null` (le caller affiche
  /// l'erreur via [aiError]). On ne stocke pas d'état : appel direct.
  Future<AiComposeResult?> aiCompose(String draft, String action) async {
    try {
      return await _repository.aiCompose(draft, action);
    } catch (e) {
      AppToast.error('Assistant IA', aiError(e));
      return null;
    }
  }

  /// Résumé IA d'une publication. Retourne le texte ou `null` (toast d'erreur).
  Future<String?> summarizePost(String postId) async {
    try {
      final summary = await _repository.summarizePost(postId);
      return summary.trim().isEmpty ? null : summary;
    } catch (e) {
      AppToast.error('Résumé IA', aiError(e));
      return null;
    }
  }

  /// Traduction IA d'une publication. Retourne le texte ou `null` (toast).
  Future<String?> translatePost(String postId, String lang) async {
    try {
      final translation = await _repository.translatePost(postId, lang);
      return translation.trim().isEmpty ? null : translation;
    } catch (e) {
      AppToast.error('Traduction IA', aiError(e));
      return null;
    }
  }

  Future<void> repost(String postId, {String? body}) async {
    try {
      final post = await _repository.repost(postId, body: body);
      posts.insert(0, post);
    } catch (e) {
      errorMessage.value = userFacingError(e);
    }
  }

  Future<void> deletePost(String postId) async {
    // Retire de toutes les listes où le post peut apparaître, rollback global.
    final lists = [posts, explorePosts, savedPosts, profilePosts];
    final backups = <RxList<Post>, List<Post>>{
      for (final list in lists) list: List<Post>.from(list),
    };
    for (final list in lists) {
      list.removeWhere((p) => p.id == postId);
    }
    try {
      await _repository.deletePost(postId);
    } catch (_) {
      backups.forEach((list, backup) => list.assignAll(backup)); // rollback
    }
  }

  // ── Abonnements (Suivre / Suivi) ────────────────────────────────────────
  /// Suit/ne suit plus l'auteur. Optimiste : met à jour TOUS les posts de cet
  /// auteur dans le fil (le bouton bascule partout), rollback si l'API échoue.
  Future<void> toggleFollow(NetworkUser user) async {
    if (user.isSelf || user.id.isEmpty) return;
    final willFollow = !user.isFollowing;
    _applyFollowState(user.id, willFollow);
    try {
      if (willFollow) {
        await _repository.follow(user.id);
      } else {
        await _repository.unfollow(user.id);
      }
      // Une fois suivi, le membre quitte les suggestions « à suivre ».
      if (willFollow) suggestions.removeWhere((u) => u.id == user.id);
    } catch (e) {
      _applyFollowState(user.id, !willFollow); // rollback
      errorMessage.value = userFacingError(e);
    }
  }

  void _applyFollowState(String userId, bool isFollowing) {
    for (var i = 0; i < posts.length; i++) {
      final author = posts[i].author;
      if (author != null && author.id == userId) {
        posts[i] = _copyWith(posts[i],
            author: author.copyWith(isFollowing: isFollowing));
      }
    }
  }

  // ── Connexions, signalement, recherche, profil ────────────────────────
  final pendingConnections = <ConnectionRequest>[].obs;
  final isLoadingConnections = false.obs;
  final connectionsErrorMessage = RxnString();

  /// Envoie une demande de connexion (optimiste sur l'état du membre).
  Future<bool> connectUser(NetworkUser user) async {
    if (user.isSelf || user.id.isEmpty) return false;
    try {
      await _repository.connect(user.id);
      _applyConnectionState(user.id, 'pending_sent');
      return true;
    } catch (e) {
      errorMessage.value = userFacingError(e);
      return false;
    }
  }

  void _applyConnectionState(String userId, String status) {
    for (var i = 0; i < posts.length; i++) {
      final author = posts[i].author;
      if (author != null && author.id == userId) {
        posts[i] = _copyWith(posts[i],
            author: author.copyWith(connectionStatus: status));
      }
    }
    final idx = suggestions.indexWhere((u) => u.id == userId);
    if (idx >= 0) {
      suggestions[idx] = suggestions[idx].copyWith(connectionStatus: status);
    }
  }

  /// Signale une publication pour un motif donné.
  Future<bool> reportPost(String postId, String reason) async {
    try {
      await _repository.report(postId, reason);
      return true;
    } catch (e) {
      errorMessage.value = userFacingError(e);
      return false;
    }
  }

  Future<Map<String, dynamic>> fetchUserProfile(String userId) =>
      _repository.getProfile(userId);

  // Listes Abonnés / Connexions d'un membre (stats cliquables du profil).
  Future<NetworkUserPage> fetchFollowers(String userId, {int page = 1}) =>
      _repository.getFollowers(userId, page: page);
  Future<NetworkUserPage> fetchUserConnections(String userId, {int page = 1}) =>
      _repository.getUserConnections(userId, page: page);

  // ── Mur de profil — publications d'un membre (façon Facebook) ─────────────
  /// Publications du membre actuellement affiché sur l'écran profil. Une seule
  /// liste partagée : on la réinitialise à chaque ouverture de profil ([_profilePostsUserId]
  /// garde l'identité courante pour ignorer les réponses obsolètes).
  final profilePosts = <Post>[].obs;
  final profilePostsLoading = false.obs;
  final profilePostsLoadingMore = false.obs;
  final profilePostsHasMore = false.obs;
  final profilePostsError = RxnString();
  String _profilePostsUserId = '';
  int _profilePostsPage = 1;

  /// Charge la 1re page des publications d'un membre (vide la liste précédente).
  Future<void> loadUserPosts(String userId) async {
    if (userId.isEmpty) return;
    _profilePostsUserId = userId;
    profilePosts.clear();
    try {
      profilePostsLoading.value = true;
      profilePostsError.value = null;
      _profilePostsPage = 1;
      final result = await _repository.getUserPosts(userId, page: 1);
      if (_profilePostsUserId != userId) return; // profil changé entre-temps
      profilePosts.assignAll(result.items);
      profilePostsHasMore.value = result.hasMore;
    } catch (e) {
      if (_profilePostsUserId != userId) return;
      profilePostsError.value = userFacingError(e);
    } finally {
      if (_profilePostsUserId == userId) profilePostsLoading.value = false;
    }
  }

  /// Pagination du mur de profil (scroll en bas de l'écran profil).
  Future<void> loadMoreUserPosts(String userId) async {
    if (profilePostsLoadingMore.value ||
        profilePostsLoading.value ||
        !profilePostsHasMore.value ||
        _profilePostsUserId != userId) {
      return;
    }
    try {
      profilePostsLoadingMore.value = true;
      final result =
          await _repository.getUserPosts(userId, page: _profilePostsPage + 1);
      if (_profilePostsUserId != userId) return;
      _profilePostsPage += 1;
      profilePosts.addAll(result.items);
      profilePostsHasMore.value = result.hasMore;
    } catch (_) {
      // Échec silencieux : l'utilisateur peut réessayer en scrollant.
    } finally {
      profilePostsLoadingMore.value = false;
    }
  }

  /// Réaction optimiste sur une publication du mur de profil.
  Future<void> toggleProfileReaction(String postId, String type) =>
      _toggleReactionIn(profilePosts, postId, type);

  // ── Cluster D — Blocage / vues de profil / compétences ───────────────────
  /// Bloque/débloque un membre. Retourne l'état `is_blocked` côté serveur
  /// (le bloquer retire aussi connexion + follow). Propage l'erreur au caller
  /// pour qu'il puisse rollback son état optimiste.
  Future<bool> setBlocked(String userId, {required bool blocked}) async {
    final result = await _repository.setBlocked(userId, blocked: blocked);
    if (blocked) {
      // Côté serveur le blocage casse connexion + follow : reflète localement.
      _applyFollowState(userId, false);
      _applyConnectionState(userId, 'none');
      suggestions.removeWhere((u) => u.id == userId);
      posts.removeWhere((p) => p.author?.id == userId);
    }
    return result;
  }

  Future<ProfileViewsResult> fetchProfileViews() =>
      _repository.getProfileViews();

  Future<Skill?> addSkill(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    try {
      return await _repository.addSkill(trimmed);
    } catch (e) {
      errorMessage.value = userFacingError(e);
      return null;
    }
  }

  Future<bool> removeSkill(String skillId) async {
    try {
      await _repository.removeSkill(skillId);
      return true;
    } catch (e) {
      errorMessage.value = userFacingError(e);
      return false;
    }
  }

  /// Recommande/retire la recommandation d'une compétence. Retourne le skill
  /// à jour (compteur + état) ou null en cas d'échec (le caller rollback).
  Future<Skill?> endorseSkill(String skillId, {required bool endorse}) async {
    try {
      return await _repository.endorseSkill(skillId, endorse: endorse);
    } catch (e) {
      errorMessage.value = userFacingError(e);
      return null;
    }
  }

  Future<List<NetworkUser>> searchPeople(String query) =>
      _repository.searchPeople(query);

  Future<void> loadPendingConnections() async {
    try {
      isLoadingConnections.value = true;
      connectionsErrorMessage.value = null;
      pendingConnections.assignAll(await _repository.getConnections());
    } catch (e) {
      connectionsErrorMessage.value = userFacingError(e);
    } finally {
      isLoadingConnections.value = false;
    }
  }

  Future<bool> respondToConnection(String connectionId, bool accept) async {
    try {
      await _repository.respondConnection(connectionId, accept: accept);
      pendingConnections.removeWhere((c) => c.connectionId == connectionId);
      // Petit burst de célébration uniquement à l'acceptation d'une connexion.
      if (accept) showCelebration(particles: 16);
      return true;
    } catch (e) {
      errorMessage.value = userFacingError(e);
      return false;
    }
  }

  // ── Commentaires ────────────────────────────────────────────────────────
  Future<List<CommunityComment>> fetchComments(String postId) =>
      _repository.getComments(postId);

  /// Ajoute un commentaire et incrémente le compteur local du post.
  Future<CommunityComment?> addComment(String postId, String body) async {
    if (body.trim().isEmpty) return null;
    try {
      final comment = await _repository.addComment(postId, body.trim());
      _bumpCommentCount(postId, 1);
      return comment;
    } catch (e) {
      errorMessage.value = userFacingError(e);
      return null;
    }
  }

  Future<bool> removeComment(String postId, String commentId) async {
    try {
      await _repository.deleteComment(commentId);
      _bumpCommentCount(postId, -1);
      return true;
    } catch (e) {
      errorMessage.value = userFacingError(e);
      return false;
    }
  }

  /// Réaction (toggle) sur un commentaire. Renvoie le résultat serveur
  /// {reactions_count, my_reaction} ou null en cas d'échec (le caller rollback).
  Future<Map<String, dynamic>?> reactComment(String commentId,
      {String type = 'like'}) async {
    try {
      return await _repository.reactComment(commentId, type: type);
    } catch (e) {
      errorMessage.value = userFacingError(e);
      return null;
    }
  }

  void _bumpCommentCount(String postId, int delta) {
    final index = posts.indexWhere((p) => p.id == postId);
    if (index < 0) return;
    final next = posts[index].commentsCount + delta;
    posts[index] = _copyWith(posts[index], commentsCount: next < 0 ? 0 : next);
  }

  /// Helper interne : délègue au [Post.copyWith] de l'entité pour préserver
  /// TOUS les champs (myReaction, reactionsBreakdown, isEdited…).
  Post _copyWith(
    Post p, {
    bool? isLiked,
    int? reactionsCount,
    int? commentsCount,
    NetworkUser? author,
  }) =>
      p.copyWith(
        author: author,
        reactionsCount: reactionsCount,
        commentsCount: commentsCount,
        isLiked: isLiked,
      );
}
