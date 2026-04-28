enum ChatSenderRole {
  tourist,
  authority,
  unknown;

  static ChatSenderRole fromJson(String? value) {
    switch (value) {
      case 'tourist':
        return ChatSenderRole.tourist;
      case 'authority':
        return ChatSenderRole.authority;
      default:
        return ChatSenderRole.unknown;
    }
  }

  String get wireName {
    switch (this) {
      case ChatSenderRole.tourist:
        return 'tourist';
      case ChatSenderRole.authority:
        return 'authority';
      case ChatSenderRole.unknown:
        return 'unknown';
    }
  }
}

enum ChatMessageType {
  text,
  location,
  image;

  static ChatMessageType fromJson(String? value) {
    switch (value) {
      case 'location':
        return ChatMessageType.location;
      case 'image':
        return ChatMessageType.image;
      case 'text':
      default:
        return ChatMessageType.text;
    }
  }

  String get wireName {
    switch (this) {
      case ChatMessageType.text:
        return 'text';
      case ChatMessageType.location:
        return 'location';
      case ChatMessageType.image:
        return 'image';
    }
  }
}

class ChatLocationData {
  const ChatLocationData({required this.lat, required this.lng});

  final double lat;
  final double lng;

  factory ChatLocationData.fromJson(Map<String, dynamic> json) {
    return ChatLocationData(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderRole,
    required this.content,
    required this.messageType,
    required this.createdAt,
    this.locationData,
    this.isRead = false,
  });

  final String id;
  final String roomId;
  final String senderId;
  final ChatSenderRole senderRole;
  final String content;
  final ChatMessageType messageType;
  final ChatLocationData? locationData;
  final bool isRead;
  final DateTime createdAt;

  ChatMessage copyWith({
    String? id,
    String? roomId,
    String? senderId,
    ChatSenderRole? senderRole,
    String? content,
    ChatMessageType? messageType,
    ChatLocationData? locationData,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      senderRole: senderRole ?? this.senderRole,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      locationData: locationData ?? this.locationData,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final locationJson = json['locationData'];
    final createdAtValue = json['createdAt'];

    return ChatMessage(
      id: (json['messageId'] ?? json['_id'] ?? json['id'] ?? '').toString(),
      roomId: (json['roomId'] ?? '').toString(),
      senderId: (json['senderId'] ?? '').toString(),
      senderRole: ChatSenderRole.fromJson(json['senderRole'] as String?),
      content: (json['content'] ?? '').toString(),
      messageType: ChatMessageType.fromJson(json['messageType'] as String?),
      locationData: locationJson is Map<String, dynamic>
          ? ChatLocationData.fromJson(locationJson)
          : null,
      isRead: json['isRead'] == true,
      createdAt: createdAtValue is String
          ? DateTime.tryParse(createdAtValue)?.toLocal() ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
