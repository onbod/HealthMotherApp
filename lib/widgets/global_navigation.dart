import 'package:flutter/material.dart';
import '../features/home_screen.dart';
import '../features/medication_screen.dart';
import '../features/visits_screen.dart';
import '../features/resources_screen.dart';
// Removed DAK dashboard import as navigation no longer includes DAK

class GlobalNavigation extends StatefulWidget {
  final int currentIndex;
  final Widget child;

  const GlobalNavigation({
    Key? key,
    required this.currentIndex,
    required this.child,
  }) : super(key: key);

  @override
  State<GlobalNavigation> createState() => _GlobalNavigationState();
}

class _GlobalNavigationState extends State<GlobalNavigation> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
  }

  void _onItemTapped(int index) {
    if (_currentIndex == index) return;

    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MedicationScreen()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const VisitsScreen()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ResourcesScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom:
                MediaQuery.of(context).viewPadding.bottom > 0
                    ? 0
                    : 2, // Add 2px padding when no system bottom padding
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFF7C4DFF),
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                icon: Icon(Icons.medication),
                label: 'Medication',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month),
                label: 'Visits',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.library_books),
                label: 'Resources',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
