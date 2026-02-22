enum MessageSender {
  tourist,
  authority,
}

enum MessageStatus {
  sent,
  delivered,
  read,
}

class MessageModel {
  const MessageModel({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.animateOnArrival = false,
  });

  final String id;
  final MessageSender sender;
  final String text;
  final DateTime timestamp;
  final MessageStatus status;
  final bool animateOnArrival;

  MessageModel copyWith({
    MessageStatus? status,
    bool? animateOnArrival,
  }) {
    return MessageModel(
      id: id,
      sender: sender,
      text: text,
      timestamp: timestamp,
      status: status ?? this.status,
      animateOnArrival: animateOnArrival ?? this.animateOnArrival,
    );
  }
}
