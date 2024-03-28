import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../bottomnavigation/bottom_navigation_screen.dart';

class OTP extends StatefulWidget {
  final String enteredName;
  final String phoneNumber;
  final String generatedOTP;

  const OTP({Key? key, required this.enteredName, required this.phoneNumber, required this.generatedOTP}) : super(key: key);

  @override
  State<OTP> createState() => _OTPState();
}

class _OTPState extends State<OTP> with SingleTickerProviderStateMixin {
  final TextEditingController _otpController = TextEditingController();
  String errorMessage = '';
  late FocusNode _otpFocusNode;
  late AnimationController _animationController;
  late Animation<double> _animation;
  late Timer _timer;
  int _start = 60;

  @override
  void initState() {
    super.initState();
    _otpFocusNode = FocusNode();
    _otpFocusNode.requestFocus();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.repeat(reverse: true);

    // Start the timer
    startTimer();
  }

  @override
  void dispose() {
    _otpFocusNode.dispose();
    _otpController.dispose();
    _animationController.dispose();
    // Dispose of the timer
    _timer.cancel();
    super.dispose();
  }

  void startTimer() {
    const oneSec = const Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
          (Timer timer) {
        if (_start == 0) {
          // If timer reaches zero, cancel the timer
          timer.cancel();
        } else {
          setState(() {
            _start--;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: const TextStyle(
        fontSize: 22,
        color: Colors.black,
      ),
      decoration: BoxDecoration(
        color: Colors.red[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.transparent),
      ),
    );
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(250),
        child: AppBar(
          backgroundColor: Color(0xffffded0),
          flexibleSpace: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _animation,
                child: Image.asset(
                  'assets/Finallogo.png',
                  width: 200,
                  height: 100,
                ),
              ),
              const Text(
                'Welcome',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.white, Colors.white]),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 50,
                ),
                Text(
                  'Verify your Phone Number',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 25,
                  ),
                  textAlign: TextAlign.start,
                ),
                SizedBox(
                  height: 30,
                ),
                Pinput(
                  length: 6,
                  defaultPinTheme: defaultPinTheme,
                  showCursor: true,
                  controller: _otpController,
                  focusNode: _otpFocusNode,
                  onChanged: (value) {
                    // Check if entered OTP is correct
                    if (value.length == 6) {
                      _verifyOTP(value, widget.generatedOTP); // Pass generated OTP for verification
                    }else {
                      // Clear the error message if OTP is not 6 digits
                      setState(() {
                        errorMessage = '';
                      });
                    }
                  },
                ),
                SizedBox(
                  height: 18,
                ),
                // Display error message or timer
                Text(
                  errorMessage.isNotEmpty
                      ? errorMessage
                      : '$_start seconds remaining',
                  style: TextStyle(color: Colors.red),
                ),
                // Button to resend OTP
                ElevatedButton(
                  onPressed: _start == 0 ? _resendOTP : null,
                  child: Text('Resend OTP'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _verifyOTP(String enteredOTP, String generatedOTP) {
    // Simulate OTP verification
    if (enteredOTP == generatedOTP) {
      // OTP verification successful, proceed with navigation
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MyHomePage(onLogout: () {}, enteredName: '', documentId: '', phoneNumber: ''),
        ),
      );
    } else {
      // OTP verification failed, display error message
      setState(() {
        errorMessage = 'Incorrect OTP. Please try again.';
      });
    }
  }

  // Function to handle resend OTP
  void _resendOTP() async {
    _otpController.clear();
    // Reset the timer
    setState(() {
      _start = 60;
    });
    // Start the timer again
    startTimer();

    // Make API call to your server to resend OTP
    try {
      await http.post(
        Uri.parse('YOUR_RESEND_OTP_ENDPOINT'), // Replace with your resend OTP endpoint
        body: {
          'phoneNumber': widget.phoneNumber,
        },
      );
    } catch (e) {
      print('Error resending OTP: $e');
      // Handle error
    }
  }
}
