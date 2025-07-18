import 'package:flutter/material.dart';
import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';
import '../widgets/shared_app_bar.dart';
import '../widgets/global_navigation.dart';
import 'first_aid_assistance_screen.dart';
import '../widgets/week_selector.dart';
import '../widgets/baby_progress_card.dart';
import '../widgets/health_videos_section.dart';
import '../widgets/health_tips_carousel.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_screen.dart'; // Import the LoginScreen
import 'package:firebase_core/firebase_core.dart'; // Import firebase_core
import 'notifications_screen.dart';
import '../providers/user_session_provider.dart';
import '../services/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../screens/alarm_page.dart';
import 'package:healthymamaapp/services/alarm_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'nutrition_tips_screen.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'messages_screen.dart';
import 'chat_screen.dart';
import 'package:intl/intl.dart'; // For date formatting

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter is initialized
  await Firebase.initializeApp(); // Initialize Firebase

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: [],
  ); // Hide status and navigation bars
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Make status bar transparent
      statusBarIconBrightness: Brightness.dark, // Dark icons for Android
      statusBarBrightness: Brightness.light, // Dark text for iOS
    ),
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const HealthTipsApp(),
    ),
  );
}

class HealthTipsApp extends StatelessWidget {
  const HealthTipsApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Health Tips',
      theme: themeProvider.theme,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return const HomeScreen(); // Navigate to HomeScreen (reverted)
          } else {
            return const LoginScreen();
          }
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _tabIndex = 0;
  final Color primaryColor = const Color(0xFF7C4DFF);
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  DateTime? _lastRefreshTime; // Add this line to track last refresh time
  Offset _fabPosition = const Offset(0, 0);
  bool _isFabPositionInitialized = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Exit App'),
                content: const Text('Do you want to exit the app?'),
                actions: <Widget>[
                  TextButton(
                    onPressed:
                        () => Navigator.of(context).pop(false), // Stay in app
                    child: const Text('No'),
                  ),
                  TextButton(
                    onPressed: () {
                      // Exit the application
                      SystemNavigator.pop(); // Use SystemNavigator.pop() to close the app
                    },
                    child: const Text('Yes'),
                  ),
                ],
              ),
        )) ??
        false; // In case dialog is dismissed by tapping outside
  }

  Future<void> _testAlarm() async {
    await AlarmService.start();
  }

  Future<void> _stopTestAlarm() async {
    await AlarmService.stop();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (!_isFabPositionInitialized) {
      // Set initial FAB position in the bottom right corner
      _fabPosition = Offset(screenWidth - 72, screenHeight - 240);
      _isFabPositionInitialized = true;
    }

    return GlobalNavigation(
      currentIndex: 0,
      child: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          backgroundColor: const Color(0xFFF3F4F6),
          appBar: SharedAppBar(
            visitNumber: 'Home',
            isHomeScreen: true,
            onNotificationPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
          body: Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async {
                  // Add debounce to prevent rapid refreshes
                  final now = DateTime.now();
                  if (_lastRefreshTime != null &&
                      now.difference(_lastRefreshTime!).inSeconds < 5) {
                    return; // Skip refresh if less than 5 seconds since last refresh
                  }
                  _lastRefreshTime = now;

                  // Trigger a refresh of user data from Firestore
                  final userSession = Provider.of<UserSessionProvider>(
                    context,
                    listen: false,
                  );
                  final phoneNumber = userSession.getPhoneNumber();
                  if (phoneNumber != null) {
                    await userSession.refreshUserData(phoneNumber);
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- FIXED WIDGETS (Next Contact Section and Week Selector) ---
                    // Next Contact Section (Old design, updated with new info)
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Consumer<UserSessionProvider>(
                                builder: (context, userSession, child) {
                                  final nextVisitDate =
                                      userSession.getNextVisitDate() ??
                                      userSession
                                          .calculateNextVisitDateFromGuidelines();
                                  final latestVisit =
                                      userSession.getLatestVisitNumber() ?? 0;

                                  String displayText =
                                      'Next Contact: Not scheduled';
                                  Color textColor = const Color(0xFF7C4DFF);

                                  if (userSession.hasDelivered()) {
                                    displayText =
                                        'Congratulations on your delivery!';
                                    textColor = Colors.green;
                                  } else if (latestVisit >= 8) {
                                    displayText = 'Completed All 8 visits';
                                    textColor = Colors.green;
                                  } else if (nextVisitDate != null) {
                                    displayText =
                                        'Next Contact: ' +
                                        DateFormat(
                                          'dd/MM/yyyy',
                                        ).format(nextVisitDate);
                                    textColor = const Color(0xFF7C4DFF);
                                  }
                                  return Text(
                                    displayText,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // WeekSelector is now fixed
                    const WeekSelector(),

                    const SizedBox(
                      height: 16,
                    ), // Margin between fixed and scrollable
                    // --- SCROLLABLE CONTENT ---
                    Expanded(
                      child: SingleChildScrollView(
                        physics:
                            const AlwaysScrollableScrollPhysics(), // Important for RefreshIndicator
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Add BabyProgressCard here
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.04,
                              ),
                              child: const BabyProgressCard(),
                            ),
                            SizedBox(height: screenHeight * 0.02),

                            // Health Videos Section
                            const HealthVideosSection(),
                            SizedBox(height: screenHeight * 0.02),

                            // Health Tips Carousel
                            const HealthTipsCarousel(),
                            SizedBox(height: screenHeight * 0.02),

                            // Nutrition Tips Carousel (new)
                            NutritionTipsCarousel(),
                            SizedBox(height: screenHeight * 0.02),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: _fabPosition.dx,
                top: _fabPosition.dy,
                child: Draggable(
                  feedback: SpeedDial(
                    icon: Icons.smart_toy_rounded,
                    activeIcon: Icons.close,
                    backgroundColor: primaryColor.withOpacity(0.5),
                    foregroundColor: Colors.white,
                    activeBackgroundColor: primaryColor.withOpacity(0.5),
                    activeForegroundColor: Colors.white,
                    buttonSize: const Size(60, 50),
                    visible: true,
                    closeManually: false,
                    curve: Curves.bounceIn,
                    overlayColor: Colors.black,
                    overlayOpacity: 0.5,
                    elevation: 8.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    children: [],
                  ),
                  childWhenDragging: Container(),
                  onDragEnd: (details) {
                    setState(() {
                      final appBarHeight = AppBar().preferredSize.height;
                      final statusBarHeight =
                          MediaQuery.of(context).viewPadding.top;

                      // Clamp the position to be within the screen bounds
                      final newDx = details.offset.dx.clamp(
                        0.0,
                        screenWidth - 60,
                      ); // 60 is FAB width
                      final newDy = (details.offset.dy -
                              appBarHeight -
                              statusBarHeight)
                          .clamp(
                            0.0,
                            screenHeight -
                                appBarHeight -
                                statusBarHeight -
                                50 - // FAB height
                                80,
                          ); // Bottom nav bar height

                      _fabPosition = Offset(newDx, newDy);
                    });
                  },
                  child: SpeedDial(
                    icon: Icons.smart_toy_rounded,
                    activeIcon: Icons.close,
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    activeBackgroundColor: primaryColor,
                    activeForegroundColor: Colors.white,
                    buttonSize: const Size(60, 50),
                    visible: true,
                    closeManually: false,
                    curve: Curves.bounceIn,
                    overlayColor: Colors.black,
                    overlayOpacity: 0.5,
                    elevation: 8.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    children: [
                      SpeedDialChild(
                        child: const Icon(Icons.smart_toy_rounded),
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        label: 'Chatbot',
                        labelStyle: const TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        labelBackgroundColor: primaryColor,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => const FirstAidAssistanceScreen(),
                            ),
                          );
                        },
                      ),
                      SpeedDialChild(
                        child: const Icon(Icons.chat_bubble_outline),
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        label: 'Chat',
                        labelStyle: const TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        labelBackgroundColor: primaryColor,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ChatScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HealthTipCard extends StatelessWidget {
  final String text;
  final String tipLabel;

  const _HealthTipCard({Key? key, required this.text, required this.tipLabel})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(minHeight: 120, maxHeight: 180),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: screenWidth < 400 ? 14 : 12,
                  height: 1.3,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              tipLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NutritionTipsCarousel extends StatelessWidget {
  const NutritionTipsCarousel({Key? key}) : super(key: key);

  Future<List<NutritionTip>> _fetchNutritionTips() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('nutrition-tips').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return NutritionTip(
        title: data['title'] ?? '',
        description: data['description'] ?? data['content'] ?? '',
        icon: Icons.spa, // Default icon, or map if you store icon info
        color: Colors.green, // Default color, or map if you store color info
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final screenWidth = MediaQuery.of(context).size.width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nutrition Tips',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NutritionTipsScreen(),
                    ),
                  );
                },
                child: Text('View All', style: TextStyle(color: primaryColor)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: FutureBuilder<List<NutritionTip>>(
            future: _fetchNutritionTips(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Failed to load nutrition tips'));
              }
              final nutritionTips = snapshot.data ?? [];
              if (nutritionTips.isEmpty) {
                return Center(child: Text('No nutrition tips available'));
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: nutritionTips.length,
                itemBuilder: (context, index) {
                  final tip = nutritionTips[index];
                  final cardWidth =
                      screenWidth < 340
                          ? screenWidth - 32
                          : (screenWidth < 400 ? screenWidth - 48 : 280);
                  return Container(
                    width: (cardWidth > 320 ? 320 : cardWidth).toDouble(),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: InkWell(
                        onTap: () {
                          _showTipDetails(context, tip);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(12), // Reduced from 16
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(
                                      6,
                                    ), // Reduced from 8
                                    decoration: BoxDecoration(
                                      color: tip.color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      tip.icon,
                                      color: tip.color,
                                      size: 20, // Reduced from 24
                                    ),
                                  ),
                                  const SizedBox(width: 8), // Reduced from 12
                                  Expanded(
                                    child: Text(
                                      tip.title,
                                      style: const TextStyle(
                                        fontSize: 14, // Reduced from 16
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8), // Reduced from 12
                              Expanded(
                                // Added Expanded to prevent overflow
                                child: Text(
                                  tip.description,
                                  style: TextStyle(
                                    fontSize: 13, // Reduced from 14
                                    color: Colors.grey[700],
                                    height: 1.3, // Reduced from 1.4
                                  ),
                                  maxLines: 3, // Reduced from 4
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 8), // Reduced from 12
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      _showTipDetails(context, tip);
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ), // Reduced padding
                                      minimumSize:
                                          Size.zero, // Allow button to be smaller
                                      tapTargetSize:
                                          MaterialTapTargetSize
                                              .shrinkWrap, // Reduce tap target
                                    ),
                                    child: Text(
                                      'Read More',
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontSize: 12, // Reduced font size
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showTipDetails(BuildContext context, NutritionTip tip) {
    final primaryColor = Theme.of(context).primaryColor;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: tip.color.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(tip.icon, color: tip.color, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          tip.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Text(
                        tip.description,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

class NutritionTip {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  NutritionTip({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
