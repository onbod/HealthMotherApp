import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/config.dart';
import 'package:provider/provider.dart';
import '../providers/user_session_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../features/pin_setup_screen.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  _PhoneAuthScreenState createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isOtpSent = false;
  String _errorMessage = '';
  int _resendCountdown = 0;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a phone number';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Format phone number with Sierra Leone country code if not already formatted
      String formattedPhone = phoneNumber;
      if (!phoneNumber.startsWith('+232')) {
        if (phoneNumber.startsWith('232')) {
          formattedPhone = '+$phoneNumber';
        } else if (phoneNumber.startsWith('0')) {
          formattedPhone = '+232${phoneNumber.substring(1)}';
        } else {
          formattedPhone = '+232$phoneNumber';
        }
      }

      final response = await http.post(
        Uri.parse(AppConfig.getApiUrl('/login/request-otp')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': formattedPhone}),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        setState(() {
          _isOtpSent = true;
        });
        _startResendCountdown();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          _errorMessage = errorData['error'] ?? 'Failed to send OTP';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred: ${e.toString()}';
      });
    }
  }

  Future<void> _verifyOtp() async {
    final phoneNumber = _phoneController.text.trim();
    final otp = _otpController.text.trim();

    if (otp.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter the OTP';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Format phone number with Sierra Leone country code if not already formatted
      String formattedPhone = phoneNumber;
      if (!phoneNumber.startsWith('+232')) {
        if (phoneNumber.startsWith('232')) {
          formattedPhone = '+$phoneNumber';
        } else if (phoneNumber.startsWith('0')) {
          formattedPhone = '+232${phoneNumber.substring(1)}';
        } else {
          formattedPhone = '+232$phoneNumber';
        }
      }

      final response = await http.post(
        Uri.parse(AppConfig.getApiUrl('/login/verify-otp')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': formattedPhone, 'otp': otp}),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          // Save JWT token
          const storage = FlutterSecureStorage();
          await storage.write(key: 'jwt', value: data['token']);

          // Load user session
          final userSession = Provider.of<UserSessionProvider>(
            context,
            listen: false,
          );
          await userSession.loadUserDataFromBackend();

          // Navigate to PIN setup
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const PinSetupScreen()),
            );
          }
        } else {
          setState(() {
            _errorMessage = 'No token received from server';
          });
        }
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          _errorMessage = errorData['error'] ?? 'OTP verification failed';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred: ${e.toString()}';
      });
    }
  }

  void _startResendCountdown() {
    _resendCountdown = 60; // 60 seconds countdown
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _resendCountdown--;
        });
        if (_resendCountdown > 0) {
          _startResendCountdown();
        }
      }
    });
  }

  // Breakpoint and max width for responsive layout
  static const double _wideScreenBreakpoint = 600;
  static const double _maxContentWidth = 400;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= _wideScreenBreakpoint;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Container(
            width: isWideScreen ? _maxContentWidth : double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: isWideScreen ? 32 : 24,
              vertical: 24,
            ),
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
                    'Phone Authentication',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Enter your phone number to receive OTP',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Phone Number Input
                  Container(
                    height: 48,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      enabled: !_isOtpSent,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter phone number';
                        }
                        if (!RegExp(r'^\+?[0-9]+').hasMatch(value)) {
                          return 'Enter a valid phone number';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '+1234567890',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // OTP Input (shown after OTP is sent)
                  if (_isOtpSent) ...[
                    Container(
                      height: 48,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter OTP';
                          }
                          if (value.length != 6) {
                            return 'Please enter 6-digit OTP';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Enter 6-digit OTP',
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Error Message
                  if (_errorMessage.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Spacer(),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed:
                          _isLoading
                              ? null
                              : (_isOtpSent ? _verifyOtp : _sendOtp),
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
                              : Text(
                                _isOtpSent ? 'Verify OTP' : 'Send OTP',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Resend OTP Button (shown after OTP is sent)
                  if (_isOtpSent)
                    Center(
                      child: TextButton(
                        onPressed:
                            (_isLoading || _resendCountdown > 0)
                                ? null
                                : _sendOtp,
                        child: Text(
                          _resendCountdown > 0
                              ? 'Resend OTP in $_resendCountdown seconds'
                              : 'Resend OTP',
                          style: TextStyle(
                            color:
                                (_isLoading || _resendCountdown > 0)
                                    ? Colors.grey
                                    : const Color(0xFF7C4DFF),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
