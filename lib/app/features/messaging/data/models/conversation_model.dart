import '../../domain/entities/conversation.dart';

class ConversationModel extends Conversation {
  const ConversationModel({
    required super.id,
    required super.title,
    required super.lastMessage,
    required super.lastMessageTime,
    required super.unreadCount,
    required super.isOnline,
    super.avatar,
  });

  /// Mappe une conversation telle que renvoyee par
  /// `MessageApiController@conversations` (serialisation Eloquent brute).
  ///
  /// Forme reelle d'un item :
  /// {
  ///   "id": "uuid-v4",
  ///   "last_message_at": "2026-05-30T09:12:00.000000Z",
  ///   "unread_employer": 0,
  ///   "unread_candidate": 2,
  ///   "latest_message": { "content": "...", "sent_at": "..." },
  ///   "candidate": { "user": { "first_name": "...", "last_name": "...",
  ///                            "avatar_url": "..." } },
  ///   "employer":  { "company_name": "...", "logo_url": "..." }
  /// }
  ///
  /// Le nom affiche depend du point de vue ([viewerType]) :
  ///  - un candidat voit l'entreprise (`employer.company_name`),
  ///  - un recruteur voit le candidat (`candidate.user.first_name + last_name`).
  factory ConversationModel.fromJson(
    Map<String, dynamic> json, {
    String? viewerType,
  }) {
    final employer = json['employer'] as Map<String, dynamic>?;
    final candidate = json['candidate'] as Map<String, dynamic>?;
    final candidateUser = candidate?['user'] as Map<String, dynamic>?;

    final companyName = (employer?['company_name'] as String?)?.trim();
    final candidateName = _fullName(
      candidateUser?['first_name'],
      candidateUser?['last_name'],
    );

    final isRecruiterViewer = viewerType == 'recruiter';

    // Choisit l'interlocuteur en priorite selon le role, avec repli sur
    // l'autre cote si la donnee preferee manque.
    final String title = (isRecruiterViewer
            ? (candidateName ?? companyName)
            : (companyName ?? candidateName)) ??
        'Inconnu';

    final avatar = isRecruiterViewer
        ? (candidateUser?['avatar_url'] ?? employer?['logo_url'])
        : (employer?['logo_url'] ?? candidateUser?['avatar_url']);

    final latest = json['latest_message'] as Map<String, dynamic>?;
    final lastMessage =
        (latest?['content'] as String?) ?? (json['preview'] as String?) ?? '';

    // `last_message_at` est la source de verite cote conversation ;
    // repli sur le `sent_at` du dernier message si besoin.
    final lastTime = _parseDate(json['last_message_at']) ??
        _parseDate(latest?['sent_at']) ??
        DateTime.now();

    final unread = ((isRecruiterViewer
                ? json['unread_employer']
                : json['unread_candidate']) as num?)
            ?.toInt() ??
        (json['unread_count'] as num?)?.toInt() ??
        0;

    return ConversationModel(
      id: json['id']?.toString() ?? '',
      title: title,
      lastMessage: lastMessage,
      lastMessageTime: lastTime,
      unreadCount: unread,
      isOnline: json['is_online'] == true,
      avatar: avatar as String?,
    );
  }

  static String? _fullName(dynamic first, dynamic last) {
    final f = (first as String?)?.trim() ?? '';
    final l = (last as String?)?.trim() ?? '';
    final full = '$f $l'.trim();
    return full.isEmpty ? null : full;
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }
}
