import 'package:flutter/material.dart';
import 'home_screen.dart'; // Import your home page

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to home after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set your background color
      body: Stack(
        children: [
          // Centered main image
          Center(
            child: Image.asset(
              'assets/icon/logo_center.png', // Your center image path
              width:
                  MediaQuery.of(context).size.width *
                  0.6, // 60% of screen width
              fit: BoxFit.contain,
            ),
          ),

          // Bottom small image
          Positioned(
            bottom: 40, // Adjust padding from bottom
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/icon/logo_bottom.png', // Your bottom image path
                width:
                    MediaQuery.of(context).size.width *
                    0.3, // 30% of screen width
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
