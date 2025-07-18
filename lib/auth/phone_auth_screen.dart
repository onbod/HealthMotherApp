import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PhoneAuthScreen extends StatefulWidget {
  @override
  _PhoneAuthScreenState createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  String? verificationId;

  Future<void> verifyPhoneNumber() async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneController.text,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        print("Auto signed in ✅");
      },
      verificationFailed: (FirebaseAuthException e) {
        print("Verification failed: ${e.message}");
      },
      codeSent: (String id, int? resendToken) {
        setState(() {
          verificationId = id;
        });
        print("Code sent ✅");
      },
      codeAutoRetrievalTimeout: (String id) {
        verificationId = id;
      },
    );
  }

  Future<void> signInWithOTP() async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId!,
      smsCode: otpController.text.trim(),
    );
    await FirebaseAuth.instance.signInWithCredential(credential);
    print("Logged in with OTP ✅");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Phone Auth')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: phoneController,
              decoration: InputDecoration(labelText: 'Phone (+1234567890)'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: verifyPhoneNumber,
              child: Text("Send OTP"),
            ),
            TextField(
              controller: otpController,
              decoration: InputDecoration(labelText: 'Enter OTP'),
            ),
            SizedBox(height: 10),
            ElevatedButton(onPressed: signInWithOTP, child: Text("Verify OTP")),
          ],
        ),
      ),
    );
  }
}
