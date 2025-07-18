import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../core/config.dart';

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
    notifyListeners();
  }

  // --- Save patient data to secure storage ---
  Future<void> savePatientToStorage() async {
    const storage = FlutterSecureStorage();
    if (patient != null) {
      await storage.write(key: 'patient', value: jsonEncode(patient));
    } else {
      await storage.delete(key: 'patient');
    }
  }

  // --- Restore patient data from secure storage ---
  Future<void> restorePatientFromStorage() async {
    const storage = FlutterSecureStorage();
    final patientJson = await storage.read(key: 'patient');
    if (patientJson != null) {
      patient = Map<String, dynamic>.from(jsonDecode(patientJson));
      notifyListeners();
    }
  }

  // --- Patient core info ---
  String? get clientNumber => patient?['client_number'];
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

  List<dynamic> get manualMedications => [];
  void removeManualMedication(String id) {}
  void toggleManualMedicationAlarm(String id, bool value) {}
  void updateManualMedication(dynamic med) {}
  void addManualMedication(dynamic med) {}

  // --- Visit gestational age range (stub) ---
  String? getVisitGestationalAgeRange(int visitNumber) {
    final ga = getVisitGestationalAge(visitNumber);
    return ga != null ? ga.toString() : null;
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
    try {
      // Try to check internet connectivity
      final result = await InternetAddress.lookup('example.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        // Online: fetch from backend
        await loadUserDataFromBackend();
        return;
      }
    } catch (_) {
      // Offline: restore from local storage
      await restorePatientFromStorage();
    }
  }

  // For compatibility with widgets/screens
  Map<String, dynamic>? getVisitPresentPregnancy(int visitNumber) =>
      getPresentPregnancy(visitNumber);

  // For FutureBuilder<bool> compatibility
  Future<bool> tryRestoreSession() async {
    try {
      await loadUserDataFromBackend();
      return true;
    } catch (_) {
      return false;
    }
  }

  // For non-nullable gestational age range
  String getVisitGestationalAgeRangeNonNull(int visitNumber) =>
      getVisitGestationalAgeRange(visitNumber) ?? '';

  String? getPhoneNumber() => phone;
}
