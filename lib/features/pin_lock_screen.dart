import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/shared_app_bar.dart';
import 'home_screen.dart';
import 'package:provider/provider.dart';
import '../providers/user_session_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class PinLockScreen extends StatefulWidget {
  final bool isChangingPin;
  final bool isDeletingPin;

  const PinLockScreen({
    Key? key,
    this.isChangingPin = false,
    this.isDeletingPin = false,
  }) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
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
      final hasPin = prefs.getString('user_pin') != null;

      if (!_isDisposed) {
        setState(() {
          _isFirstTime = !pinSetupCompleted || hasPin == null;
        });
      }
    } catch (e) {
      debugPrint('Error checking for existing PIN: $e');
    }
  }

  Future<void> _validatePin(String pin) async {
    if (pin.length != 4 || _isLoading || _isDisposed) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      if (_isFirstTime) {
        if (!_isConfirmingPin) {
          // First PIN entry
          if (!_isDisposed) {
            setState(() {
              _firstPin = pin;
              _isConfirmingPin = true;
              _pinController.clear();
            });
          }
        } else {
          // Confirm PIN
          if (pin == _firstPin) {
            await prefs.setString('user_pin', pin);
            await prefs.setBool('pin_setup_completed', true);

            // Load user data before navigating
            final userSession = Provider.of<UserSessionProvider>(
              context,
              listen: false,
            );
            final phoneNumber = userSession.getPhoneNumber();
            if (phoneNumber != null) {
              await userSession.loadUserData(phoneNumber);
            }

            if (!_isDisposed) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            }
          } else {
            if (!_isDisposed) {
              setState(() {
                _errorMessage = 'PINs do not match. Please try again.';
                _isConfirmingPin = false;
                _firstPin = null;
                _pinController.clear();
              });
            }
          }
        }
      } else {
        // Verify existing PIN
        final storedPin = prefs.getString('user_pin');
        debugPrint('Verifying PIN. Stored PIN: $storedPin, Entered PIN: $pin');
        debugPrint(
          'isChangingPin: ${widget.isChangingPin}, isDeletingPin: ${widget.isDeletingPin}',
        );

        if (pin == storedPin) {
          if (widget.isChangingPin || widget.isDeletingPin) {
            // Return true to indicate successful verification
            debugPrint('PIN verified successfully, returning true');
            if (!_isDisposed) {
              Navigator.of(context).pop(true);
            }
          } else {
            // Load user data before navigating
            final userSession = Provider.of<UserSessionProvider>(
              context,
              listen: false,
            );
            final phoneNumber = userSession.getPhoneNumber();
            if (phoneNumber != null) {
              await userSession.loadUserData(phoneNumber);
            }

            if (!_isDisposed) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            }
          }
        } else {
          debugPrint('Incorrect PIN');
          if (!_isDisposed) {
            setState(() {
              _errorMessage = 'Incorrect PIN';
              _pinController.clear();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Incorrect PIN'),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error during PIN verification: $e');
      if (!_isDisposed) {
        setState(() {
          _errorMessage = 'Error: $e';
        });
      }
    } finally {
      if (!_isDisposed) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resetPinSetup() {
    if (!_isDisposed) {
      setState(() {
        _isConfirmingPin = false;
        _firstPin = null;
        _pinController.clear();
        _errorMessage = '';
      });
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
    String title = 'Enter PIN';
    if (widget.isChangingPin) {
      title = 'Enter Current PIN';
    } else if (widget.isDeletingPin) {
      title = 'Enter PIN to Delete';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7C4DFF),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                widget.isChangingPin
                    ? 'Please enter your current PIN to change it'
                    : widget.isDeletingPin
                    ? 'Please enter your PIN to delete it'
                    : 'Please enter your PIN to continue',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final isLargeScreen = screenWidth > 600;
                  return Column(
                    children: [
                      Form(
                        key: _formKey,
                        child: Container(
                          alignment: Alignment.center,
                          margin:
                              isLargeScreen
                                  ? const EdgeInsets.symmetric(horizontal: 200)
                                  : EdgeInsets.zero,
                          child: PinCodeTextField(
                            appContext: context,
                            length: 4,
                            controller: _pinController,
                            onChanged: (value) {
                              if (value.length == 4) {
                                _validatePin(value);
                              }
                            },
                            pinTheme: PinTheme(
                              shape: PinCodeFieldShape.box,
                              borderRadius: BorderRadius.circular(8),
                              fieldHeight: isLargeScreen ? 60 : 50,
                              fieldWidth: isLargeScreen ? 60 : 50,
                              activeFillColor: Colors.white,
                              activeColor: const Color(0xFF7C4DFF),
                              selectedColor: const Color(0xFF7C4DFF),
                              inactiveColor: Colors.grey[300],
                            ),
                            keyboardType: TextInputType.number,
                            enableActiveFill: false,
                            showCursor: false,
                            enablePinAutofill: false,
                            autoDismissKeyboard: true,
                            obscureText: true,
                            obscuringCharacter: '●',
                          ),
                        ),
                      ),
                      if (_errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
