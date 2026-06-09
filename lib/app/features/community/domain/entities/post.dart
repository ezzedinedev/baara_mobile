 import 'network_user.dart';

/// Pièce jointe d'une publication (image ou PDF).
class PostMedia {
  final String type; // image | pdf
  final String? url;
  final String? name;

  const PostMedia({required this.type, this.url, this.name});

  bool get isImage => type == 'image';
  bool get isPdf => type == 'pdf';
}

/// Publication du fil Communauté.
class Post {
  final String id;
  final String? body;
  final String category; // general | emploi | formation | article | evenement
  final String visibility; // public | connections
  final DateTime createdAt;
  final NetworkUser? author;
  final int reactionsCount;
  final int commentsCount;
  final int sharesCount;
  final bool isLiked;
  final List<PostMedia> media;
  final String? imageUrl;
  final List<String> hashtags;
  final Post? shared; // publication republiée (repost)

  const Post({
    required this.id,
    required this.body,
    required this.category,
    required this.visibility,
    required this.createdAt,
    required this.author,
    required this.reactionsCount,
    required this.commentsCount,
    required this.sharesCount,
    required this.isLiked,
    required this.media,
    this.imageUrl,
    this.hashtags = const [],
    this.shared,
  });

  bool get isRepost => shared != null;
  List<PostMedia> get images => media.where((m) => m.isImage).toList();
  List<PostMedia> get pdfs => media.where((m) => m.isPdf).toList();
}
