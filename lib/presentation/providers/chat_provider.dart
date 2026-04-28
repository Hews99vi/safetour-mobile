import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/jwt_utils.dart';
import '../../data/models/chat_message.dart';
import '../../services/chat_service.dart';
import 'safety_providers.dart';

class ChatMessagesState {
  const ChatMessagesState({
    this.messages = const [],
    this.isLoading = true,
    this.isSending = false,
    this.errorMessage,
  });

  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isSending;
  final String? errorMessage;

  ChatMessagesState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isSending,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatMessagesState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final chatServiceProvider = Provider<ChatService>((ref) {
  final service = ChatService();
  ref.onDispose(service.dispose);
  return service;
});

final chatRoomProvider = FutureProvider<String?>((ref) async {
  final token = await ref.watch(secureStorageProvider).readToken();
  if (token == null || token.isEmpty) return null;

  final payload = decodeJwtPayload(token);
  if (payload == null || payload.role == 'admin') return null;

  return 'tourist_${payload.userId}';
});

final chatConnectionProvider = StreamProvider<bool>((ref) {
  return ref.watch(chatServiceProvider).connectionStream;
});

final typingProvider = NotifierProvider.family
    .autoDispose<TypingNotifier, bool, String>(TypingNotifier.new);

class TypingNotifier extends Notifier<bool> {
  TypingNotifier(this.roomId);

  final String roomId;
  Timer? _clearTimer;
  StreamSubscription<ChatTypingEvent>? _typingSub;

  @override
  bool build() {
    _typingSub = ref.read(chatServiceProvider).typingStream.listen((event) {
      if (event.roomId.isNotEmpty && event.roomId != roomId) return;

      state = true;
      _clearTimer?.cancel();
      _clearTimer = Timer(const Duration(seconds: 2), () {
        state = false;
      });
    });

    ref.onDispose(() {
      _clearTimer?.cancel();
      _typingSub?.cancel();
    });

    return false;
  }
}

final chatMessagesProvider = NotifierProvider.family
    .autoDispose<ChatMessagesNotifier, ChatMessagesState, String>(
      ChatMessagesNotifier.new,
    );

class ChatMessagesNotifier extends Notifier<ChatMessagesState> {
  ChatMessagesNotifier(this.roomId);

  final String roomId;
  StreamSubscription<ChatMessage>? _messageSub;

  @override
  ChatMessagesState build() {
    ref.onDispose(() {
      _messageSub?.cancel();
    });

    Future<void>.microtask(_start);
    return const ChatMessagesState();
  }

  Future<void> sendText(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;

    state = state.copyWith(isSending: true, clearError: true);

    try {
      await ref
          .read(chatServiceProvider)
          .sendMessage(roomId: roomId, content: trimmed);
      state = state.copyWith(isSending: false);
    } catch (_) {
      state = state.copyWith(
        isSending: false,
        errorMessage: 'Unable to send message. Check your connection.',
      );
    }
  }

  Future<void> sendLocation(double lat, double lng) async {
    state = state.copyWith(isSending: true, clearError: true);

    try {
      await ref
          .read(chatServiceProvider)
          .sendMessage(
            roomId: roomId,
            content: 'My current location',
            messageType: ChatMessageType.location.wireName,
            locationData: {'lat': lat, 'lng': lng},
          );
      state = state.copyWith(isSending: false);
    } catch (_) {
      state = state.copyWith(
        isSending: false,
        errorMessage: 'Unable to send location. Check your connection.',
      );
    }
  }

  void sendTyping() {
    ref.read(chatServiceProvider).sendTyping(roomId);
  }

  Future<void> markRead() async {
    try {
      await ref.read(chatServiceProvider).markRead(roomId);
    } catch (_) {
      // Read receipts are helpful but should not block the chat UI.
    }
  }

  Future<void> _start() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final storage = ref.read(secureStorageProvider);
      final token = await storage.readToken();
      if (token == null || token.isEmpty || decodeJwtPayload(token) == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Please log in to use chat.',
        );
        return;
      }

      final service = ref.read(chatServiceProvider);
      service.connect(token);

      await _messageSub?.cancel();
      _messageSub = service.messageStream.listen(_addIncomingMessage);

      await service.joinRoom(roomId);
      final history = await ref
          .read(safetyApiProvider)
          .fetchChatHistory(roomId);
      state = state.copyWith(
        messages: history,
        isLoading: false,
        clearError: true,
      );
      await markRead();
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to connect to chat.',
      );
    }
  }

  void _addIncomingMessage(ChatMessage message) {
    if (message.roomId.isNotEmpty && message.roomId != roomId) return;

    final normalized = message.roomId.isEmpty
        ? message.copyWith(roomId: roomId)
        : message;
    final current = state.messages;
    if (normalized.id.isNotEmpty &&
        current.any((item) => item.id == normalized.id)) {
      return;
    }

    state = state.copyWith(
      messages: [...current, normalized],
      isLoading: false,
      clearError: true,
    );
    unawaited(markRead());
  }
}
