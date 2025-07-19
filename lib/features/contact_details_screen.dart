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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contact ${widget.contactNumber} Details'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<UserSessionProvider>(
        builder: (context, userSession, child) {
          final contactData = userSession.getVisitData(widget.contactNumber);

          if (contactData == null) {
            return const Center(
              child: Text('No data available for this contact.'),
            );
          }

          // Map backend fields
          final String? gestationalAge =
              contactData['gestational_age_weeks']?.toString();
          final String? visitDateStr = contactData['visit_date']?.toString();
          String formattedVisitDate = 'N/A';
          if (visitDateStr != null) {
            try {
              final date = DateTime.parse(visitDateStr);
              formattedVisitDate = DateFormat('dd/MM/yyyy').format(date);
            } catch (_) {}
          }

          // Example: Map more fields as needed
          final String? systolicBp = contactData['systolic_bp']?.toString();
          final String? diastolicBp = contactData['diastolic_bp']?.toString();
          final String? weight = contactData['weight']?.toString();
          final String? hemoglobin = contactData['hemoglobin']?.toString();
          final String? counselingNotes =
              contactData['counseling_notes']?.toString();

          final bool isCompleted =
              userSession.getVisitData(widget.contactNumber) != null;

          final nextVisitDate =
              userSession.getNextVisitDate() ??
              userSession.calculateNextVisitDateFromGuidelines();
          String nextVisitText =
              nextVisitDate != null
                  ? 'Next Visit: ${DateFormat('dd/MM/yyyy').format(nextVisitDate)}'
                  : 'No next visit scheduled';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contact ${widget.contactNumber} Summary',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const Divider(height: 24),
                        _buildInfoRow(
                          context,
                          'Gestational Age:',
                          gestationalAge != null
                              ? '$gestationalAge weeks'
                              : 'N/A',
                        ),
                        _buildInfoRow(
                          context,
                          'Date of ANC Contact:',
                          formattedVisitDate,
                        ),
                        _buildInfoRow(
                          context,
                          'Systolic BP:',
                          systolicBp ?? 'N/A',
                        ),
                        _buildInfoRow(
                          context,
                          'Diastolic BP:',
                          diastolicBp ?? 'N/A',
                        ),
                        _buildInfoRow(
                          context,
                          'Weight:',
                          weight != null ? '$weight kg' : 'N/A',
                        ),
                        _buildInfoRow(
                          context,
                          'Hemoglobin:',
                          hemoglobin ?? 'N/A',
                        ),
                        _buildInfoRow(
                          context,
                          'Counseling Notes:',
                          counselingNotes ?? 'N/A',
                        ),
                        if (!isCompleted)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Not completed',
                              style: TextStyle(
                                color: Colors.red[400],
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        _buildInfoRow(context, 'Next Visit:', nextVisitText),
                      ],
                    ),
                  ),
                ),
                // Add more cards/sections for other mapped fields as needed
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    print('ContactDetailsScreen disposed');
    super.dispose();
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
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
              value,
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
