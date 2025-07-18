import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart'; // Import your home screen

class PasscodeScreen extends StatefulWidget {
  const PasscodeScreen({Key? key}) : super(key: key);

  @override
  State<PasscodeScreen> createState() => _PasscodeScreenState();
}

class _PasscodeScreenState extends State<PasscodeScreen> {
  final TextEditingController _passcodeController = TextEditingController();
  String _message = '';
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _checkBiometricsAndAuthenticate();
  }

  Future<void> _checkBiometricsAndAuthenticate() async {
    bool canCheckBiometrics = await auth.canCheckBiometrics;
    if (canCheckBiometrics) {
      List<BiometricType> availableBiometrics =
          await auth.getAvailableBiometrics();

      if (availableBiometrics.isNotEmpty) {
        try {
          bool authenticated = await auth.authenticate(
            localizedReason: 'Please authenticate to access the app',
            options: const AuthenticationOptions(
              stickyAuth: true,
              biometricOnly: true,
            ),
          );

          if (authenticated) {
            _navigateToHome();
          } else {
            setState(() {
              _message = 'Biometric authentication failed. Please enter passcode.';
            });
          }
        } catch (e) {
          setState(() {
            _message = 'Error during biometric authentication: $e';
          });
        }
      }
    }
  }

  void _verifyPasscode(String enteredPasscode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedPasscode = prefs.getString('app_passcode');

    if (storedPasscode == null || storedPasscode.isEmpty) {
      // If no passcode is set, set this as the new passcode
      await prefs.setString('app_passcode', enteredPasscode);
      _navigateToHome();
    } else if (storedPasscode == enteredPasscode) {
      _navigateToHome();
    } else {
      setState(() {
        _message = 'Incorrect Passcode';
      });
      _passcodeController.clear();
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  Widget _buildPasscodeDigit(int digit) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: OutlinedButton(
        onPressed: () {
          if (_passcodeController.text.length < 4) {
            _passcodeController.text += digit.toString();
            if (_passcodeController.text.length == 4) {
              _verifyPasscode(_passcodeController.text);
            }
          }
        },
        style: OutlinedButton.styleFrom(
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(20),
        ),
        child: Text(
          digit.toString(),
          style: const TextStyle(fontSize: 24, color: Colors.black),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter Passcode')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Enter your 4-digit passcode',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passcodeController,
              obscureText: true,
              maxLength: 4,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              readOnly: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                counterText: '',
              ),
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            Text(
              _message,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 20),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPasscodeDigit(1),
                    _buildPasscodeDigit(2),
                    _buildPasscodeDigit(3),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPasscodeDigit(4),
                    _buildPasscodeDigit(5),
                    _buildPasscodeDigit(6),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPasscodeDigit(7),
                    _buildPasscodeDigit(8),
                    _buildPasscodeDigit(9),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPasscodeDigit(0),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: OutlinedButton(
                        onPressed: () {
                          if (_passcodeController.text.isNotEmpty) {
                            _passcodeController.text = _passcodeController
                                .text
                                .substring(
                                    0, _passcodeController.text.length - 1);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(20),
                        ),
                        child: const Icon(Icons.backspace, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 