import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/pin_setup_screen.dart';
import '../providers/user_session_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/config.dart';
import 'dart:async'; // Added for Timer

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final List<TextEditingController> _codeControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  String? phoneNumber;
  String? given;
  String? family;
  String? identifier;
  String? nationalId;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isCodeInvalid = false;
  int _resendCountdown = 0;

  final Color primaryColor = const Color(0xFF7C4DFF);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        phoneNumber = args['phoneNumber'];
        given = args['given'];
        family = args['family'];
        identifier = args['identifier'];
        nationalId = args['national_id'];
        _focusNodes[0].requestFocus();
      }
    });
  }

  Future<void> _verifyCode() async {
    final smsCode =
        _codeControllers.map((controller) => controller.text).join();

    if (smsCode.length != 6) {
      setState(() {
        _errorMessage = 'Please enter the complete 6-digit code.';
        _isCodeInvalid = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _isCodeInvalid = false;
    });

    try {
      debugPrint('Verifying OTP with code: $smsCode');

      // Determine which verification method to use
      String endpoint;
      Map<String, dynamic> body;

      if (phoneNumber != null) {
        // Phone number verification
        endpoint = '/login/verify-otp';
        body = {"phone": phoneNumber, "otp": smsCode};
      } else if (given != null && family != null && identifier != null) {
        // Name and identifier verification
        endpoint = '/login/verify-otp';
        body = {
          "given": given,
          "family": family,
          "identifier": identifier,
          "otp": smsCode,
        };
      } else if (nationalId != null) {
        // National ID verification
        endpoint = '/login/verify-otp';
        body = {"national_id": nationalId, "otp": smsCode};
      } else {
        throw Exception('Invalid authentication parameters');
      }

      final response = await http.post(
        Uri.parse(AppConfig.getApiUrl(endpoint)),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
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
          throw Exception('No token received from server');
        }
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          _errorMessage = errorData['error'] ?? 'OTP verification failed';
          _isCodeInvalid = true;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred: ${e.toString()}';
        _isCodeInvalid = true;
      });
      debugPrint('Error during OTP verification: $e');
    }
  }

  Future<void> _resendCode() async {
    if (_isLoading || _resendCountdown > 0) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _isCodeInvalid = false;
    });

    try {
      String endpoint;
      Map<String, dynamic> body;

      if (phoneNumber != null) {
        endpoint = '/login/request-otp';
        body = {"phone": phoneNumber};
      } else if (given != null && family != null && identifier != null) {
        endpoint = '/login/request-otp';
        body = {"given": given, "family": family, "identifier": identifier};
      } else if (nationalId != null) {
        endpoint = '/login/request-otp';
        body = {"national_id": nationalId};
      } else {
        throw Exception('Invalid authentication parameters');
      }

      final response = await http.post(
        Uri.parse(AppConfig.getApiUrl(endpoint)),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'OTP sent successfully'),
              backgroundColor: Colors.green,
            ),
          );

          // Start countdown for resend
          _startResendCountdown();
        }
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          _errorMessage = errorData['error'] ?? 'Failed to resend OTP';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred while resending OTP';
      });
      debugPrint('Error during OTP resend: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startResendCountdown() {
    _resendCountdown = 60; // 60 seconds countdown
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _resendCountdown--;
        });
        if (_resendCountdown <= 0) {
          timer.cancel();
        }
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => Navigator.pop(context),
                  ),
                  TextButton(
                    onPressed:
                        _isLoading
                            ? null
                            : () => Navigator.pushReplacementNamed(
                              context,
                              '/login',
                            ),
                    child: const Text(
                      'Change number',
                      style: TextStyle(color: Color(0xFF6366F1)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Title
              const Text(
                'Enter authentication code',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                _getSubtitleText(),
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 16),
              ),

              const SizedBox(height: 40),

              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 45,
                    height: 55,
                    child: TextField(
                      controller: _codeControllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _isCodeInvalid ? Colors.red : primaryColor,
                            width: 2.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _isCodeInvalid ? Colors.red : primaryColor,
                            width: 2.0,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2.0,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2.0,
                          ),
                        ),
                        filled: true,
                        fillColor:
                            _isCodeInvalid
                                ? Colors.red.shade50
                                : Colors.grey.shade50,
                      ),
                      onChanged: (value) {
                        if (_errorMessage.isNotEmpty || _isCodeInvalid) {
                          setState(() {
                            _errorMessage = '';
                            _isCodeInvalid = false;
                          });
                        }

                        if (value.length == 1 && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }

                        if (index == 5 && value.length == 1) {
                          FocusScope.of(context).unfocus();
                          _verifyCode();
                        }
                      },
                    ),
                  );
                }),
              ),

              // Error Message
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
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
                ),

              const SizedBox(height: 40),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      _isLoading
                          ? null
                          : () {
                            final code =
                                _codeControllers
                                    .map((controller) => controller.text)
                                    .join();
                            if (code.length == 6) {
                              _verifyCode();
                            } else {
                              setState(() {
                                _errorMessage =
                                    'Please enter the complete 6-digit code.';
                                _isCodeInvalid = true;
                              });
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
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

              const SizedBox(height: 20),

              // Resend Code Button
              Center(
                child: TextButton(
                  onPressed:
                      (_isLoading || _resendCountdown > 0) ? null : _resendCode,
                  child: Text(
                    _resendCountdown > 0
                        ? 'Resend code in $_resendCountdown seconds'
                        : 'Resend code',
                    style: TextStyle(
                      color:
                          (_isLoading || _resendCountdown > 0)
                              ? Colors.grey
                              : primaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSubtitleText() {
    if (phoneNumber != null) {
      return 'Enter the 6-digit code sent to $phoneNumber';
    } else if (given != null && family != null && identifier != null) {
      return 'Enter the 6-digit code sent to $given $family';
    } else if (nationalId != null) {
      return 'Enter the 6-digit code sent to your registered phone';
    } else {
      return 'Enter the 6-digit code sent to your phone';
    }
  }
}
