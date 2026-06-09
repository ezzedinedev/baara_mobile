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
  });

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

    return PostModel(
      id: json['id']?.toString() ?? '',
      body: json['body'] as String?,
      category: json['category']?.toString() ?? 'general',
      visibility: json['visibility']?.toString() ?? 'public',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
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
    );
  }
}
