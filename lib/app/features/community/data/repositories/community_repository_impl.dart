import 'package:http/http.dart' as http;
import 'package:opportune_bf/app/core/network/api_provider.dart';
import 'package:opportune_bf/app/core/constants/api_constants.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/community_comment.dart';
import '../../domain/entities/network_user.dart';
import '../../domain/entities/connection_request.dart';
import '../../domain/repositories/i_community_repository.dart';
import '../models/post_model.dart';
import '../models/community_comment_model.dart';
import '../models/network_user_model.dart';

class CommunityRepositoryImpl implements ICommunityRepository {
  final ApiProvider _apiProvider;

  CommunityRepositoryImpl({required ApiProvider apiProvider})
      : _apiProvider = apiProvider;

  @override
  Future<FeedPage> getFeed({String? type, int page = 1}) async {
    final query = StringBuffer('?page=$page');
    if (type != null && type.isNotEmpty) query.write('&type=$type');
    final res = await _apiProvider.getJson('${ApiConstants.communityFeed}$query');
    final data = res['data'] as Map<String, dynamic>? ?? const {};
    final items = (data['items'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((j) => PostModel.fromJson(j))
        .toList();
    return FeedPage(
      items: items,
      currentPage: (data['current_page'] as num?)?.toInt() ?? page,
      lastPage: (data['last_page'] as num?)?.toInt() ?? page,
      hasMore: data['has_more'] == true,
    );
  }

  @override
  Future<Post> createPost({
    required String body,
    String category = 'general',
    String visibility = 'public',
    List<String> mediaPaths = const [],
  }) async {
    final fields = {'body': body, 'category': category, 'visibility': visibility};
    final files = <http.MultipartFile>[];
    for (final path in mediaPaths) {
      files.add(await http.MultipartFile.fromPath('media[]', path));
    }
    final res = await _apiProvider.multipartPost(
      ApiConstants.communityPosts,
      fields: fields,
      files: files,
    );
    return PostModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> deletePost(String postId) async {
    await _apiProvider.deleteJson(ApiConstants.communityPost(postId));
  }

  @override
  Future<Map<String, dynamic>> react(String postId, String type) async {
    final res = await _apiProvider.postJson(
      ApiConstants.communityPostReact(postId),
      {'type': type},
    );
    return (res['data'] as Map<String, dynamic>?) ?? const {};
  }

  @override
  Future<Post> repost(String postId, {String? body}) async {
    final res = await _apiProvider.postJson(
      ApiConstants.communityPostRepost(postId),
      {if (body != null) 'body': body},
    );
    return PostModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> report(String postId, String reason) async {
    await _apiProvider.postJson(
      ApiConstants.communityPostReport(postId),
      {'reason': reason},
    );
  }

  @override
  Future<List<CommunityComment>> getComments(String postId) async {
    final res = await _apiProvider.getJson(ApiConstants.communityPostComments(postId));
    final list = res['data'] as List? ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((j) => CommunityCommentModel.fromJson(j))
        .toList();
  }

  @override
  Future<CommunityComment> addComment(String postId, String body, {String? parentId}) async {
    final res = await _apiProvider.postJson(
      ApiConstants.communityPostComments(postId),
      {'body': body, if (parentId != null) 'parent_id': parentId},
    );
    return CommunityCommentModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteComment(String commentId) async {
    await _apiProvider.deleteJson(ApiConstants.communityComment(commentId));
  }

  @override
  Future<void> follow(String userId) async {
    await _apiProvider.postJson(ApiConstants.communityUserFollow(userId), {});
  }

  @override
  Future<void> unfollow(String userId) async {
    await _apiProvider.deleteJson(ApiConstants.communityUserFollow(userId));
  }

  @override
  Future<void> connect(String userId) async {
    await _apiProvider.postJson(ApiConstants.communityUserConnect(userId), {});
  }

  @override
  Future<void> respondConnection(String connectionId, {required bool accept}) async {
    await _apiProvider.postJson(
      ApiConstants.communityConnectionRespond(connectionId),
      {'action': accept ? 'accept' : 'reject'},
    );
  }

  @override
  Future<List<ConnectionRequest>> getConnections() async {
    final res = await _apiProvider.getJson(ApiConstants.communityConnections);
    final data = res['data'] as Map<String, dynamic>? ?? const {};
    final list = data['pending'] as List? ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .where((j) => j['user'] is Map<String, dynamic>)
        .map((j) => ConnectionRequest(
              connectionId: j['connection_id']?.toString() ?? '',
              user: NetworkUserModel.fromJson(
                  j['user'] as Map<String, dynamic>),
            ))
        .toList();
  }

  @override
  Future<List<NetworkUser>> getSuggestions() async {
    final res = await _apiProvider.getJson(ApiConstants.communitySuggestions);
    final list = res['data'] as List? ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((j) => NetworkUserModel.fromJson(j))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> getProfile(String userId) async {
    final res = await _apiProvider.getJson(ApiConstants.communityUser(userId));
    return (res['data'] as Map<String, dynamic>?) ?? const {};
  }

  @override
  Future<Map<String, dynamic>> search(String query, {String type = 'people'}) async {
    final res = await _apiProvider.getJson(
      '${ApiConstants.communitySearch}?q=${Uri.encodeQueryComponent(query)}&type=$type',
    );
    return (res['data'] as Map<String, dynamic>?) ?? const {};
  }

  @override
  Future<List<NetworkUser>> searchPeople(String query) async {
    final data = await search(query, type: 'people');
    final list = data['results'] as List? ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((j) => NetworkUserModel.fromJson(j))
        .toList();
  }
}
