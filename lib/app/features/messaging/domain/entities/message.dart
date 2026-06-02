class Message {
  final String id;
  final String text;
  final DateTime sentAt;
  final bool isMine;
  final String senderName;

  const Message({
    required this.id,
    required this.text,
    required this.sentAt,
    required this.isMine,
    required this.senderName,
  });
}
