import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_session_provider.dart';
import 'package:intl/intl.dart'; // For date formatting

class ContactDetailsScreen extends StatefulWidget {
  final int contactNumber;

  const ContactDetailsScreen({super.key, required this.contactNumber});

  @override
  State<ContactDetailsScreen> createState() => _ContactDetailsScreenState();
}

class _ContactDetailsScreenState extends State<ContactDetailsScreen> {
  Completer<Map<String, dynamic>>? _dataCompleter;
  Future<Map<String, dynamic>>? _visitDetailsFuture;
  String? _patientId;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _dataCompleter = Completer<Map<String, dynamic>>();
    _visitDetailsFuture = _dataCompleter!.future;

    // Use microtask to ensure widget is fully built
    Future.microtask(() async {
      if (_isDisposed || !mounted || _dataCompleter == null) {
        if (_dataCompleter != null && !_dataCompleter!.isCompleted) {
          _dataCompleter!.complete({});
        }
        return;
      }

      try {
        final currentContext = context;
        if (_isDisposed || !mounted || _dataCompleter == null) {
          if (_dataCompleter != null && !_dataCompleter!.isCompleted) {
            _dataCompleter!.complete({});
          }
          return;
        }

        final userSession = Provider.of<UserSessionProvider>(
          currentContext,
          listen: false,
        );

        // Try multiple patient ID field names and convert to string
        final patientIdDynamic =
            userSession.patient?['patient_id'] ??
            userSession.patient?['id'] ??
            userSession.patient?['patientId'];

        _patientId = patientIdDynamic?.toString();

        print('DEBUG ContactDetails: patientId = $_patientId');
        print(
          'DEBUG ContactDetails: patient data keys = ${userSession.patient?.keys.toList()}',
        );

        Map<String, dynamic> visitData;

        // Use cached data from UserSessionProvider if available, otherwise fetch
        if (userSession.ancVisits.isNotEmpty || userSession.pregnancy != null) {
          print(
            'DEBUG ContactDetails: Using cached data from UserSessionProvider',
          );
          visitData = _buildDataFromSession(userSession);
          print(
            'DEBUG ContactDetails: Session data built with keys: ${visitData.keys.toList()}',
          );
        } else if (_patientId != null && _patientId!.isNotEmpty) {
          print(
            'DEBUG ContactDetails: Fetching data from API for patientId: $_patientId',
          );
          visitData = await fetchAllVisitDetails(_patientId!);
        } else {
          print(
            'DEBUG ContactDetails: No patientId found (patientId=$_patientId), using empty data',
          );
          visitData = {};
        }

        // Complete the completer only if not disposed
        if (!_isDisposed && mounted && _dataCompleter != null && !_dataCompleter!.isCompleted) {
          try {
            _dataCompleter!.complete(visitData);
          } catch (e) {
            // Ignore if already completed or disposed
            debugPrint('Error completing completer: $e');
          }
        }
      } catch (e) {
        print('DEBUG ContactDetails: Error in initState: $e');
        // Complete with empty data on error
        if (!_isDisposed && mounted && _dataCompleter != null && !_dataCompleter!.isCompleted) {
          try {
            _dataCompleter!.complete({});
          } catch (completerError) {
            // Ignore if already completed or disposed
            debugPrint('Error completing completer on error: $completerError');
          }
        }
      }
    });
  }

  Map<String, dynamic> _buildDataFromSession(UserSessionProvider userSession) {
    print('DEBUG ContactDetails: Building from session');
    print(
      'DEBUG ContactDetails: ANC visits count: ${userSession.ancVisits.length}',
    );
    print(
      'DEBUG ContactDetails: Looking for contact number: ${widget.contactNumber}',
    );

    if (userSession.ancVisits.isNotEmpty) {
      print(
        'DEBUG ContactDetails: First ANC visit keys: ${userSession.ancVisits.first.keys.toList()}',
      );
      print(
        'DEBUG ContactDetails: First ANC visit visit_number: ${userSession.ancVisits.first['visit_number']}',
      );
      print(
        'DEBUG ContactDetails: First ANC visit dak_contact_number: ${userSession.ancVisits.first['dak_contact_number']}',
      );
    }

    return {
      'ancVisits': userSession.ancVisits,
      'pregnancies':
          userSession.pregnancy != null ? [userSession.pregnancy!] : [],
      'deliveries': userSession.delivery != null ? [userSession.delivery!] : [],
      'neonates': userSession.neonates,
      'postnatalVisits': userSession.postnatalVisits,
    };
  }

  @override
  void dispose() {
    _isDisposed = true;
    _patientId = null;
    // Complete the completer if it's still pending to prevent memory leaks
    // This prevents the FutureBuilder from trying to rebuild after disposal
    if (_dataCompleter != null && !_dataCompleter!.isCompleted) {
      try {
        _dataCompleter!.complete({});
      } catch (e) {
        // Ignore if already completed
        debugPrint('Completer already completed: $e');
      }
    }
    _dataCompleter = null;
    _visitDetailsFuture = null; // Clear future reference
    super.dispose();
  }

  Future<Map<String, dynamic>> fetchAllVisitDetails(String patientId) async {
    if (_isDisposed || patientId.isEmpty) {
      print('DEBUG ContactDetails fetch: Disposed or empty patientId');
      return {};
    }

    print(
      'DEBUG ContactDetails fetch: Starting fetch for patientId=$patientId',
    );

    // Declare all lists at function scope
    List<dynamic> ancVisits = [];
    List<dynamic> pregnancies = [];
    List<dynamic> deliveries = [];
    List<dynamic> neonates = [];
    List<dynamic> postnatalVisits = [];

    // Fetch ANC visits
    if (_isDisposed) return {};
    try {
    final ancResponse = await http.get(
      Uri.parse(
        'https://health-fhir-backend-production-6ae1.up.railway.app/anc_visit',
      ),
    );
      if (_isDisposed) return {};

      print(
        'DEBUG ContactDetails: ANC response status=${ancResponse.statusCode}',
      );

      try {
        final decoded = jsonDecode(ancResponse.body);
        // Handle API response wrapper: { success: true, data: [...] }
        List<dynamic> visitsList = [];
        if (decoded is Map && decoded['data'] != null) {
          visitsList = decoded['data'] as List;
        } else if (decoded is List) {
          visitsList = decoded;
        }

        print('DEBUG ContactDetails: Decoded ${visitsList.length} ANC visits');
        // Convert both to strings for comparison to handle int/string mismatch
        ancVisits =
            visitsList.where((v) {
              final vPatientId =
                  v['patient_id']?.toString() ?? v['patientId']?.toString();
              return vPatientId == patientId;
            }).toList();
        print(
          'DEBUG ContactDetails: Filtered to ${ancVisits.length} matching visits',
        );
        if (ancVisits.isNotEmpty) {
          print(
            'DEBUG ContactDetails: Sample visit keys: ${ancVisits.first.keys.toList()}',
          );
        }
      } catch (e) {
        print('DEBUG ContactDetails: Error decoding ANC visits: $e');
      }
    } catch (e) {
      print('DEBUG ContactDetails: Error fetching ANC visits: $e');
    }

    // Fetch pregnancy
    if (_isDisposed) return {};
    try {
    final pregResponse = await http.get(
      Uri.parse(
        'https://health-fhir-backend-production-6ae1.up.railway.app/pregnancy',
      ),
    );
      if (_isDisposed) return {};

      try {
        final decoded = jsonDecode(pregResponse.body);
        List<dynamic> pregList = [];
        if (decoded is Map && decoded['data'] != null) {
          pregList = decoded['data'] as List;
        } else if (decoded is List) {
          pregList = decoded;
        }

        pregnancies =
            pregList.where((p) {
              final pPatientId =
                  p['patient_id']?.toString() ?? p['patientId']?.toString();
              return pPatientId == patientId;
            }).toList();
      } catch (e) {
        print('DEBUG ContactDetails: Error decoding pregnancies: $e');
      }
    } catch (e) {
      print('DEBUG ContactDetails: Error fetching pregnancies: $e');
    }

    // Fetch delivery
    if (_isDisposed) return {};
    try {
    final deliveryResponse = await http.get(
      Uri.parse(
        'https://health-fhir-backend-production-6ae1.up.railway.app/delivery',
      ),
    );
      if (_isDisposed) return {};

      try {
        final decoded = jsonDecode(deliveryResponse.body);
        List<dynamic> delList = [];
        if (decoded is Map && decoded['data'] != null) {
          delList = decoded['data'] as List;
        } else if (decoded is List) {
          delList = decoded;
        }

        deliveries =
            delList
                .where(
                  (d) => pregnancies.any(
                    (p) =>
                        (p['pregnancy_id']?.toString() ==
                            d['pregnancy_id']?.toString()) ||
                        (p['id']?.toString() == d['pregnancy_id']?.toString()),
                  ),
                )
            .toList();
      } catch (e) {
        print('DEBUG ContactDetails: Error decoding deliveries: $e');
      }
    } catch (e) {
      print('DEBUG ContactDetails: Error fetching deliveries: $e');
    }

    // Fetch neonate
    if (_isDisposed) return {};
    try {
    final neonateResponse = await http.get(
      Uri.parse(
        'https://health-fhir-backend-production-6ae1.up.railway.app/neonate',
      ),
    );
      if (_isDisposed) return {};

      try {
        final decoded = jsonDecode(neonateResponse.body);
        List<dynamic> neonList = [];
        if (decoded is Map && decoded['data'] != null) {
          neonList = decoded['data'] as List;
        } else if (decoded is List) {
          neonList = decoded;
        }

        neonates =
            neonList
                .where(
                  (n) => deliveries.any(
                    (d) =>
                        (d['delivery_id']?.toString() ==
                            n['delivery_id']?.toString()) ||
                        (d['id']?.toString() == n['delivery_id']?.toString()),
                  ),
                )
            .toList();
      } catch (e) {
        print('DEBUG ContactDetails: Error decoding neonates: $e');
      }
    } catch (e) {
      print('DEBUG ContactDetails: Error fetching neonates: $e');
    }

    // Fetch postnatal visits (schema table: postnatal_care)
    if (_isDisposed) return {};
    try {
    final postnatalResponse = await http.get(
      Uri.parse(
          'https://health-fhir-backend-production-6ae1.up.railway.app/postnatal_care',
        ),
      );
      if (_isDisposed) return {};

      try {
        final decoded = jsonDecode(postnatalResponse.body);
        List<dynamic> pncList = [];
        if (decoded is Map && decoded['data'] != null) {
          pncList = decoded['data'] as List;
        } else if (decoded is List) {
          pncList = decoded;
        }

        postnatalVisits =
            pncList.where((p) {
              final pPatientId =
                  p['patient_id']?.toString() ?? p['patientId']?.toString();
              return pPatientId == patientId;
            }).toList();
      } catch (e) {
        print('DEBUG ContactDetails: Error decoding postnatal visits: $e');
      }
    } catch (e) {
      print('DEBUG ContactDetails: Error fetching postnatal visits: $e');
    }

    print(
      'DEBUG ContactDetails: Final data - ANC: ${ancVisits.length}, Pregnancies: ${pregnancies.length}, Deliveries: ${deliveries.length}, Neonates: ${neonates.length}, Postnatal: ${postnatalVisits.length}',
    );

    return {
      'ancVisits': ancVisits,
      'pregnancies': pregnancies,
      'deliveries': deliveries,
      'neonates': neonates,
      'postnatalVisits': postnatalVisits,
    };
  }

  @override
  Widget build(BuildContext context) {
    // Don't build if disposed
    if (_isDisposed) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Visit ${widget.contactNumber} Details'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Use the safest navigation method
            if (mounted && !_isDisposed) {
              Navigator.maybePop(context);
            }
          },
        ),
      ),
      body: WillPopScope(
        onWillPop: () async {
          // Prevent back navigation if widget is disposed
          if (_isDisposed || !mounted) {
            return false;
          }
          // Complete completer before navigating back to prevent rebuild issues
          if (_dataCompleter != null && !_dataCompleter!.isCompleted) {
            try {
              _dataCompleter!.complete({});
            } catch (e) {
              debugPrint('Error completing completer on back: $e');
            }
          }
          return true;
        },
        child: _visitDetailsFuture == null
            ? const Center(child: CircularProgressIndicator())
            : FutureBuilder<Map<String, dynamic>>(
                key: ValueKey('contact_details_${widget.contactNumber}'),
                future: _visitDetailsFuture,
                builder: (context, snapshot) {
                  // Early return if disposed - don't try to build anything
                  if (_isDisposed || !mounted) {
                    return const SizedBox.shrink();
                  }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading data: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Loading data...'));
          }

          // Additional safety check before accessing data
          if (_isDisposed || !mounted) {
            return const SizedBox.shrink();
          }

          final data = snapshot.data!;
          print(
            'DEBUG ContactDetails: Received data keys: ${data.keys.toList()}',
          );

          // Handle different data structures
          List<Map<String, dynamic>> ancVisits = [];
          if (data['ancVisits'] != null) {
            if (data['ancVisits'] is List) {
              ancVisits =
                  (data['ancVisits'] as List)
                      .map((v) => Map<String, dynamic>.from(v))
                      .toList();
            }
          }

          List<Map<String, dynamic>> pregnancies = [];
          if (data['pregnancies'] != null) {
            if (data['pregnancies'] is List) {
              pregnancies =
                  (data['pregnancies'] as List)
                      .map((v) => Map<String, dynamic>.from(v))
                      .toList();
            }
          }

          List<Map<String, dynamic>> deliveries = [];
          if (data['deliveries'] != null) {
            if (data['deliveries'] is List) {
              deliveries =
                  (data['deliveries'] as List)
                      .map((v) => Map<String, dynamic>.from(v))
                      .toList();
            }
          }

          List<Map<String, dynamic>> neonates = [];
          if (data['neonates'] != null) {
            if (data['neonates'] is List) {
              neonates =
                  (data['neonates'] as List)
                      .map((v) => Map<String, dynamic>.from(v))
                      .toList();
            }
          }

          List<Map<String, dynamic>> postnatalVisits = [];
          if (data['postnatalVisits'] != null) {
            if (data['postnatalVisits'] is List) {
              postnatalVisits =
                  (data['postnatalVisits'] as List)
                      .map((v) => Map<String, dynamic>.from(v))
                      .toList();
            }
          }

          print(
            'DEBUG ContactDetails: Parsed data - ANC: ${ancVisits.length}, Pregnancies: ${pregnancies.length}, Deliveries: ${deliveries.length}, Neonates: ${neonates.length}, Postnatal: ${postnatalVisits.length}',
          );

          // Check if we have any data at all
          final hasAnyData =
              ancVisits.isNotEmpty ||
              pregnancies.isNotEmpty ||
              deliveries.isNotEmpty ||
              neonates.isNotEmpty ||
              postnatalVisits.isNotEmpty;

          if (!hasAnyData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No data available for this visit.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Visit Number: ${widget.contactNumber}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Find the ANC visit for this contact number
          // Schema: anc_visit.dak_contact_number (INTEGER) and visit_number (INTEGER)
          Map<String, dynamic> ancVisit = {};
          if (ancVisits.isNotEmpty) {
            print(
              'DEBUG ContactDetails: Searching for contact ${widget.contactNumber} in ${ancVisits.length} visits',
            );

            // Log all visit numbers for debugging
            for (var visit in ancVisits) {
              print(
                'DEBUG ContactDetails: Visit - visit_number: ${visit['visit_number']}, dak_contact_number: ${visit['dak_contact_number']}',
              );
            }

            try {
              ancVisit = ancVisits.firstWhere((v) {
                final visitNum = v['visit_number'];
                final dakContactNum = v['dak_contact_number'];
                final match =
                    visitNum == widget.contactNumber ||
                    dakContactNum == widget.contactNumber ||
                    visitNum?.toString() == widget.contactNumber.toString() ||
                    dakContactNum?.toString() ==
                        widget.contactNumber.toString();
                if (match) {
                  print(
                    'DEBUG ContactDetails: Found matching visit - visit_number: $visitNum, dak_contact_number: $dakContactNum',
                  );
                }
                return match;
              });
              print(
                'DEBUG ContactDetails: Successfully found matching ANC visit',
              );
            } catch (e) {
              print('DEBUG ContactDetails: No exact match found, error: $e');
              // If no exact match, try to find by visit_number closest to contact number
              // Or use the first visit as fallback
              if (ancVisits.isNotEmpty) {
                print(
                  'DEBUG ContactDetails: No exact match, showing first available visit',
                );
                ancVisit = Map<String, dynamic>.from(ancVisits.first);
              }
            }
          } else {
            print('DEBUG ContactDetails: No ANC visits available');
          }

          // Always show data even if no exact match - show all available data
          print(
            'DEBUG ContactDetails: Final state - ancVisit empty: ${ancVisit.isEmpty}, has pregnancies: ${pregnancies.isNotEmpty}',
          );

          if (!mounted || _isDisposed) {
            return const SizedBox.shrink();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show ANC visit details if available
                if (ancVisit.isNotEmpty) ...[
                  _buildSectionCard(
                    context,
                    title: 'ANC Visit Information',
                    icon: Icons.medical_services,
                    color: const Color(0xFF7C4DFF),
                    children: [
                      _buildInfoRow(
                        context,
                        'Visit Number:',
                        ancVisit['visit_number']?.toString(),
                      ),
                      _buildInfoRow(
                        context,
                        'DAK Contact Number:',
                        ancVisit['dak_contact_number']?.toString(),
                      ),
                      _buildInfoRow(
                    context,
                    'Visit Date:',
                    _formatDate(ancVisit['visit_date']),
                  ),
                  _buildInfoRow(
                    context,
                    'Gestational Age:',
                        (ancVisit['gestation_weeks'] ??
                                        ancVisit['gestational_age_weeks'])
                                    ?.toString() !=
                                null
                            ? '${(ancVisit['gestation_weeks'] ?? ancVisit['gestational_age_weeks'])} weeks'
                            : 'N/A',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Vitals Section
                  _buildSectionCard(
                    context,
                    title: 'Vital Signs',
                    icon: Icons.favorite,
                    color: Colors.red[400]!,
                    children: [
                      _buildInfoRow(
                        context,
                        'Weight:',
                        ancVisit['weight_kg']?.toString() != null
                            ? '${ancVisit['weight_kg']} kg'
                            : 'N/A',
                  ),
                  _buildInfoRow(
                    context,
                        'Blood Pressure:',
                        (ancVisit['blood_pressure_systolic'] != null &&
                                ancVisit['blood_pressure_diastolic'] != null)
                            ? '${ancVisit['blood_pressure_systolic']}/${ancVisit['blood_pressure_diastolic']} mmHg'
                            : 'N/A',
                  ),
                  _buildInfoRow(
                    context,
                    'Hemoglobin:',
                        ancVisit['hemoglobin_gdl']?.toString() != null
                            ? '${ancVisit['hemoglobin_gdl']} g/dL'
                            : 'N/A',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Medications Section
                  _buildSectionCard(
                    context,
                    title: 'Medications & Supplements',
                    icon: Icons.medication,
                    color: Colors.blue[600]!,
                    children: [
                      _buildInfoRow(
                        context,
                        'Iron Supplement:',
                        ancVisit['iron_supplement_given'] == true
                            ? 'Yes'
                            : ancVisit['iron_supplement_given'] == false
                            ? 'No'
                            : 'N/A',
                  ),
                  _buildInfoRow(
                    context,
                        'Folic Acid:',
                        ancVisit['folic_acid_given'] == true
                            ? 'Yes'
                            : ancVisit['folic_acid_given'] == false
                            ? 'No'
                            : 'N/A',
                  ),
                  _buildInfoRow(
                    context,
                        'Tetanus Toxoid:',
                        ancVisit['tetanus_toxoid_given'] == true
                            ? 'Yes'
                            : ancVisit['tetanus_toxoid_given'] == false
                            ? 'No'
                            : 'N/A',
                      ),
                      if (ancVisit['tetanus_toxoid_dose'] != null)
                        _buildInfoRow(
                          context,
                          'Tetanus Dose:',
                          ancVisit['tetanus_toxoid_dose']?.toString(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Risk Assessment Section
                  _buildSectionCard(
                    context,
                    title: 'Risk Assessment',
                    icon: Icons.warning,
                    color: Colors.orange[600]!,
                    children: [
                      _buildInfoRow(
                        context,
                        'Risk Level:',
                        ancVisit['risk_level']?.toString().toUpperCase() ??
                            'N/A',
                        valueColor: _getRiskLevelColor(
                          ancVisit['risk_level']?.toString(),
                        ),
                      ),
                      if ((ancVisit['danger_signs_list'] ??
                              ancVisit['danger_signs']) !=
                          null)
                        _buildInfoRow(
                          context,
                          'Danger Signs:',
                          (ancVisit['danger_signs_list'] ??
                                  ancVisit['danger_signs'])
                              ?.toString(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Follow-up Section
                  _buildSectionCard(
                    context,
                    title: 'Follow-up',
                    icon: Icons.calendar_today,
                    color: Colors.green[600]!,
                    children: [
                      _buildInfoRow(
                        context,
                        'Next Visit Date:',
                        _formatDate(ancVisit['next_visit_date']),
                      ),
                      if (ancVisit['provider_name'] != null)
                        _buildInfoRow(
                          context,
                          'Provider:',
                          ancVisit['provider_name']?.toString(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ] else if (ancVisits.isNotEmpty) ...[
                  // Show message if we have visits but no exact match
                  _buildWarningCard(
                    context,
                    'Visit ${widget.contactNumber} not found',
                    '${ancVisits.length} visit(s) available in your records.',
                  ),
                  const SizedBox(height: 24),
                ],
                if (pregnancies.isNotEmpty) ...[
                  _buildSectionCard(
                    context,
                    title: 'Pregnancy Details',
                    icon: Icons.child_care,
                    color: Colors.pink[400]!,
                    children: [
                      _buildInfoRow(
                    context,
                    'LMP:',
                        _formatDate(pregnancies.first['lmp_date']),
                  ),
                  _buildInfoRow(
                    context,
                    'EDD:',
                        _formatDate(pregnancies.first['edd_date']),
                      ),
                      _buildInfoRow(
                        context,
                        'Current Gestation:',
                        pregnancies.first['current_gestation_weeks']
                                    ?.toString() !=
                                null
                            ? '${pregnancies.first['current_gestation_weeks']} weeks'
                            : 'N/A',
                      ),
                      _buildInfoRow(
                        context,
                        'Gravida:',
                        pregnancies.first['gravida']?.toString(),
                      ),
                      _buildInfoRow(
                        context,
                        'Para:',
                        pregnancies.first['para']?.toString(),
                  ),
                  _buildInfoRow(
                    context,
                    'Pregnancy Number:',
                    pregnancies.first['pregnancy_number']?.toString(),
                  ),
                  _buildInfoRow(
                    context,
                    'Status:',
                        pregnancies.first['status']?.toString().toUpperCase() ??
                            'N/A',
                        valueColor: _getPregnancyStatusColor(
                    pregnancies.first['status']?.toString(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
                if (deliveries.isNotEmpty) ...[
                  _buildSectionCard(
                    context,
                    title: 'Delivery Details',
                    icon: Icons.local_hospital,
                    color: Colors.purple[600]!,
                    children: [
                      _buildInfoRow(
                    context,
                    'Delivery Date:',
                    _formatDate(deliveries.first['delivery_date']),
                  ),
                  _buildInfoRow(
                    context,
                    'Mode:',
                        deliveries.first['delivery_mode']
                                ?.toString()
                                .replaceAll('_', ' ')
                                .toUpperCase() ??
                            'N/A',
                      ),
                      if (deliveries.first['complications'] != null)
                  _buildInfoRow(
                    context,
                    'Complications:',
                    deliveries.first['complications']?.toString(),
                  ),
                      if (deliveries.first['blood_loss_ml'] != null)
                  _buildInfoRow(
                    context,
                    'Blood Loss:',
                          '${deliveries.first['blood_loss_ml']} ml',
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
                if (neonates.isNotEmpty) ...[
                  _buildSectionCard(
                    context,
                    title: 'Neonate Details',
                    icon: Icons.baby_changing_station,
                    color: Colors.cyan[600]!,
                    children: [
                      _buildInfoRow(
                        context,
                        'Birth Date:',
                        _formatDate(neonates.first['birth_date']),
                      ),
                      _buildInfoRow(
                        context,
                        'Sex/Gender:',
                        (neonates.first['sex'] ?? neonates.first['gender'])
                                ?.toString()
                                .toUpperCase() ??
                            'N/A',
                  ),
                  _buildInfoRow(
                    context,
                    'Birth Weight:',
                        (neonates.first['birth_weight_grams'] ??
                                        neonates.first['birth_weight'])
                                    ?.toString() !=
                                null
                            ? '${(neonates.first['birth_weight_grams'] ?? neonates.first['birth_weight'])} g'
                            : 'N/A',
                      ),
                      if (neonates.first['apgar_1min'] != null ||
                          neonates.first['apgar_5min'] != null)
                  _buildInfoRow(
                    context,
                          'Apgar Scores:',
                          '${neonates.first['apgar_1min'] ?? 'N/A'}/1min, ${neonates.first['apgar_5min'] ?? 'N/A'}/5min',
                  ),
                      if (neonates.first['congenital_anomalies'] != null)
                  _buildInfoRow(
                    context,
                    'Congenital Anomalies:',
                    neonates.first['congenital_anomalies']?.toString(),
                  ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
                if (postnatalVisits.isNotEmpty) ...[
                  _buildSectionCard(
                    context,
                    title: 'Postnatal Visit Information',
                    icon: Icons.health_and_safety,
                    color: Colors.teal[600]!,
                    children: [
                      _buildInfoRow(
                    context,
                    'Visit Date:',
                    _formatDate(postnatalVisits.first['visit_date']),
                  ),
                      if (postnatalVisits.first['visit_type'] != null)
                        _buildInfoRow(
                          context,
                          'Visit Type:',
                          postnatalVisits.first['visit_type']?.toString(),
                        ),
                      if (postnatalVisits.first['days_postpartum'] != null)
                  _buildInfoRow(
                    context,
                          'Days Postpartum:',
                          '${postnatalVisits.first['days_postpartum']} days',
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildSectionCard(
                    context,
                    title: 'Maternal Assessment',
                    icon: Icons.pregnant_woman,
                    color: Colors.pink[300]!,
                    children: [
                      if (postnatalVisits.first['maternal_weight_kg'] != null)
                        _buildInfoRow(
                          context,
                          'Weight:',
                          '${postnatalVisits.first['maternal_weight_kg']} kg',
                        ),
                      if (postnatalVisits.first['maternal_bp_systolic'] !=
                              null &&
                          postnatalVisits.first['maternal_bp_diastolic'] !=
                              null)
                        _buildInfoRow(
                          context,
                          'Blood Pressure:',
                          '${postnatalVisits.first['maternal_bp_systolic']}/${postnatalVisits.first['maternal_bp_diastolic']} mmHg',
                        ),
                      if (postnatalVisits.first['maternal_complaints'] != null)
                        _buildInfoRow(
                          context,
                          'Complaints:',
                          postnatalVisits.first['maternal_complaints']
                              ?.toString(),
                        ),
                      if (postnatalVisits.first['maternal_bleeding'] != null)
                        _buildInfoRow(
                          context,
                          'Bleeding:',
                          postnatalVisits.first['maternal_bleeding']
                                  ?.toString()
                                  .toUpperCase() ??
                              'N/A',
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildSectionCard(
                    context,
                    title: 'Neonate Assessment',
                    icon: Icons.child_friendly,
                    color: Colors.lightBlue[400]!,
                    children: [
                      if (postnatalVisits.first['neonate_weight_grams'] != null)
                        _buildInfoRow(
                          context,
                          'Weight:',
                          '${postnatalVisits.first['neonate_weight_grams']} g',
                        ),
                      if (postnatalVisits.first['neonate_temperature'] != null)
                        _buildInfoRow(
                          context,
                          'Temperature:',
                          '${postnatalVisits.first['neonate_temperature']} °C',
                        ),
                      if (postnatalVisits.first['neonate_feeding_status'] !=
                          null)
                        _buildInfoRow(
                          context,
                          'Feeding Status:',
                          postnatalVisits.first['neonate_feeding_status']
                                  ?.toString()
                                  .replaceAll('_', ' ')
                                  .toUpperCase() ??
                              'N/A',
                        ),
                      if (postnatalVisits.first['neonate_health_status'] !=
                          null)
                        _buildInfoRow(
                          context,
                          'Health Status:',
                          postnatalVisits.first['neonate_health_status']
                                  ?.toString()
                                  .toUpperCase() ??
                              'N/A',
                  ),
                  _buildInfoRow(
                    context,
                        'Jaundice:',
                        postnatalVisits.first['neonate_jaundice'] == true
                            ? 'Yes'
                            : postnatalVisits.first['neonate_jaundice'] == false
                            ? 'No'
                            : 'N/A',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          );
        },
      ),
    ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    if (!mounted || _isDisposed) {
      return const SizedBox.shrink();
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
      child: Text(
        title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard(BuildContext context, String title, String message) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange[200]!, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange[700], size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[900],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(fontSize: 14, color: Colors.orange[800]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRiskLevelColor(String? riskLevel) {
    if (riskLevel == null) return Colors.grey;
    switch (riskLevel.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red[600]!;
      case 'critical':
        return Colors.red[900]!;
      default:
        return Colors.grey;
    }
  }

  Color _getPregnancyStatusColor(String? status) {
    if (status == null) return Colors.grey;
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'terminated':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr.toString());
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return dateStr.toString();
    }
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String? value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value ?? 'N/A',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.grey[900],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
