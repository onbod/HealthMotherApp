import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final TextEditingController _clientNumberController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  void _requestOtp() async {
    final name = _nameController.text.trim();
    final clientNumber = _clientNumberController.text.trim();
    if (name.isEmpty || clientNumber.isEmpty) {
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
      final given = [nameParts.first];
      final family = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      final response = await http.post(
        Uri.parse(AppConfig.getApiUrl('/login/request-otp')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "given": given,
          "family": family,
          "client_number": clientNumber,
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
            'client_number': clientNumber,
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
    final clientNumberOrNin = _clientNumberController.text.trim();
    if (name.isEmpty || clientNumberOrNin.isEmpty) {
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
      final given = [nameParts.first];
      final family = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      final response = await http.post(
        Uri.parse(AppConfig.getApiUrl('/login/direct')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "given": given,
          "family": family,
          "client_number": clientNumberOrNin,
          "nin_number": clientNumberOrNin,
        }),
      );
      setState(() {
        _isLoading = false;
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          // Save token securely
          final storage = FlutterSecureStorage();
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
    _clientNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Image.asset('assets/icon/new_Icon.png', height: 80),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Welcome back.',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Log in to your account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    height: 48,
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
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextFormField(
                      controller: _clientNumberController,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(letterSpacing: 1.2, fontSize: 16),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter your client number or NIN',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your client number or NIN as shown on your ANC card',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 32),
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
                  Center(
                    child: TextButton(
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
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
