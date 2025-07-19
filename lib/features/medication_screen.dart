import 'package:flutter/material.dart';
import '../widgets/shared_app_bar.dart';
import '../widgets/global_navigation.dart';
import 'notifications_screen.dart';
import 'package:provider/provider.dart';
import '../providers/user_session_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'add_medication_screen.dart';

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({Key? key}) : super(key: key);

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  final Color primaryColor = const Color(0xFF7C4DFF);
  final List<Map<String, String>> _soundOptions = [
    {'file': 'alarm.mp3', 'label': 'Alarm Sound'},
    {'file': 'notification.mp3', 'label': 'Notification Sound'},
    {'file': 'system_alarm', 'label': 'System Alarm'},
    {'file': 'system_notification', 'label': 'System Notification'},
    {'file': 'system_ringtone', 'label': 'System Ringtone'},
  ];

  @override
  Widget build(BuildContext context) {
    return GlobalNavigation(
      currentIndex: 1,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: SharedAppBar(
          visitNumber: 'Medications',
          onNotificationPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            );
          },
        ),
        body: Consumer<UserSessionProvider>(
          builder: (context, userSession, child) {
            // Group medications by contact number
            Map<int, List<String>> medicationsByContact = {};
            for (int i = 1; i <= 8; i++) {
              final List<dynamic>? meds = userSession.getMedications(i);
              if (meds != null && meds.isNotEmpty) {
                medicationsByContact[i] =
                    meds.map((e) => e.toString()).toList();
              }
            }

            // Check if both types of medication lists are empty
            final bool hasFirebaseMeds = medicationsByContact.isNotEmpty;
            final bool hasManualMeds = userSession.manualMedications.isNotEmpty;

            if (!hasFirebaseMeds && !hasManualMeds) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.medication_liquid_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No medications recorded yet.',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add your medications or check your contact records.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              );
            }

            // Combined scrollable content for both types of medications
            return Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section for Firebase-collected medications
                    if (hasFirebaseMeds) ...[
                      Text(
                        'Medications from Contacts',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Use a Column here, as ListView.builder within SingleChildScrollView can cause issues without fixed height
                      Column(
                        children: List.generate(8, (index) {
                          final int contactNumber = index + 1;
                          final List<String>? medsForContact =
                              medicationsByContact[contactNumber];

                          if (medsForContact == null ||
                              medsForContact.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16.0),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Animate(
                              effects: [
                                FadeEffect(duration: 300.ms),
                                SlideEffect(
                                  begin: const Offset(0.1, 0),
                                  duration: 300.ms,
                                ),
                              ],
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Contact $contactNumber',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                    const Divider(height: 16),
                                    ...medsForContact
                                        .map(
                                          (med) => Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 4.0,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.circle,
                                                  size: 8,
                                                  color: primaryColor,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    med,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Section for Manually Added Medications
                    if (hasManualMeds) ...[
                      Text(
                        'Your Personal Medications',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Column(
                        children:
                            userSession.manualMedications
                                .map(
                                  (medication) => Card(
                                    margin: const EdgeInsets.only(bottom: 16.0),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Animate(
                                      effects: [
                                        FadeEffect(duration: 300.ms),
                                        SlideEffect(
                                          begin: const Offset(0.1, 0),
                                          duration: 300.ms,
                                        ),
                                      ],
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    medication.name,
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: primaryColor,
                                                    ),
                                                  ),
                                                ),
                                                PopupMenuButton<String>(
                                                  onSelected: (value) {
                                                    if (value == 'edit') {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder:
                                                              (
                                                                context,
                                                              ) => AddMedicationScreen(
                                                                medication:
                                                                    medication,
                                                              ),
                                                        ),
                                                      );
                                                    } else if (value ==
                                                        'delete') {
                                                      _showDeleteConfirmation(
                                                        medication.id,
                                                      );
                                                    }
                                                  },
                                                  itemBuilder:
                                                      (context) => [
                                                        const PopupMenuItem(
                                                          value: 'edit',
                                                          child: Row(
                                                            children: [
                                                              Icon(Icons.edit),
                                                              SizedBox(
                                                                width: 8,
                                                              ),
                                                              Text('Edit'),
                                                            ],
                                                          ),
                                                        ),
                                                        const PopupMenuItem(
                                                          value: 'delete',
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                Icons.delete,
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                              SizedBox(
                                                                width: 8,
                                                              ),
                                                              Text(
                                                                'Delete',
                                                                style: TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .red,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                  child: Icon(
                                                    Icons.more_vert,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Dosage: ${medication.dosage}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Frequency: ${medication.frequency}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                              ),
                                            ),
                                            if (medication
                                                .notes
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                'Notes: ${medication.notes}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.calendar_today,
                                                  size: 16,
                                                  color: Colors.grey[600],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Starts: ${medication.startDate.day.toString().padLeft(2, '0')}/${medication.startDate.month.toString().padLeft(2, '0')}/${medication.startDate.year}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (medication.endDate != null) ...[
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.calendar_today,
                                                    size: 16,
                                                    color: Colors.grey[600],
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Ends: ${medication.endDate!.day.toString().padLeft(2, '0')}/${medication.endDate!.month.toString().padLeft(2, '0')}/${medication.endDate!.year}',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(
                                                  medication.alarmEnabled
                                                      ? Icons.alarm_on
                                                      : Icons.alarm_off,
                                                  size: 16,
                                                  color:
                                                      medication.alarmEnabled
                                                          ? Colors.green
                                                          : Colors.grey[600],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  medication.alarmEnabled
                                                      ? 'Reminders enabled'
                                                      : 'Reminders disabled',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color:
                                                        medication.alarmEnabled
                                                            ? Colors.green
                                                            : Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Switch(
                                                  value:
                                                      medication.alarmEnabled,
                                                  onChanged:
                                                      (val) => _toggleAlarm(
                                                        medication.id,
                                                        val,
                                                      ),
                                                  activeColor: primaryColor,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Enable reminders',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (medication.alarmEnabled) ...[
                                              const SizedBox(height: 8),
                                              Text(
                                                'Reminder times:',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Wrap(
                                                spacing: 8,
                                                children:
                                                    medication.reminderTimes
                                                        .map(
                                                          (time) => Chip(
                                                            label: Text(
                                                              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                  ),
                                                            ),
                                                            backgroundColor:
                                                                primaryColor
                                                                    .withOpacity(
                                                                      0.1,
                                                                    ),
                                                          ),
                                                        )
                                                        .toList(),
                                              ),
                                            ],
                                            if (medication
                                                .sound
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.volume_up,
                                                    size: 16,
                                                    color: Colors.grey[600],
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Sound: ${medication.sound.isNotEmpty ? medication.sound : 'System default'}',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ],
                    // No need for a Spacer here, SingleChildScrollView handles content height
                  ],
                ),
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddMedicationScreen(),
              ),
            );
          },
          backgroundColor: primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String medicationId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Medication'),
            content: const Text(
              'Are you sure you want to delete this medication?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Provider.of<UserSessionProvider>(
                    context,
                    listen: false,
                  ).removeManualMedication(medicationId);
                  Navigator.pop(context);
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _toggleAlarm(String medicationId, bool value) {
    Provider.of<UserSessionProvider>(
      context,
      listen: false,
    ).toggleManualMedicationAlarm(medicationId, value);
  }
}
