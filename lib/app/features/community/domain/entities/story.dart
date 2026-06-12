/// Auteur d'une story (sous-ensemble du profil réseau).
class StoryAuthor {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? userType;

  const StoryAuthor({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.userType,
  });
}

/// Une story (un média éphémère).
class StoryItem {
  final String id;
  final String? mediaUrl;
  final String mediaType; // 'image' | 'video'
  final String? caption;
  final String? backgroundColor; // story texte (hex) quand pas de média
  final DateTime createdAt;
  final bool isMine;
  final int? viewsCount; // visible seulement par l'auteur
  final int? reactionsCount;

  /// État local : vue par l'utilisateur courant (mutable pour MAJ instantanée).
  bool seen;

  StoryItem({
    required this.id,
    required this.mediaUrl,
    required this.mediaType,
    required this.caption,
    required this.backgroundColor,
    required this.createdAt,
    required this.isMine,
    required this.seen,
    this.viewsCount,
    this.reactionsCount,
  });

  /// Story texte (pas de média, fond coloré).
  bool get isText => (mediaUrl == null || mediaUrl!.isEmpty);
}

/// Regroupement des stories par auteur (une « bulle » dans la barre).
class StoryBucket {
  final StoryAuthor user;
  final bool isMine;
  final List<StoryItem> stories;

  StoryBucket({
    required this.user,
    required this.isMine,
    required this.stories,
  });

  bool get hasUnseen => stories.any((s) => !s.seen);
}
