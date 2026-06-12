import 'package:opportune_bf/app/core/constants/api_constants.dart';
import '../../domain/entities/story.dart';

/// Parse une « bulle » d'auteur renvoyée par GET /stories.
class StoryBucketModel {
  static StoryBucket fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>? ?? const {};
    final author = StoryAuthor(
      id: userJson['id']?.toString() ?? '',
      name: (userJson['name'] ??
              '${userJson['first_name'] ?? ''} ${userJson['last_name'] ?? ''}')
          .toString()
          .trim(),
      avatarUrl:
          ApiConstants.resolveMediaUrl(userJson['avatar_url']?.toString()),
      userType: userJson['user_type']?.toString(),
    );

    final stories = (json['stories'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_storyFromJson)
        .toList();

    return StoryBucket(
      user: author,
      isMine: json['is_mine'] == true,
      stories: stories,
    );
  }

  static StoryItem _storyFromJson(Map<String, dynamic> j) {
    final media = (j['media'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final first = media.isNotEmpty ? media.first : const <String, dynamic>{};
    return StoryItem(
      id: j['id']?.toString() ?? '',
      mediaUrl: ApiConstants.resolveMediaUrl(first['url']?.toString()),
      mediaType: first['type']?.toString() ?? 'image',
      caption: j['caption']?.toString(),
      backgroundColor: j['background_color']?.toString(),
      createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ??
          DateTime.now(),
      isMine: j['is_mine'] == true,
      seen: j['seen'] == true,
      viewsCount: (j['views_count'] as num?)?.toInt(),
      reactionsCount: (j['reactions_count'] as num?)?.toInt(),
    );
  }
}
