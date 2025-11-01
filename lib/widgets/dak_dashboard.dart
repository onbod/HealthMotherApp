import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_session_provider.dart';
import '../services/dak_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// DAK-compliant dashboard widget showing decision support and scheduling
class DAKDashboard extends StatefulWidget {
  const DAKDashboard({Key? key}) : super(key: key);

  @override
  State<DAKDashboard> createState() => _DAKDashboardState();
}

class _DAKDashboardState extends State<DAKDashboard> {
  Map<String, dynamic>? _decisionSupport;
  Map<String, dynamic>? _schedulingRecommendations;
  bool _isLoading = true;
  String? _jwt;

  @override
  void initState() {
    super.initState();
    _loadDAKData();
  }

  Future<void> _loadDAKData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final storage = FlutterSecureStorage();
      _jwt = await storage.read(key: 'jwt');

      if (_jwt != null) {
        final userSession = Provider.of<UserSessionProvider>(
          context,
          listen: false,
        );
        final patientId = userSession.patient?['id'];

        if (patientId != null) {
          // Load decision support and scheduling data in parallel
          final futures = await Future.wait([
            DAKService.getDecisionSupport(patientId, _jwt!),
            DAKService.getSchedulingRecommendations(patientId, _jwt!),
          ]);

          setState(() {
            _decisionSupport = futures[0];
            _schedulingRecommendations = futures[1];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading DAK data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildDecisionSupportCard(),
          const SizedBox(height: 16),
          _buildSchedulingCard(),
          const SizedBox(height: 16),
          _buildComplianceCard(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.health_and_safety, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'DAK Compliance Dashboard',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Digital Adaptation Kit for Antenatal Care',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecisionSupportCard() {
    final alerts =
        _decisionSupport?['decisionSupportAlerts'] as List<dynamic>? ?? [];
    final highPriorityAlerts =
        alerts.where((alert) => alert['priority'] == 'high').length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Decision Support Alerts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildAlertCount('Total', alerts.length, Colors.blue),
                const SizedBox(width: 16),
                _buildAlertCount(
                  'High Priority',
                  highPriorityAlerts,
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (alerts.isNotEmpty) ...[
              Text(
                'Recent Alerts:',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...alerts
                  .take(3)
                  .map(
                    (alert) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        DAKService.formatDAKAlert(alert),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
              if (alerts.length > 3)
                Text(
                  '... and ${alerts.length - 3} more alerts',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
            ] else
              Text(
                'No alerts at this time',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.green),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedulingCard() {
    final recommendation =
        _schedulingRecommendations?['nextVisitRecommendation'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Next Visit Recommendation',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (recommendation != null) ...[
              Text(
                DAKService.formatNextVisitRecommendation(recommendation),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              if (recommendation['requiredAssessments'] != null) ...[
                Text(
                  'Required Assessments:',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                ...(recommendation['requiredAssessments'] as List<dynamic>).map(
                  (assessment) => Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 2.0),
                    child: Text(
                      '• ${DAKService.getDecisionPointDescription(assessment)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ],
            ] else
              Text(
                'No scheduling recommendations available',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplianceCard() {
    final alertsList =
        _decisionSupport?['decisionSupportAlerts'] as List<dynamic>? ?? [];
    final alerts = alertsList.map((e) => e as Map<String, dynamic>).toList();
    final complianceScore = DAKService.calculateComplianceScore(alerts);
    final complianceStatus = DAKService.getComplianceStatus(complianceScore);

    Color statusColor = Colors.green;
    if (complianceScore < 80) statusColor = Colors.orange;
    if (complianceScore < 60) statusColor = Colors.red;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: statusColor),
                const SizedBox(width: 8),
                Text(
                  'DAK Compliance Score',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${complianceScore.toStringAsFixed(1)}%',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        complianceStatus,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: statusColor),
                      ),
                    ],
                  ),
                ),
                CircularProgressIndicator(
                  value: complianceScore / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Based on DAK decision support alerts and recommendations',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCount(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}
