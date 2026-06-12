import 'network_user.dart';

/// Commentaire d'une publication (avec réponses imbriquées, 1 niveau).
class CommunityComment {
  final String id;
  final String body;
  final String? parentId;
  final DateTime createdAt;
  final NetworkUser? user;
  final List<CommunityComment> replies;

  /// Nombre de réactions sur le commentaire.
  final int reactionsCount;

  /// Type de ma réaction (ex. 'like') ou null si je n'ai pas réagi.
  final String? myReaction;

  const CommunityComment({
    required this.id,
    required this.body,
    required this.parentId,
    required this.createdAt,
    required this.user,
    this.replies = const [],
    this.reactionsCount = 0,
    this.myReaction,
  });

  CommunityComment copyWith({
    String? body,
    List<CommunityComment>? replies,
    int? reactionsCount,
    String? myReaction,
    bool clearMyReaction = false,
  }) =>
      CommunityComment(
        id: id,
        body: body ?? this.body,
        parentId: parentId,
        createdAt: createdAt,
        user: user,
        replies: replies ?? this.replies,
        reactionsCount: reactionsCount ?? this.reactionsCount,
        myReaction: clearMyReaction ? null : (myReaction ?? this.myReaction),
      );
}
