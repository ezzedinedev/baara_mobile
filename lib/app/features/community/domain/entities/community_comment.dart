import 'network_user.dart';

/// Commentaire d'une publication (avec réponses imbriquées, 1 niveau).
class CommunityComment {
  final String id;
  final String body;
  final String? parentId;
  final DateTime createdAt;
  final NetworkUser? user;
  final List<CommunityComment> replies;

  const CommunityComment({
    required this.id,
    required this.body,
    required this.parentId,
    required this.createdAt,
    required this.user,
    this.replies = const [],
  });
}
