import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/shared_app_bar.dart';
import '../widgets/global_navigation.dart';
import '../providers/user_session_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BabyProgressScreen extends StatelessWidget {
  const BabyProgressScreen({Key? key}) : super(key: key);

  int calculateCurrentWeek(UserSessionProvider userSession) {
    // --- WeekSelector logic ---
    List<Map<String, dynamic>> visits = [];
    for (int i = 1; i <= 8; i++) {
      final visit = userSession.getVisitData(i);
      if (visit != null && visit['presentPregnancy'] != null) {
        final presentPregnancy = visit['presentPregnancy'];
        final dateOfAncContact = presentPregnancy['dateOfAncContact'];
        final gestationalAge = presentPregnancy['gestationalAge'];
        if (dateOfAncContact != null && gestationalAge != null) {
          DateTime contactDate;
          try {
            contactDate = dateOfAncContact is DateTime
                ? dateOfAncContact
                : DateTime.fromMillisecondsSinceEpoch(
                    (dateOfAncContact as Timestamp).millisecondsSinceEpoch,
                  );
          } catch (e) {
            continue;
          }
          visits.add({
            'visitNumber': i,
            'contactDate': contactDate,
            'gestationalAge': gestationalAge,
          });
        }
      }
    }
    if (visits.isEmpty) return 1;
    visits.sort((a, b) => a['visitNumber'].compareTo(b['visitNumber']));
    final baseVisit = visits.last;
    int baseWeek = baseVisit['gestationalAge'] is num
        ? baseVisit['gestationalAge'].toInt()
        : int.tryParse(baseVisit['gestationalAge'].toString()) ?? 1;
    DateTime baseDate = baseVisit['contactDate'];
    final now = DateTime.now();
    int currentWeek;
    if (baseDate.isAfter(now)) {
      currentWeek = baseWeek;
    } else {
      final daysSinceBase = now.difference(baseDate).inDays;
      final additionalWeeks = (daysSinceBase / 7).floor();
      currentWeek = (baseWeek + additionalWeeks).clamp(1, 40);
    }
    return currentWeek;
  }

  @override
  Widget build(BuildContext context) {
    final Color highlightColor = const Color(0xFF7C4DFF);
    final userSession = Provider.of<UserSessionProvider>(context);
    final bool babyBorn = userSession.hasDelivered();
    final int currentWeek = calculateCurrentWeek(userSession);
    const int totalWeeks = 40;
    final int remainingWeeks = totalWeeks - currentWeek;
    final int remainingDays = remainingWeeks * 7;
    final double progress = babyBorn ? 1.0 : currentWeek / totalWeeks;
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
    return GlobalNavigation(
      currentIndex: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: const SharedAppBar(
          visitNumber: 'Resources',
          // No screenTitle, so no 'Baby Progress' text
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Week $currentWeek (${remainingWeeks} weeks remaining)',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 18,
                        backgroundColor: Colors.grey[300],
                        valueColor:
                            AlwaysStoppedAnimation<Color>(highlightColor),
                      ),
                    ),
                    ClipOval(
                      child: Image.asset(
                        babyImage,
                        width: 140,
                        height: 140,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  '$remainingDays days remaining until due date',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 16,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(highlightColor),
                ),
                const SizedBox(height: 16),
                Text(
                  '${(progress * 100).toStringAsFixed(1)}% completed',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
