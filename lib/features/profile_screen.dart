import 'package:flutter/material.dart';
import '../widgets/shared_app_bar.dart';
import '../widgets/global_navigation.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GlobalNavigation(
      currentIndex: 3,
      child: Scaffold(
        appBar: SharedAppBar(
          userName: 'Profile',
          userInitials: 'PR',
          visitNumber: '',
          showNextVisit: false,
        ),
        body: const Center(child: Text('Profile Screen - Coming Soon')),
      ),
    );
  }
}
