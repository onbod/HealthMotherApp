import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinVerificationScreen extends StatefulWidget {
  final bool isChangingPin;
  final bool isDeletingPin;
  final VoidCallback? onVerified;

  const PinVerificationScreen({
    Key? key,
    this.isChangingPin = false,
    this.isDeletingPin = false,
    this.onVerified,
  }) : super(key: key);

  @override
  State<PinVerificationScreen> createState() => _PinVerificationScreenState();
}

class _PinVerificationScreenState extends State<PinVerificationScreen> {
  final List<TextEditingController> _pinControllers =
      List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  String _errorMessage = '';
  bool _isLoading = false;
  bool _isPinInvalid = false;

  @override
  void dispose() {
    for (var controller in _pinControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyPin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _isPinInvalid = false;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPin = prefs.getString('user_pin');
      final enteredPin = _pinControllers.map((c) => c.text).join();

      if (savedPin == enteredPin) {
        if (mounted) {
          if (widget.onVerified != null) {
            widget.onVerified!();
          } else {
            Navigator.pop(context, true);
          }
        }
      } else {
        setState(() {
          _errorMessage = 'Incorrect PIN. Please try again.';
          _isPinInvalid = true;
          for (var c in _pinControllers) {
            c.clear();
          }
          _focusNodes[0].requestFocus();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to verify PIN. Please try again.';
        _isPinInvalid = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Verify PIN';
    if (widget.isChangingPin) {
      title = 'Enter Current PIN';
    } else if (widget.isDeletingPin) {
      title = 'Verify PIN to Delete';
    }
    final Color primaryColor = const Color(0xFF7C4DFF);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              reverse: true,
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        Text(
                          widget.isChangingPin
                              ? 'Please enter your current PIN to change it'
                              : widget.isDeletingPin
                                  ? 'Please enter your PIN to delete it'
                                  : 'Enter your 4-digit PIN to continue',
                          style: const TextStyle(color: Color(0xFF6B7280)),
                        ),
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(4, (index) {
                            return SizedBox(
                              width: 48,
                              child: TextField(
                                controller: _pinControllers[index],
                                focusNode: _focusNodes[index],
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                maxLength: 1,
                                style: const TextStyle(fontSize: 24),
                                obscureText: true,
                                decoration: InputDecoration(
                                  counterText: '',
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(50),
                                    borderSide: BorderSide(
                                      color: _isPinInvalid
                                          ? Colors.red
                                          : primaryColor,
                                      width: 2.0,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(50),
                                    borderSide: BorderSide(
                                      color: _isPinInvalid
                                          ? Colors.red
                                          : primaryColor,
                                      width: 2.0,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(50),
                                    borderSide: const BorderSide(
                                      color: Colors.red,
                                      width: 2.0,
                                    ),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(50),
                                    borderSide: const BorderSide(
                                      color: Colors.red,
                                      width: 2.0,
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                ),
                                onChanged: (value) {
                                  if (_errorMessage.isNotEmpty ||
                                      _isPinInvalid) {
                                    setState(() {
                                      _errorMessage = '';
                                      _isPinInvalid = false;
                                    });
                                  }
                                  if (value.length == 1 && index < 3) {
                                    _focusNodes[index + 1].requestFocus();
                                  } else if (value.isEmpty && index > 0) {
                                    _focusNodes[index - 1].requestFocus();
                                  }
                                  if (index == 3 && value.length == 1) {
                                    FocusScope.of(context).unfocus();
                                    _verifyPin();
                                  }
                                },
                              ),
                            );
                          }),
                        ),
                        if (_errorMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 24.0),
                            child: Center(
                              child: Text(
                                _errorMessage,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    final pin = _pinControllers
                                        .map((c) => c.text)
                                        .join();
                                    if (pin.length == 4) {
                                      _verifyPin();
                                    } else {
                                      setState(() {
                                        _errorMessage =
                                            'Please enter the complete 4-digit PIN.';
                                        _isPinInvalid = true;
                                      });
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text(
                                    'Continue',
                                    style: TextStyle(color: Colors.white),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
