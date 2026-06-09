class AppNotification {
  final String id;
  final String title;
  final String body;
  final String category;
  final DateTime createdAt;
  final bool isRead;
  final String? targetType;
  final String? targetId;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.createdAt,
    required this.isRead,
    this.targetType,
    this.targetId,
  });

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        title: title,
        body: body,
        category: category,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
        targetType: targetType,
        targetId: targetId,
      );
}
