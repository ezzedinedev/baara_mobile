import 'network_user.dart';

/// Pièce jointe d'une publication (image, PDF ou vidéo).
class PostMedia {
  final String type; // image | pdf | video
  final String? url;
  final String? thumbUrl; // miniature légère (grilles/aperçus)
  final String? name;

  const PostMedia({required this.type, this.url, this.thumbUrl, this.name});

  /// URL à privilégier pour les grilles/aperçus (miniature si dispo).
  String? get previewUrl => thumbUrl ?? url;

  bool get isImage => type == 'image';
  bool get isPdf => type == 'pdf';
  bool get isVideo => type == 'video';
}

/// Une option d'un sondage.
class PollOption {
  final String id;
  final String label;
  final int votesCount;
  final bool votedByMe;

  const PollOption({
    required this.id,
    required this.label,
    required this.votesCount,
    required this.votedByMe,
  });

  PollOption copyWith({int? votesCount, bool? votedByMe}) => PollOption(
        id: id,
        label: label,
        votesCount: votesCount ?? this.votesCount,
        votedByMe: votedByMe ?? this.votedByMe,
      );
}

/// Sondage attaché à une publication.
class PostPoll {
  final String id;
  final String? question;
  final bool multiple;
  final DateTime? closesAt;
  final bool isClosed;
  final int totalVotes;
  final List<PollOption> options;
  final List<String> myVotes;

  const PostPoll({
    required this.id,
    this.question,
    required this.multiple,
    this.closesAt,
    required this.isClosed,
    required this.totalVotes,
    required this.options,
    this.myVotes = const [],
  });

  bool get hasVoted => myVotes.isNotEmpty;

  /// Le sondage doit afficher les résultats (voté OU clôturé).
  bool get showResults => hasVoted || isClosed;

  /// Fraction [0..1] des voix d'une option par rapport au total.
  double fractionFor(PollOption option) {
    if (totalVotes <= 0) return 0;
    return (option.votesCount / totalVotes).clamp(0.0, 1.0);
  }

  PostPoll copyWith({
    bool? isClosed,
    int? totalVotes,
    List<PollOption>? options,
    List<String>? myVotes,
  }) =>
      PostPoll(
        id: id,
        question: question,
        multiple: multiple,
        closesAt: closesAt,
        isClosed: isClosed ?? this.isClosed,
        totalVotes: totalVotes ?? this.totalVotes,
        options: options ?? this.options,
        myVotes: myVotes ?? this.myVotes,
      );
}

/// Aperçu (Open Graph) d'un lien détecté dans une publication.
class PostLinkPreview {
  final String url;
  final String? title;
  final String? description;
  final String? image;

  const PostLinkPreview({
    required this.url,
    this.title,
    this.description,
    this.image,
  });

  /// Nom de domaine lisible (sans `www.`) pour l'affichage de la carte.
  String get domain {
    final uri = Uri.tryParse(url);
    final host = uri?.host ?? '';
    return host.startsWith('www.') ? host.substring(4) : host;
  }
}

/// Types de réaction supportés par le backend.
/// Ordre = ordre d'affichage dans le picker.
const List<String> kReactionTypes = ['like', 'love', 'bravo', 'instructif'];

/// Emoji associé à chaque type de réaction.
const Map<String, String> kReactionEmojis = {
  'like': '👍',
  'love': '❤️',
  'bravo': '👏',
  'instructif': '💡',
};

/// Libellé court (FR) de chaque type de réaction.
const Map<String, String> kReactionLabels = {
  'like': "J'aime",
  'love': 'J\'adore',
  'bravo': 'Bravo',
  'instructif': 'Instructif',
};

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

  /// Réaction de l'utilisateur courant : like | love | bravo | instructif | null.
  final String? myReaction;

  /// Répartition des réactions par type, ex. {like:0, love:1, bravo:0, instructif:0}.
  final Map<String, int> reactionsBreakdown;

  /// La publication a été éditée par son auteur.
  final bool isEdited;

  /// Date de la dernière édition (si [isEdited]).
  final DateTime? editedAt;

  /// La publication est enregistrée (signet) par l'utilisateur courant.
  final bool isSaved;

  /// Sondage attaché (null si aucun).
  final PostPoll? poll;

  /// Aperçu du lien détecté dans le corps (null si aucun).
  final PostLinkPreview? linkPreview;

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
    this.myReaction,
    this.reactionsBreakdown = const {},
    this.isEdited = false,
    this.editedAt,
    this.isSaved = false,
    this.poll,
    this.linkPreview,
  });

  bool get isRepost => shared != null;
  List<PostMedia> get images => media.where((m) => m.isImage).toList();
  List<PostMedia> get pdfs => media.where((m) => m.isPdf).toList();
  List<PostMedia> get videos => media.where((m) => m.isVideo).toList();

  /// Types réellement présents (count > 0), dans l'ordre canonique.
  List<String> get presentReactionTypes => [
        for (final t in kReactionTypes)
          if ((reactionsBreakdown[t] ?? 0) > 0) t,
      ];

  Post copyWith({
    String? body,
    NetworkUser? author,
    int? reactionsCount,
    int? commentsCount,
    int? sharesCount,
    bool? isLiked,
    String? myReaction,
    bool clearMyReaction = false,
    Map<String, int>? reactionsBreakdown,
    bool? isEdited,
    DateTime? editedAt,
    bool? isSaved,
    PostPoll? poll,
    PostLinkPreview? linkPreview,
  }) =>
      Post(
        id: id,
        body: body ?? this.body,
        category: category,
        visibility: visibility,
        createdAt: createdAt,
        author: author ?? this.author,
        reactionsCount: reactionsCount ?? this.reactionsCount,
        commentsCount: commentsCount ?? this.commentsCount,
        sharesCount: sharesCount ?? this.sharesCount,
        isLiked: isLiked ?? this.isLiked,
        media: media,
        imageUrl: imageUrl,
        hashtags: hashtags,
        shared: shared,
        myReaction: clearMyReaction ? null : (myReaction ?? this.myReaction),
        reactionsBreakdown: reactionsBreakdown ?? this.reactionsBreakdown,
        isEdited: isEdited ?? this.isEdited,
        editedAt: editedAt ?? this.editedAt,
        isSaved: isSaved ?? this.isSaved,
        poll: poll ?? this.poll,
        linkPreview: linkPreview ?? this.linkPreview,
      );
}
