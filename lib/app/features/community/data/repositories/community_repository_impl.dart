import 'package:http/http.dart' as http;
import 'package:jobaway/app/core/network/api_provider.dart';
import 'package:jobaway/app/core/constants/api_constants.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/community_comment.dart';
import '../../domain/entities/network_user.dart';
import '../../domain/entities/connection_request.dart';
import '../../domain/repositories/i_community_repository.dart';
import '../../domain/entities/story.dart';
import '../../domain/entities/skill.dart';
import '../../domain/entities/profile_viewer.dart';
import '../models/post_model.dart';
import '../models/community_comment_model.dart';
import '../models/network_user_model.dart';
import '../models/story_model.dart';

class CommunityRepositoryImpl implements ICommunityRepository {
  final ApiProvider _apiProvider;

  CommunityRepositoryImpl({required ApiProvider apiProvider})
      : _apiProvider = apiProvider;

  @override
  Future<FeedPage> getFeed({
    String tab = 'foryou',
    String? type,
    int page = 1,
  }) async {
    final query = StringBuffer('?page=$page&tab=$tab');
    if (type != null && type.isNotEmpty) query.write('&type=$type');
    return _fetchFeedPage('${ApiConstants.communityFeed}$query', page);
  }

  @override
  Future<FeedPage> getExplore({String? type, int page = 1}) async {
    final query = StringBuffer('?page=$page');
    if (type != null && type.isNotEmpty) query.write('&type=$type');
    return _fetchFeedPage('${ApiConstants.communityExplore}$query', page);
  }

  @override
  Future<FeedPage> getUserPosts(String userId, {int page = 1}) async {
    return _fetchFeedPage(
        '${ApiConstants.communityUserPosts(userId)}?page=$page', page);
  }

  @override
  Future<NetworkUserPage> getFollowers(String userId, {int page = 1}) {
    return _fetchUserPage(
        '${ApiConstants.communityUserFollowers(userId)}?page=$page', page);
  }

  @override
  Future<NetworkUserPage> getUserConnections(String userId, {int page = 1}) {
    return _fetchUserPage(
        '${ApiConstants.communityUserConnections(userId)}?page=$page', page);
  }

  /// Mutualise le parsing d'une page de membres (abonnés / connexions).
  Future<NetworkUserPage> _fetchUserPage(String endpoint, int page) async {
    final res = await _apiProvider.getJson(endpoint);
    final data = res['data'] as Map<String, dynamic>? ?? const {};
    final items = (data['items'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((j) => NetworkUserModel.fromJson(j))
        .toList();
    return NetworkUserPage(
      items: items,
      currentPage: (data['current_page'] as num?)?.toInt() ?? page,
      hasMore: data['has_more'] == true,
    );
  }

  /// Mutualise le parsing d'une page de feed (feed + explore, même forme).
  Future<FeedPage> _fetchFeedPage(String endpoint, int page) async {
    final res = await _apiProvider.getJson(endpoint);
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
    PollDraft? poll,
  }) async {
    final fields = <String, String>{
      'body': body,
      'category': category,
      'visibility': visibility,
    };
    // Sondage : envoyé en champs multipart "à la PHP" (poll[...]) — c'est la
    // forme attendue par Laravel sur un POST multipart (validation `poll.options`).
    if (poll != null) {
      if (poll.question != null && poll.question!.trim().isNotEmpty) {
        fields['poll[question]'] = poll.question!.trim();
      }
      fields['poll[multiple]'] = poll.multiple ? '1' : '0';
      if (poll.closesAt != null) {
        fields['poll[closes_at]'] = poll.closesAt!.toUtc().toIso8601String();
      }
      for (var i = 0; i < poll.options.length; i++) {
        fields['poll[options][$i]'] = poll.options[i];
      }
    }
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

  // ── Wave 2 — Contenu riche ──────────────────────────────────────────────
  @override
  Future<PostPoll> votePoll(String pollId, List<String> optionIds) async {
    final res = await _apiProvider.postJson(
      ApiConstants.communityPollVote(pollId),
      {'option_ids': optionIds},
    );
    final data = res['data'] as Map<String, dynamic>? ?? const {};
    return PostModel.fromJson({'id': '', 'poll': data}).poll ??
        (throw const FormatException('Réponse de vote invalide'));
  }

  @override
  Future<bool> toggleSave(String postId, {required bool save}) async {
    final endpoint = ApiConstants.communityPostSave(postId);
    final res = save
        ? await _apiProvider.postJson(endpoint, {})
        : await _apiProvider.deleteJson(endpoint);
    final data = res['data'] as Map<String, dynamic>? ?? const {};
    return data['is_saved'] == true;
  }

  @override
  Future<FeedPage> getSaved({int page = 1}) async {
    return _fetchFeedPage('${ApiConstants.communitySaved}?page=$page', page);
  }

  @override
  Future<PostLinkPreview?> fetchLinkPreview(String url) async {
    final res = await _apiProvider.getJson(
      '${ApiConstants.communityLinkPreview}?url=${Uri.encodeQueryComponent(url)}',
    );
    final data = res['data'];
    if (data is! Map<String, dynamic>) return null;
    return PostModel.fromJson({'id': '', 'link_preview': data}).linkPreview;
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
  Future<Post> updatePost(String id, String body) async {
    final res = await _apiProvider.putJson(
      ApiConstants.communityPostUpdate(id),
      {'body': body},
    );
    return PostModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<CommunityComment>> getComments(String postId) async {
    final res =
        await _apiProvider.getJson(ApiConstants.communityPostComments(postId));
    final list = res['data'] as List? ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((j) => CommunityCommentModel.fromJson(j))
        .toList();
  }

  @override
  Future<CommunityComment> addComment(String postId, String body,
      {String? parentId}) async {
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
  Future<CommunityComment> updateComment(String id, String body) async {
    final res = await _apiProvider.putJson(
      ApiConstants.communityCommentUpdate(id),
      {'body': body},
    );
    return CommunityCommentModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> reactComment(String id,
      {String type = 'like'}) async {
    final res = await _apiProvider.postJson(
      ApiConstants.communityCommentReact(id),
      {'type': type},
    );
    return (res['data'] as Map<String, dynamic>?) ?? const {};
  }

  @override
  Future<FeedPage> getHashtagFeed(String tag, {int page = 1}) async {
    final res = await _apiProvider.getJson(
      '${ApiConstants.communityHashtag(tag)}?page=$page',
    );
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

  // ── Wave 2 — Assistant IA (Mistral) ──────────────────────────────────────
  @override
  Future<AiComposeResult> aiCompose(String draft, String action) async {
    final res = await _apiProvider.postJson(
      ApiConstants.communityAiCompose,
      {'draft': draft, 'action': action},
    );
    final data = res['data'] as Map<String, dynamic>? ?? const {};
    final suggestions = data['suggestions'];
    if (suggestions is List) {
      return AiComposeResult(
        suggestions: suggestions
            .map((e) => e?.toString() ?? '')
            .where((s) => s.trim().isNotEmpty)
            .toList(),
      );
    }
    return AiComposeResult(text: data['result']?.toString() ?? '');
  }

  @override
  Future<String> summarizePost(String postId) async {
    final res = await _apiProvider.postJson(
      ApiConstants.communityPostSummarize(postId),
      const {},
    );
    final data = res['data'] as Map<String, dynamic>? ?? const {};
    return data['summary']?.toString() ?? '';
  }

  @override
  Future<String> translatePost(String postId, String lang) async {
    final res = await _apiProvider.postJson(
      ApiConstants.communityPostTranslate(postId),
      {'lang': lang},
    );
    final data = res['data'] as Map<String, dynamic>? ?? const {};
    return data['translation']?.toString() ?? '';
  }

  @override
  Future<List<TrendingHashtag>> getTrendingHashtags() async {
    final res =
        await _apiProvider.getJson(ApiConstants.communityTrendingHashtags);
    final list = res['data'] as List? ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((j) => TrendingHashtag(
              tag: j['tag']?.toString() ?? '',
              count: (j['count'] as num?)?.toInt() ?? 0,
            ))
        .where((t) => t.tag.isNotEmpty)
        .toList();
  }

  @override
  Future<List<Mentionable>> getMentionables(String q) async {
    final res = await _apiProvider.getJson(
      '${ApiConstants.communityMentionables}?q=${Uri.encodeQueryComponent(q)}',
    );
    final list = res['data'] as List? ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((j) => Mentionable(
              id: j['id']?.toString() ?? '',
              name: j['name']?.toString() ?? '',
              avatarUrl:
                  ApiConstants.resolveMediaUrl(j['avatar_url']?.toString()),
              headline: j['headline']?.toString(),
            ))
        .where((m) => m.id.isNotEmpty && m.name.isNotEmpty)
        .toList();
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
  Future<void> respondConnection(String connectionId,
      {required bool accept}) async {
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
              user:
                  NetworkUserModel.fromJson(j['user'] as Map<String, dynamic>),
            ))
        .toList();
  }

  // ── Cluster D — Sécurité & graphe social ──────────────────────────────────
  @override
  Future<bool> setBlocked(String userId, {required bool blocked}) async {
    final endpoint = ApiConstants.communityUserBlock(userId);
    final res = blocked
        ? await _apiProvider.postJson(endpoint, {})
        : await _apiProvider.deleteJson(endpoint);
    final data = res['data'] as Map<String, dynamic>? ?? const {};
    return data['is_blocked'] == true;
  }

  @override
  Future<ProfileViewsResult> getProfileViews() async {
    final res = await _apiProvider.getJson(ApiConstants.communityProfileViews);
    final data = res['data'] as Map<String, dynamic>? ?? const {};
    final viewers = (data['viewers'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((j) => ProfileViewer.fromJson(j))
        .where((v) => v.id.isNotEmpty)
        .toList();
    return ProfileViewsResult(
      viewers: viewers,
      total: (data['total'] as num?)?.toInt() ?? viewers.length,
    );
  }

  @override
  Future<Skill> addSkill(String name) async {
    final res = await _apiProvider
        .postJson(ApiConstants.communitySkills, {'name': name});
    return Skill.fromJson(res['data'] as Map<String, dynamic>? ?? const {});
  }

  @override
  Future<void> removeSkill(String skillId) async {
    await _apiProvider.deleteJson(ApiConstants.communitySkill(skillId));
  }

  @override
  Future<Skill> endorseSkill(String skillId, {required bool endorse}) async {
    final endpoint = ApiConstants.communitySkillEndorse(skillId);
    final res = endorse
        ? await _apiProvider.postJson(endpoint, {})
        : await _apiProvider.deleteJson(endpoint);
    final data = res['data'] as Map<String, dynamic>? ?? const {};
    return Skill(
      id: data['skill_id']?.toString() ?? skillId,
      name: data['name']?.toString() ?? '',
      endorsementsCount: (data['endorsements_count'] as num?)?.toInt() ?? 0,
      endorsedByMe: data['endorsed_by_me'] == true,
    );
  }

  // ── Stories ──────────────────────────────────────────────────────────────
  @override
  Future<List<StoryBucket>> getStories() async {
    final res = await _apiProvider.getJson(ApiConstants.stories);
    final list = res['data'] as List? ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((j) => StoryBucketModel.fromJson(j))
        .toList();
  }

  @override
  Future<void> createStory({
    String? mediaPath,
    String? caption,
    String? backgroundColor,
    String visibility = 'connections',
    List<String> mentions = const [],
  }) async {
    await _apiProvider.multipartPost(
      ApiConstants.stories,
      fields: {
        'visibility': visibility,
        if (caption != null && caption.isNotEmpty) 'caption': caption,
        if (backgroundColor != null && backgroundColor.isNotEmpty)
          'background_color': backgroundColor,
        // @mentions : envoyées en `mentions[i]` (Laravel les reconstruit en
        // tableau). Le backend notifie chaque mentionné (type mention_story).
        for (var i = 0; i < mentions.length; i++) 'mentions[$i]': mentions[i],
      },
      files: [
        if (mediaPath != null)
          await http.MultipartFile.fromPath('media', mediaPath),
      ],
    );
  }

  @override
  Future<void> viewStory(String storyId) async {
    await _apiProvider.postJson(ApiConstants.storyView(storyId), {});
  }

  @override
  Future<void> reactStory(String storyId, String type) async {
    await _apiProvider
        .postJson(ApiConstants.storyReact(storyId), {'type': type});
  }

  @override
  Future<String?> replyStory(String storyId, String content) async {
    final res = await _apiProvider.postJson(
      ApiConstants.storyReply(storyId),
      {'content': content},
    );
    final data = res['data'] as Map<String, dynamic>?;
    return data?['conversation_id']?.toString();
  }

  @override
  Future<void> deleteStory(String storyId) async {
    await _apiProvider.deleteJson(ApiConstants.story(storyId));
  }

  @override
  Future<Map<String, dynamic>> storyViewers(String storyId) async {
    final res = await _apiProvider.getJson(ApiConstants.storyViewers(storyId));
    return (res['data'] as Map<String, dynamic>?) ?? const {};
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
  Future<List<SuggestionInsight>> getSuggestionInsights() async {
    final res =
        await _apiProvider.getJson(ApiConstants.communitySuggestionsInsight);
    final data = res['data'] as Map<String, dynamic>? ?? const {};
    final list = data['insights'] as List? ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((j) {
          final insight = (j['insight'] as String?)?.trim();
          return SuggestionInsight(
            userId: j['user_id']?.toString() ?? '',
            insight: (insight == null || insight.isEmpty) ? null : insight,
            ai: j['ai'] == true,
          );
        })
        .where((s) => s.userId.isNotEmpty)
        .toList();
  }

  @override
  Future<Map<String, dynamic>> getProfile(String userId) async {
    final res = await _apiProvider.getJson(ApiConstants.communityUser(userId));
    return (res['data'] as Map<String, dynamic>?) ?? const {};
  }

  @override
  Future<Map<String, dynamic>> search(String query,
      {String type = 'people'}) async {
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
