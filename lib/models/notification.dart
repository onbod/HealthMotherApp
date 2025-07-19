class Notification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  bool isRead;

  Notification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
  });

  // Convert a Notification object into a Map object
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  // Extract a Notification object from a Map object
  factory Notification.fromMap(Map<String, dynamic> map) {
    return Notification(
      id: map['id'],
      title: map['title'],
      body: map['body'],
      timestamp: DateTime.parse(map['timestamp']),
      isRead: map['isRead'] ?? false,
    );
  }
}
