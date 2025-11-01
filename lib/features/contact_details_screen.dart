import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_session_provider.dart';
import 'package:intl/intl.dart'; // For date formatting

class ContactDetailsScreen extends StatefulWidget {
  final int contactNumber;

  const ContactDetailsScreen({Key? key, required this.contactNumber})
    : super(key: key);

  @override
  State<ContactDetailsScreen> createState() => _ContactDetailsScreenState();
}

class _ContactDetailsScreenState extends State<ContactDetailsScreen> {
  Future<Map<String, dynamic>>? _visitDetailsFuture;

  @override
  void initState() {
    super.initState();
    final userSession = Provider.of<UserSessionProvider>(
      context,
      listen: false,
    );
    final clientNumber = userSession.clientNumber;
    _visitDetailsFuture = fetchAllVisitDetails(clientNumber);
  }

  Future<Map<String, dynamic>> fetchAllVisitDetails(
    String? clientNumber,
  ) async {
    if (clientNumber == null) return {};
    final userSession = Provider.of<UserSessionProvider>(
      context,
      listen: false,
    );
    final patientId = userSession.patient?['id'];
    if (patientId == null) return {};

    // Fetch ANC visits
    final ancResponse = await http.get(
      Uri.parse(
        'https://health-fhir-backend-production-6ae1.up.railway.app/anc_visit',
      ),
    );
    final ancVisits =
        (jsonDecode(ancResponse.body) as List)
            .where((v) => v['patient_id'] == patientId)
            .toList();

    // Fetch pregnancy
    final pregResponse = await http.get(
      Uri.parse(
        'https://health-fhir-backend-production-6ae1.up.railway.app/pregnancy',
      ),
    );
    final pregnancies =
        (jsonDecode(pregResponse.body) as List)
            .where((p) => p['patient_id'] == patientId)
            .toList();

    // Fetch delivery
    final deliveryResponse = await http.get(
      Uri.parse(
        'https://health-fhir-backend-production-6ae1.up.railway.app/delivery',
      ),
    );
    final deliveries =
        (jsonDecode(deliveryResponse.body) as List)
            .where((d) => pregnancies.any((p) => p['id'] == d['pregnancy_id']))
            .toList();

    // Fetch neonate
    final neonateResponse = await http.get(
      Uri.parse(
        'https://health-fhir-backend-production-6ae1.up.railway.app/neonate',
      ),
    );
    final neonates =
        (jsonDecode(neonateResponse.body) as List)
            .where((n) => deliveries.any((d) => d['id'] == n['delivery_id']))
            .toList();

    // Fetch postnatal visits
    final postnatalResponse = await http.get(
      Uri.parse(
        'https://health-fhir-backend-production-6ae1.up.railway.app/postnatal_visit',
      ),
    );
    final postnatalVisits =
        (jsonDecode(postnatalResponse.body) as List)
            .where((p) => p['patient_id'] == patientId)
            .toList();

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
    return Scaffold(
      appBar: AppBar(
        title: Text('Contact ${widget.contactNumber} Details'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _visitDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No data available for this contact.'),
            );
          }
          final data = snapshot.data!;
          final ancVisits = data['ancVisits'] as List? ?? [];
          final pregnancies = data['pregnancies'] as List? ?? [];
          final deliveries = data['deliveries'] as List? ?? [];
          final neonates = data['neonates'] as List? ?? [];
          final postnatalVisits = data['postnatalVisits'] as List? ?? [];

          // Find the ANC visit for this contact number
          final ancVisit = ancVisits.firstWhere(
            (v) => v['visit_number'] == widget.contactNumber,
            orElse: () => null,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ancVisit != null) ...[
                  _buildSectionTitle('ANC Visit Details'),
                  _buildInfoRow(
                    context,
                    'Visit Date:',
                    _formatDate(ancVisit['visit_date']),
                  ),
                  _buildInfoRow(
                    context,
                    'Gestational Age:',
                    ancVisit['gestational_age_weeks']?.toString(),
                  ),
                  _buildInfoRow(
                    context,
                    'Systolic BP:',
                    ancVisit['systolic_bp']?.toString(),
                  ),
                  _buildInfoRow(
                    context,
                    'Diastolic BP:',
                    ancVisit['diastolic_bp']?.toString(),
                  ),
                  _buildInfoRow(
                    context,
                    'Hemoglobin:',
                    ancVisit['hemoglobin']?.toString(),
                  ),
                  _buildInfoRow(
                    context,
                    'Danger Signs:',
                    ancVisit['danger_signs']?.toString(),
                  ),
                  _buildInfoRow(
                    context,
                    'Counseling Topics:',
                    ancVisit['counseling_topics']?.toString(),
                  ),
                  _buildInfoRow(
                    context,
                    'Iron/Folic Acid Given:',
                    ancVisit['iron_folic_acid_given']?.toString(),
                  ),
                  _buildInfoRow(
                    context,
                    'IPTp Doses:',
                    ancVisit['iptp_doses']?.toString(),
                  ),
                  _buildInfoRow(
                    context,
                    'Tetanus Doses:',
                    ancVisit['tetanus_doses']?.toString(),
                  ),
                  _buildInfoRow(
                    context,
                    'Next Visit Date:',
                    _formatDate(ancVisit['next_visit_date']),
                  ),
                  const Divider(height: 32),
                ],
                if (pregnancies.isNotEmpty) ...[
                  _buildSectionTitle('Pregnancy Details'),
                  _buildInfoRow(
                    context,
                    'LMP:',
                    _formatDate(pregnancies.first['lmp']),
                  ),
                  _buildInfoRow(
                    context,
                    'EDD:',
                    _formatDate(pregnancies.first['edd']),
                  ),
                  _buildInfoRow(
                    context,
                    'Pregnancy Number:',
                    pregnancies.first['pregnancy_number']?.toString(),
                  ),
                  _buildInfoRow(
                    context,
                    'Status:',
                    pregnancies.first['status']?.toString(),
                  ),
                  const Divider(height: 32),
                ],
                if (deliveries.isNotEmpty) ...[
                  _buildSectionTitle('Delivery Details'),
                  _buildInfoRow(
                    context,
                    'Delivery Date:',
                    _formatDate(deliveries.first['delivery_date']),
                  ),
                  _buildInfoRow(
                    context,
                    'Mode:',
                    deliveries.first['delivery_mode']?.toString(),
                  ),
                  _buildInfoRow(
                    context,
                    'Complications:',
                    deliveries.first['complications']?.toString(),
                  ),
                  _buildInfoRow(
                    context,
                    'Blood Loss:',
                    deliveries.first['blood_loss']?.toString(),
                  ),
                  const Divider(height: 32),
                ],
                if (neonates.isNotEmpty) ...[
                  _buildSectionTitle('Neonate Details'),
                  _buildInfoRow(
                    context,
                    'Gender:',
                    neonates.first['gender']?.toString(),
                  ),
                  _buildInfoRow(
                    context,
                    'Birth Weight:',
                    neonates.first['birth_weight']?.toString(),
                  ),
                  _buildInfoRow(
                    context,
                    'Apgar Score:',
                    neonates.first['apgar_score']?.toString(),
                  ),
                  _buildInfoRow(
                    context,
                    'Congenital Anomalies:',
                    neonates.first['congenital_anomalies']?.toString(),
                  ),
                  const Divider(height: 32),
                ],
                if (postnatalVisits.isNotEmpty) ...[
                  _buildSectionTitle('Postnatal Visit Details'),
                  _buildInfoRow(
                    context,
                    'Visit Date:',
                    _formatDate(postnatalVisits.first['visit_date']),
                  ),
                  _buildInfoRow(
                    context,
                    'Mother Condition:',
                    postnatalVisits.first['mother_condition']?.toString(),
                  ),
                  _buildInfoRow(
                    context,
                    'Baby Condition:',
                    postnatalVisits.first['baby_condition']?.toString(),
                  ),
                  _buildInfoRow(
                    context,
                    'Breastfeeding Status:',
                    postnatalVisits.first['breastfeeding_status']?.toString(),
                  ),
                  _buildInfoRow(
                    context,
                    'Family Planning:',
                    postnatalVisits.first['family_planning']?.toString(),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
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
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
          Flexible(
            child: Text(
              value ?? 'N/A',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
