class ChatMessage {
  final String id;
  final String text;
  final bool isUserMessage;
  final DateTime timestamp;
  final bool isTyping;
  bool animate;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUserMessage,
    required this.timestamp,
    this.isTyping = false,
    this.animate = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isUserMessage': isUserMessage,
      'timestamp': timestamp.toIso8601String(),
      'isTyping': isTyping,
      // 'animate' is intentionally not persisted
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      text: json['text'],
      isUserMessage: json['isUserMessage'],
      timestamp: DateTime.parse(json['timestamp']),
      isTyping: json['isTyping'] ?? false,
      // animate is not loaded from storage
    );
  }
}
