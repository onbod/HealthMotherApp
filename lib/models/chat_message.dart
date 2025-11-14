// ChatMessage model for chat system
class ChatMessage {
  // Primary keys
  final int? id; // Database ID (SERIAL)
  final String fhirId; // FHIR resource ID

  // Thread and participant information
  final int threadId; // References chat_threads(id)
  final String senderId; // User/health worker ID
  final String receiverId; // User/health worker ID
  final String? senderType; // 'patient', 'health_worker', etc.

  // References
  final int? patientId; // References patient(patient_id)
  final int? organizationId; // References organization(organization_id)

  // Message content
  final String message; // Message text (TEXT NOT NULL)

  // Status
  final bool isRead; // Read status (BOOLEAN DEFAULT FALSE)

  // DAK specific fields
  final String? dakMessageId; // DAK specific message ID

  // FHIR resource data
  final Map<String, dynamic>? fhirResource; // FHIR JSONB resource
  final String? versionId; // FHIR version ID

  // Timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastUpdated;

  // UI-only fields (not persisted to database)
  bool animate;
  bool isTyping;
  
  // Backward compatibility: stored isUserMessage flag (for legacy code)
  final bool? _isUserMessage;

  ChatMessage({
    // Accept both String (UUID) and int (database ID) for backward compatibility
    dynamic id,
    String? fhirId,
    int? threadId,
    String? senderId,
    String? receiverId,
    this.senderType,
    this.patientId,
    this.organizationId,
    String? message,
    String? text, // Backward compatibility: maps to message
    this.isRead = false,
    this.dakMessageId,
    this.fhirResource,
    this.versionId,
    DateTime? createdAt,
    DateTime? timestamp, // Backward compatibility: maps to createdAt
    this.updatedAt,
    this.lastUpdated,
    this.animate = false,
    this.isTyping = false,
    bool? isUserMessage, // Backward compatibility: stored boolean flag
  })  : id = id is int ? id : null,
        fhirId = fhirId ?? (id != null ? id.toString() : ''),
        threadId = threadId ?? 0,
        senderId = senderId ?? '',
        receiverId = receiverId ?? '',
        message = message ?? text ?? '',
        createdAt = createdAt ?? timestamp,
        _isUserMessage = isUserMessage;

  /// Convenience getter for timestamp (prioritizes created_at, then last_updated)
  DateTime get timestamp => createdAt ?? lastUpdated ?? DateTime.now();

  /// Backward compatibility: getter for text (maps to message)
  String get text => message;

  /// Backward compatibility: getter for isUserMessage
  /// If _isUserMessage was set, use it; otherwise check senderId
  bool get isUserMessage {
    if (_isUserMessage != null) {
      return _isUserMessage!;
    }
    // If no stored value, we can't determine without current user context
    // Return false as default (can be overridden by calling isUserMessageWithId)
    return false;
  }

  /// Method to determine if message is from user (requires current user ID)
  /// This is determined by comparing sender_id with current user
  bool isUserMessageWithId(String currentUserId) {
    return senderId == currentUserId;
  }

  /// Convert to JSON for API requests and database storage
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'fhir_id': fhirId,
      'thread_id': threadId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      if (senderType != null) 'sender_type': senderType,
      if (patientId != null) 'patient_id': patientId,
      if (organizationId != null) 'organization_id': organizationId,
      'message': message,
      'is_read': isRead,
      if (dakMessageId != null) 'dak_message_id': dakMessageId,
      if (fhirResource != null) 'fhir_resource': fhirResource,
      if (versionId != null) 'version_id': versionId,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (lastUpdated != null) 'last_updated': lastUpdated!.toIso8601String(),
      // UI-only fields (for backward compatibility with local storage)
      'isTyping': isTyping,
      if (_isUserMessage != null) 'isUserMessage': _isUserMessage,
      // 'animate' is intentionally not persisted
    };
  }

  /// Create from JSON (from API or database)
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] is int ? json['id'] as int : (json['id'] is String ? json['id'] as String : null),
      fhirId: json['fhir_id'] as String? ?? json['fhirId'] as String? ?? '',
      threadId: json['thread_id'] as int? ?? json['threadId'] as int? ?? 0,
      senderId: json['sender_id'] as String? ?? json['senderId'] as String? ?? '',
      receiverId: json['receiver_id'] as String? ?? json['receiverId'] as String? ?? '',
      senderType: json['sender_type'] as String? ?? json['senderType'] as String?,
      patientId: json['patient_id'] as int? ?? json['patientId'] as int?,
      organizationId: json['organization_id'] as int? ?? json['organizationId'] as int?,
      message: json['message'] as String? ?? json['text'] as String? ?? '',
      isRead: json['is_read'] as bool? ?? json['isRead'] as bool? ?? false,
      dakMessageId: json['dak_message_id'] as String? ?? json['dakMessageId'] as String?,
      fhirResource: json['fhir_resource'] as Map<String, dynamic>? ?? 
                    json['fhirResource'] as Map<String, dynamic>?,
      versionId: json['version_id'] as String? ?? json['versionId'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'] as String)
              : json['timestamp'] != null
                  ? DateTime.tryParse(json['timestamp'] as String)
                  : null,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : json['updatedAt'] != null
              ? DateTime.tryParse(json['updatedAt'] as String)
              : null,
      lastUpdated: json['last_updated'] != null
          ? DateTime.tryParse(json['last_updated'] as String)
          : json['lastUpdated'] != null
              ? DateTime.tryParse(json['lastUpdated'] as String)
              : null,
      isTyping: json['isTyping'] as bool? ?? false,
      isUserMessage: json['isUserMessage'] as bool?,
      animate: json['animate'] as bool? ?? false,
    );
  }

  /// Create a copy with updated fields
  ChatMessage copyWith({
    dynamic id,
    String? fhirId,
    int? threadId,
    String? senderId,
    String? receiverId,
    String? senderType,
    int? patientId,
    int? organizationId,
    String? message,
    String? text,
    bool? isRead,
    String? dakMessageId,
    Map<String, dynamic>? fhirResource,
    String? versionId,
    DateTime? createdAt,
    DateTime? timestamp,
    DateTime? updatedAt,
    DateTime? lastUpdated,
    bool? animate,
    bool? isTyping,
    bool? isUserMessage,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      fhirId: fhirId ?? this.fhirId,
      threadId: threadId ?? this.threadId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      senderType: senderType ?? this.senderType,
      patientId: patientId ?? this.patientId,
      organizationId: organizationId ?? this.organizationId,
      message: message ?? text ?? this.message,
      isRead: isRead ?? this.isRead,
      dakMessageId: dakMessageId ?? this.dakMessageId,
      fhirResource: fhirResource ?? this.fhirResource,
      versionId: versionId ?? this.versionId,
      createdAt: createdAt ?? timestamp ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      animate: animate ?? this.animate,
      isTyping: isTyping ?? this.isTyping,
      isUserMessage: isUserMessage ?? _isUserMessage,
    );
  }

  /// Convert to legacy format for backward compatibility
  /// Used when working with existing code that expects the old format
  Map<String, dynamic> toLegacyJson() {
    return {
      'id': id?.toString() ?? fhirId,
      'text': message,
      'isUserMessage': false, // Will need current user context to determine
      'timestamp': timestamp.toIso8601String(),
      'isTyping': isTyping,
    };
  }

  /// Create from legacy format for backward compatibility
  factory ChatMessage.fromLegacyJson(Map<String, dynamic> json, {
    String? currentUserId,
    int? threadId,
    String? receiverId,
  }) {
    final isUserMessage = json['isUserMessage'] as bool? ?? false;
    final senderId = currentUserId ?? '';
    
    return ChatMessage(
      id: json['id'] is int ? json['id'] as int : (json['id'] is String ? json['id'] as String : null),
      fhirId: json['id']?.toString() ?? '',
      threadId: threadId ?? 0,
      senderId: senderId,
      receiverId: receiverId ?? '',
      text: json['text'] as String? ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.tryParse(json['timestamp'] as String)
          : null,
      isTyping: json['isTyping'] as bool? ?? false,
      isUserMessage: isUserMessage,
      animate: json['animate'] as bool? ?? false,
    );
  }
}
