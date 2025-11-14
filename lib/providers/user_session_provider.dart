import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../core/config.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class UserSessionProvider with ChangeNotifier {
  // --- Raw session data from backend ---
  Map<String, dynamic>? userData;
  Map<String, dynamic>? patient;
  Map<String, dynamic>? pregnancy;
  List<Map<String, dynamic>> ancVisits = [];
  Map<String, dynamic>? delivery;
  List<Map<String, dynamic>> neonates = [];
  List<Map<String, dynamic>> postnatalVisits = [];

  // --- Load session from backend ---
  Future<void> loadUserDataFromBackend() async {
    const storage = FlutterSecureStorage();
    final jwt = await storage.read(key: 'jwt');
    print('DEBUG: JWT used for /user/session: $jwt');
    if (jwt == null) throw Exception('No JWT found');

    final response = await http.get(
      Uri.parse(AppConfig.getApiUrl('/user/session')),
      headers: {'Authorization': 'Bearer $jwt'},
    );
    if (response.statusCode != 200) {
      print('DEBUG: /user/session response status: ${response.statusCode}');
      print('DEBUG: /user/session response body: ${response.body}');
      
      // If token is invalid (401), clear it and fall back to local storage
      if (response.statusCode == 401) {
        print('DEBUG: Invalid token detected, clearing JWT and falling back to local storage');
        await storage.delete(key: 'jwt');
        // Try to restore from local storage instead
        await restorePatientFromStorage();
        return;
      }
      
      throw Exception('Failed to load user session: ${response.body}');
    }
    final data = jsonDecode(response.body);
    userData = data;
    patient = Map<String, dynamic>.from(data['patient'] ?? {});
    await savePatientToStorage();
    pregnancy =
        data['pregnancy'] != null
            ? Map<String, dynamic>.from(data['pregnancy'])
            : null;
    ancVisits =
        (data['ancVisits'] as List?)
            ?.map((v) => Map<String, dynamic>.from(v))
            .toList() ??
        [];
    delivery =
        data['delivery'] != null
            ? Map<String, dynamic>.from(data['delivery'])
            : null;
    neonates =
        (data['neonates'] as List?)
            ?.map((v) => Map<String, dynamic>.from(v))
            .toList() ??
        [];
    postnatalVisits =
        (data['postnatalVisits'] as List?)
            ?.map((v) => Map<String, dynamic>.from(v))
            .toList() ??
        [];

    // Load manual medications from local storage
    await _loadManualMedications();

    notifyListeners();
  }

  // --- Save patient data to secure storage or shared preferences ---
  Future<void> savePatientToStorage() async {
    if (patient != null) {
      final patientJson = jsonEncode(patient);
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('patient', patientJson);
      } else {
        const storage = FlutterSecureStorage();
        await storage.write(key: 'patient', value: patientJson);
      }
    } else {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('patient');
      } else {
        const storage = FlutterSecureStorage();
        await storage.delete(key: 'patient');
      }
    }
  }

  // --- Restore patient data from secure storage or shared preferences ---
  Future<void> restorePatientFromStorage() async {
    try {
      String? patientJson;
      if (kIsWeb) {
        try {
          final prefs = await SharedPreferences.getInstance();
          patientJson = prefs.getString('patient');
        } catch (e) {
          print('DEBUG: Error reading from SharedPreferences: $e');
          return;
        }
      } else {
        try {
          const storage = FlutterSecureStorage();
          patientJson = await storage.read(key: 'patient');
        } catch (e) {
          print('DEBUG: Error reading from FlutterSecureStorage: $e');
          return;
        }
      }
      if (patientJson != null && patientJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(patientJson);
          if (decoded is Map) {
            patient = Map<String, dynamic>.from(decoded);
            notifyListeners();
          }
        } catch (e) {
          print('DEBUG: Error decoding patient JSON: $e');
          // Clear corrupted data
          if (kIsWeb) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('patient');
          } else {
            const storage = FlutterSecureStorage();
            await storage.delete(key: 'patient');
          }
        }
      }
    } catch (e) {
      print('DEBUG: Unexpected error in restorePatientFromStorage: $e');
      // Don't throw - allow app to continue
    }
  }

  // --- Patient core info ---
  String? get clientNumber => patient?['client_number'] ?? patient?['identifier'] ?? patient?['phone'];
  String? get ninNumber => patient?['nin_number'];
  String? get phone => patient?['phone'];
  int? get age => patient?['age'];
  String? get gender => patient?['gender'];
  String? get bloodGroup => patient?['blood_group'];
  String? get responsiblePerson => patient?['responsible_person'];
  String? get birthDate => patient?['birth_date'];
  String? get registrationDate => patient?['registration_date'];
  String? get emergencyContactName => patient?['emergency_contact']?['name'];
  String? get emergencyContactPhone => patient?['emergency_contact']?['phone'];
  String? get addressText => patient?['address']?['text'];

  // --- FHIR HumanName parsing ---
  String? getClientName() {
    if (patient == null) return null;
    final name = patient!['name'];
    if (name is Map) {
      final given = name['given'];
      final family = name['family'];
      if (given is List && family != null) {
        return '${given.join(' ')} $family';
      }
    } else if (name is List && name.isNotEmpty) {
      // FHIR allows name to be a list
      final n = name.first;
      final given = n['given'];
      final family = n['family'];
      if (given is List && family != null) {
        return '${given.join(' ')} $family';
      }
    }
    return null;
  }

  // --- Pregnancy info ---
  Map<String, dynamic>? getCurrentPregnancy() => pregnancy;
  DateTime? getEdd() {
    final edd = pregnancy?['edd'];
    if (edd is String) return DateTime.tryParse(edd);
    return null;
  }

  DateTime? getLmp() {
    final lmp = pregnancy?['lmp'];
    if (lmp is String) return DateTime.tryParse(lmp);
    return null;
  }

  int? get gravida => pregnancy?['gravida'];
  int? get parity => pregnancy?['parity'];
  int? get livingChildren => pregnancy?['living_children'];
  int? get previousCs => pregnancy?['previous_cs'];
  double? get heightCm =>
      pregnancy?['height_cm'] is num
          ? (pregnancy?['height_cm'] as num).toDouble()
          : null;
  double? get bookingWeightKg =>
      pregnancy?['booking_weight_kg'] is num
          ? (pregnancy?['booking_weight_kg'] as num).toDouble()
          : null;
  List<dynamic>? get riskFactors => pregnancy?['risk_factors'];

  // --- ANC visits ---
  List<Map<String, dynamic>> getAncVisits() => ancVisits;
  Map<String, dynamic>? getLatestVisit() =>
      ancVisits.isNotEmpty ? ancVisits.last : null;
  int? getLatestVisitNumber() =>
      ancVisits.isNotEmpty ? ancVisits.last['visit_number'] : null;
  Map<String, dynamic>? getVisitData(int visitNumber) {
    return ancVisits.firstWhere(
      (v) => v['visit_number'] == visitNumber,
      orElse: () => <String, dynamic>{},
    );
  }

  // --- New: Get the latest completed ANC visit ---
  Map<String, dynamic>? getLatestAncVisit() {
    if (ancVisits.isEmpty) return null;
    final sorted = List<Map<String, dynamic>>.from(ancVisits)..sort(
      (a, b) => (a['visit_number'] ?? 0).compareTo(b['visit_number'] ?? 0),
    );
    return sorted.last;
  }

  // --- New: Get the next visit date from the latest ANC visit ---
  DateTime? getNextVisitDate() {
    final latest = getLatestAncVisit();
    if (latest == null || latest['next_visit_date'] == null) return null;
    return DateTime.tryParse(latest['next_visit_date'].toString());
  }

  // --- New: Get the latest gestational age in weeks ---
  int? getLatestGestationalAge() {
    final latest = getLatestAncVisit();
    if (latest == null || latest['gestational_age_weeks'] == null) return null;
    final ga = latest['gestational_age_weeks'];
    if (ga is int) return ga;
    if (ga is String) return int.tryParse(ga);
    return null;
  }

  Map<String, dynamic>? getPresentPregnancy(int visitNumber) {
    final visit = getVisitData(visitNumber);
    return visit?['presentPregnancy'] ?? visit?['present_pregnancy'];
  }

  // Gestational age for a visit
  int? getVisitGestationalAge(int visitNumber) {
    final visit = getVisitData(visitNumber);
    final ga = visit?['gestationalAge'] ?? visit?['gestational_age'];
    if (ga is int) return ga;
    if (ga is String) return int.tryParse(ga);
    return null;
  }

  // --- Delivery info ---
  bool hasDelivered() => delivery != null;
  Map<String, dynamic>? getDelivery() => delivery;
  DateTime? getDeliveryDate() {
    final d = delivery?['delivery_date'];
    if (d is String) return DateTime.tryParse(d);
    return null;
  }

  // --- Neonate info ---
  List<Map<String, dynamic>> getNeonates() => neonates;

  // --- Postnatal visits ---
  List<Map<String, dynamic>> getPostnatalVisits() => postnatalVisits;

  // --- Gestational week calculation ---
  int getCurrentGestationalWeek() {
    final lmp = getLmp();
    if (lmp == null) return 1;
    final now = DateTime.now();
    final diff = now.difference(lmp).inDays;
    return (diff / 7).floor().clamp(1, 40);
  }

  // --- Next visit info ---
  Map<String, dynamic>? getNextVisitInfo() {
    if (ancVisits.isEmpty) return null;
    return ancVisits.firstWhere(
      (v) =>
          v['next_visit_date'] != null &&
          DateTime.tryParse(
                v['next_visit_date'] ?? '',
              )?.isAfter(DateTime.now()) ==
              true,
      orElse: () => <String, dynamic>{},
    );
  }

  // --- Address, contact, and demographics ---
  String? getAddress() => addressText;
  int? getAge() => age;
  String? getMaritalStatus() => patient?['marital_status'];
  String? getOccupation() => patient?['occupation'];
  String? getEducation() => patient?['education'];

  // --- Facility info (if present in pregnancy or patient) ---
  String? getFacilityName() => pregnancy?['facility_name'];
  String? getFacilityAddress() => pregnancy?['facility_address'];
  String? getFacilityPhone() => pregnancy?['facility_phone'];
  String? getFacilityEmail() => pregnancy?['facility_email'];

  // --- Pregnancy stats ---
  int? getTotalPregnancies() => gravida;
  int? getLiveBirths() => livingChildren;
  int? getMiscarriages() => pregnancy?['miscarriages'];
  int? getAbortions() => pregnancy?['abortions'];

  // --- Medications (stub, can be extended if ANC visit has meds) ---
  List<dynamic>? getMedications(int visitNumber) {
    final visit = getVisitData(visitNumber);
    return visit?['medications'];
  }

  // --- Manual Medications ---
  List<Map<String, dynamic>> _manualMedications = [];

  List<Map<String, dynamic>> get manualMedications =>
      List.from(_manualMedications);

  Future<void> _loadManualMedications() async {
    try {
      String? medicationsJson;
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        medicationsJson = prefs.getString('manualMedications');
      } else {
        const storage = FlutterSecureStorage();
        medicationsJson = await storage.read(key: 'manualMedications');
      }

      if (medicationsJson != null) {
        final List<dynamic> medicationsList = jsonDecode(medicationsJson);
        _manualMedications =
            medicationsList
                .map((med) => Map<String, dynamic>.from(med))
                .toList();
      }
    } catch (e) {
      print('Error loading manual medications: $e');
      _manualMedications = [];
    }
  }

  Future<void> _saveManualMedications() async {
    try {
      final medicationsJson = jsonEncode(_manualMedications);
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('manualMedications', medicationsJson);
      } else {
        const storage = FlutterSecureStorage();
        await storage.write(key: 'manualMedications', value: medicationsJson);
      }
    } catch (e) {
      print('Error saving manual medications: $e');
    }
  }

  void addManualMedication(dynamic med) {
    if (med is Map<String, dynamic>) {
      _manualMedications.add(med);
      _saveManualMedications();
      notifyListeners();
    }
  }

  void updateManualMedication(dynamic med) {
    if (med is Map<String, dynamic>) {
      final id = med['id'];
      final index = _manualMedications.indexWhere((m) => m['id'] == id);
      if (index != -1) {
        _manualMedications[index] = med;
        _saveManualMedications();
        notifyListeners();
      }
    }
  }

  void removeManualMedication(String id) {
    _manualMedications.removeWhere((med) => med['id'] == id);
    _saveManualMedications();
    notifyListeners();
  }

  void toggleManualMedicationAlarm(String id, bool value) {
    final index = _manualMedications.indexWhere((med) => med['id'] == id);
    if (index != -1) {
      _manualMedications[index]['alarmEnabled'] = value;
      _saveManualMedications();
      notifyListeners();
    }
  }

  // --- Visit gestational age range (stub) ---
  String? getVisitGestationalAgeRange(int visitNumber) {
    final ga = getVisitGestationalAge(visitNumber);
    return ga?.toString();
  }

  // --- Visit flagged (stub) ---
  bool isVisitFlagged(int visitNumber) => false;

  // --- Calculate current week from latest ANC (stub) ---
  int calculateCurrentWeekFromLatestANC() => getCurrentGestationalWeek();

  // --- Calculate next visit date from WHO/DAK guidelines if not listed ---
  DateTime? calculateNextVisitDateFromGuidelines() {
    final latest = getLatestAncVisit();
    if (latest == null) return null;

    final lastVisitWeekRaw = latest['gestational_age_weeks'];
    int? lastVisitWeek;
    if (lastVisitWeekRaw is int) {
      lastVisitWeek = lastVisitWeekRaw;
    } else if (lastVisitWeekRaw is String) {
      lastVisitWeek = int.tryParse(lastVisitWeekRaw);
    } else if (lastVisitWeekRaw is num) {
      lastVisitWeek = lastVisitWeekRaw.toInt();
    }
    final lastVisitDateStr = latest['visit_date'];
    if (lastVisitWeek == null || lastVisitDateStr == null) return null;

    final lastVisitDate = DateTime.tryParse(lastVisitDateStr.toString());
    if (lastVisitDate == null) return null;

    // WHO/DAK recommended weeks
    final List<int> recommendedAncWeeks = [12, 16, 20, 26, 30, 34, 36, 38];

    // Find the next recommended week
    int? nextWeek;
    for (final w in recommendedAncWeeks) {
      if (w > lastVisitWeek) {
        nextWeek = w;
        break;
      }
    }
    if (nextWeek == null) return null; // No more recommended visits

    final weeksToAdd = nextWeek - lastVisitWeek;
    return lastVisitDate.add(Duration(days: weeksToAdd * 7));
  }

  // --- Session management ---
  void clearSession() {
    userData = null;
    patient = null;
    pregnancy = null;
    ancVisits = [];
    delivery = null;
    neonates = [];
    postnatalVisits = [];
    _manualMedications = [];
    notifyListeners();
  }

  // --- Logout: clear JWT and session ---
  Future<void> logout() async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'jwt');
    clearSession();
  }

  // --- Legacy compatibility stubs ---
  Future<void> loadUserData([String? phoneNumber]) async {
    await loadUserDataFromBackend();
  }

  Future<void> refreshUserData([String? phoneNumber]) async {
    await loadUserDataFromBackend();
  }

  /// Try to restore session from backend if online, otherwise from local storage
  Future<void> restoreOrFetchSession() async {
    print('SESSION: Starting restoreOrFetchSession...');
    try {
      // Try to check internet connectivity with timeout
      try {
        print('SESSION: Checking internet connectivity...');
        final result = await InternetAddress.lookup('example.com')
            .timeout(const Duration(seconds: 3));
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          print('SESSION: Online - attempting backend fetch...');
          // Online: fetch from backend
          try {
            await loadUserDataFromBackend();
            print('SESSION: Backend fetch successful');
            return;
          } catch (e, stackTrace) {
            // If backend fetch fails (e.g., invalid token), fall back to local storage
            print('SESSION: Backend fetch failed, falling back to local storage: $e');
            print('SESSION: Stack trace: $stackTrace');
            try {
              await restorePatientFromStorage();
              print('SESSION: Local storage restore successful after backend failure');
            } catch (storageError) {
              print('SESSION: Failed to restore from local storage: $storageError');
            }
            return;
          }
        }
      } catch (e) {
        // Network check failed, assume offline
        print('SESSION: Network check failed, assuming offline: $e');
      }
    } catch (e, stackTrace) {
      print('SESSION: Error in restoreOrFetchSession: $e');
      print('SESSION: Stack trace: $stackTrace');
    }
    
    // Offline or error: restore from local storage
    print('SESSION: Attempting local storage restore...');
    try {
      await restorePatientFromStorage();
      print('SESSION: Local storage restore successful');
    } catch (e, stackTrace) {
      print('SESSION: Failed to restore from local storage: $e');
      print('SESSION: Stack trace: $stackTrace');
      // Don't throw - allow app to continue even without session data
    }
    print('SESSION: restoreOrFetchSession completed');
  }

  // For compatibility with widgets/screens
  Map<String, dynamic>? getVisitPresentPregnancy(int visitNumber) =>
      getPresentPregnancy(visitNumber);

  // For FutureBuilder<bool> compatibility
  Future<bool> tryRestoreSession() async {
    try {
      await loadUserDataFromBackend();
      return true;
    } catch (e) {
      // If backend fails, try local storage
      try {
        await restorePatientFromStorage();
        // Return true if we have local data, false otherwise
        return patient != null;
      } catch (_) {
        return false;
      }
    }
  }

  // For non-nullable gestational age range
  String getVisitGestationalAgeRangeNonNull(int visitNumber) =>
      getVisitGestationalAgeRange(visitNumber) ?? '';

  String? getPhoneNumber() => phone;
}
