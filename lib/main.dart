import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode, FlutterError, FlutterErrorDetails;
import 'dart:ui' show PlatformDispatcher;
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
import 'package:healthymamaapp/widgets/global_navigation.dart';
import 'features/pin_setup_screen.dart';
import 'features/pin_verification_screen.dart';
import 'package:healthymamaapp/services/local_notification_manager.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:healthymamaapp/services/alarm_service.dart';
import 'dart:io' show Platform;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Add comprehensive error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // Log to console in release mode
    if (kReleaseMode) {
      print('FLUTTER ERROR: ${details.exception}');
      print('STACK TRACE: ${details.stack}');
    } else {
      print('Flutter Error: ${details.exception}');
      print('Stack trace: ${details.stack}');
    }
  };

  // Platform errors
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kReleaseMode) {
      print('PLATFORM ERROR: $error');
      print('PLATFORM STACK: $stack');
    } else {
      print('Platform Error: $error');
      print('Stack trace: $stack');
    }
    return true;
  };

  try {
    WidgetsFlutterBinding.ensureInitialized();
    // Only initialize AndroidAlarmManager on Android, not iOS
    if (!kIsWeb && Platform.isAndroid) {
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
  bool _hasRestoredWebSession = false; // Track if we successfully restored web session

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
      try {
        // Wait for the first frame to ensure context is available
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) {
          _webPatientRestored = true;
          return;
        }
        final userSessionProvider = Provider.of<UserSessionProvider>(
          context,
          listen: false,
        );
        await userSessionProvider.restorePatientFromStorage();
        
        // Check if we successfully restored patient data
        if (userSessionProvider.patient != null) {
          _hasRestoredWebSession = true;
          print('Web session restored successfully with patient data');
        }
        
        if (mounted) {
          setState(() {
            _webPatientRestored = true;
          });
        }
      } catch (e) {
        print('Error restoring web patient session: $e');
        if (mounted) {
          setState(() {
            _webPatientRestored = true;
          });
        }
      }
    } else {
      _webPatientRestored = true;
    }
  }

  Future<void> _restoreSession() async {
    try {
      // Wait for the first frame to ensure context is available
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) {
        _sessionRestored = true;
        return;
      }
      final userSessionProvider = Provider.of<UserSessionProvider>(
        context,
        listen: false,
      );
      await userSessionProvider.restoreOrFetchSession();
      if (mounted) {
        setState(() {
          _sessionRestored = true;
        });
      }
    } catch (e) {
      print('Error restoring session: $e');
      if (mounted) {
        setState(() {
          _sessionRestored = true;
        });
      }
    }
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
      // Try to restore session from backend or local storage
      await userSessionProvider.restoreOrFetchSession();
    } catch (e) {
      print('Error loading user session: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while restoring session
    if (!_sessionRestored || !_webPatientRestored) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icon/logo_center.png',
                width: 150,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.favorite,
                  color: Color(0xFF7C4DFF),
                  size: 64,
                ),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C4DFF)),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_isFirstLaunch) {
      return const OnboardingScreen();
    }

    // On web, check if we have restored session first (before checking Firebase auth)
    // This prevents asking for re-authentication on refresh
    if (kIsWeb) {
      final userSessionProvider = Provider.of<UserSessionProvider>(
        context,
        listen: false,
      );
      
      // If we have patient data stored, go directly to home
      if (userSessionProvider.patient != null || _hasRestoredWebSession) {
        return const GlobalNavigation(currentIndex: 0, child: HomeScreen());
      }
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C4DFF)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Checking authentication...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          // Load user session data when authenticated
          _loadUserSession(snapshot.data!);

          if (_showPinScreen && !kIsWeb) {
            return const PinLockScreen();
          }
          return const GlobalNavigation(currentIndex: 0, child: HomeScreen());
        }

        // Try to restore local session if not authenticated via Firebase
        final userSessionProvider = Provider.of<UserSessionProvider>(
          context,
          listen: false,
        );
        
        return FutureBuilder<bool>(
          future: userSessionProvider.tryRestoreSession(),
          builder: (context, localSnapshot) {
            if (localSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                backgroundColor: Colors.white,
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C4DFF)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Restoring session...',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
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
