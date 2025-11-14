import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'package:provider/provider.dart';
import '../providers/user_session_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class PinLockScreen extends StatefulWidget {
  final bool isChangingPin;
  final bool isDeletingPin;
  final String? customMessage;
  final String? customTitle;

  const PinLockScreen({
    super.key,
    this.isChangingPin = false,
    this.isDeletingPin = false,
    this.customMessage,
    this.customTitle,
  });

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final TextEditingController _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isFirstTime = true;
  bool _isConfirmingPin = false;
  String? _firstPin;
  bool _isDisposed = false;

  final Color primaryColor = const Color(0xFF7C4DFF);

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isDisposed) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      });
      return;
    }
    _checkForExistingPin();
  }

  Future<void> _checkForExistingPin() async {
    if (_isDisposed) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final pinSetupCompleted = prefs.getBool('pin_setup_completed') ?? false;

      if (!_isDisposed && mounted) {
        setState(() {
          _isFirstTime = !pinSetupCompleted;
        });
      }
    } catch (e) {
      debugPrint('Error checking for existing PIN: $e');
    }
  }

  Future<void> _validatePin(String pin) async {
    if (pin.length != 4 || _isLoading || _isDisposed || !mounted) return;

    if (!mounted || _isDisposed) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted || _isDisposed) return;

      if (_isFirstTime) {
        if (!_isConfirmingPin) {
          if (!_isDisposed && mounted) {
            setState(() {
              _firstPin = pin;
              _isConfirmingPin = true;
            });
            try {
              _pinController.clear();
            } catch (e) {
              debugPrint('Error clearing PIN controller: $e');
            }
          }
        } else {
          if (pin == _firstPin) {
            await prefs.setString('user_pin', pin);
            await prefs.setBool('pin_setup_completed', true);
            if (!mounted || _isDisposed) return;

            try {
              // Use a small delay to ensure context is stable
              await Future.delayed(const Duration(milliseconds: 100));
              if (!mounted || _isDisposed) return;
              
              final userSession = Provider.of<UserSessionProvider>(
                context,
                listen: false,
              );
              await userSession.restoreOrFetchSession();
            } catch (e, stackTrace) {
              debugPrint('Error restoring session after PIN setup: $e');
              debugPrint('Stack trace: $stackTrace');
              // Continue to navigation even if session restore fails
            }

            if (!_isDisposed && mounted) {
              // Use a post-frame callback to ensure navigation happens after current frame
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (!mounted || _isDisposed) return;
                
                try {
                  // Try navigation with a small delay to ensure context is stable
                  await Future.delayed(const Duration(milliseconds: 50));
                  if (!mounted || _isDisposed) return;
                  
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                } catch (e, stackTrace) {
                  debugPrint('Error navigating to HomeScreen: $e');
                  debugPrint('Stack trace: $stackTrace');
                  // Try alternative navigation method
                  if (mounted && !_isDisposed) {
                    try {
                      await Future.delayed(const Duration(milliseconds: 100));
                      if (!mounted || _isDisposed) return;
                      
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                        (route) => false,
                      );
                    } catch (e2) {
                      debugPrint('Alternative navigation also failed: $e2');
                      // Last resort: try to navigate using the route name
                      if (mounted && !_isDisposed) {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/home',
                          (route) => false,
                        );
                      }
                    }
                  }
                }
              });
            }
          } else {
            if (!_isDisposed && mounted) {
              setState(() {
                _errorMessage = 'PINs do not match. Please try again.';
                _isConfirmingPin = false;
                _firstPin = null;
              });
              try {
                _pinController.clear();
              } catch (e) {
                debugPrint('Error clearing PIN controller: $e');
              }
            }
          }
        }
      } else {
        final storedPin = prefs.getString('user_pin');
        debugPrint('Verifying PIN. Stored PIN: $storedPin, Entered PIN: $pin');

        if (pin == storedPin) {
          if (widget.isChangingPin || widget.isDeletingPin) {
            debugPrint('PIN verified successfully, returning true');
            if (!_isDisposed && mounted) {
              Navigator.maybePop(context, true);
            }
          } else {
            // Show loading indicator
            if (mounted && !_isDisposed) {
              setState(() {
                _isLoading = true;
                _errorMessage = 'Loading session...';
              });
            }
            
            try {
              print('PIN_LOCK: Starting session restoration process...');
              // Use a small delay to ensure context is stable
              await Future.delayed(const Duration(milliseconds: 200));
              if (!mounted || _isDisposed) {
                print('PIN_LOCK: Widget disposed during delay');
                return;
              }
              
              print('PIN_LOCK: Attempting to access Provider...');
              final userSession = Provider.of<UserSessionProvider>(
                context,
                listen: false,
              );
              print('PIN_LOCK: Provider accessed successfully');
              
              print('PIN_LOCK: Starting session restoration...');
              await userSession.restoreOrFetchSession();
              print('PIN_LOCK: Session restoration completed');
            } catch (e, stackTrace) {
              print('PIN_LOCK: ERROR restoring session after PIN verification: $e');
              print('PIN_LOCK: Stack trace: $stackTrace');
              // Continue to navigation even if session restore fails
              if (mounted && !_isDisposed) {
                setState(() {
                  _isLoading = false;
                  _errorMessage = '';
                });
              }
            }

            if (!_isDisposed && mounted) {
              // Use a post-frame callback to ensure navigation happens after current frame
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (!mounted || _isDisposed) return;
                
                try {
                  // Try navigation with a small delay to ensure context is stable
                  await Future.delayed(const Duration(milliseconds: 50));
                  if (!mounted || _isDisposed) return;
                  
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                } catch (e, stackTrace) {
                  debugPrint('Error navigating to HomeScreen: $e');
                  debugPrint('Stack trace: $stackTrace');
                  // Try alternative navigation method
                  if (mounted && !_isDisposed) {
                    try {
                      await Future.delayed(const Duration(milliseconds: 100));
                      if (!mounted || _isDisposed) return;
                      
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                        (route) => false,
                      );
                    } catch (e2) {
                      debugPrint('Alternative navigation also failed: $e2');
                      // Last resort: try to navigate using the route name
                      if (mounted && !_isDisposed) {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/home',
                          (route) => false,
                        );
                      }
                    }
                  }
                }
              });
            }
          }
        } else {
          debugPrint('Incorrect PIN');
          if (!_isDisposed && mounted) {
            setState(() {
              _errorMessage = 'Incorrect PIN';
            });
            try {
              _pinController.clear();
            } catch (e) {
              debugPrint('Error clearing PIN controller: $e');
            }
            try {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Incorrect PIN'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            } catch (e) {
              debugPrint('Error showing snackbar: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error during PIN verification: $e');
      if (!_isDisposed && mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error: $e';
        });
      }
    } finally {
      if (!_isDisposed && mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const SizedBox.shrink();
    }
    String title = widget.customTitle ?? 'Enter PIN';
    String subtitle = widget.customMessage ?? 'Please enter your PIN to continue';
    if (widget.customTitle == null && widget.customMessage == null) {
      if (widget.isChangingPin) {
        title = 'Enter Current PIN';
        subtitle = 'Please enter your current PIN to change it';
      } else if (widget.isDeletingPin) {
        title = 'Enter PIN to Delete';
        subtitle = 'Please enter your PIN to delete it';
      } else if (_isFirstTime) {
        title = _isConfirmingPin ? 'Confirm PIN' : 'Create PIN';
        subtitle = _isConfirmingPin
            ? 'Please confirm your PIN'
            : 'Please create a 4-digit PIN to secure your account';
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (mounted && !_isDisposed) {
              Navigator.maybePop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Header Card
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
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _isFirstTime
                            ? Icons.lock_outline
                            : Icons.lock_open_outlined,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // PIN Input Card
              Container(
                padding: const EdgeInsets.all(24),
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
                    Form(
                      key: _formKey,
                      child: PinCodeTextField(
                        appContext: context,
                        length: 4,
                        controller: _pinController,
                        onChanged: (value) {
                          if (_isDisposed || !mounted) return;
                          if (value.length == 4) {
                            _validatePin(value);
                          }
                        },
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.box,
                          borderRadius: BorderRadius.circular(12),
                          fieldHeight: 60,
                          fieldWidth: 60,
                          activeFillColor: Colors.white,
                          activeColor: primaryColor,
                          selectedColor: primaryColor,
                          inactiveColor: Colors.grey.shade300,
                          errorBorderColor: Colors.red,
                        ),
                        keyboardType: TextInputType.number,
                        enableActiveFill: false,
                        showCursor: false,
                        enablePinAutofill: false,
                        autoDismissKeyboard: true,
                        obscureText: true,
                        obscuringCharacter: '●',
                        animationType: AnimationType.fade,
                        animationDuration: const Duration(milliseconds: 300),
                      ),
                    ),
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
                    if (_isLoading) ...[
                      const SizedBox(height: 20),
                      const CircularProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
