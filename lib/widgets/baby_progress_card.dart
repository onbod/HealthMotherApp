import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:provider/provider.dart';
import '../providers/user_session_provider.dart';
import '../features/visits_screen.dart';
import 'package:intl/intl.dart';

class BabyProgressCard extends StatefulWidget {
  const BabyProgressCard({super.key});

  @override
  _BabyProgressCardState createState() => _BabyProgressCardState();
}

class _BabyProgressCardState extends State<BabyProgressCard>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _contentController;
  late Animation<double> _progressAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final Color highlightColor = const Color(0xFF7C4DFF);

  @override
  void initState() {
    super.initState();
    // Controller for progress bar animation
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Controller for content animations
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _progressAnimation.addListener(() {
      if (mounted) {
      setState(() {});
      }
    });

    // Reset and animate when widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _progressController.reset();
        _progressController.forward();
        _contentController.reset();
        _contentController.forward();
      }
    });
  }

  @override
  void didUpdateWidget(BabyProgressCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset animation when widget updates to show fresh animation
    if (mounted) {
      _progressController.reset();
      _progressController.forward();
      _contentController.reset();
      _contentController.forward();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  /// Get the appropriate baby image based on gestational week
  String _getBabyImage(int week) {
    if (week <= 7) return 'assets/images/week7.jpg';
    if (week <= 8) return 'assets/images/week8.jpg';
    if (week <= 9) return 'assets/images/week9.jpg';
    if (week <= 10) return 'assets/images/week10.jpg';
    if (week <= 11) return 'assets/images/week11.jpg';
    if (week <= 12) return 'assets/images/week12.png';
    if (week <= 15) return 'assets/images/week15.jpg';
    if (week <= 20) return 'assets/images/week20.png';
    if (week <= 25) return 'assets/images/week25.png';
    if (week <= 30) return 'assets/images/week30.png';
    if (week <= 35) return 'assets/images/week35.png';
    return 'assets/images/week40.png';
  }

  /// Calculate EDD from LMP or use stored EDD
  DateTime? _calculateEDD(UserSessionProvider userSession) {
    // First try to get EDD from pregnancy data (edd_date field)
    final preg = userSession.getCurrentPregnancy();
    if (preg != null) {
      // Try edd_date first
      if (preg['edd_date'] != null) {
        final eddDate = preg['edd_date'];
        if (eddDate is String) {
          final parsed = DateTime.tryParse(eddDate);
          if (parsed != null) return parsed;
        }
      }
      // Try edd field
      if (preg['edd'] != null) {
        final edd = preg['edd'];
        if (edd is String) {
          final parsed = DateTime.tryParse(edd);
          if (parsed != null) return parsed;
        }
      }
    }

    // Try getEdd() method
    final edd = userSession.getEdd();
    if (edd != null) return edd;

    // Calculate from LMP (LMP + 280 days = EDD)
    final lmp = userSession.getLmp();
    if (lmp != null) {
      return lmp.add(const Duration(days: 280));
    }

    // Last resort: calculate from current week if we have it
    final gaFromVisits = userSession.getLatestGestationalAge();
    if (gaFromVisits != null && gaFromVisits > 0) {
      final now = DateTime.now();
      final weeksRemaining = 40 - gaFromVisits;
      return now.add(Duration(days: weeksRemaining * 7));
    }

    return null;
  }

  /// Check if baby survived (for delivery cases)
  bool? _checkBabySurvival(UserSessionProvider userSession) {
    final delivery = userSession.getDelivery();
    if (delivery == null) return null;

    // Check delivery_outcome field
    final outcome = delivery['delivery_outcome']?.toString().toLowerCase();
    if (outcome == 'live_birth') return true;
    if (outcome == 'stillbirth' || outcome == 'miscarriage') return false;

    // Check outcome field
    final outcomeStr = delivery['outcome']?.toString().toLowerCase();
    if (outcomeStr != null) {
      if (outcomeStr.contains('live') || outcomeStr.contains('alive'))
        return true;
      if (outcomeStr.contains('stillbirth') ||
          outcomeStr.contains('dead') ||
          outcomeStr.contains('miscarriage'))
        return false;
    }

    // Check neonates - if there are any live neonates, baby survived
    final neonates = userSession.getNeonates();
    if (neonates.isNotEmpty) {
      // Assume neonates exist means baby survived unless explicitly marked otherwise
      return true;
    }

    return null; // Unknown
  }

  /// Get baby size estimate based on gestational week
  String _getBabySizeEstimate(int week) {
    if (week <= 8) return 'Size of a raspberry';
    if (week <= 12) return 'Size of a plum';
    if (week <= 16) return 'Size of an avocado';
    if (week <= 20) return 'Size of a banana';
    if (week <= 24) return 'Size of an ear of corn';
    if (week <= 28) return 'Size of an eggplant';
    if (week <= 32) return 'Size of a squash';
    if (week <= 36) return 'Size of a head of romaine lettuce';
    return 'Size of a watermelon';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserSessionProvider>(
      builder: (context, userSession, child) {
        try {
          final latestVisit = userSession.getLatestVisitNumber() ?? 1;
          final bool babyBorn = userSession.hasDelivered();

        // Determine current gestational week from schema (prioritize most accurate sources)
        int currentWeek = 1;
        final gaFromVisits = userSession.getLatestGestationalAge();
        if (gaFromVisits != null && gaFromVisits > 0) {
          // Most accurate: from latest ANC visit
          currentWeek = gaFromVisits.clamp(1, 40);
        } else {
          final preg = userSession.getCurrentPregnancy();
          if (preg != null && preg['current_gestation_weeks'] != null) {
            // Second priority: from pregnancy data
            final cg = preg['current_gestation_weeks'];
            if (cg is int) {
              currentWeek = cg.clamp(1, 40);
            } else if (cg is String) {
              currentWeek = (int.tryParse(cg) ?? 1).clamp(1, 40);
            } else if (cg is num) {
              currentWeek = cg.toInt().clamp(1, 40);
            }
          } else {
            // Last resort: calculate from LMP
            final lmp = userSession.getLmp();
            if (lmp != null) {
              final diffDays = DateTime.now().difference(lmp).inDays;
              currentWeek = (diffDays / 7).floor().clamp(1, 40);
            }
          }
        }

        // Calculate current gestational days
        // Use the week calculation * 7 for accuracy, don't rely on LMP difference alone
        // as it might be incorrect if LMP date is wrong
        int currentDays = currentWeek * 7;

        // Also check if we can get days from latest ANC visit for more precision
        final latestAncVisit = userSession.getLatestAncVisit();
        if (latestAncVisit != null) {
          // Try to get gestation_weeks from visit
          final visitWeeks =
              latestAncVisit['gestation_weeks'] ??
              latestAncVisit['gestational_age_weeks'] ??
              latestAncVisit['gestational_age'];
          if (visitWeeks != null) {
            int? weeks;
            if (visitWeeks is int) {
              weeks = visitWeeks;
            } else if (visitWeeks is String) {
              weeks = int.tryParse(visitWeeks);
            } else if (visitWeeks is num) {
              weeks = visitWeeks.toInt();
            }
            if (weeks != null && weeks > 0) {
              currentDays = weeks * 7;
              currentWeek = weeks.clamp(1, 40);
            }
          }

          // If visit has a visit_date, we can calculate days more precisely
          final visitDateStr = latestAncVisit['visit_date'];
          if (visitDateStr != null) {
            final visitDate = DateTime.tryParse(visitDateStr.toString());
            if (visitDate != null) {
              final visitWeeksFromVisit =
                  latestAncVisit['gestation_weeks'] ??
                  latestAncVisit['gestational_age_weeks'];
              if (visitWeeksFromVisit != null) {
                int? visitWeeksNum;
                if (visitWeeksFromVisit is int) {
                  visitWeeksNum = visitWeeksFromVisit;
                } else if (visitWeeksFromVisit is String) {
                  visitWeeksNum = int.tryParse(visitWeeksFromVisit);
                } else if (visitWeeksFromVisit is num) {
                  visitWeeksNum = visitWeeksFromVisit.toInt();
                }

                if (visitWeeksNum != null && visitWeeksNum > 0) {
                  // Calculate days since visit and add to gestational age at visit
                  final daysSinceVisit =
                      DateTime.now().difference(visitDate).inDays;
                  final daysAtVisit = visitWeeksNum * 7;
                  // Only clamp if baby hasn't been delivered yet
                  if (!babyBorn) {
                    currentDays = (daysAtVisit + daysSinceVisit).clamp(1, 280);
                    currentWeek = (currentDays / 7).floor().clamp(1, 40);
                  } else {
                    // If baby is born, show 280 (full term)
                    currentDays = 280;
                    currentWeek = 40;
                  }
                }
              }
            }
          }
        }

        // Only clamp if baby hasn't been delivered yet
        // If delivered, always show 280 (full term)
        if (babyBorn) {
          currentDays = 280;
          currentWeek = 40;
        } else {
          // Ensure days are within valid range for ongoing pregnancy
          currentDays = currentDays.clamp(1, 280);
          currentWeek = (currentDays / 7).ceil().clamp(1, 40);
        }

        // Debug: Print calculation details (only in debug mode to reduce spam)
        if (!kReleaseMode) {
          print('=== BABY PROGRESS CALCULATION ===');
          print('Baby Born: $babyBorn');
          print('Latest Gestational Age from Visits: $gaFromVisits');
          print('Current Week Calculated: $currentWeek');
          print('Current Days Calculated: $currentDays');
          if (latestAncVisit != null) {
            print('Latest Visit Date: ${latestAncVisit['visit_date']}');
            print(
              'Latest Visit Gestational Age: ${latestAncVisit['gestation_weeks'] ?? latestAncVisit['gestational_age_weeks']}',
            );
          }
          print('LMP Date: ${userSession.getLmp()}');
          print('=== END CALCULATION ===');
        }

        // Calculate EDD or Delivery Date
        final deliveryDate = userSession.getDeliveryDate();
        final expectedDueDate = _calculateEDD(userSession);
        final now = DateTime.now();

        // If baby is born, show delivery date; otherwise show expected due date
        final displayDate =
            babyBorn && deliveryDate != null ? deliveryDate : expectedDueDate;

        final dateLabel =
            babyBorn && deliveryDate != null
                ? 'Delivery Date'
                : 'Expected Due Date';

        final formattedDate =
            displayDate != null
                ? DateFormat('dd/MM/yyyy').format(displayDate)
                : 'Calculating...';

        // Calculate expected due days remaining (only if not delivered)
        final dueDaysRemaining =
            babyBorn
                ? null
                : (expectedDueDate != null
                    ? expectedDueDate.difference(now).inDays
                    : null);

        // Total pregnancy days (40 weeks)
        const totalDays = 280;

        // Calculate current visit (assuming 8 total visits)
        int currentVisit = latestVisit.clamp(1, 8);

        // Calculate progress percentage
        final progress =
            babyBorn ? 1.0 : (currentDays / totalDays).clamp(0.0, 1.0);

        // Check baby survival status
        final babySurvived = _checkBabySurvival(userSession);

        // Get the appropriate baby image based on the current week
        final babyImage = _getBabyImage(currentWeek);
        final babySizeEstimate = _getBabySizeEstimate(currentWeek);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: highlightColor.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: highlightColor.withOpacity(0.15),
                spreadRadius: 3,
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Top row: Visit, Progress, Days remaining
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                      // Left side: Visit information
                  GestureDetector(
                    onTap: () {
                          if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VisitsScreen(),
                        ),
                      );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: highlightColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: highlightColor,
                                size: 28,
                        ),
                              const SizedBox(height: 6),
                        Text(
                          'Visit',
                          style: TextStyle(
                                  fontSize: 12,
                            color: highlightColor,
                                  fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                                '$currentVisit/8',
                                style: TextStyle(
                                  fontSize: 20,
                            fontWeight: FontWeight.bold,
                                  color: highlightColor,
                          ),
                        ),
                      ],
                          ),
                    ),
                  ),
                  // Center: Circular Progress and Baby Image
                      GestureDetector(
                        onTap: () {
                          if (mounted && !babyBorn) {
                            // Navigate to visits screen to show baby progress details
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const VisitsScreen(),
                              ),
                            );
                          }
                        },
                        child: Stack(
                    alignment: Alignment.center,
                    children: [
                            AnimatedBuilder(
                              animation: _progressAnimation,
                              builder: (context, child) {
                                return SizedBox(
                                  width: 110,
                                  height: 110,
                        child: CircularProgressIndicator(
                          value: _progressAnimation.value * progress,
                                    strokeWidth: 12,
                                    backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            highlightColor,
                          ),
                        ),
                                );
                              },
                            ),
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: highlightColor.withOpacity(0.3),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: highlightColor.withOpacity(0.2),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                        child: Image.asset(
                          babyImage,
                                  width: 90,
                                  height: 90,
                          fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[200],
                                      child: Icon(
                                        Icons.child_care,
                                        color: highlightColor,
                                        size: 40,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            // Days indicator overlay
                            Positioned(
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: highlightColor,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: highlightColor.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Day $currentDays',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                      ),
                      // Right side: Days left or delivery message
                  babyBorn
                          ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  babySurvived == false
                                      ? Colors.grey.withOpacity(0.1)
                                      : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    babySurvived == false
                                        ? Colors.grey[400]!
                                        : Colors.green[300]!,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                        children: [
                          Icon(
                                  babySurvived == false
                                      ? Icons.favorite_border
                                      : Icons.celebration,
                                  color:
                                      babySurvived == false
                                          ? Colors.grey[700]
                                          : Colors.green[700],
                                  size: 28,
                                ),
                                const SizedBox(height: 6),
                          Text(
                                  babySurvived == false
                                      ? 'Your Delivery'
                                      : 'Your Delivery',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                    fontSize: 12,
                              fontWeight: FontWeight.bold,
                                    color:
                                        babySurvived == false
                                            ? Colors.grey[700]
                                            : Colors.green[700],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  babySurvived == false
                                      ? 'We\'re here\nfor you ❤️'
                                      : 'Congratulations!',
                            textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        babySurvived == false
                                            ? Colors.grey[600]
                                            : Colors.grey[700],
                                    fontStyle:
                                        babySurvived == false
                                            ? FontStyle.italic
                                            : FontStyle.normal,
                                  ),
                                ),
                              ],
                            ),
                      )
                      : GestureDetector(
                        onTap: () {
                              if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                    builder:
                                        (context) => const VisitsScreen(),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                        child: Column(
                          children: [
                                  Icon(
                                    Icons.timer,
                                    color: Colors.orange[700],
                                    size: 28,
                                  ),
                                  const SizedBox(height: 6),
                            Text(
                                    dueDaysRemaining != null
                                        ? dueDaysRemaining.toString()
                                        : '--',
                                    style: TextStyle(
                                      fontSize: 20,
                                fontWeight: FontWeight.bold,
                                      color: Colors.orange[700],
                              ),
                            ),
                            Text(
                                    'Days Left',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                              ),
                        ),
                      ),
                ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Divider
              FadeTransition(
                opacity: _fadeAnimation,
                child: Divider(color: Colors.grey[300], thickness: 1, height: 1),
              ),
              const SizedBox(height: 16),
              // Bottom row: EDD and baby size
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Expected Due Date
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: highlightColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                children: [
                              Icon(
                                babyBorn ? Icons.event : Icons.cake,
                                color: highlightColor,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  dateLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                  Text(
                            formattedDate,
                    style: TextStyle(
                              fontSize: 16,
                      color: highlightColor,
                      fontWeight: FontWeight.bold,
                    ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    // Baby Size
                    Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.pink.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    babyBorn
                                        ? Icons.child_care
                                        : Icons.auto_awesome,
                                    color: Colors.pink[600],
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      babyBorn ? 'Baby Status' : 'Development',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                babyBorn
                                    ? (babySurvived == false
                                        ? 'Our thoughts\nare with you'
                                        : 'Healthy & Well')
                                    : babySizeEstimate,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.pink[600],
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
        } catch (e, stackTrace) {
          print('BABY_PROGRESS: Error in build: $e');
          print('BABY_PROGRESS: Stack trace: $stackTrace');
          // Return a simple error widget instead of crashing
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red, width: 1),
            ),
            child: const Center(
              child: Text('Error loading progress'),
            ),
          );
        }
      },
    );
  }
}
