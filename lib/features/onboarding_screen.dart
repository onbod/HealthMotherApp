import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/main_login_screen.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _controller = PageController();
  bool onLastPage = false;
  late AnimationController _completionController;
  late Animation<double> _completionAnimation;

  // Breakpoint for responsive layout
  static const double _wideScreenBreakpoint = 800;

  @override
  void initState() {
    super.initState();
    _completionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _completionAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _completionController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _completionController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    // Start completion animation
    await _completionController.forward();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_launch', false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainLoginScreen()),
    );
  }

  Future<void> _goToNextPage() async {
    // Start completion animation for page transition
    await _completionController.forward();
    _completionController.reset();

    _controller.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= _wideScreenBreakpoint;

    return Scaffold(
      body: isWideScreen ? _buildWideScreenLayout() : _buildMobileLayout(),
    );
  }

  // Mobile layout (original)
  Widget _buildMobileLayout() {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _completionAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _completionAnimation.value,
              child: PageView(
                controller: _controller,
                onPageChanged: (index) {
                  setState(() {
                    onLastPage = index == 2;
                  });
                },
                children: const [
                  OnboardingPage(
                    image: 'assets/onboarding/pregnant.png',
                    title: 'Pregnancy',
                    description:
                        'Register with your phone number to unlock medical records, appointment reminders and medication alerts.',
                  ),
                  OnboardingPage(
                    image: 'assets/onboarding/pregnantphone2.jpg',
                    title: 'Tracking',
                    description:
                        'Track your pregnancy\'s growth, get weekly tips, and stay informed every step of the way.',
                  ),
                  OnboardingPage(
                    image: 'assets/onboarding/afterpregnancy.jpg',
                    title: 'Child\'s Health',
                    description:
                        'Track vaccinations, feedings, and development—for a happy, healthy child.',
                  ),
                ],
              ),
            );
          },
        ),

        // Page Indicator - bottom left
        Positioned(
          bottom: 30,
          left: 20,
          child: SmoothPageIndicator(
            controller: _controller,
            count: 3,
            effect: const WormEffect(
              dotHeight: 10,
              dotWidth: 10,
              activeDotColor: Color(0xFF6B4EFF),
            ),
          ),
        ),

        // Next / Get Started Button - bottom right
        Positioned(
          bottom: 20,
          right: 20,
          child: SizedBox(
            height: 40,
            width: 130,
            child: ElevatedButton(
              onPressed: () {
                if (onLastPage) {
                  _completeOnboarding();
                } else {
                  _goToNextPage();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B4EFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                onLastPage ? "Get Started" : "Next",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Wide screen layout (split view)
  Widget _buildWideScreenLayout() {
    final onboardingData = [
      {
        'image': 'assets/onboarding/pregnant.png',
        'title': 'Pregnancy',
        'description':
            'Register with your phone number to unlock medical records, appointment reminders and medication alerts.',
      },
      {
        'image': 'assets/onboarding/pregnantphone2.jpg',
        'title': 'Tracking',
        'description':
            'Track your pregnancy\'s growth, get weekly tips, and stay informed every step of the way.',
      },
      {
        'image': 'assets/onboarding/afterpregnancy.jpg',
        'title': 'Child\'s Health',
        'description':
            'Track vaccinations, feedings, and development—for a happy, healthy child.',
      },
    ];

    return Row(
      children: [
        // Left side - Image with PageView
        Expanded(
          flex: 1,
          child: AnimatedBuilder(
            animation: _completionAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _completionAnimation.value,
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (index) {
                    setState(() {
                      onLastPage = index == 2;
                    });
                  },
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    return _WideScreenImagePanel(
                      image: onboardingData[index]['image']!,
                    );
                  },
                ),
              );
            },
          ),
        ),

        // Right side - Content
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset(
                    'assets/icon/new_Icon.png',
                    height: 80,
                  ),
                  const SizedBox(height: 48),

                  // Animated content based on page
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      key: ValueKey<int>(_controller.hasClients
                          ? (_controller.page?.round() ?? 0)
                          : 0),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          onboardingData[_controller.hasClients
                              ? (_controller.page?.round() ?? 0)
                              : 0]['title']!,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          onboardingData[_controller.hasClients
                              ? (_controller.page?.round() ?? 0)
                              : 0]['description']!,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black87,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Page Indicator
                  SmoothPageIndicator(
                    controller: _controller,
                    count: 3,
                    effect: const WormEffect(
                      dotHeight: 12,
                      dotWidth: 12,
                      activeDotColor: Color(0xFF6B4EFF),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Button
                  SizedBox(
                    height: 56,
                    width: 200,
                    child: ElevatedButton(
                      onPressed: () {
                        if (onLastPage) {
                          _completeOnboarding();
                        } else {
                          _goToNextPage();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B4EFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        onLastPage ? "Get Started" : "Next",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Wide screen image panel
class _WideScreenImagePanel extends StatefulWidget {
  final String image;

  const _WideScreenImagePanel({required this.image});

  @override
  State<_WideScreenImagePanel> createState() => _WideScreenImagePanelState();
}

class _WideScreenImagePanelState extends State<_WideScreenImagePanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(widget.image),
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }
}

class OnboardingPage extends StatefulWidget {
  final String image;
  final String title;
  final String description;

  const OnboardingPage({
    super.key,
    required this.image,
    required this.title,
    required this.description,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    // Calculate responsive content height
    final contentHeight = screenHeight < 700
        ? screenHeight * 0.30
        : screenHeight * 0.25;

    return Stack(
      children: [
        AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: SizedBox(
                height: screenHeight,
                width: double.infinity,
                child: Image.asset(widget.image, fit: BoxFit.cover),
              ),
            );
          },
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.only(top: 20),
            width: double.infinity,
            height: contentHeight,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Text(
                    widget.description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
