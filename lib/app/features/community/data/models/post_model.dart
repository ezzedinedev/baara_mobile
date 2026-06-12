import 'package:opportune_bf/app/core/constants/api_constants.dart';
import '../../domain/entities/post.dart';
import 'network_user_model.dart';

class PostModel extends Post {
  const PostModel({
    required super.id,
    required super.body,
    required super.category,
    required super.visibility,
    required super.createdAt,
    required super.author,
    required super.reactionsCount,
    required super.commentsCount,
    required super.sharesCount,
    required super.isLiked,
    required super.media,
    super.imageUrl,
    super.hashtags,
    super.shared,
    super.myReaction,
    super.reactionsBreakdown,
    super.isEdited,
    super.editedAt,
    super.isSaved,
    super.poll,
    super.linkPreview,
  });

  static PostPoll? _parsePoll(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    final optionsRaw = raw['options'];
    final options = (optionsRaw is List)
        ? optionsRaw
            .whereType<Map<String, dynamic>>()
            .map((o) => PollOption(
                  id: o['id']?.toString() ?? '',
                  label: o['label']?.toString() ?? '',
                  votesCount: (o['votes_count'] as num?)?.toInt() ?? 0,
                  votedByMe: o['voted_by_me'] == true,
                ))
            .toList()
        : <PollOption>[];
    final myVotesRaw = raw['my_votes'];
    final myVotes = (myVotesRaw is List)
        ? myVotesRaw.map((e) => e.toString()).toList()
        : <String>[];
    return PostPoll(
      id: raw['id']?.toString() ?? '',
      question: (raw['question'] as String?)?.trim().isEmpty == true
          ? null
          : raw['question'] as String?,
      multiple: raw['multiple'] == true,
      closesAt: DateTime.tryParse(raw['closes_at']?.toString() ?? ''),
      isClosed: raw['is_closed'] == true,
      totalVotes: (raw['total_votes'] as num?)?.toInt() ?? 0,
      options: options,
      myVotes: myVotes,
    );
  }

  static PostLinkPreview? _parseLinkPreview(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    final url = raw['url']?.toString() ?? '';
    if (url.isEmpty) return null;
    return PostLinkPreview(
      url: ApiConstants.resolveMediaUrl(url) ?? url,
      title: raw['title'] as String?,
      description: raw['description'] as String?,
      image: ApiConstants.resolveMediaUrl(raw['image'] as String?),
    );
  }

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final mediaRaw = json['media'];
    final media = (mediaRaw is List)
        ? mediaRaw
            .whereType<Map<String, dynamic>>()
            .map((m) => PostMedia(
                  type: m['type']?.toString() ?? 'image',
                  url: m['url'] as String?,
                  name: m['name'] as String?,
                ))
            .toList()
        : <PostMedia>[];

    final hashtagsRaw = json['hashtags'];
    final hashtags = (hashtagsRaw is List)
        ? hashtagsRaw.map((e) => e.toString()).toList()
        : <String>[];

    final breakdownRaw = json['reactions_breakdown'];
    final breakdown = <String, int>{};
    if (breakdownRaw is Map) {
      breakdownRaw.forEach((k, v) {
        breakdown[k.toString()] = (v as num?)?.toInt() ?? 0;
      });
    }

    final myReactionRaw = json['my_reaction'];
    final myReaction = (myReactionRaw is String && myReactionRaw.isNotEmpty)
        ? myReactionRaw
        : null;

    return PostModel(
      id: json['id']?.toString() ?? '',
      body: json['body'] as String?,
      category: json['category']?.toString() ?? 'general',
      visibility: json['visibility']?.toString() ?? 'public',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      author: json['author'] is Map<String, dynamic>
          ? NetworkUserModel.fromJson(json['author'] as Map<String, dynamic>)
          : null,
      reactionsCount: (json['reactions_count'] as num?)?.toInt() ?? 0,
      commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
      sharesCount: (json['shares_count'] as num?)?.toInt() ?? 0,
      isLiked: json['is_liked'] == true,
      media: media,
      imageUrl: json['image_url'] as String?,
      hashtags: hashtags,
      shared: json['shared'] is Map<String, dynamic>
          ? PostModel.fromJson(json['shared'] as Map<String, dynamic>)
          : null,
      myReaction: myReaction,
      reactionsBreakdown: breakdown,
      isEdited: json['is_edited'] == true,
      editedAt: DateTime.tryParse(json['edited_at']?.toString() ?? ''),
      isSaved: json['is_saved'] == true,
      poll: _parsePoll(json['poll']),
      linkPreview: _parseLinkPreview(json['link_preview']),
    );
  }
}
