import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_session_provider.dart';
import '../features/home_screen.dart'; // Import HomeScreen
import 'package:healthymamaapp/widgets/global_navigation.dart'; // Import GlobalNavigation
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PasscodeScreen extends StatefulWidget {
  const PasscodeScreen({Key? key}) : super(key: key);

  @override
  State<PasscodeScreen> createState() => _PasscodeScreenState();
}

class _PasscodeScreenState extends State<PasscodeScreen> {
  final TextEditingController _passcodeController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;

  void _verifyPasscode() async {
    if (_passcodeController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your passcode';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Check if JWT token exists (user is authenticated)
      const storage = FlutterSecureStorage();
      final jwt = await storage.read(key: 'jwt');

      if (jwt == null) {
        setState(() {
          _errorMessage = 'No active session found. Please login again.';
          _isLoading = false;
        });
        return;
      }

      // For now, we'll use a simple passcode validation
      // In a real app, you might want to store the passcode securely
      // and validate it against the stored value
      const expectedPasscode = '1234'; // This should be stored securely

      if (_passcodeController.text == expectedPasscode) {
        setState(() {
          _errorMessage = '';
          _isLoading = false;
        });

        // Load user session from backend
        final userSession = Provider.of<UserSessionProvider>(
          context,
          listen: false,
        );

        try {
          await userSession.loadUserDataFromBackend();

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (context) => const GlobalNavigation(
                      currentIndex: 0,
                      child: HomeScreen(),
                    ),
              ),
            );
          }
        } catch (e) {
          setState(() {
            _errorMessage = 'Failed to load user data: ${e.toString()}';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Invalid Passcode';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Passcode'),
        backgroundColor: const Color(0xFF7C4DFF),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _passcodeController,
                keyboardType: TextInputType.number,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Passcode',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyPasscode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C4DFF),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
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
                          'Submit',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
