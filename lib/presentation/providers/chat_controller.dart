import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/message_model.dart';
import '../../data/services/translation_service.dart';

class ChatState {
  const ChatState({
    this.messages = const [],
    this.isTyping = false,
    this.isSending = false,
  });

  final List<MessageModel> messages;
  final bool isTyping;
  final bool isSending;

  ChatState copyWith({
    List<MessageModel>? messages,
    bool? isTyping,
    bool? isSending,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      isSending: isSending ?? this.isSending,
    );
  }
}

class ChatController extends Notifier<ChatState> {
  Timer? _typingTimer;

  @override
  ChatState build() {
    ref.onDispose(() {
      _typingTimer?.cancel();
    });
    return ChatState(
      messages: [
        MessageModel(
          id: 'm1',
          sender: MessageSender.authority,
          text: 'SafeTour Control online. Describe your situation.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          status: MessageStatus.read,
        ),
        MessageModel(
          id: 'm2',
          sender: MessageSender.tourist,
          text: 'I need help near the central station. Feeling unsafe.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
          status: MessageStatus.delivered,
        ),
      ],
    );
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final msg = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: MessageSender.tourist,
      text: text.trim(),
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      animateOnArrival: true,
    );
    state = state.copyWith(
      isSending: true,
      messages: [...state.messages, msg],
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    state = state.copyWith(
      isSending: false,
      messages: state.messages
          .map((m) => m.id == msg.id ? m.copyWith(status: MessageStatus.delivered) : m)
          .toList(),
    );
    _simulateAuthorityTyping();
  }

  void _simulateAuthorityTyping() {
    state = state.copyWith(isTyping: true);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      final reply = MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: MessageSender.authority,
        text: 'Stay calm. We are dispatching assistance now.',
        timestamp: DateTime.now(),
        status: MessageStatus.read,
        animateOnArrival: true,
      );
      state = state.copyWith(
        isTyping: false,
        messages: [...state.messages, reply],
      );
    });
  }

  Future<void> translateMessage(MessageModel message) async {
    final translation = await ref.read(translationServiceProvider).translate(
          text: message.text,
          targetLanguage: 'en',
        );
    final updated = message.copyWith();
    state = state.copyWith(
      messages: [
        for (final msg in state.messages)
          if (msg.id == updated.id)
            MessageModel(
              id: '${msg.id}-t',
              sender: msg.sender,
              text: translation,
              timestamp: DateTime.now(),
              status: msg.status,
              animateOnArrival: true,
            )
          else
            msg,
      ],
    );
  }
}

final chatControllerProvider =
    NotifierProvider<ChatController, ChatState>(ChatController.new);

final translationServiceProvider = Provider<TranslationService>((ref) {
  return TranslationService();
});
