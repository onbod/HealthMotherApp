import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _verificationId;
  bool _isLoading = false;

  void _requestOtp(String phoneNumber) async {
    final formattedNumber = '+232$phoneNumber';
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.post(
        Uri.parse(AppConfig.getApiUrl('/login/request-otp')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': formattedNumber}),
      );
      setState(() {
        _isLoading = false;
      });
      if (response.statusCode == 200) {
        Navigator.pushNamed(
          context,
          '/auth',
          arguments: {'phoneNumber': formattedNumber},
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
      print('Error during OTP request: ' + e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: ' + e.toString())),
      );
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new),
                  color: Colors.black,
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Phone Login',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Enter your phone number to continue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: Image.asset(
                          'assets/slflag.png',
                          width: 24,
                          height: 16,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const Text(
                        '+232',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter phone number';
                            }
                            if (!RegExp(r'^[0-9]+').hasMatch(value)) {
                              return 'Enter a valid phone number (digits only)';
                            }
                            if (value.length != 8) {
                              return 'Please enter a valid 8-digit number';
                            }
                            if (value.startsWith('0')) {
                              return 'Number must not start with 0';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'xx xxx xxx',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter the phone number from your first contact',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                const Spacer(),
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed:
                          _isLoading
                              ? null
                              : () {
                                if (_formKey.currentState!.validate()) {
                                  _requestOtp(_phoneController.text);
                                }
                              },
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
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/main_login');
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF7C4DFF),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Back to Main Login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
