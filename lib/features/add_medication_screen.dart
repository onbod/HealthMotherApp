import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/user_session_provider.dart';
import '../models/medication.dart';
import '../services/notification_service.dart';
import '../services/alarm_service.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/services.dart';
import '../widgets/global_navigation.dart';
import 'medication_screen.dart';

// Top-level callback for alarm
void medicationAlarmCallback() async {
  await AlarmService.start();
}

class AddMedicationScreen extends StatefulWidget {
  final Medication? medication;

  const AddMedicationScreen({Key? key, this.medication}) : super(key: key);

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String? _selectedFrequency;
  List<TimeOfDay> _selectedTimes = [];

  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  final Uuid _uuid = Uuid();
  bool _alarmEnabled = false;
  String _selectedSound = '';
  String _selectedSoundTitle = 'Default Alarm';
  static const MethodChannel _soundPickerChannel = MethodChannel(
    'com.example.healthymamaapp/sound_picker',
  );

  @override
  void initState() {
    super.initState();
    if (widget.medication != null) {
      _nameController.text = widget.medication!.name;
      _notesController.text = widget.medication!.notes;
      final validFrequencies = [
        'Once daily',
        'Twice daily',
        'Three times daily',
        'Four times daily',
        'As needed',
      ];
      if (validFrequencies.contains(widget.medication!.frequency)) {
        _selectedFrequency = widget.medication!.frequency;
      }
      _startDate = widget.medication!.startDate;
      _endDate = widget.medication!.endDate;
      _selectedTimes =
          widget.medication!.reminderTimes
              .map((dt) => TimeOfDay(hour: dt.hour, minute: dt.minute))
              .toList();
      _alarmEnabled = widget.medication!.alarmEnabled;
      _selectedSound = widget.medication!.sound;
      _selectedSoundTitle =
          _selectedSound.isNotEmpty ? _selectedSound : 'Default Alarm';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int _getNumberOfTimePickers(String? frequency) {
    switch (frequency) {
      case 'Once daily':
        return 1;
      case 'Twice daily':
        return 2;
      case 'Three times daily':
        return 3;
      case 'Four times daily':
        return 4;
      default:
        return 0;
    }
  }

  Future<void> _selectDate(
    BuildContext context, {
    required bool isStartDate,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : (_endDate ?? _startDate),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != (isStartDate ? _startDate : _endDate)) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime:
          _selectedTimes.length > index
              ? _selectedTimes[index]
              : TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (_selectedTimes.length <= index) {
          _selectedTimes.add(picked);
        } else {
          _selectedTimes[index] = picked;
        }
        _selectedTimes.sort(
          (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
        );
      });
    }
  }

  Future<void> _pickAlarmSound() async {
    try {
      final result = await _soundPickerChannel.invokeMethod('pickAlarmSound');
      if (result != null && result is Map) {
        setState(() {
          _selectedSound = result['uri'] ?? '';
          _selectedSoundTitle = result['title'] ?? _selectedSound;
        });
        print('Picked sound URI: $_selectedSound, title: $_selectedSoundTitle');
      }
    } catch (e) {
      // Fallback: show error or ignore
    }
  }

  Future<void> _saveMedication() async {
    if (_formKey.currentState!.validate()) {
      final medicationId = widget.medication?.id ?? _uuid.v4();
      final medicationName = _nameController.text;

      // Create a list of reminder times as DateTime objects
      List<DateTime> reminderDateTimes =
          _selectedTimes.map((time) {
            final now = DateTime.now();
            return DateTime(
              now.year,
              now.month,
              now.day,
              time.hour,
              time.minute,
            );
          }).toList();

      // Create the medication object
      final newMedication = Medication(
        id: medicationId,
        name: medicationName,
        dosage: '', // Assuming dosage is not captured in the form
        frequency: _selectedFrequency!,
        startDate: _startDate,
        endDate: _endDate,
        notes: _notesController.text,
        reminderTimes: reminderDateTimes,
        alarmEnabled: _alarmEnabled,
        sound: _selectedSound,
      );

      // Save the medication to the user's session
      final userSession = Provider.of<UserSessionProvider>(
        context,
        listen: false,
      );

      // Convert Medication object to Map for storage
      final medicationMap = newMedication.toMap();

      if (widget.medication != null) {
        userSession.updateManualMedication(medicationMap);
      } else {
        userSession.addManualMedication(medicationMap);
      }

      // Schedule notifications for each reminder time
      final notificationService = NotificationService();
      await notificationService.schedulePeriodicMedicationNotifications();

      // Schedule alarm if enabled (using native alarm for better reliability)
      if (_alarmEnabled && reminderDateTimes.isNotEmpty) {
        print(
          'Scheduling ${reminderDateTimes.length} alarms for medication: $medicationName',
        );
        for (int i = 0; i < reminderDateTimes.length; i++) {
          final reminderTime = reminderDateTimes[i];
          final now = DateTime.now();
          final scheduledTime = DateTime(
            now.year,
            now.month,
            now.day,
            reminderTime.hour,
            reminderTime.minute,
          );
          // If the scheduled time is in the past for today, schedule for tomorrow
          final alarmTime =
              scheduledTime.isAfter(now)
                  ? scheduledTime
                  : scheduledTime.add(const Duration(days: 1));

          print(
            'Scheduling alarm ${i + 1} for: $alarmTime with sound: $_selectedSound',
          );

          // Schedule native alarm for better reliability
          await AlarmService.scheduleNativeAlarm(alarmTime, _selectedSound);
        }
      }

      // Show a confirmation dialog and navigate back to medication screen
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Success!'),
            content: Text(
              _alarmEnabled
                  ? "Your medication has been saved with alarm enabled. You will receive a notification and hear an alarm sound when it's time to take your medication."
                  : "Your medication has been saved. You will receive a notification when it's time to take your medication.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  // Navigate back to medication screen
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder:
                          (context) => const GlobalNavigation(
                            currentIndex: 1,
                            child: MedicationScreen(),
                          ),
                    ),
                  );
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.medication != null ? 'Edit Medication' : 'Add New Medication',
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                controller: _nameController,
                labelText: 'Medication Name',
                validator:
                    (value) =>
                        value!.isEmpty ? 'Please enter medication name' : null,
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: DropdownButtonFormField<String>(
                  value: _selectedFrequency,
                  decoration: InputDecoration(
                    labelText: 'Frequency',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  hint: const Text('Select frequency'),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedFrequency = newValue;
                      if (newValue == 'As needed') {
                        _selectedTimes = [];
                      } else {
                        _selectedTimes = List.filled(
                          _getNumberOfTimePickers(newValue),
                          TimeOfDay.now(),
                        );
                      }
                    });
                  },
                  validator:
                      (value) =>
                          value == null ? 'Please select frequency' : null,
                  items: const [
                    DropdownMenuItem(
                      value: 'Once daily',
                      child: Text('Once daily'),
                    ),
                    DropdownMenuItem(
                      value: 'Twice daily',
                      child: Text('Twice daily'),
                    ),
                    DropdownMenuItem(
                      value: 'Three times daily',
                      child: Text('Three times daily'),
                    ),
                    DropdownMenuItem(
                      value: 'Four times daily',
                      child: Text('Four times daily'),
                    ),
                    DropdownMenuItem(
                      value: 'As needed',
                      child: Text('As needed'),
                    ),
                  ],
                ),
              ),
              // Alarm toggle
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Alarm with Sound',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  subtitle: Text(
                    _alarmEnabled
                        ? 'Will play continuous alarm sound until stopped'
                        : 'Will only show notification',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  value: _alarmEnabled,
                  onChanged: (val) {
                    setState(() {
                      _alarmEnabled = val;
                    });
                  },
                  secondary: Icon(
                    _alarmEnabled ? Icons.alarm_on : Icons.alarm_off,
                    color: _alarmEnabled ? Colors.red : Colors.grey,
                    size: 28,
                  ),
                ),
              ),
              // Sound picker button
              if (_alarmEnabled) ...[
                const SizedBox(height: 8),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('Alarm Sound: $_selectedSoundTitle'),
                        ),
                        ElevatedButton(
                          onPressed: _pickAlarmSound,
                          child: const Text('Pick Sound'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (_selectedFrequency != 'As needed' &&
                  _selectedFrequency != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Reminder Times',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                Column(
                  children: List.generate(
                    _getNumberOfTimePickers(_selectedFrequency),
                    (index) => _buildTimeSelectionField(
                      context,
                      index,
                      _selectedTimes.length > index
                          ? _selectedTimes[index]
                          : null,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Start Date',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              _buildDateSelectionField(context, _startDate, isStartDate: true),
              const SizedBox(height: 16),
              Text(
                'End Date (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              _buildDateSelectionField(context, _endDate, isStartDate: false),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _notesController,
                labelText: 'Notes (Optional)',
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: _saveMedication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    widget.medication != null
                        ? 'Modify Medication'
                        : 'Add Medication',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    String? Function(String?)? validator,
    int? maxLines,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        validator: validator,
        maxLines: maxLines,
      ),
    );
  }

  Widget _buildDateSelectionField(
    BuildContext context,
    DateTime? date, {
    required bool isStartDate,
  }) {
    return InkWell(
      onTap: () => _selectDate(context, isStartDate: isStartDate),
      child: InputDecorator(
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date == null
                  ? 'Select Date'
                  : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
              style: TextStyle(
                fontSize: 16,
                color: date == null ? Colors.grey[600] : Colors.black,
              ),
            ),
            const Icon(Icons.calendar_today, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelectionField(
    BuildContext context,
    int index,
    TimeOfDay? time,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () => _selectTime(context, index),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Time ${index + 1}',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                time == null ? 'Select Time' : time.format(context),
                style: TextStyle(
                  fontSize: 16,
                  color: time == null ? Colors.grey[600] : Colors.black,
                ),
              ),
              const Icon(Icons.access_time, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
