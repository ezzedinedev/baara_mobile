import 'package:get/get.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/network_user.dart';
import '../../domain/entities/community_comment.dart';
import '../../domain/entities/connection_request.dart';
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

  int _page = 1;

  @override
  void onInit() {
    super.onInit();
    loadFeed();
    loadSuggestions();
  }

  Future<void> loadFeed({String? type}) async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      activeType.value = type;
      _page = 1;
      final result = await _repository.getFeed(type: type, page: 1);
      posts.assignAll(result.items);
      hasMore.value = result.hasMore;
    } catch (e) {
      errorMessage.value = _friendlyError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshFeed() => loadFeed(type: activeType.value);

  Future<void> loadMore() async {
    if (isLoadingMore.value || isLoading.value || !hasMore.value) return;
    try {
      isLoadingMore.value = true;
      final result = await _repository.getFeed(type: activeType.value, page: _page + 1);
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
    } catch (_) {}
  }

  /// Publie une nouvelle publication et l'ajoute en tête du fil.
  Future<bool> publish({
    required String body,
    String category = 'general',
    String visibility = 'public',
    List<String> mediaPaths = const [],
  }) async {
    if (body.trim().isEmpty) return false;
    try {
      isPublishing.value = true;
      final post = await _repository.createPost(
        body: body,
        category: category,
        visibility: visibility,
        mediaPaths: mediaPaths,
      );
      posts.insert(0, post);
      return true;
    } catch (e) {
      errorMessage.value = _friendlyError(e);
      return false;
    } finally {
      isPublishing.value = false;
    }
  }

  /// Réaction optimiste (mise à jour locale immédiate, rollback si échec).
  Future<void> toggleReaction(String postId, String type) async {
    final index = posts.indexWhere((p) => p.id == postId);
    if (index < 0) return;
    final current = posts[index];
    final optimistic = current.isLiked
        ? (current.reactionsCount - 1)
        : (current.reactionsCount + 1);
    posts[index] = _copyWith(current, isLiked: !current.isLiked, reactionsCount: optimistic < 0 ? 0 : optimistic);
    try {
      final res = await _repository.react(postId, type);
      final count = (res['reactions_count'] as num?)?.toInt();
      if (count != null) {
        posts[index] = _copyWith(posts[index], reactionsCount: count);
      }
    } catch (_) {
      posts[index] = current; // rollback
    }
  }

  Future<void> repost(String postId, {String? body}) async {
    try {
      final post = await _repository.repost(postId, body: body);
      posts.insert(0, post);
    } catch (e) {
      errorMessage.value = _friendlyError(e);
    }
  }

  Future<void> deletePost(String postId) async {
    final backup = List<Post>.from(posts);
    posts.removeWhere((p) => p.id == postId);
    try {
      await _repository.deletePost(postId);
    } catch (_) {
      posts.assignAll(backup); // rollback
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
      errorMessage.value = _friendlyError(e);
    }
  }

  void _applyFollowState(String userId, bool isFollowing) {
    for (var i = 0; i < posts.length; i++) {
      final author = posts[i].author;
      if (author != null && author.id == userId) {
        posts[i] = _copyWith(posts[i], author: author.copyWith(isFollowing: isFollowing));
      }
    }
  }

  // ── Connexions, signalement, recherche, profil ────────────────────────
  final pendingConnections = <ConnectionRequest>[].obs;
  final isLoadingConnections = false.obs;

  /// Envoie une demande de connexion (optimiste sur l'état du membre).
  Future<bool> connectUser(NetworkUser user) async {
    if (user.isSelf || user.id.isEmpty) return false;
    try {
      await _repository.connect(user.id);
      _applyConnectionState(user.id, 'pending_sent');
      return true;
    } catch (e) {
      errorMessage.value = _friendlyError(e);
      return false;
    }
  }

  void _applyConnectionState(String userId, String status) {
    for (var i = 0; i < posts.length; i++) {
      final author = posts[i].author;
      if (author != null && author.id == userId) {
        posts[i] =
            _copyWith(posts[i], author: author.copyWith(connectionStatus: status));
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
      errorMessage.value = _friendlyError(e);
      return false;
    }
  }

  Future<Map<String, dynamic>> fetchUserProfile(String userId) =>
      _repository.getProfile(userId);

  Future<List<NetworkUser>> searchPeople(String query) =>
      _repository.searchPeople(query);

  Future<void> loadPendingConnections() async {
    try {
      isLoadingConnections.value = true;
      pendingConnections.assignAll(await _repository.getConnections());
    } catch (_) {
    } finally {
      isLoadingConnections.value = false;
    }
  }

  Future<bool> respondToConnection(String connectionId, bool accept) async {
    try {
      await _repository.respondConnection(connectionId, accept: accept);
      pendingConnections.removeWhere((c) => c.connectionId == connectionId);
      return true;
    } catch (e) {
      errorMessage.value = _friendlyError(e);
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
      errorMessage.value = _friendlyError(e);
      return null;
    }
  }

  Future<bool> removeComment(String postId, String commentId) async {
    try {
      await _repository.deleteComment(commentId);
      _bumpCommentCount(postId, -1);
      return true;
    } catch (e) {
      errorMessage.value = _friendlyError(e);
      return false;
    }
  }

  void _bumpCommentCount(String postId, int delta) {
    final index = posts.indexWhere((p) => p.id == postId);
    if (index < 0) return;
    final next = posts[index].commentsCount + delta;
    posts[index] = _copyWith(posts[index], commentsCount: next < 0 ? 0 : next);
  }

  Post _copyWith(
    Post p, {
    bool? isLiked,
    int? reactionsCount,
    int? commentsCount,
    NetworkUser? author,
  }) =>
      Post(
        id: p.id,
        body: p.body,
        category: p.category,
        visibility: p.visibility,
        createdAt: p.createdAt,
        author: author ?? p.author,
        reactionsCount: reactionsCount ?? p.reactionsCount,
        commentsCount: commentsCount ?? p.commentsCount,
        sharesCount: p.sharesCount,
        isLiked: isLiked ?? p.isLiked,
        media: p.media,
        imageUrl: p.imageUrl,
        hashtags: p.hashtags,
        shared: p.shared,
      );

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('réseau') || msg.contains('network')) {
      return 'Connexion impossible. Vérifiez votre réseau.';
    }
    if (msg.contains('vous-même')) {
      return 'Action non autorisée sur votre propre profil.';
    }
    return 'Une erreur est survenue. Réessayez.';
  }
}
