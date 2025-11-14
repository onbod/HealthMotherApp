import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinVerificationScreen extends StatefulWidget {
  final bool isChangingPin;
  final bool isDeletingPin;
  final VoidCallback? onVerified;

  const PinVerificationScreen({
    super.key,
    this.isChangingPin = false,
    this.isDeletingPin = false,
    this.onVerified,
  });

  @override
  State<PinVerificationScreen> createState() => _PinVerificationScreenState();
}

class _PinVerificationScreenState extends State<PinVerificationScreen> {
  final List<TextEditingController> _pinControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  String _errorMessage = '';
  bool _isLoading = false;
  bool _isPinInvalid = false;
  bool _isDisposed = false;

  final Color primaryColor = const Color(0xFF7C4DFF);

  @override
  void dispose() {
    _isDisposed = true;
    for (var controller in _pinControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyPin() async {
    if (_isDisposed || !mounted) return;

    final enteredPin = _pinControllers.map((c) => c.text).join();

    if (!mounted || _isDisposed) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _isPinInvalid = false;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted || _isDisposed) return;

      final savedPin = prefs.getString('user_pin');

      if (savedPin == enteredPin) {
        if (mounted && !_isDisposed) {
          if (widget.onVerified != null) {
            widget.onVerified!();
          } else {
            Navigator.maybePop(context, true);
          }
        }
      } else {
        if (!mounted || _isDisposed) return;
        setState(() {
          _errorMessage = 'Incorrect PIN. Please try again.';
          _isPinInvalid = true;
        });

        if (mounted && !_isDisposed) {
          try {
            for (var c in _pinControllers) {
              c.clear();
            }
            if (_focusNodes[0].canRequestFocus) {
              _focusNodes[0].requestFocus();
            }
          } catch (e) {
            debugPrint('Error clearing PIN controllers: $e');
          }
        }
      }
    } catch (e) {
      if (!mounted || _isDisposed) return;
      setState(() {
        _errorMessage = 'Failed to verify PIN. Please try again.';
        _isPinInvalid = true;
      });
    } finally {
      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Verify PIN';
    String subtitle = 'Enter your 4-digit PIN to continue';
    if (widget.isChangingPin) {
      title = 'Enter Current PIN';
      subtitle = 'Please enter your current PIN to change it';
    } else if (widget.isDeletingPin) {
      title = 'Verify PIN to Delete';
      subtitle = 'Please enter your PIN to delete it';
    }

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
                        Navigator.maybePop(context);
                      }
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
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
                      child: const Icon(
                        Icons.lock_outline,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(4, (index) {
                        return SizedBox(
                          width: 60,
                          height: 70,
                          child: TextField(
                            controller: _pinControllers[index],
                            focusNode: _focusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                            obscureText: true,
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: _isPinInvalid
                                  ? Colors.red.shade50
                                  : Colors.grey.shade50,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: _isPinInvalid
                                      ? Colors.red
                                      : Colors.grey.shade300,
                                  width: 2.0,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: _isPinInvalid
                                      ? Colors.red
                                      : primaryColor,
                                  width: 2.5,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 2.0,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 2.5,
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              if (_isDisposed || !mounted) return;

                              if (_errorMessage.isNotEmpty ||
                                  _isPinInvalid) {
                                if (mounted && !_isDisposed) {
                                  setState(() {
                                    _errorMessage = '';
                                    _isPinInvalid = false;
                                  });
                                }
                              }
                              if (value.length == 1 && index < 3) {
                                if (_focusNodes[index + 1].canRequestFocus) {
                                  _focusNodes[index + 1].requestFocus();
                                }
                              } else if (value.isEmpty && index > 0) {
                                if (_focusNodes[index - 1].canRequestFocus) {
                                  _focusNodes[index - 1].requestFocus();
                                }
                              }
                              if (index == 3 && value.length == 1) {
                                FocusScope.of(context).unfocus();
                                Future.microtask(() {
                                  if (mounted && !_isDisposed) {
                                    _verifyPin();
                                  }
                                });
                              }
                            },
                          ),
                        );
                      }),
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
                                textAlign: TextAlign.center,
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
              const SizedBox(height: 24),
              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading || _isDisposed
                      ? null
                      : () {
                          if (!mounted || _isDisposed) return;
                          final pin =
                              _pinControllers.map((c) => c.text).join();
                          if (pin.length == 4) {
                            _verifyPin();
                          } else {
                            if (mounted && !_isDisposed) {
                              setState(() {
                                _errorMessage =
                                    'Please enter the complete 4-digit PIN.';
                                _isPinInvalid = true;
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
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
            ],
          ),
        ),
      ),
    );
  }
}
