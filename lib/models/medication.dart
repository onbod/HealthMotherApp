import 'package:flutter/foundation.dart'; // For @required if using older Dart, or just use nullable types

class Medication {
  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final String notes;
  final List<DateTime>
      reminderTimes; // New field for specific reminder times (e.g., 8:00 AM, 1:00 PM)
  final bool alarmEnabled;
  final String sound; // URI or asset name for selected alarm sound
  // Add any other fields you deem necessary for a medication

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.notes = '',
    required this.reminderTimes, // Make it required for simplicity, or handle null case
    required this.alarmEnabled,
    this.sound = '', // Default: empty means use system default
  });

  // Convert a Medication object to a Map (for JSON serialization / Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'startDate': startDate.millisecondsSinceEpoch, // Store as timestamp
      'endDate': endDate?.millisecondsSinceEpoch, // Store as timestamp
      'notes': notes,
      'reminderTimes': reminderTimes
          .map((time) => time.millisecondsSinceEpoch)
          .toList(), // Store times as milliseconds
      'alarmEnabled': alarmEnabled,
      'sound': sound,
    };
  }

  // Create a Medication object from a Map (for JSON deserialization / Firestore)
  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'] as String,
      name: map['name'] as String,
      dosage: map['dosage'] as String,
      frequency: map['frequency'] as String,
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate'] as int),
      endDate: map['endDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['endDate'] as int)
          : null,
      notes: map['notes'] as String? ?? '',
      reminderTimes: (map['reminderTimes'] as List<dynamic>?)
              ?.map(
                (timestamp) =>
                    DateTime.fromMillisecondsSinceEpoch(timestamp as int),
              )
              .toList() ??
          [],
      alarmEnabled: map['alarmEnabled'] ?? false,
      sound: map['sound'] ?? '',
    );
  }

  // For easy debugging
  @override
  String toString() {
    return 'Medication(id: $id, name: $name, dosage: $dosage, frequency: $frequency, startDate: $startDate, endDate: $endDate, notes: $notes, sound: $sound)';
  }

  Medication copyWith({
    String? id,
    String? name,
    String? dosage,
    String? frequency,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    List<DateTime>? reminderTimes,
    bool? alarmEnabled,
    String? sound,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      alarmEnabled: alarmEnabled ?? this.alarmEnabled,
      sound: sound ?? this.sound,
    );
  }
}
