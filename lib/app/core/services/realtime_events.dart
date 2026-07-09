import 'dart:async';

import 'package:get/get.dart';

import '../../features/messaging/domain/entities/message.dart';

/// Bus d'événements temps réel — découple [RealtimeService] des controllers UI.
sealed class RealtimeEvent {}

class RealtimeMessageSent extends RealtimeEvent {
  RealtimeMessageSent({
    required this.conversationId,
    this.message,
    this.raw,
  });

  final String? conversationId;
  final Message? message;
  final Map<String, dynamic>? raw;
}

class RealtimeTyping extends RealtimeEvent {
  RealtimeTyping({
    required this.conversationId,
    required this.userId,
    required this.typing,
  });

  final String conversationId;
  final String userId;
  final bool typing;
}

class RealtimeMessagesRead extends RealtimeEvent {
  RealtimeMessagesRead({
    required this.conversationId,
    required this.readerId,
    required this.readAt,
  });

  final String conversationId;
  final String readerId;
  final DateTime readAt;
}

class RealtimeMessageReaction extends RealtimeEvent {
  RealtimeMessageReaction({
    required this.messageId,
    required this.userId,
    required this.emoji,
    required this.removed,
  });

  final String messageId;
  final String userId;
  final String emoji;
  final bool removed;
}

class RealtimeNotificationCreated extends RealtimeEvent {}

class RealtimeStoryCreated extends RealtimeEvent {}

class RealtimeEventBus extends GetxService {
  final _controller = StreamController<RealtimeEvent>.broadcast();

  Stream<RealtimeEvent> get stream => _controller.stream;

  void emit(RealtimeEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  @override
  void onClose() {
    _controller.close();
    super.onClose();
  }
}
