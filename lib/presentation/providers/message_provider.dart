import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ChatSender { user, authority }

enum ChatMessageStatus { sent, delivered, failed }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.status = ChatMessageStatus.sent,
    this.animateOnArrival = false,
    this.translatedText,
    this.isTranslating = false,
  });

  final String id;
  final ChatSender sender;
  final String text;
  final DateTime timestamp;
  final ChatMessageStatus status;
  final bool animateOnArrival;
  final String? translatedText;
  final bool isTranslating;

  ChatMessage copyWith({
    ChatMessageStatus? status,
    bool? animateOnArrival,
    String? translatedText,
    bool? isTranslating,
  }) {
    return ChatMessage(
      id: id,
      sender: sender,
      text: text,
      timestamp: timestamp,
      status: status ?? this.status,
      animateOnArrival: animateOnArrival ?? this.animateOnArrival,
      translatedText: translatedText ?? this.translatedText,
      isTranslating: isTranslating ?? this.isTranslating,
    );
  }
}

class ChatState {
  const ChatState({
    this.messages = const [],
    this.isTyping = false,
    this.isSending = false,
  });

  final List<ChatMessage> messages;
  final bool isTyping;
  final bool isSending;

  ChatState copyWith({
    List<ChatMessage>? messages,
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

class MessageController extends Notifier<ChatState> {
  Timer? _typingTimer;
  final _rng = Random();

  @override
  ChatState build() {
    ref.onDispose(() {
      _typingTimer?.cancel();
    });
    return const ChatState(messages: []);
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final msg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: ChatSender.user,
      text: text.trim(),
      timestamp: DateTime.now(),
      status: ChatMessageStatus.sent,
      animateOnArrival: true,
    );
    state = state.copyWith(
      isSending: true,
      messages: [...state.messages, msg],
    );
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final shouldFail = _rng.nextInt(6) == 0;
    if (shouldFail) {
      state = state.copyWith(
        isSending: false,
        messages: state.messages
            .map((m) =>
                m.id == msg.id ? m.copyWith(status: ChatMessageStatus.failed) : m)
            .toList(),
      );
      return;
    }
    state = state.copyWith(
      isSending: false,
      messages: state.messages
          .map((m) => m.id == msg.id
              ? m.copyWith(status: ChatMessageStatus.delivered)
              : m)
          .toList(),
    );
    _simulateAuthorityTyping();
  }

  Future<void> retryMessage(ChatMessage message) async {
    state = state.copyWith(
      isSending: true,
      messages: state.messages
          .map((m) => m.id == message.id
              ? m.copyWith(status: ChatMessageStatus.sent)
              : m)
          .toList(),
    );
    await Future<void>.delayed(const Duration(milliseconds: 350));
    state = state.copyWith(
      isSending: false,
      messages: state.messages
          .map((m) => m.id == message.id
              ? m.copyWith(status: ChatMessageStatus.delivered)
              : m)
          .toList(),
    );
  }

  void _simulateAuthorityTyping() {
    state = state.copyWith(isTyping: true);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      final reply = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: ChatSender.authority,
        text: 'Tourist Police here. We are dispatching assistance now.',
        timestamp: DateTime.now(),
        status: ChatMessageStatus.delivered,
        animateOnArrival: true,
      );
      state = state.copyWith(
        isTyping: false,
        messages: [...state.messages, reply],
      );
    });
  }

  Future<void> translateMessage(ChatMessage message) async {
    if (message.isTranslating) return;
    state = state.copyWith(
      messages: state.messages
          .map((m) => m.id == message.id ? m.copyWith(isTranslating: true) : m)
          .toList(),
    );
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final translated = 'Translated: ${message.text}';
    state = state.copyWith(
      messages: state.messages
          .map((m) => m.id == message.id
              ? m.copyWith(isTranslating: false, translatedText: translated)
              : m)
          .toList(),
    );
  }
}

final messageProvider =
    NotifierProvider<MessageController, ChatState>(MessageController.new);
