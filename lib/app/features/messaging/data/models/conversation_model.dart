import 'package:jobaway/app/core/constants/api_constants.dart';

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
    super.lastSeenAt,
    super.peerUserId,
    super.isRequest,
    super.isRequester,
  });

  /// Mappe une conversation telle que renvoyee par
  /// `MessageApiController@conversations` (serialisation Eloquent brute).
  ///

  factory ConversationModel.fromJson(
    Map<String, dynamic> json, {
    String? viewerType,
  }) {
    // Conversation DIRECTE (DM reseau, reponse a une story) : l'interlocuteur
    // est `direct_user` (pose par le backend), pas employer/candidate.
    final directUser = json['direct_user'] as Map<String, dynamic>?;
    final directName = directUser == null
        ? null
        : _fullName(directUser['first_name'], directUser['last_name']);
    final directAvatar = directUser?['avatar_url'] as String?;

    final employer = json['employer'] as Map<String, dynamic>?;
    final candidate = json['candidate'] as Map<String, dynamic>?;
    final candidateUser = candidate?['user'] as Map<String, dynamic>?;

    final companyName = (employer?['company_name'] as String?)?.trim();
    final candidateName = _fullName(
      candidateUser?['first_name'],
      candidateUser?['last_name'],
    );

    final isRecruiterViewer = viewerType == 'recruiter';

    // Direct d'abord ; sinon choix selon le role avec repli sur l'autre cote.
    final String title = directName ??
        (isRecruiterViewer
            ? (candidateName ?? companyName)
            : (companyName ?? candidateName)) ??
        'Inconnu';

    final rawAvatar = directAvatar ??
        (isRecruiterViewer
            ? (candidateUser?['avatar_url'] ?? employer?['logo_url'])
            : (employer?['logo_url'] ?? candidateUser?['avatar_url']));
    final avatar = ApiConstants.resolveMediaUrl(rawAvatar as String?);

    final latest = json['latest_message'] as Map<String, dynamic>?;
    final lastMessage =
        (latest?['content'] as String?) ?? (json['preview'] as String?) ?? '';

    // `last_message_at` est la source de verite cote conversation ;
    // repli sur le `sent_at` du dernier message si besoin.
    final lastTime = _parseDate(json['last_message_at']) ??
        _parseDate(latest?['sent_at']) ??
        DateTime.now();

    // Direct : `unread_for_me` ; sinon compteur selon le role.
    final unread = (json['unread_for_me'] as num?)?.toInt() ??
        ((isRecruiterViewer
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
      // `is_online`/`last_seen_at` peuvent venir de `direct_user` (DM) ou de
      // la racine de l'item selon le backend : on lit les deux.
      isOnline: directUser?['is_online'] == true || json['is_online'] == true,
      avatar: avatar,
      lastSeenAt: _parseDate(directUser?['last_seen_at']) ??
          _parseDate(json['last_seen_at']),
      peerUserId: directUser?['id']?.toString(),
      // Demande de message (statut 'pending') + qui en est l'émetteur.
      // cf. MessageApiController@decorateDirect.
      isRequest: json['is_request'] == true,
      isRequester: json['is_requester'] == true,
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
