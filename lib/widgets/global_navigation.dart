import 'package:flutter/material.dart';
import '../features/home_screen.dart';
import '../features/medication_screen.dart';
import '../features/visits_screen.dart';
import '../features/resources_screen.dart';

class GlobalNavigation extends StatefulWidget {
  final int currentIndex;
  final Widget child;

  const GlobalNavigation({
    super.key,
    required this.currentIndex,
    required this.child,
  });

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Use side navigation on wide screens (web/desktop)
    final bool usesSideNav = screenWidth >= 800;
    
    if (usesSideNav) {
      // Wide screen: Use NavigationRail on the left
      // Don't wrap in Scaffold - just use Row with the child
      return Row(
        children: [
          // Side Navigation Rail
          Material(
            elevation: 2,
            child: Container(
              color: Colors.white,
              child: NavigationRail(
                selectedIndex: _currentIndex,
                onDestinationSelected: _onItemTapped,
                labelType: NavigationRailLabelType.all,
                backgroundColor: Colors.transparent,
                minWidth: 80,
                selectedIconTheme: const IconThemeData(
                  color: Color(0xFF7C4DFF),
                  size: 26,
                ),
                selectedLabelTextStyle: const TextStyle(
                  color: Color(0xFF7C4DFF),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                unselectedIconTheme: IconThemeData(
                  color: Colors.grey[600],
                  size: 24,
                ),
                unselectedLabelTextStyle: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
                leading: Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 24),
                  child: Image.asset(
                    'assets/icon/new_Icon.png',
                    height: 48,
                    errorBuilder: (context, error, stackTrace) => Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C4DFF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Color(0xFF7C4DFF),
                        size: 32,
                      ),
                    ),
                  ),
                ),
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.home_outlined, color: Colors.grey[600]),
                    selectedIcon: const Icon(Icons.home, color: Color(0xFF7C4DFF)),
                    label: const Text('Home'),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.medication_outlined, color: Colors.grey[600]),
                    selectedIcon: const Icon(Icons.medication, color: Color(0xFF7C4DFF)),
                    label: const Text('Medication'),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.calendar_month_outlined, color: Colors.grey[600]),
                    selectedIcon: const Icon(Icons.calendar_month, color: Color(0xFF7C4DFF)),
                    label: const Text('Visits'),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.menu_book_outlined, color: Colors.grey[600]),
                    selectedIcon: const Icon(Icons.menu_book, color: Color(0xFF7C4DFF)),
                    label: const Text('Resources'),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ],
              ),
            ),
          ),
          // Main Content - the child already has its own Scaffold
          Expanded(child: widget.child),
        ],
      );
    }
    
    // Mobile: Use bottom navigation
    // The child already has its own Scaffold, so we wrap it to add bottom nav
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: theme.bottomNavigationBarTheme.backgroundColor ??
                theme.scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom:
                  MediaQuery.of(context).viewPadding.bottom > 0
                      ? 0
                      : 2,
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: const Color(0xFF7C4DFF),
              unselectedItemColor: isDark ? Colors.grey[400] : Colors.grey[600],
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
      ),
    );
  }
}
