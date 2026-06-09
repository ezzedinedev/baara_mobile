class ChatMessage {
  final String role;
  final String content;
  final DateTime at;
  final List<CtaAction> ctaActions;
  final bool isError;

  const ChatMessage({
    required this.role,
    required this.content,
    required this.at,
    this.ctaActions = const [],
    this.isError = false,
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}

class CtaAction {
  final String type;
  final String? id;
  final String label;

  const CtaAction({
    required this.type,
    this.id,
    required this.label,
  });
}
