import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../core/config/backend_config.dart';
import '../data/models/chat_message.dart';

class ChatTypingEvent {
  const ChatTypingEvent({required this.roomId});

  final String roomId;

  factory ChatTypingEvent.fromJson(dynamic data) {
    if (data is Map) {
      return ChatTypingEvent(roomId: (data['roomId'] ?? '').toString());
    }

    return const ChatTypingEvent(roomId: '');
  }
}

class ChatService {
  io.Socket? _socket;
  String? _activeToken;
  Timer? _typingDebounce;

  final _messageController = StreamController<ChatMessage>.broadcast();
  final _typingController = StreamController<ChatTypingEvent>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<ChatMessage> get messageStream => _messageController.stream;
  Stream<ChatTypingEvent> get typingStream => _typingController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isConnected => _socket?.connected == true;

  void connect(String token) {
    if (token.isEmpty) {
      _connectionController.add(false);
      return;
    }

    if (_activeToken == token && _socket != null) {
      if (!isConnected) {
        _socket?.connect();
      }
      return;
    }

    _socket?.dispose();
    _activeToken = token;

    final options = io.OptionBuilder()
        .setTransports(['websocket'])
        .setAuth({'token': token})
        .enableReconnection()
        .setReconnectionAttempts(5)
        .setReconnectionDelay(500)
        .setReconnectionDelayMax(8000)
        .disableAutoConnect()
        .build();

    final socket = io.io(BackendConfig.wsBaseUrl, options);
    _socket = socket;

    socket.onConnect((_) {
      _connectionController.add(true);
      debugPrint('SafeTour chat socket connected');
    });

    socket.onDisconnect((_) {
      _connectionController.add(false);
      debugPrint('SafeTour chat socket disconnected');
    });

    socket.onConnectError((error) {
      _connectionController.add(false);
      debugPrint('SafeTour chat socket connect error: $error');
    });

    socket.onError((error) {
      _connectionController.add(false);
      debugPrint('SafeTour chat socket error: $error');
    });

    socket.on('message_received', (data) {
      if (data is Map) {
        _messageController.add(
          ChatMessage.fromJson(Map<String, dynamic>.from(data)),
        );
      }
    });

    socket.on('typing_indicator', (data) {
      _typingController.add(ChatTypingEvent.fromJson(data));
    });

    socket.on('chat_error', (data) {
      debugPrint('SafeTour chat error: $data');
    });

    socket.connect();
  }

  Future<void> joinRoom(String roomId) {
    return _emitWithAck('join_room', {'roomId': roomId});
  }

  Future<void> sendMessage({
    required String roomId,
    required String content,
    String messageType = 'text',
    Map<String, dynamic>? locationData,
  }) {
    return _emitWithAck('send_message', {
      'roomId': roomId,
      'content': content,
      'messageType': messageType,
      ...?locationData == null ? null : {'locationData': locationData},
    });
  }

  void sendTyping(String roomId) {
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(milliseconds: 500), () {
      _socket?.emit('typing', {'roomId': roomId});
    });
  }

  Future<void> markRead(String roomId) {
    return _emitWithAck('mark_read', {'roomId': roomId});
  }

  Future<void> _emitWithAck(String event, Map<String, dynamic> payload) {
    final socket = _socket;
    if (socket == null || socket.connected != true) {
      return Future<void>.error(StateError('Chat is disconnected.'));
    }

    final completer = Completer<void>();
    socket.emitWithAck(
      event,
      payload,
      ack: (response) {
        if (response is Map && response['success'] == true) {
          completer.complete();
          return;
        }

        final message = response is Map
            ? (response['message'] ?? 'Chat request failed.').toString()
            : 'Chat request failed.';
        completer.completeError(StateError(message));
      },
    );

    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('Chat request timed out.'),
    );
  }

  void dispose() {
    _typingDebounce?.cancel();
    _socket?.dispose();
    _messageController.close();
    _typingController.close();
    _connectionController.close();
  }
}
