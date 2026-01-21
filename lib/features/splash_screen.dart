import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'home_screen.dart'; // Import your home page

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animation for loading indicator
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Navigate to home after 3 seconds (longer for web)
    Future.delayed(Duration(seconds: kIsWeb ? 4 : 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Centered main image
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/icon/logo_center.png',
                  width: isWide
                      ? 300 // Fixed size for wide screens
                      : screenWidth * 0.6, // 60% of screen width on mobile
                  fit: BoxFit.contain,
                ),
                // Loading indicator for web
                if (kIsWeb) ...[
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 200,
                    child: Column(
                      children: [
                        // Animated loading bar
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Container(
                              height: 4,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                color: Colors.grey[200],
                              ),
                              child: Stack(
                                children: [
                                  AnimatedBuilder(
                                    animation: _animationController,
                                    builder: (context, child) {
                                      return FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: _animationController.value,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(2),
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFF7C4DFF),
                                                Color(0xFFB47CFF),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Text(
                            'Loading...',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Bottom small image
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/icon/logo_bottom.png',
                width: isWide
                    ? 150 // Fixed size for wide screens
                    : screenWidth * 0.3, // 30% of screen width on mobile
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
