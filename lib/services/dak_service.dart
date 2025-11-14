import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config.dart';

// DAK Service for decision support and scheduling
class DAKService {
  static String get _baseUrl => AppConfig.getBackendUrl();

  /// Get DAK decision support for a patient
  static Future<Map<String, dynamic>?> getDecisionSupport(
    String patientId,
    String jwt,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/dak/decision-support/$patientId'),
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error getting DAK decision support: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception getting DAK decision support: $e');
      return null;
    }
  }

  /// Get DAK scheduling recommendations for a patient
  static Future<Map<String, dynamic>?> getSchedulingRecommendations(
    String patientId,
    String jwt,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/dak/scheduling/$patientId'),
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error getting DAK scheduling: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception getting DAK scheduling: $e');
      return null;
    }
  }

  /// Get DAK quality metrics
  static Future<Map<String, dynamic>?> getQualityMetrics(
    String jwt, {
    String? facilityId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      String url = '$_baseUrl/dak/quality-metrics';
      List<String> queryParams = [];

      if (facilityId != null) queryParams.add('facilityId=$facilityId');
      if (startDate != null) queryParams.add('startDate=$startDate');
      if (endDate != null) queryParams.add('endDate=$endDate');

      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error getting DAK quality metrics: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception getting DAK quality metrics: $e');
      return null;
    }
  }

  /// Get DAK ANC indicators
  static Future<Map<String, dynamic>?> getANCIndicators(String jwt) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/indicators/anc'),
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error getting ANC indicators: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception getting ANC indicators: $e');
      return null;
    }
  }

  /// Format DAK alert for display
  static String formatDAKAlert(Map<String, dynamic> alert) {
    final message = alert['message'] ?? '';
    final priority = alert['priority'] ?? 'medium';

    String priorityIcon = '⚠️';
    switch (priority) {
      case 'high':
        priorityIcon = '🚨';
        break;
      case 'medium':
        priorityIcon = '⚠️';
        break;
      case 'low':
        priorityIcon = 'ℹ️';
        break;
    }

    return '$priorityIcon $message';
  }

  /// Get DAK decision point description
  static String getDecisionPointDescription(String decisionPoint) {
    const descriptions = {
      'ANC.DT.01': 'Danger Signs Assessment',
      'ANC.DT.02': 'Blood Pressure Assessment',
      'ANC.DT.03': 'Proteinuria Testing',
      'ANC.DT.04': 'Anemia Screening',
      'ANC.DT.05': 'HIV Testing and Counseling',
      'ANC.DT.06': 'Syphilis Screening',
      'ANC.DT.07': 'Malaria Prevention',
      'ANC.DT.08': 'Tetanus Immunization',
      'ANC.DT.09': 'Iron Supplementation',
      'ANC.DT.10': 'Birth Preparedness',
      'ANC.DT.11': 'Emergency Planning',
      'ANC.DT.12': 'Postpartum Care Planning',
      'ANC.DT.13': 'Family Planning Counseling',
      'ANC.DT.14': 'Danger Sign Recognition',
    };

    return descriptions[decisionPoint] ?? 'Unknown Decision Point';
  }

  /// Get DAK scheduling description
  static String getSchedulingDescription(String scheduleCode) {
    const descriptions = {
      'ANC.S.01': 'First ANC Visit (8-12 weeks)',
      'ANC.S.02': 'Second ANC Visit (20-24 weeks)',
      'ANC.S.03': 'Third ANC Visit (26-30 weeks)',
      'ANC.S.04': 'Fourth ANC Visit (32-36 weeks)',
      'ANC.S.05': 'Fifth ANC Visit (38-40 weeks)',
    };

    return descriptions[scheduleCode] ?? 'Unknown Schedule';
  }

  /// Calculate DAK compliance score
  static double calculateComplianceScore(List<Map<String, dynamic>> alerts) {
    if (alerts.isEmpty) return 100.0;

    final highPriorityAlerts =
        alerts.where((alert) => alert['priority'] == 'high').length;
    final mediumPriorityAlerts =
        alerts.where((alert) => alert['priority'] == 'medium').length;
    final lowPriorityAlerts =
        alerts.where((alert) => alert['priority'] == 'low').length;

    // Weighted scoring: high priority alerts have more impact
    final totalWeightedAlerts =
        (highPriorityAlerts * 3) +
        (mediumPriorityAlerts * 2) +
        lowPriorityAlerts;
    final maxPossibleAlerts = alerts.length * 3; // Assuming all high priority

    if (maxPossibleAlerts == 0) return 100.0;

    final compliancePercentage =
        ((maxPossibleAlerts - totalWeightedAlerts) / maxPossibleAlerts) * 100;
    return compliancePercentage.clamp(0.0, 100.0);
  }

  /// Get DAK compliance status
  static String getComplianceStatus(double score) {
    if (score >= 90) return 'Excellent';
    if (score >= 80) return 'Good';
    if (score >= 70) return 'Fair';
    if (score >= 60) return 'Poor';
    return 'Critical';
  }

  /// Format next visit recommendation
  static String formatNextVisitRecommendation(
    Map<String, dynamic> recommendation,
  ) {
    final visitNumber = recommendation['visitNumber'] ?? 0;
    final gestationalAge = recommendation['recommendedGestationalAge'] ?? 0;
    final recommendedDate = recommendation['recommendedDate'] ?? '';
    final priority = recommendation['priority'] ?? 'medium';

    String priorityText = '';
    switch (priority) {
      case 'high':
        priorityText = 'High Priority';
        break;
      case 'medium':
        priorityText = 'Medium Priority';
        break;
      case 'low':
        priorityText = 'Low Priority';
        break;
    }

    return 'Visit $visitNumber recommended at $gestationalAge weeks ($recommendedDate) - $priorityText';
  }
}
