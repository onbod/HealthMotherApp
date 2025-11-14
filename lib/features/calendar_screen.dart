import 'package:flutter/material.dart';
import '../widgets/shared_app_bar.dart';
import '../widgets/global_navigation.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GlobalNavigation(
      currentIndex: 1,
      child: Scaffold(
        appBar: SharedAppBar(
          userName: 'Calendar',
          userInitials: 'CA',
          visitNumber: '',
          showNextVisit: false,
        ),
        body: const Center(child: Text('Calendar Screen - Coming Soon')),
      ),
    );
  }
}
