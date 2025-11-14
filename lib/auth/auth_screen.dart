import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/pin_setup_screen.dart';
import '../providers/user_session_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/config.dart';
import 'dart:async';

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
  bool _isDisposed = false;
  Timer? _countdownTimer;

  final Color primaryColor = const Color(0xFF7C4DFF);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed || !mounted) return;
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        phoneNumber = args['phoneNumber'];
        given = args['given'];
        family = args['family'];
        identifier = args['identifier'];
        nationalId = args['national_id'];
        if (mounted && !_isDisposed) {
          _focusNodes[0].requestFocus();
        }
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _countdownTimer?.cancel();
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyCode() async {
    if (_isDisposed || !mounted) return;

    final smsCode =
        _codeControllers.map((controller) => controller.text).join();

    if (smsCode.length != 6) {
      if (!mounted || _isDisposed) return;
      setState(() {
        _errorMessage = 'Please enter the complete 6-digit code.';
        _isCodeInvalid = true;
      });
      return;
    }

    if (!mounted || _isDisposed) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _isCodeInvalid = false;
    });

    try {
      debugPrint('Verifying OTP with code: $smsCode');

      String endpoint;
      Map<String, dynamic> body;

      if (phoneNumber != null) {
        endpoint = '/login/verify-otp';
        body = {"phone": phoneNumber, "otp": smsCode};
      } else if (given != null && family != null && identifier != null) {
        endpoint = '/login/verify-otp';
        body = {
          "given": given,
          "family": family,
          "identifier": identifier,
          "otp": smsCode,
        };
      } else if (nationalId != null) {
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

      if (!mounted || _isDisposed) return;
      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          const storage = FlutterSecureStorage();
          await storage.write(key: 'jwt', value: data['token']);

          final userSession = Provider.of<UserSessionProvider>(
            context,
            listen: false,
          );
          await userSession.loadUserDataFromBackend();

          if (mounted && !_isDisposed) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const PinSetupScreen()),
            );
          }
        } else {
          if (!mounted || _isDisposed) return;
          setState(() {
            _errorMessage = 'No token received from server';
            _isCodeInvalid = true;
          });
        }
      } else {
        final errorData = jsonDecode(response.body);
        if (!mounted || _isDisposed) return;
        setState(() {
          _errorMessage = errorData['error'] ?? 'OTP verification failed';
          _isCodeInvalid = true;
        });
      }
    } catch (e) {
      if (!mounted || _isDisposed) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred: ${e.toString()}';
        _isCodeInvalid = true;
      });
      debugPrint('Error during OTP verification: $e');
    }
  }

  Future<void> _resendCode() async {
    if (_isLoading || _resendCountdown > 0 || _isDisposed || !mounted) return;

    if (!mounted || _isDisposed) return;
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
        if (mounted && !_isDisposed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'OTP sent successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          _startResendCountdown();
        }
      } else {
        final errorData = jsonDecode(response.body);
        if (!mounted || _isDisposed) return;
        setState(() {
          _errorMessage = errorData['error'] ?? 'Failed to resend OTP';
        });
      }
    } catch (e) {
      if (!mounted || _isDisposed) return;
      setState(() {
        _errorMessage = 'An error occurred while resending OTP';
      });
      debugPrint('Error during OTP resend: $e');
    } finally {
      if (!mounted || _isDisposed) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startResendCountdown() {
    _countdownTimer?.cancel();
    _resendCountdown = 60;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isDisposed) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendCountdown--;
      });
      if (_resendCountdown <= 0) {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 28),
                    onPressed: () {
                      if (mounted && !_isDisposed) {
                        Navigator.pop(context);
                      }
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            if (mounted && !_isDisposed) {
                              Navigator.pushReplacementNamed(context, '/login');
                            }
                          },
                    child: const Text(
                      'Change number',
                      style: TextStyle(
                        color: Color(0xFF7C4DFF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Title Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor,
                      primaryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Enter authentication code',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getSubtitleText(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // OTP Input Fields
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // Calculate available width minus padding and spacing
                        final availableWidth = constraints.maxWidth;
                        final spacing = 8.0 * 5; // 5 spaces between 6 fields
                        final fieldWidth = (availableWidth - spacing) / 6;
                        final fieldSize = fieldWidth.clamp(40.0, 50.0);
                        
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (index) {
                            return SizedBox(
                              width: fieldSize,
                              height: 60,
                              child: TextField(
                                controller: _codeControllers[index],
                                focusNode: _focusNodes[index],
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                maxLength: 1,
                                style: TextStyle(
                                  fontSize: fieldSize > 45 ? 28 : 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                                decoration: InputDecoration(
                                  counterText: '',
                                  filled: true,
                                  fillColor: _isCodeInvalid
                                      ? Colors.red.shade50
                                      : Colors.grey.shade50,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: _isCodeInvalid
                                          ? Colors.red
                                          : Colors.grey.shade300,
                                      width: 2.0,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: _isCodeInvalid
                                          ? Colors.red
                                          : primaryColor,
                                      width: 2.5,
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
                                      width: 2.5,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onChanged: (value) {
                                  if (_isDisposed || !mounted) return;
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
                                    Future.microtask(() {
                                      if (mounted && !_isDisposed) {
                                        _verifyCode();
                                      }
                                    });
                                  }
                                },
                              ),
                            );
                          }),
                        );
                      },
                    ),

                    // Error Message
                    if (_errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
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
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (_isDisposed || !mounted) return;
                          final code = _codeControllers
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
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
                      color: (_isLoading || _resendCountdown > 0)
                          ? Colors.grey
                          : primaryColor,
                      fontWeight: FontWeight.w600,
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
