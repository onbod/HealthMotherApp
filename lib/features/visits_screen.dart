import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/shared_app_bar.dart';
import '../widgets/global_navigation.dart';
import '../providers/user_session_provider.dart';
import 'contact_details_screen.dart';
import 'pin_lock_screen.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../core/widgets.dart';

class VisitsScreen extends StatefulWidget {
  const VisitsScreen({super.key});

  @override
  State<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends State<VisitsScreen> {
  final Color primaryColor = const Color(0xFF7C4DFF);
  String? _expandedCategory; // 'pregnancy', 'birth', 'postnatal', or null

  @override
  Widget build(BuildContext context) {
    final isWide = context.isWideScreen;
    
    return GlobalNavigation(
      currentIndex: 2,
      child: Scaffold(
        backgroundColor: isWide ? const Color(0xFFEEEEEE) : const Color(0xFFF3F4F6),
        appBar: SharedAppBar(
          visitNumber: 'Visits',
          onNotificationPressed: () {
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //     builder: (context) => const NotificationsScreen(),
            //   ),
            // );
          },
        ),
        body: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: isWide ? 800 : double.infinity),
            decoration: isWide
                ? BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  )
                : null,
            child: Consumer<UserSessionProvider>(
          builder: (context, userSession, child) {
            final ancVisits = userSession.getAncVisits();
            final delivery = userSession.getDelivery();
            final postnatalVisits = userSession.getPostnatalVisits();
            final hasDelivered = userSession.hasDelivered();

            // Sort ANC visits by visit_number
            final sortedAncVisits = List<Map<String, dynamic>>.from(ancVisits)
              ..sort((a, b) {
                final aNum = a['visit_number'] ?? a['dak_contact_number'] ?? 0;
                final bNum = b['visit_number'] ?? b['dak_contact_number'] ?? 0;
                return (aNum as num).compareTo(bNum as num);
              });

            // Sort postnatal visits by visit_date or pnc_visit_number
            final sortedPostnatalVisits = List<Map<String, dynamic>>.from(
              postnatalVisits,
            )..sort((a, b) {
              final aDate = a['visit_date'];
              final bDate = b['visit_date'];
              if (aDate != null && bDate != null) {
                try {
                  final aParsed = DateTime.tryParse(aDate.toString());
                  final bParsed = DateTime.tryParse(bDate.toString());
                  if (aParsed != null && bParsed != null) {
                    return aParsed.compareTo(bParsed);
                  }
                } catch (_) {}
              }
              final aNum = a['pnc_visit_number'] ?? 0;
              final bNum = b['pnc_visit_number'] ?? 0;
              return (aNum as num).compareTo(bNum as num);
            });

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Next Visit Section
                  _buildNextVisitSection(userSession),
                  const SizedBox(height: 24),

                  // Category Cards
                  // 1. During Pregnancy Card
                  _buildCategoryCard(
                    context,
                    title: 'During Pregnancy',
                    subtitle: 'ANC Visits',
                    icon: Icons.pregnant_woman,
                    color: const Color(0xFF7C4DFF),
                    count: sortedAncVisits.length,
                    isExpanded: _expandedCategory == 'pregnancy',
                    onTap: () {
                      setState(() {
                        _expandedCategory =
                            _expandedCategory == 'pregnancy'
                                ? null
                                : 'pregnancy';
                      });
                    },
                    child:
                        _expandedCategory == 'pregnancy'
                            ? _buildPregnancyVisitsList(
                              context,
                              sortedAncVisits,
                              userSession,
                              hasDelivered,
                            )
                            : null,
                  ),

                  const SizedBox(height: 16),

                  // 2. During Birth Card
                  _buildCategoryCard(
                    context,
                    title: 'During Birth',
                    subtitle: 'Delivery',
                    icon: Icons.child_care,
                    color: Colors.orange,
                    count: hasDelivered && delivery != null ? 1 : 0,
                    isExpanded: _expandedCategory == 'birth',
                    onTap:
                        hasDelivered && delivery != null
                            ? () {
                              setState(() {
                                _expandedCategory =
                                    _expandedCategory == 'birth'
                                        ? null
                                        : 'birth';
                              });
                            }
                            : null,
                    child:
                        _expandedCategory == 'birth' && delivery != null
                            ? _buildDeliveryCard(context, delivery, userSession)
                            : null,
                  ),

                  const SizedBox(height: 16),

                  // 3. Post Pregnancy Card
                  if (hasDelivered)
                    _buildCategoryCard(
                      context,
                      title: 'Post Pregnancy',
                      subtitle: 'Postnatal Visits',
                      icon: Icons.family_restroom,
                      color: Colors.green,
                      count: sortedPostnatalVisits.length,
                      isExpanded: _expandedCategory == 'postnatal',
                      onTap: () {
                        setState(() {
                          _expandedCategory =
                              _expandedCategory == 'postnatal'
                                  ? null
                                  : 'postnatal';
                        });
                      },
                      child:
                          _expandedCategory == 'postnatal'
                              ? _buildPostnatalVisitsList(
                                context,
                                sortedPostnatalVisits,
                                userSession,
                              )
                              : null,
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
          ),
        ),
      ),
    );
  }

  Widget _buildNextVisitSection(UserSessionProvider userSession) {
    final nextVisitDate =
        userSession.getNextVisitDate() ??
        userSession.calculateNextVisitDateFromGuidelines();
    final latestVisit = userSession.getLatestVisitNumber() ?? 0;
    final hasDelivered = userSession.hasDelivered();

    String displayText = 'Next Visit: Not scheduled';
    Color textColor = const Color(0xFF7C4DFF);
    IconData icon = Icons.calendar_today;

    if (hasDelivered) {
      displayText = 'Delivery completed';
      textColor = Colors.green;
      icon = Icons.check_circle;
    } else if (latestVisit >= 8) {
      displayText = 'Completed All 8 Standard Visits';
      textColor = Colors.green;
      icon = Icons.check_circle;
    } else if (nextVisitDate != null) {
      displayText =
          'Next Visit: ${DateFormat('dd/MM/yyyy').format(nextVisitDate)}';
      textColor = const Color(0xFF7C4DFF);
      icon = Icons.calendar_today;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              displayText,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required int count,
    required bool isExpanded,
    required VoidCallback? onTap,
    Widget? child,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpanded ? color : color.withOpacity(0.2),
          width: isExpanded ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color:
                isExpanded
                    ? color.withOpacity(0.2)
                    : Colors.black.withOpacity(0.05),
            blurRadius: isExpanded ? 20 : 10,
            offset: Offset(0, isExpanded ? 8 : 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Card Header (Always Visible)
          InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Icon Container
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [color, color.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  // Title and Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Count Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          count == 1 ? 'visit' : 'visits',
                          style: TextStyle(
                            fontSize: 12,
                            color: color.withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Expand/Collapse Icon
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: color,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expanded Content
          if (isExpanded && child != null) ...[
            Divider(height: 1, thickness: 1, color: color.withOpacity(0.2)),
            Padding(padding: const EdgeInsets.all(16.0), child: child),
          ],
        ],
      ),
    );
  }

  Widget _buildPregnancyVisitsList(
    BuildContext context,
    List<Map<String, dynamic>> sortedAncVisits,
    UserSessionProvider userSession,
    bool hasDelivered,
  ) {
    if (sortedAncVisits.isEmpty && !hasDelivered) {
      return _buildEmptyState('No ANC visits recorded yet');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show standard 8 visits (1-8)
        ...List.generate(8, (index) {
          final visitNum = index + 1;
          final visit = sortedAncVisits.firstWhere(
            (v) => (v['visit_number'] ?? v['dak_contact_number']) == visitNum,
            orElse: () => <String, dynamic>{},
          );
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildAncVisitCard(context, visitNum, visit, userSession),
          );
        }),
        // Show additional visits (beyond 8)
        if (sortedAncVisits.any((v) {
          final num = v['visit_number'] ?? v['dak_contact_number'] ?? 0;
          return num > 8;
        })) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Container(
                  height: 1,
                  width: 20,
                  color: primaryColor.withOpacity(0.3),
                ),
                const SizedBox(width: 8),
                Text(
                  'Additional Visits',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 1,
                    color: primaryColor.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
          ...sortedAncVisits
              .where((v) {
                final num = v['visit_number'] ?? v['dak_contact_number'] ?? 0;
                return num > 8;
              })
              .map((visit) {
                final visitNum =
                    visit['visit_number'] ?? visit['dak_contact_number'] ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildAncVisitCard(
                    context,
                    visitNum,
                    visit,
                    userSession,
                  ),
                );
              }),
        ],
      ],
    );
  }

  Widget _buildPostnatalVisitsList(
    BuildContext context,
    List<Map<String, dynamic>> sortedPostnatalVisits,
    UserSessionProvider userSession,
  ) {
    if (sortedPostnatalVisits.isEmpty) {
      return _buildEmptyState('No postnatal visits recorded yet');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          sortedPostnatalVisits.map((visit) {
            final visitNum =
                visit['pnc_visit_number'] ??
                sortedPostnatalVisits.indexOf(visit) + 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildPostnatalVisitCard(
                context,
                visitNum,
                visit,
                userSession,
              ),
            );
          }).toList(),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _buildAncVisitCard(
    BuildContext context,
    int visitNumber,
    Map<String, dynamic> visitData,
    UserSessionProvider userSession,
  ) {
    final bool isCompleted =
        visitData.isNotEmpty && visitData.containsKey('visit_date');

    // Get gestational age
    String gestationalAgeText = '';
    if (isCompleted) {
      final gestationWeeks =
          visitData['gestation_weeks'] ?? visitData['gestational_age_weeks'];
      if (gestationWeeks != null) {
        gestationalAgeText = 'Week $gestationWeeks';
      }
    }

    // Get visit date
    String visitDateText = '';
    if (isCompleted && visitData['visit_date'] != null) {
      try {
        final date = DateTime.parse(visitData['visit_date'].toString());
        visitDateText = DateFormat('MMM dd, yyyy').format(date);
      } catch (e) {
        visitDateText = visitData['visit_date'].toString();
      }
    }

    // Determine if this is a standard visit (1-8) or additional visit
    final bool isStandardVisit = visitNumber >= 1 && visitNumber <= 8;

    return GestureDetector(
      onTap:
          isCompleted
              ? () async {
                if (!mounted) return;
                if (kIsWeb) {
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              ContactDetailsScreen(contactNumber: visitNumber),
                    ),
                  );
                } else {
                  if (!mounted) return;
                  final bool isStandardVisit =
                      visitNumber >= 1 && visitNumber <= 8;
                  final String visitType =
                      isStandardVisit
                          ? 'ANC Visit $visitNumber'
                          : 'Additional Visit $visitNumber';
                  final pinOk = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder:
                          (context) => PinLockScreen(
                            isChangingPin: true,
                            customTitle: 'View $visitType',
                            customMessage:
                                'Enter your PIN to view $visitType details',
                          ),
                    ),
                  );
                  if (!mounted) return;
                  if (pinOk == true) {
                    // Small delay to ensure PIN screen is fully disposed
                    await Future.delayed(const Duration(milliseconds: 100));
                    if (!mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ContactDetailsScreen(
                              contactNumber: visitNumber,
                            ),
                      ),
                    );
                  }
                }
              }
              : null,
      child: Container(
        decoration: BoxDecoration(
          color: isCompleted ? Colors.white : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isCompleted ? primaryColor.withOpacity(0.3) : Colors.grey[300]!,
            width: 1.5,
          ),
          boxShadow:
              isCompleted
                  ? [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
        ),
        child: _buildMobileCardContent(
          visitNumber,
          isCompleted,
          gestationalAgeText,
          visitDateText,
          isStandardVisit,
        ),
      ),
    );
  }

  Widget _buildDeliveryCard(
    BuildContext context,
    Map<String, dynamic> deliveryData,
    UserSessionProvider userSession,
  ) {
    final deliveryDate = deliveryData['delivery_date'];
    String deliveryDateText = '';
    if (deliveryDate != null) {
      try {
        final date = DateTime.parse(deliveryDate.toString());
        deliveryDateText = DateFormat('MMM dd, yyyy').format(date);
      } catch (e) {
        deliveryDateText = deliveryDate.toString();
      }
    }

    final deliveryMode = deliveryData['delivery_mode'] ?? 'Not specified';
    final outcome =
        deliveryData['delivery_outcome'] ??
        deliveryData['outcome'] ??
        'Not specified';

    return GestureDetector(
      onTap: () async {
        if (!mounted) return;
        if (kIsWeb) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ContactDetailsScreen(
                    contactNumber: 0, // Use 0 or special number for delivery
                  ),
            ),
          );
        } else {
          final pinOk = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              fullscreenDialog: true,
              builder:
                  (context) => const PinLockScreen(
                    isChangingPin: true,
                    customTitle: 'View Delivery Details',
                    customMessage:
                        'Enter your PIN to view your delivery details',
                  ),
            ),
          );
          if (!mounted) return;
          if (pinOk == true) {
            // Small delay to ensure PIN screen is fully disposed
            await Future.delayed(const Duration(milliseconds: 100));
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ContactDetailsScreen(contactNumber: 0),
              ),
            );
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.orange, width: 2),
                ),
                child: const Icon(
                  Icons.child_care,
                  color: Colors.orange,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Delivery',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: const Text(
                            'Completed',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (deliveryDateText.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            deliveryDateText,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.medical_services,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '$deliveryMode • $outcome',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.orange, size: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostnatalVisitCard(
    BuildContext context,
    int visitNumber,
    Map<String, dynamic> visitData,
    UserSessionProvider userSession,
  ) {
    final bool isCompleted = visitData.isNotEmpty;

    // Get visit date
    String visitDateText = '';
    if (isCompleted && visitData['visit_date'] != null) {
      try {
        final date = DateTime.parse(visitData['visit_date'].toString());
        visitDateText = DateFormat('MMM dd, yyyy').format(date);
      } catch (e) {
        visitDateText = visitData['visit_date'].toString();
      }
    }

    final daysPostpartum = visitData['days_postpartum'];
    String daysText = '';
    if (daysPostpartum != null) {
      daysText = '$daysPostpartum days postpartum';
    }

    return GestureDetector(
      onTap:
          isCompleted
              ? () async {
                if (!mounted) return;
                if (kIsWeb) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ContactDetailsScreen(
                            contactNumber:
                                visitNumber + 100, // Offset for postnatal
                          ),
                    ),
                  );
                } else {
                  final pinOk = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder:
                          (context) => PinLockScreen(
                            isChangingPin: true,
                            customTitle: 'View Postnatal Visit $visitNumber',
                            customMessage:
                                'Enter your PIN to view Postnatal Visit $visitNumber details',
                          ),
                    ),
                  );
                  if (!mounted) return;
                  if (pinOk == true) {
                    // Small delay to ensure PIN screen is fully disposed
                    await Future.delayed(const Duration(milliseconds: 100));
                    if (!mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ContactDetailsScreen(
                              contactNumber: visitNumber + 100,
                            ),
                      ),
                    );
                  }
                }
              }
              : null,
      child: Container(
        decoration: BoxDecoration(
          color: isCompleted ? Colors.white : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isCompleted ? Colors.green.withOpacity(0.3) : Colors.grey[300]!,
            width: 1.5,
          ),
          boxShadow:
              isCompleted
                  ? [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color:
                      isCompleted
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey[200],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted ? Colors.green : Colors.grey[400]!,
                    width: 2,
                  ),
                ),
                child: Icon(
                  isCompleted ? Icons.check_circle : Icons.lock_outline,
                  color: isCompleted ? Colors.green : Colors.grey[600],
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Postnatal Visit $visitNumber',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                isCompleted ? Colors.green : Colors.grey[700],
                          ),
                        ),
                        if (isCompleted) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green[200]!),
                            ),
                            child: const Text(
                              'Completed',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (visitDateText.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            visitDateText,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (daysText.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            daysText,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (isCompleted)
                const Icon(Icons.chevron_right, color: Colors.green, size: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileCardContent(
    int contactNumber,
    bool isCompleted,
    String gestationalAgeText,
    String visitDateText,
    bool isStandardVisit,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Left side: Icon and status
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color:
                  isCompleted
                      ? primaryColor.withOpacity(0.1)
                      : Colors.grey[200],
              shape: BoxShape.circle,
              border: Border.all(
                color: isCompleted ? primaryColor : Colors.grey[400]!,
                width: 2,
              ),
            ),
            child: Icon(
              isCompleted ? Icons.check_circle : Icons.lock_outline,
              color: isCompleted ? primaryColor : Colors.grey[600],
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          // Right side: Visit details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(
                      isStandardVisit
                          ? 'ANC Visit $contactNumber'
                          : 'Additional Visit $contactNumber',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? primaryColor : Colors.grey[700],
                      ),
                    ),
                    if (!isStandardVisit && isCompleted) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Text(
                          'Extra',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    if (isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Text(
                          'Completed',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                  ],
                ),
                if (gestationalAgeText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        gestationalAgeText,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
                if (visitDateText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        visitDateText,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
                if (!isCompleted) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Not completed',
                    style: TextStyle(
                      color: Colors.orange[600],
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Right arrow for completed visits
          if (isCompleted)
            Icon(Icons.chevron_right, color: primaryColor, size: 28),
        ],
      ),
    );
  }
}
