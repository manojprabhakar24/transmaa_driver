import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:transmaa_driver/login_registration/personalinformation.dart';
import 'package:twilio_flutter/twilio_flutter.dart'; // Import Twilio package

class Register extends StatefulWidget {
  const Register({Key? key}) : super(key: key);
  static String verify = "";

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController countryCode = TextEditingController();
  var phone = "";
  bool _isLoading = false;
  int selectedSegment = 0;
  String errorMessage = '';
  late FocusNode _otpFocusNode;
  late Timer _timer;
  int _start = 60;
  bool isVerificationCompleted = false;
  bool _isTimerExpired = false;
  bool _otpSent = false; // Flag to track if OTP is sent

  // Initialize TwilioFlutter instance
  final twilioFlutter = TwilioFlutter(
    accountSid: 'ACe4cb64943355f783e3126cdbdce9e9ee',
    authToken: 'ab47ff372fe110076ca009d309f0cec6',
    twilioNumber: '+14108461447',
  );

  String generateOTP() {
    Random random = Random();
    int otp = random.nextInt(900000) +
        100000; // Generates a random 6-digit number
    return otp.toString();
  }

  @override
  void initState() {
    super.initState();
    _otpFocusNode = FocusNode();
    countryCode.text = '+91';
  }

  @override
  void dispose() {
    _otpFocusNode.dispose();
    _otpController.dispose();
    if (_timer.isActive) {
      _timer.cancel();
    }
    super.dispose();
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
              Image.asset(
                'assets/Finallogo.png',
                width: 200,
                height: 100,
              ),
              Text(
                'Welcome',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              Text(
                '"Unlock Your Journey"',
                style: TextStyle(fontSize: 18),
              ),
              Text(
                'Register Today',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedSegment = 0;
                      });
                    },
                    child: buildSegment(
                        height: 9,
                        color:
                        selectedSegment == 0 ? Colors.orange : Colors.grey),
                  ),
                ),
                SizedBox(width: 8), // Add a gap
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedSegment = 1;
                      });
                    },
                    child: buildSegment(
                        height: 9,
                        color:
                        selectedSegment == 1 ? Colors.orange : Colors.grey),
                  ),
                ),
                SizedBox(width: 8), // Add a gap
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedSegment = 2;
                      });
                    },
                    child: buildSegment(
                        height: 9,
                        color:
                        selectedSegment == 2 ? Colors.orange : Colors.grey),
                  ),
                ),
                SizedBox(width: 8), // Add a gap
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedSegment = 3;
                      });
                    },
                    child: buildSegment(
                        height: 9,
                        color:
                        selectedSegment == 3 ? Colors.orange : Colors.grey),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Registration',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 55,
                    decoration: BoxDecoration(
                      border: Border.all(width: 1, color: Colors.orange),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white38,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: TextField(
                              style: TextStyle(color: Colors.black87),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                              ),
                              controller: countryCode,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          '|',
                          style: TextStyle(fontSize: 30, color: Colors.black),
                        ),
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.phone,
                            onChanged: (value) {
                              setState(() {
                                phone = value;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Enter your number',
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.phone),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          onPressed: () async {
                            // Reset the verification ID
                            Register.verify = "";

                            // Check if OTP is already sent
                            if (!_otpSent) {
                              // Check if the phone number is already registered
                              bool isPhoneNumberRegistered = await APIs
                                  .isPhoneNumberRegistered(
                                  '${countryCode.text + phone}');

                              if (isPhoneNumberRegistered) {
                                // If phone number is already registered, show an error dialog
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      content: Text(
                                          "Sorry, the entered mobile number is already registered."),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Text('OK'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              } else {
                                // Send OTP using Twilio
                                await sendOTP('${countryCode.text + phone}');
                              }
                            }
                          },
                          child: Text(
                            'Get OTP',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OTP',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 10),
            Pinput(
              length: 6,


              defaultPinTheme: defaultPinTheme,
              controller: _otpController,
              focusNode: _otpFocusNode,
              onChanged: (value) {
                if (value.length == 6) {
                  _verifyOTP(value);
                }
              },
            ),
            SizedBox(height: 10),
            Center(
              child: Text(
                errorMessage,
                style: TextStyle(color: Colors.red),
              ),
            ),
            SizedBox(height: 10),
            Center(
              child: _start > 0 && !_isTimerExpired
                  ? Text(
                'Resend OTP in $_start seconds',
                style: TextStyle(color: Colors.orange),
              )
                  : TextButton(
                onPressed: () async {
                  setState(() {
                    _start = 60;
                    _isTimerExpired = false;
                  });
                  // Reset the OTP sent flag
                  _otpSent = false;
                  _otpController.clear();
                  await _startTimer();
                  // Resend OTP using Twilio
                  await sendOTP('${countryCode.text + phone}');
                },
                style: ButtonStyle(
                  foregroundColor: MaterialStateProperty.all<Color>(
                      Colors.orange),
                  textStyle: MaterialStateProperty.all<TextStyle>(
                      TextStyle(decoration: TextDecoration.underline)),
                ),
                child: Text('Resend OTP'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSegment({double height = 6, Color color = Colors.grey}) {
    return Container(
      height: height,
      color: color,
    );
  }

  void _verifyOTP(String enteredOTP) async {
    try {
      if (_isTimerExpired) {
        setState(() {
          errorMessage =
          'OTP has expired. Please click Resend OTP to get a new one.';
        });
      } else {
        // Check if the entered OTP matches the one sent via Twilio
        if (enteredOTP == Register.verify) {
          // OTP verification successful, navigate to the next screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  PersonalScreen(phoneNumber: countryCode.text + phone),
            ),
          );
        } else {
          // Incorrect OTP, display an error message
          setState(() {
            errorMessage = 'Incorrect OTP. Please enter the correct OTP.';
          });
        }
      }
    } catch (e) {
      print("Error verifying OTP: $e");
      setState(() {
        errorMessage = 'An unexpected error occurred. Please try again.';
      });
    }
  }

  Future<void> _startTimer() async {
    const oneSec = const Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
          (Timer timer) {
        if (_start == 0) {
          setState(() {
            _isTimerExpired = true;
            timer.cancel();
          });
        } else {
          setState(() {
            _start--;
          });
        }
      },
    );
  }

  // Function to send OTP using Twilio
// Function to send OTP using Twilio
  Future<void> sendOTP(String phoneNumber) async {
    try {
      String otp = generateOTP(); // Generate the OTP

      // Save the OTP to verify against when entered by the user
      Register.verify = otp; // Add this line to save the OTP

      final response = await twilioFlutter.sendSMS(
        toNumber: phoneNumber, // Corrected the parameter name to 'toNumber'
        messageBody: 'Your Transmaa OTP is: $otp', // Use the generated OTP in the message
      );

      // Check if OTP is sent successfully
      if (response != null) {
        setState(() {
          _otpSent = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP has been sent to $phoneNumber'),
          ),
        );

        // Start the timer when OTP is sent
        _startTimer();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send OTP. Please try again.'),
          ),
        );
      }
    } catch (e) {
      print('Error sending OTP: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending OTP. Please try again.'),
        ),
      );
    }
  }
}

class APIs {
  static FirebaseAuth auth = FirebaseAuth.instance;
  static FirebaseFirestore firestore = FirebaseFirestore.instance;

  static Future<void> updatePhoneNumber(String phoneNumber) async {
    try {
      DocumentSnapshot docSnapshot =
      await firestore.collection('number').doc(auth.currentUser!.uid).get();

      if (docSnapshot.exists) {
        await firestore.collection('number').doc(auth.currentUser!.uid).update({
          'phoneNumber': phoneNumber,
        });
      } else {
        await firestore.collection('number').doc(auth.currentUser!.uid).set({
          'phoneNumber': phoneNumber,
        });
      }
    } catch (e) {
      print("Error updating phone number: $e");
    }
  }

  static Future<bool> isPhoneNumberRegistered(String phoneNumber) async {
    try {
      QuerySnapshot querySnapshot = await firestore
          .collection('number')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print("Error checking phone number registration: $e");
      return false;
    }
  }

}