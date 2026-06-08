import '../entities/post.dart';
import '../entities/community_comment.dart';
import '../entities/network_user.dart';
import '../entities/connection_request.dart';

/// Résultat paginé du fil.
class FeedPage {
  final List<Post> items;
  final int currentPage;
  final int lastPage;
  final bool hasMore;

  const FeedPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.hasMore,
  });
}

abstract class ICommunityRepository {
  // Fil
  Future<FeedPage> getFeed({String? type, int page = 1});

  // Publications
  Future<Post> createPost({
    required String body,
    String category = 'general',
    String visibility = 'public',
    List<String> mediaPaths = const [],
  });
  Future<void> deletePost(String postId);
  Future<Map<String, dynamic>> react(String postId, String type); // {status, reactions_count}
  Future<Post> repost(String postId, {String? body});
  Future<void> report(String postId, String reason);

  // Commentaires
  Future<List<CommunityComment>> getComments(String postId);
  Future<CommunityComment> addComment(String postId, String body, {String? parentId});
  Future<void> deleteComment(String commentId);

  // Graphe social
  Future<void> follow(String userId);
  Future<void> unfollow(String userId);
  Future<void> connect(String userId);
  Future<void> respondConnection(String connectionId, {required bool accept});
  Future<List<ConnectionRequest>> getConnections();

  // Découverte
  Future<List<NetworkUser>> getSuggestions();
  Future<Map<String, dynamic>> getProfile(String userId);
  Future<Map<String, dynamic>> search(String query, {String type = 'people'});
  Future<List<NetworkUser>> searchPeople(String query);
}
