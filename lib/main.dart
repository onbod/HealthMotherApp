import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth/main_login_screen.dart';
import 'auth/login_screen.dart';
import 'auth/auth_screen.dart';
import 'features/onboarding_screen.dart';
import 'features/home_screen.dart';
import 'features/pin_lock_screen.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/user_session_provider.dart';
import 'firebase_options.dart';
import 'package:healthymamaapp/services/notification_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:healthymamaapp/widgets/global_navigation.dart';
import 'features/pin_setup_screen.dart';
import 'features/pin_verification_screen.dart';
import 'package:healthymamaapp/services/local_notification_manager.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:healthymamaapp/services/alarm_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    if (!kIsWeb) {
      await AndroidAlarmManager.initialize();
    }
    print('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');

    print('Initializing notifications...');
    try {
      final notificationService = NotificationService();
      print('NotificationService instance created');

      await notificationService.init();
      print('NotificationService initialized successfully');

      // Schedule periodic check for medication reminders
      await notificationService.schedulePeriodicMedicationNotifications();

      // LocalNotificationManager: handle app launch (welcome notification)
      await LocalNotificationManager().handleAppLaunch();
      print('LocalNotificationManager handleAppLaunch called');

      // Schedule a reminder notification for 3 days later
      await notificationService.scheduleReminderNotification(
        title: 'We miss you!',
        body: 'Come back and check out new health tips and features!',
        scheduledTime: DateTime.now().add(const Duration(days: 3)),
      );
      print('Reminder notification scheduled successfully');
      print('Notifications initialized and reminder scheduled successfully');
    } catch (e) {
      print('Warning: Failed to initialize notifications: $e');
      print('Error details: ${e.toString()}');
      // Continue app initialization even if notifications fail
    }

    runApp(const MyApp());
  } catch (e, stackTrace) {
    print('Error during app initialization: $e');
    print('Stack trace: $stackTrace');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Error initializing app'),
                const SizedBox(height: 16),
                Text(e.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Restart the app
                    main();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => UserSessionProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Healthy Mother',
            theme: themeProvider.theme,
            navigatorKey: navigatorKey,
            home: const AuthWrapper(),
            routes: {
              '/onboarding': (context) => const OnboardingScreen(),
              '/main_login': (context) => const MainLoginScreen(),
              '/login': (context) => const LoginScreen(),
              '/auth': (context) => const AuthScreen(),
              '/home': (context) => const HomeScreen(),
              '/pin_setup': (context) => const PinSetupScreen(),
              '/pin_verify': (context) => const PinVerificationScreen(),
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  bool _showPinScreen = false;
  bool _isFirstLaunch = false;
  bool _sessionRestored = false;
  bool _webPatientRestored = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkFirstLaunch();
    _checkPinStatus();
    _restoreWebPatientSession();
    _restoreSession();
  }

  Future<void> _restoreWebPatientSession() async {
    if (kIsWeb) {
      final userSessionProvider = Provider.of<UserSessionProvider>(
        context,
        listen: false,
      );
      await userSessionProvider.restorePatientFromStorage();
      setState(() {
        _webPatientRestored = true;
      });
    } else {
      _webPatientRestored = true;
    }
  }

  Future<void> _restoreSession() async {
    final userSessionProvider = Provider.of<UserSessionProvider>(
      context,
      listen: false,
    );
    await userSessionProvider.restoreOrFetchSession();
    setState(() {
      _sessionRestored = true;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;
    setState(() {
      _isFirstLaunch = isFirstLaunch;
    });
  }

  Future<void> _checkPinStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final pinSetupCompleted = prefs.getBool('pin_setup_completed') ?? false;
    final hasPin = prefs.getString('user_pin') != null;

    setState(() {
      _showPinScreen = pinSetupCompleted && hasPin;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPinStatus();
      _stopLingeringAlarms();
    }
  }

  Future<void> _stopLingeringAlarms() async {
    try {
      await AlarmService.stop();
      print('Stopped any lingering alarms on app resume via platform channel.');
    } catch (e) {
      print('Error stopping lingering alarms: $e');
    }
  }

  Future<void> _loadUserSession(User user) async {
    final userSessionProvider = Provider.of<UserSessionProvider>(
      context,
      listen: false,
    );
    try {
      final phoneNumber = user.phoneNumber ?? user.email;
      if (phoneNumber != null) {
        await userSessionProvider.loadUserData(phoneNumber);
      }
    } catch (e) {
      print('Error loading user session: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_sessionRestored || !_webPatientRestored) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_isFirstLaunch) {
      return const OnboardingScreen();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          // Load user session data when authenticated
          _loadUserSession(snapshot.data!);

          if (_showPinScreen && !kIsWeb) {
            return const PinLockScreen();
          }
          return const GlobalNavigation(currentIndex: 0, child: HomeScreen());
        }

        // NEW: Try to restore local session if not authenticated
        final userSessionProvider = Provider.of<UserSessionProvider>(
          context,
          listen: false,
        );
        return FutureBuilder<bool>(
          future: userSessionProvider.tryRestoreSession(),
          builder: (context, localSnapshot) {
            if (localSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            // On web, if we have patient data in provider, go to Home
            if (kIsWeb && userSessionProvider.patient != null) {
              return const GlobalNavigation(
                currentIndex: 0,
                child: HomeScreen(),
              );
            }
            if (localSnapshot.data == true) {
              if (_showPinScreen && !kIsWeb) {
                return const PinLockScreen();
              }
              return const GlobalNavigation(
                currentIndex: 0,
                child: HomeScreen(),
              );
            }
            return const MainLoginScreen();
          },
        );
      },
    );
  }
}
