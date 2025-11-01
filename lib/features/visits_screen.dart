import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/shared_app_bar.dart';
import '../widgets/global_navigation.dart';
import '../providers/user_session_provider.dart';
import 'package:flutter_animate/flutter_animate.dart'; // For animations
import 'contact_details_screen.dart'; // New screen for contact details
import 'pin_verification_screen.dart'; // Import for PIN dialog
import 'package:shared_preferences/shared_preferences.dart';
import 'pin_lock_screen.dart'; // Import for PIN lock screen
import 'package:intl/intl.dart'; // Added for date formatting
import 'package:flutter/foundation.dart' show kIsWeb;

class VisitsScreen extends StatefulWidget {
  const VisitsScreen({Key? key}) : super(key: key);

  @override
  State<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends State<VisitsScreen> {
  final Color primaryColor = const Color(0xFF7C4DFF);

  Future<bool> _showPinDialog(BuildContext context) async {
    String pin = '';
    String error = '';
    bool isLoading = false;
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: const Text('Enter PIN'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (i) {
                          return Container(
                            width: 40,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: TextField(
                              autofocus: i == 0,
                              obscureText: true,
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              textAlign: TextAlign.center,
                              onChanged: (val) {
                                if (val.length == 1) {
                                  if (pin.length > i) {
                                    pin =
                                        pin.substring(0, i) +
                                        val +
                                        pin.substring(i + 1);
                                  } else if (pin.length == i) {
                                    pin += val;
                                  }
                                  if (i < 3) {
                                    FocusScope.of(context).nextFocus();
                                  }
                                } else if (val.isEmpty && i > 0) {
                                  FocusScope.of(context).previousFocus();
                                }
                              },
                              onSubmitted: (_) {
                                if (i == 3) {
                                  setState(() {});
                                }
                              },
                              decoration: InputDecoration(
                                counterText: '',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      if (error.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            error,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed:
                          isLoading
                              ? null
                              : () async {
                                setState(() => isLoading = true);
                                final prefs =
                                    await SharedPreferences.getInstance();
                                final savedPin = prefs.getString('user_pin');
                                if (pin.length == 4 && savedPin == pin) {
                                  Navigator.of(context).pop(true);
                                } else {
                                  setState(() {
                                    error = 'Incorrect PIN. Please try again.';
                                    isLoading = false;
                                  });
                                }
                              },
                      child:
                          isLoading
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('OK'),
                    ),
                  ],
                );
              },
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return GlobalNavigation(
      currentIndex: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
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
        body: Column(
          children: [
            // Next Contact Section
            Center(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Consumer<UserSessionProvider>(
                      builder: (context, userSession, child) {
                        final nextVisitDate =
                            userSession.getNextVisitDate() ??
                            userSession.calculateNextVisitDateFromGuidelines();
                        final latestVisit =
                            userSession.getLatestVisitNumber() ?? 0;

                        String displayText = 'Next Visit: Not scheduled';
                        Color textColor = const Color(0xFF7C4DFF);

                        if (latestVisit >= 8) {
                          displayText = 'Completed All 8 visits';
                          textColor = Colors.green;
                        } else if (nextVisitDate != null) {
                          displayText =
                              'Next Visit: ' +
                              DateFormat('dd/MM/yyyy').format(nextVisitDate);
                          textColor = const Color(0xFF7C4DFF);
                        }
                        return Text(
                          displayText,
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Grid for 8 Contact Cards
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Consumer<UserSessionProvider>(
                  builder: (context, userSession, child) {
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: kIsWeb ? 3 : 2, // More columns on web
                        crossAxisSpacing: 16.0,
                        mainAxisSpacing: 16.0,
                        childAspectRatio:
                            kIsWeb ? 1.4 : 1.0, // Wider, shorter boxes on web
                      ),
                      itemCount: 8,
                      itemBuilder: (context, index) {
                        final int contactNumber = index + 1;
                        // Find the anc_visit with this visit_number
                        final visitData = userSession.ancVisits.firstWhere(
                          (v) => v['visit_number'] == contactNumber,
                          orElse: () => <String, dynamic>{},
                        );
                        final bool isCompleted = visitData.isNotEmpty;
                        String gestationalAgeRange = '';
                        if (isCompleted &&
                            visitData['gestational_age'] != null) {
                          gestationalAgeRange =
                              visitData['gestational_age'].toString();
                        }
                        bool isFlagged =
                            false; // You can add your own flag logic here
                        return GestureDetector(
                          onTap:
                              isCompleted
                                  ? () async {
                                    print('Visit $contactNumber tapped');
                                    if (kIsWeb) {
                                      print(
                                        'Web: Skipping PIN, navigating directly to ContactDetailsScreen for visit $contactNumber',
                                      );
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => ContactDetailsScreen(
                                                contactNumber: contactNumber,
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
                                              ),
                                        ),
                                      );
                                      print('PIN result: $pinOk');
                                      if (pinOk == true) {
                                        print(
                                          'Navigating to ContactDetailsScreen for visit $contactNumber',
                                        );
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    ContactDetailsScreen(
                                                      contactNumber:
                                                          contactNumber,
                                                    ),
                                          ),
                                        );
                                      } else {
                                        print(
                                          'PIN not correct or cancelled, staying on VisitsScreen',
                                        );
                                      }
                                    }
                                  }
                                  : null,
                          child: AnimatedContainer(
                            duration: 300.ms,
                            curve: Curves.easeOut,
                            decoration: BoxDecoration(
                              color:
                                  isCompleted
                                      ? primaryColor.withOpacity(0.1)
                                      : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    isCompleted
                                        ? primaryColor
                                        : Colors.grey[400]!,
                                width: 1.5,
                              ),
                              boxShadow:
                                  isCompleted
                                      ? [
                                        BoxShadow(
                                          color: primaryColor.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                      : null,
                            ),
                            child: Stack(
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Animate(
                                      effects:
                                          isCompleted
                                              ? [
                                                ScaleEffect(
                                                  duration: 500.ms,
                                                  curve: Curves.easeOut,
                                                ),
                                                FadeEffect(
                                                  duration: 500.ms,
                                                  curve: Curves.easeOut,
                                                ),
                                              ]
                                              : [],
                                      child: Icon(
                                        isCompleted
                                            ? Icons.check_circle
                                            : Icons.lock,
                                        color: primaryColor,
                                        size:
                                            kIsWeb
                                                ? 32
                                                : 48, // Smaller icon on web
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Visit $contactNumber',
                                      style: TextStyle(
                                        fontSize: kIsWeb ? 14 : 18,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            isCompleted
                                                ? primaryColor
                                                : Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '($gestationalAgeRange)',
                                      style: TextStyle(
                                        fontSize: kIsWeb ? 10 : 12,
                                        color:
                                            isCompleted
                                                ? primaryColor.withOpacity(0.8)
                                                : Colors.grey[500],
                                      ),
                                    ),
                                    if (!isCompleted)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                        ),
                                        child: Text(
                                          'Not completed',
                                          style: TextStyle(
                                            color: Colors.red[400],
                                            fontWeight: FontWeight.w600,
                                            fontSize: kIsWeb ? 11 : 13,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                AnimatedPositioned(
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.easeOutCubic,
                                  left: 0,
                                  right: 0,
                                  bottom: isFlagged ? 0 : -16,
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 350),
                                    opacity: isFlagged ? 1.0 : 0.0,
                                    child: Container(
                                      height: 12,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFD32F2F), // Deep red
                                            Color(0xFFFF7043), // Orange-red
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.red.withOpacity(0.4),
                                            blurRadius: 12,
                                            spreadRadius: 2,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft: Radius.circular(12),
                                          bottomRight: Radius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate(
                          effects: [
                            FadeEffect(duration: 500.ms, curve: Curves.easeIn),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
