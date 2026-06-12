/// Cible de navigation d'une notification (deep-link).
///
/// Renseignée par le backend via le bloc `target` :
/// `{type, target_type: 'post'|'conversation'|'story'|'profile'|'connection'
/// |'application'|'training'|null, target_id: string|null}`.
/// Tolérant : tous les champs peuvent être absents/null.
class NotificationTarget {
  /// Type métier brut de la notif (ex. `mention_post`, `new_message`,
  /// `network_request`, `story_reaction`…).
  final String? type;

  /// Type de la ressource ciblée pour le deep-link.
  final String? targetType;

  /// Identifiant de la ressource ciblée.
  final String? targetId;

  const NotificationTarget({this.type, this.targetType, this.targetId});

  bool get hasDestination =>
      targetType != null && targetType!.trim().isNotEmpty;
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String category;
  final DateTime createdAt;
  final bool isRead;
  final NotificationTarget? target;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.createdAt,
    required this.isRead,
    this.target,
  });

  /// Type métier de la notif, utilisé pour le mapping icône (ex. `mention_post`).
  /// Retombe sur [category] si le `target.type` est absent.
  String get typeKey =>
      (target?.type?.trim().isNotEmpty ?? false) ? target!.type! : category;

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        title: title,
        body: body,
        category: category,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
        target: target,
      );
}
