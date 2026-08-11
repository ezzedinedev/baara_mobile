import 'package:http/http.dart' as http;
import 'package:baara/app/core/network/api_provider.dart';
import 'package:baara/app/core/network/api_response.dart';
import 'package:baara/app/core/constants/api_constants.dart';
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
    ApiResponse.ensureSuccess(res,
        fallback: 'Impossible de charger cette liste de membres.');
    final data = ApiResponse.dataMap(res);
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
    ApiResponse.ensureSuccess(res, fallback: 'Impossible de charger le fil.');
    final data = ApiResponse.dataMap(res);
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
    ApiResponse.ensureSuccess(res,
        fallback: 'Impossible de publier votre post.');
    return PostModel.fromJson(ApiResponse.dataMap(res));
  }

  // ── Wave 2 — Contenu riche ──────────────────────────────────────────────
  @override
  Future<PostPoll> votePoll(String pollId, List<String> optionIds) async {
    final res = await _apiProvider.postJson(
      ApiConstants.communityPollVote(pollId),
      {'option_ids': optionIds},
    );
    ApiResponse.ensureSuccess(res,
        fallback: 'Impossible d\'enregistrer votre vote.');
    final data = ApiResponse.dataMap(res);
    return PostModel.fromJson({'id': '', 'poll': data}).poll ??
        (throw const FormatException('Réponse de vote invalide'));
  }

  @override
  Future<bool> toggleSave(String postId, {required bool save}) async {
    final endpoint = ApiConstants.communityPostSave(postId);
    final res = save
        ? await _apiProvider.postJson(endpoint, {})
        : await _apiProvider.deleteJson(endpoint);
    ApiResponse.ensureSuccess(res,
        fallback: 'Impossible de mettre à jour vos enregistrements.');
    return ApiResponse.dataMap(res)['is_saved'] == true;
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
    ApiResponse.ensureSuccess(res,
        fallback: 'Aperçu du lien indisponible.');
    final data = res['data'];
    if (data is! Map<String, dynamic>) return null;
    return PostModel.fromJson({'id': '', 'link_preview': data}).linkPreview;
  }

  @override
  Future<void> deletePost(String postId) async {
    final res =
        await _apiProvider.deleteJson(ApiConstants.communityPost(postId));
    ApiResponse.ensureSuccess(res,
        fallback: 'Impossible de supprimer ce post.');
  }

  @override
  Future<Map<String, dynamic>> react(String postId, String type) async {
    final res = await _apiProvider.postJson(
      ApiConstants.communityPostReact(postId),
      {'type': type},
    );
    ApiResponse.ensureSuccess(res,
        fallback: 'Impossible d\'enregistrer votre réaction.');
    return ApiResponse.dataMap(res);
  }

  @override
  Future<Post> repost(String postId, {String? body}) async {
    final res = await _apiProvider.postJson(
      ApiConstants.communityPostRepost(postId),
      {if (body != null) 'body': body},
    );
    ApiResponse.ensureSuccess(res, fallback: 'Impossible de repartager.');
    return PostModel.fromJson(ApiResponse.dataMap(res));
  }

  @override
  Future<void> report(String postId, String reason) async {
    final res = await _apiProvider.postJson(
      ApiConstants.communityPostReport(postId),
      {'reason': reason},
    );
    ApiResponse.ensureSuccess(res,
        fallback: 'Impossible d\'envoyer ce signalement.');
  }

  @override
  Future<Post> updatePost(String id, String body) async {
    final res = await _apiProvider.putJson(
      ApiConstants.communityPostUpdate(id),
      {'body': body},
    );
    ApiResponse.ensureSuccess(res,
        fallback: 'Impossible de modifier ce post.');
    return PostModel.fromJson(ApiResponse.dataMap(res));
  }

  @override
  Future<List<CommunityComment>> getComments(String postId) async {
    final res =
        await _apiProvider.getJson(ApiConstants.communityPostComments(postId));
    ApiResponse.ensureSuccess(res,
        fallback: 'Impossible de charger les commentaires.');
    return ApiResponse.extractList(res['data'])
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
    ApiResponse.ensureSuccess(res,
        fallback: 'Impossible de publier votre commentaire.');
    return CommunityCommentModel.fromJson(ApiResponse.dataMap(res));
  }

  @override
  Future<void> deleteComment(String commentId) async {
    final res =
        await _apiProvider.deleteJson(ApiConstants.communityComment(commentId));
    ApiResponse.ensureSuccess(res,
        fallback: 'Impossible de supprimer ce commentaire.');
  }

  @override
  Future<CommunityComment> updateComment(String id, String body) async {
    final res = await _apiProvider.putJson(
      ApiConstants.communityCommentUpdate(id),
      {'body': body},
    );
    ApiResponse.ensureSuccess(res,
        fallback: 'Impossible de modifier ce commentaire.');
    return CommunityCommentModel.fromJson(ApiResponse.dataMap(res));
  }

  @override
  Future<Map<String, dynamic>> reactComment(String id,
      {String type = 'like'}) async {
    final res = await _apiProvider.postJson(
      ApiConstants.communityCommentReact(id),
      {'type': type},
    );
    ApiResponse.ensureSuccess(res,
        fallback: 'Impossible d\'enregistrer votre réaction.');
    return ApiResponse.dataMap(res);
  }

  @override
  Future<FeedPage> getHashtagFeed(String tag, {int page = 1}) async {
    final res = await _apiProvider.getJson(
      '${ApiConstants.communityHashtag(tag)}?page=$page',
    );
    ApiResponse.ensureSuccess(res,
        fallback: 'Impossible de charger ce hashtag.');
    final data = ApiResponse.dataMap(res);
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
    ApiResponse.ensureSuccess(res,
        fallback: 'L\'assistant est indisponible pour le moment.');
    final data = ApiResponse.dataMap(res);
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
    ApiResponse.ensureSuccess(res,
        fallback: 'Impossible de résumer ce post.');
    return ApiResponse.dataMap(res)['summary']?.toString() ?? '';
  }

  @override
  Future<String> translatePost(String postId, String lang) async {
    final res = await _apiProvider.postJson(
      ApiConstants.communityPostTranslate(postId),
      {'lang': lang},
    );
    ApiResponse.ensureSuccess(res,
        fallback: 'Impossible de traduire ce post.');
    return ApiResponse.dataMap(res)['translation']?.toString() ?? '';
  }

  @override
  Future<List<TrendingHashtag>> getTrendingHashtags() async {
    final res =
        await _apiProvider.getJson(ApiConstants.communityTrendingHashtags);
    ApiResponse.ensureSuccess(res,
        fallback: 'Impossible de charger les tendances.');
    final list = ApiResponse.extractList(res['data']);
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
    ApiResponse.ensureSuccess(res,
        fallback: 'Impossible de charger les suggestions de mention.');
    final list = ApiResponse.extractList(res['data']);
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
    final res = await _apiProvider
        .postJson(ApiConstants.communityUserFollow(userId), {});
    ApiResponse.ensureSuccess(res, fallback: 'Impossible de suivre ce membre.');
  }

  @override
  Future<void> unfollow(String userId) async {
    final res = await _apiProvider
        .deleteJson(ApiConstants.communityUserFollow(userId));
    ApiResponse.ensureSuccess(res,
        fallback: 'Impossible de ne plus suivre ce membre.');
  }

  @override
  Future<void> connect(String userId) async {
    final res = await _apiProvider
        .postJson(ApiConstants.communityUserConnect(userId), {});
    ApiResponse.ensureSuccess(res,
        fallback: 'Impossible d\'envoyer cette demande de connexion.');
  }

  @override
  Future<void> respondConnection(String connectionId,
      {required bool accept}) async {
    final res = await _apiProvider.postJson(
      ApiConstants.communityConnectionRespond(connectionId),
      {'action': accept ? 'accept' : 'reject'},
    );
    ApiResponse.ensureSuccess(res,
        fallback: 'Impossible de répondre à cette demande.');
  }

  @override
  Future<List<ConnectionRequest>> getConnections() async {
    final res = await _apiProvider.getJson(ApiConstants.communityConnections);
    ApiResponse.ensureSuccess(res,
        fallback: 'Impossible de charger vos demandes de connexion.');
    final data = ApiResponse.dataMap(res);
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
    ApiResponse.ensureSuccess(res,
        fallback: 'Impossible de mettre à jour le blocage.');
    return ApiResponse.dataMap(res)['is_blocked'] == true;
  }

  @override
  Future<ProfileViewsResult> getProfileViews() async {
    final res = await _apiProvider.getJson(ApiConstants.communityProfileViews);
    ApiResponse.ensureSuccess(res,
        fallback: 'Impossible de charger les vues de profil.');
    final data = ApiResponse.dataMap(res);
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
    ApiResponse.ensureSuccess(res,
        fallback: 'Impossible d\'ajouter cette compétence.');
    return Skill.fromJson(ApiResponse.dataMap(res));
  }

  @override
  Future<void> removeSkill(String skillId) async {
    final res =
        await _apiProvider.deleteJson(ApiConstants.communitySkill(skillId));
    ApiResponse.ensureSuccess(res,
        fallback: 'Impossible de retirer cette compétence.');
  }

  @override
  Future<Skill> endorseSkill(String skillId, {required bool endorse}) async {
    final endpoint = ApiConstants.communitySkillEndorse(skillId);
    final res = endorse
        ? await _apiProvider.postJson(endpoint, {})
        : await _apiProvider.deleteJson(endpoint);
    ApiResponse.ensureSuccess(res,
        fallback: 'Impossible de mettre à jour cette recommandation.');
    final data = ApiResponse.dataMap(res);
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
    ApiResponse.ensureSuccess(res,
        fallback: 'Impossible de charger les stories.');
    return ApiResponse.extractList(res['data'])
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
    final res = await _apiProvider.multipartPost(
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
    ApiResponse.ensureSuccess(res,
        fallback: 'Impossible de publier votre story.');
  }

  @override
  Future<void> viewStory(String storyId) async {
    final res =
        await _apiProvider.postJson(ApiConstants.storyView(storyId), {});
    ApiResponse.ensureSuccess(res,
        fallback: 'Impossible d\'enregistrer cette vue.');
  }

  @override
  Future<void> reactStory(String storyId, String type) async {
    final res = await _apiProvider
        .postJson(ApiConstants.storyReact(storyId), {'type': type});
    ApiResponse.ensureSuccess(res,
        fallback: 'Impossible d\'envoyer votre réaction.');
  }

  @override
  Future<String?> replyStory(String storyId, String content) async {
    final res = await _apiProvider.postJson(
      ApiConstants.storyReply(storyId),
      {'content': content},
    );
    ApiResponse.ensureSuccess(res,
        fallback: 'Impossible d\'envoyer votre réponse.');
    return ApiResponse.dataMap(res)['conversation_id']?.toString();
  }

  @override
  Future<void> deleteStory(String storyId) async {
    final res = await _apiProvider.deleteJson(ApiConstants.story(storyId));
    ApiResponse.ensureSuccess(res,
        fallback: 'Impossible de supprimer cette story.');
  }

  @override
  Future<Map<String, dynamic>> storyViewers(String storyId) async {
    final res = await _apiProvider.getJson(ApiConstants.storyViewers(storyId));
    ApiResponse.ensureSuccess(res,
        fallback: 'Impossible de charger les vues de cette story.');
    return ApiResponse.dataMap(res);
  }

  @override
  Future<List<NetworkUser>> getSuggestions() async {
    final res = await _apiProvider.getJson(ApiConstants.communitySuggestions);
    ApiResponse.ensureSuccess(res,
        fallback: 'Impossible de charger les suggestions.');
    return ApiResponse.extractList(res['data'])
        .whereType<Map<String, dynamic>>()
        .map((j) => NetworkUserModel.fromJson(j))
        .toList();
  }

  @override
  Future<List<SuggestionInsight>> getSuggestionInsights() async {
    final res =
        await _apiProvider.getJson(ApiConstants.communitySuggestionsInsight);
    ApiResponse.ensureSuccess(res,
        fallback: 'Impossible de charger les suggestions.');
    final data = ApiResponse.dataMap(res);
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
    ApiResponse.ensureSuccess(res,
        fallback: 'Impossible de charger ce profil.');
    return ApiResponse.dataMap(res);
  }

  @override
  Future<Map<String, dynamic>> search(String query,
      {String type = 'people'}) async {
    final res = await _apiProvider.getJson(
      '${ApiConstants.communitySearch}?q=${Uri.encodeQueryComponent(query)}&type=$type',
    );
    ApiResponse.ensureSuccess(res, fallback: 'La recherche a échoué.');
    return ApiResponse.dataMap(res);
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
