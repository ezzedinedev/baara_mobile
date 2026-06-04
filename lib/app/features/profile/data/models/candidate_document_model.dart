/// Document du candidat (diplôme, certificat, lettre…) — miroir du payload
/// backend `ProfileApiController@transformDocument`.
class CandidateDocument {
  const CandidateDocument({
    required this.id,
    required this.type,
    required this.typeLabel,
    required this.title,
    required this.originalFilename,
    required this.mimeType,
    required this.sizeLabel,
    required this.downloadUrl,
  });

  final String id;
  final String type;
  final String typeLabel;
  final String title;
  final String originalFilename;
  final String mimeType;
  final String sizeLabel;
  final String downloadUrl;

  bool get isPdf => mimeType.contains('pdf');
  bool get isImage => mimeType.startsWith('image/');

  factory CandidateDocument.fromJson(Map<String, dynamic> json) {
    return CandidateDocument(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'other',
      typeLabel: json['type_label']?.toString() ?? 'Document',
      title: json['title']?.toString() ?? '',
      originalFilename: json['original_filename']?.toString() ?? '',
      mimeType: json['mime_type']?.toString() ?? '',
      sizeLabel: json['size_label']?.toString() ?? '',
      downloadUrl: json['download_url']?.toString() ?? '',
    );
  }
}

/// Types de documents acceptés par le backend (`CandidateDocument::TYPES`).
class DocumentType {
  const DocumentType(this.key, this.label);
  final String key;
  final String label;

  static const all = <DocumentType>[
    DocumentType('diploma', 'Diplôme'),
    DocumentType('certificate', 'Certificat'),
    DocumentType('cover_letter', 'Lettre de motivation'),
    DocumentType('reference', 'Lettre de recommandation'),
    DocumentType('other', 'Autre'),
  ];
}
