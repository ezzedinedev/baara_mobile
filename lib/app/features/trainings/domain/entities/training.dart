class Training {
  final String id;
  final String title;
  final String providerName;
  final String? providerLogo;
  final String location;
  final String format;
  final String level;
  final int lessons;
  final double rating;
  final int enrolledCount;
  final String status;
  final String priceLabel;
  final double? price;
  final String sector;
  final String description;
  final String durationLabel;
  final String startDateLabel;
  final String deadlineLabel;
  final String certificationLabel;
  final String languageLabel;
  final List<String> objectives;
  final List<String> requirements;
  final List<TrainingModule> modules;
  final String contactLabel;
  final bool isBookmarked;
  final bool isEnrolled;
  final String coverUrl;

  const Training({
    required this.id,
    required this.title,
    required this.providerName,
    this.providerLogo,
    required this.location,
    required this.format,
    required this.level,
    required this.lessons,
    required this.rating,
    required this.enrolledCount,
    required this.status,
    required this.priceLabel,
    this.price,
    required this.sector,
    required this.description,
    required this.durationLabel,
    required this.startDateLabel,
    required this.deadlineLabel,
    required this.certificationLabel,
    required this.languageLabel,
    required this.objectives,
    required this.requirements,
    required this.modules,
    required this.contactLabel,
    required this.isBookmarked,
    required this.isEnrolled,
    required this.coverUrl,
  });
}

/// Type de contenu d'une leçon (module). Mappé depuis `content_type` côté
/// backend (`video|pdf|image|text|link`, plus alias powerpoint/word/excel/quiz
/// dégradés vers le viewer le plus proche).
enum LessonContentType { video, pdf, image, text, link, unknown }

class TrainingModule {
  final String id;
  final String title;
  final String description;
  final int duration;
  final bool isCompleted;

  /// Type de contenu de la leçon.
  final LessonContentType contentType;

  /// URL brute résolue du média/document principal (`content_url`).
  final String contentUrl;

  /// URL spécifique vidéo (si distincte de [contentUrl]).
  final String videoUrl;

  /// URL spécifique document/PDF.
  final String documentUrl;

  /// URL spécifique image.
  final String imageUrl;

  /// Contenu texte riche (leçon de type article).
  final String textContent;

  /// Lien externe / ressource complémentaire.
  final String resourceUrl;

  const TrainingModule({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.isCompleted,
    this.contentType = LessonContentType.unknown,
    this.contentUrl = '',
    this.videoUrl = '',
    this.documentUrl = '',
    this.imageUrl = '',
    this.textContent = '',
    this.resourceUrl = '',
  });

  bool get isVideo => contentType == LessonContentType.video;
  bool get isPdf => contentType == LessonContentType.pdf;
  bool get isImage => contentType == LessonContentType.image;
  bool get isText => contentType == LessonContentType.text;
  bool get isLink => contentType == LessonContentType.link;

  /// URL effective à afficher selon le type, en retombant sur [contentUrl].
  String get effectiveUrl {
    if (isVideo && videoUrl.isNotEmpty) return videoUrl;
    if (isPdf && documentUrl.isNotEmpty) return documentUrl;
    if (isImage && imageUrl.isNotEmpty) return imageUrl;
    if (isLink && resourceUrl.isNotEmpty) return resourceUrl;
    if (contentUrl.isNotEmpty) return contentUrl;
    return videoUrl.isNotEmpty
        ? videoUrl
        : documentUrl.isNotEmpty
            ? documentUrl
            : imageUrl.isNotEmpty
                ? imageUrl
                : resourceUrl;
  }

  /// Libellé court du type pour les badges.
  String get typeLabel {
    switch (contentType) {
      case LessonContentType.video:
        return 'Vidéo';
      case LessonContentType.pdf:
        return 'Document';
      case LessonContentType.image:
        return 'Image';
      case LessonContentType.text:
        return 'Article';
      case LessonContentType.link:
        return 'Lien';
      case LessonContentType.unknown:
        return 'Leçon';
    }
  }
}
