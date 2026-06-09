import '../../domain/entities/community_comment.dart';
import 'network_user_model.dart';

class CommunityCommentModel extends CommunityComment {
  const CommunityCommentModel({
    required super.id,
    required super.body,
    required super.parentId,
    required super.createdAt,
    required super.user,
    super.replies,
  });

  factory CommunityCommentModel.fromJson(Map<String, dynamic> json) {
    final repliesRaw = json['replies'];
    final replies = (repliesRaw is List)
        ? repliesRaw
            .whereType<Map<String, dynamic>>()
            .map((r) => CommunityCommentModel.fromJson(r))
            .toList()
        : <CommunityComment>[];

    return CommunityCommentModel(
      id: json['id']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      parentId: json['parent_id'] as String?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      user: json['user'] is Map<String, dynamic>
          ? NetworkUserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      replies: replies,
    );
  }
}
