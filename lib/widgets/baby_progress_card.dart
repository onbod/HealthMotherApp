import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_session_provider.dart';
import '../features/visits_screen.dart';
import '../features/baby_progress_screen.dart'; // Added import for BabyProgressScreen

class BabyProgressCard extends StatefulWidget {
  // You might want to pass dynamic data to this widget later
  // final double progress;
  // final String length;
  // final String weight;
  // final String daysLeft;

  const BabyProgressCard({Key? key}) : super(key: key);

  @override
  _BabyProgressCardState createState() => _BabyProgressCardState();
}

class _BabyProgressCardState extends State<BabyProgressCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  final Color highlightColor = const Color(0xFF7C4DFF);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_controller);

    _progressAnimation.addListener(() {
      setState(() {});
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserSessionProvider>(
      builder: (context, userSession, child) {
        final latestVisit = userSession.getLatestVisitNumber() ?? 1;
        final bool babyBorn = userSession.hasDelivered();

        // Determine current gestational week from schema
        int currentWeek = 1;
        final gaFromVisits = userSession.getLatestGestationalAge();
        if (gaFromVisits != null) {
          currentWeek = gaFromVisits;
        } else {
          final preg = userSession.getCurrentPregnancy();
          if (preg != null && preg['current_gestation_weeks'] != null) {
            final cg = preg['current_gestation_weeks'];
            if (cg is int)
              currentWeek = cg;
            else if (cg is String) {
              currentWeek = int.tryParse(cg) ?? 1;
            }
          } else {
            final lmp = userSession.getLmp();
            if (lmp != null) {
              final diffDays = DateTime.now().difference(lmp).inDays;
              currentWeek = (diffDays / 7).floor().clamp(1, 40);
            }
          }
        }

        // Calculate remaining weeks and days
        const totalWeeks = 40;
        final remainingWeeks = totalWeeks - currentWeek;
        final remainingDays = remainingWeeks * 7;

        // Calculate remaining visits (assuming 8 total visits)
        int currentVisit = latestVisit;
        int remainingVisits = 8 - currentVisit;

        // Calculate progress percentage
        final progress = babyBorn ? 1.0 : currentWeek / totalWeeks;

        // Get the appropriate baby image based on the current week
        String babyImage = 'assets/images/week6.jpg'; // Default image
        if (currentWeek <= 7) {
          babyImage = 'assets/images/week7.jpg';
        } else if (currentWeek <= 8) {
          babyImage = 'assets/images/week8.jpg';
        }
        if (currentWeek <= 9) {
          babyImage = 'assets/images/week9.jpg';
        } else if (currentWeek <= 10) {
          babyImage = 'assets/images/week10.jpg';
        }
        if (currentWeek <= 11) {
          babyImage = 'assets/images/week11.jpg';
        } else if (currentWeek <= 12) {
          babyImage = 'assets/images/week12.png';
        }
        if (currentWeek <= 15) {
          babyImage = 'assets/images/week15.jpg';
        } else if (currentWeek <= 20) {
          babyImage = 'assets/images/week20.png';
        } else if (currentWeek <= 25) {
          babyImage = 'assets/images/week25.png';
        } else if (currentWeek <= 30) {
          babyImage = 'assets/images/week30.png';
        } else if (currentWeek <= 35) {
          babyImage = 'assets/images/week35.png';
        } else {
          babyImage = 'assets/images/week40.png';
        }

        print('\n=== BABY PROGRESS DEBUG INFO ===');
        print('Current visit: $currentVisit');
        print('Current week: $currentWeek');
        print('Remaining visits: $remainingVisits');
        print('=== END BABY PROGRESS DEBUG INFO ===\n');

        // Calculate expected due date (EDD)
        int gestationalAgeWeeks = currentWeek;
        final now = DateTime.now();
        final daysToAdd = (40 - gestationalAgeWeeks) * 7;
        final expectedDueDate = now.add(Duration(days: daysToAdd));
        final formattedEdd =
            "${expectedDueDate.day.toString().padLeft(2, '0')}/${expectedDueDate.month.toString().padLeft(2, '0')}/${expectedDueDate.year}";

        // Calculate expected due days remaining
        final dueDaysRemaining = expectedDueDate.difference(now).inDays;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left side: Contact information
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VisitsScreen(),
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: highlightColor,
                          size: 30,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Visit',
                          style: TextStyle(
                            fontSize: 14,
                            color: highlightColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$currentVisit',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Center: Circular Progress and Baby Image
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: CircularProgressIndicator(
                          value: _progressAnimation.value * progress,
                          strokeWidth: 14,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            highlightColor,
                          ),
                        ),
                      ),
                      ClipOval(
                        child: Image.asset(
                          babyImage,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                  // Right side: Days left information
                  babyBorn
                      ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.celebration,
                            color: highlightColor,
                            size: 30,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Congratulations!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: highlightColor,
                            ),
                          ),
                          const Text(
                            'Your baby\nhas been born.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      )
                      : GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BabyProgressScreen(),
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            Icon(Icons.timer, color: highlightColor, size: 30),
                            const SizedBox(height: 8),
                            Text(
                              dueDaysRemaining.toString(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'Expected due\ndays remaining',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cake, color: highlightColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Expected Due Date: ',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  Text(
                    formattedEdd,
                    style: TextStyle(
                      fontSize: 15,
                      color: highlightColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
