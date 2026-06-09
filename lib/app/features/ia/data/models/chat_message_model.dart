import '../../domain/entities/chat_message.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.role,
    required super.content,
    required super.at,
    super.ctaActions = const [],
    super.isError = false,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final atRaw = json['at']?.toString();
    final at = atRaw != null ? DateTime.tryParse(atRaw) ?? DateTime.now() : DateTime.now();
    final ctaRaw = (json['cta_actions'] as List?) ?? [];
    
    return ChatMessageModel(
      role: json['role']?.toString() ?? 'assistant',
      content: json['content']?.toString() ?? '',
      at: at,
      ctaActions: ctaRaw
          .whereType<Map>()
          .map((m) => CtaActionModel.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
    );
  }
}

class CtaActionModel extends CtaAction {
  const CtaActionModel({
    required super.type,
    super.id,
    required super.label,
  });

  factory CtaActionModel.fromJson(Map<String, dynamic> json) {
    return CtaActionModel(
      type: json['type']?.toString() ?? '',
      id: json['id']?.toString(),
      label: json['label']?.toString() ?? 'Ouvrir',
    );
  }
}
