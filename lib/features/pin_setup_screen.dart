import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../providers/user_session_provider.dart';
import 'home_screen.dart';
import '../widgets/shared_app_bar.dart';

class PinSetupScreen extends StatefulWidget {
  final bool isChangingPin;

  const PinSetupScreen({
    Key? key,
    this.isChangingPin = false,
  }) : super(key: key);

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;
  bool _isConfirmingPin = false;
  String? _firstPin;
  bool _obscurePin = true;

  @override
  void initState() {
    super.initState();
    _pinController.addListener(_onPinChanged);
  }

  void _onPinChanged() {
    if (_pinController.text.length == 4) {
      _validateAndSavePin();
    }
  }

  @override
  void dispose() {
    _pinController.removeListener(_onPinChanged);
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _savePin(String pin) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_pin', pin);
      await prefs.setBool('pin_setup_completed', true);

      if (!mounted) return;

      if (widget.isChangingPin) {
        // If changing PIN, just go back
        Navigator.of(context).pop(true);
      } else {
        // If setting up PIN for the first time, go to home screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Failed to save PIN. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _validateAndSavePin() {
    if (!mounted) return;

    if (!_isConfirmingPin) {
      // First PIN entry
      final pin = _pinController.text;
      if (pin.length != 4) {
        setState(() {
          _errorMessage = 'PIN must be 4 digits';
        });
        return;
      }
      setState(() {
        _firstPin = pin;
        _isConfirmingPin = true;
        _pinController.clear();
      });
    } else {
      // Confirm PIN
      final pin = _pinController.text;
      if (pin.length != 4) {
        setState(() {
          _errorMessage = 'PIN must be 4 digits';
        });
        return;
      }

      if (pin != _firstPin) {
        setState(() {
          _errorMessage = 'PINs do not match';
          _isConfirmingPin = false;
          _firstPin = null;
          _pinController.clear();
        });
        return;
      }

      _savePin(pin);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isConfirmingPin) {
          setState(() {
            _isConfirmingPin = false;
            _firstPin = null;
            _pinController.clear();
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: SharedAppBar(
          visitNumber: widget.isChangingPin
              ? (_isConfirmingPin ? 'Confirm New PIN' : 'Enter New PIN')
              : (_isConfirmingPin ? 'Confirm PIN' : 'Create PIN'),
          onNotificationPressed: () {
            // Handle notification press
          },
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Text(
                  widget.isChangingPin
                      ? (_isConfirmingPin ? 'Confirm New PIN' : 'Enter New PIN')
                      : (_isConfirmingPin ? 'Confirm PIN' : 'Create PIN'),
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
                      ? (_isConfirmingPin
                          ? 'Please confirm your new PIN'
                          : 'Please enter your new PIN')
                      : (_isConfirmingPin
                          ? 'Please confirm your PIN'
                          : 'Please create a 4-digit PIN to secure your account'),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Container(
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: _obscurePin,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      letterSpacing: 8,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                      hintText: '••••',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        letterSpacing: 8,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePin ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey[600],
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePin = !_obscurePin;
                          });
                        },
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
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
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _validateAndSavePin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C4DFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : Text(
                            _isConfirmingPin ? 'Confirm PIN' : 'Continue',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
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
