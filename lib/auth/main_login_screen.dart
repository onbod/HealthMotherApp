import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_session_provider.dart';
import 'login_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/config.dart';

class MainLoginScreen extends StatefulWidget {
  const MainLoginScreen({super.key});

  @override
  State<MainLoginScreen> createState() => _MainLoginScreenState();
}

class _MainLoginScreenState extends State<MainLoginScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _identifierController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  void _requestOtp() async {
    final name = _nameController.text.trim();
    final identifier = _identifierController.text.trim();
    if (name.isEmpty || identifier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      // Split name into given and family (simple split by space)
      final nameParts = name.split(' ');
      final given = nameParts.first;
      final family = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      final response = await http.post(
        Uri.parse(AppConfig.getApiUrl('/login/request-otp')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "given": given,
          "family": family,
          "identifier": identifier,
        }),
      );
      setState(() {
        _isLoading = false;
      });
      if (response.statusCode == 200) {
        Navigator.pushNamed(
          context,
          '/auth',
          arguments: {
            'given': given,
            'family': family,
            'identifier': identifier,
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send OTP: ${response.body}')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: ${e.toString()}')),
      );
    }
  }

  void _directLogin() async {
    final name = _nameController.text.trim();
    final identifier = _identifierController.text.trim();
    if (name.isEmpty || identifier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      // Split name into given and family (simple split by space)
      final nameParts = name.split(' ');
      final given = nameParts.first;
      final family = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      final response = await http.post(
        Uri.parse(AppConfig.getApiUrl('/login/direct')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "given": given,
          "family": family,
          "identifier": identifier,
          "national_id": identifier, // Try both identifier and national_id
        }),
      );
      setState(() {
        _isLoading = false;
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          // Save token securely
          const storage = FlutterSecureStorage();
          await storage.write(key: 'jwt', value: data['token']);
          // Load user session from backend
          final userSession = Provider.of<UserSessionProvider>(
            context,
            listen: false,
          );
          await userSession.loadUserDataFromBackend();
          // Navigate to PIN setup or verification
          Navigator.pushReplacementNamed(context, '/pin_setup');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${response.body}')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _identifierController.dispose();
    super.dispose();
  }

  // Breakpoint and max width for responsive layout
  static const double _wideScreenBreakpoint = 600;
  static const double _maxContentWidth = 420;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= _wideScreenBreakpoint;

    return Scaffold(
      backgroundColor: isWideScreen ? const Color(0xFFF5F5F5) : Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: isWideScreen ? _maxContentWidth : double.infinity,
              margin: isWideScreen
                  ? const EdgeInsets.symmetric(vertical: 40)
                  : EdgeInsets.zero,
              padding: EdgeInsets.symmetric(
                horizontal: isWideScreen ? 40 : 24,
                vertical: isWideScreen ? 40 : 24,
              ),
              decoration: isWideScreen
                  ? BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    )
                  : null,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/icon/new_Icon.png', height: 80),
                    const SizedBox(height: 32),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Welcome back.',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Log in to your account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      height: 48,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Enter your name',
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 48,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        controller: _identifierController,
                        textCapitalization: TextCapitalization.characters,
                        style: const TextStyle(letterSpacing: 1.2, fontSize: 16),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Enter your patient ID or NIN',
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Enter your patient ID or NIN as shown on your ANC card',
                        style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _directLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C4DFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            _isLoading
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : const Text(
                                  'Continue',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF7C4DFF),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Login with Phone Number'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
