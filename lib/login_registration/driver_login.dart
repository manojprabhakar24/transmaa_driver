import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:transmaa_driver/login_registration/register.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  static String verify = "";
  final String phoneNumber;
  final VoidCallback onLogin;

  const LoginScreen({Key? key, required this.onLogin, required this.phoneNumber}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController countryCodeController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  var phoneNumber = "";

  @override
  void initState() {
    countryCodeController.text = '+91';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(250),
        child: AppBar(
          automaticallyImplyLeading: true,
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
            Center(
              child: Text(
                'Login',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 15),
            Container(
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
                        controller: countryCodeController,
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
                          phoneNumber = value;
                        });
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: InputDecoration(
                        hintText: 'Enter your number',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.phone),
                      ),
                      controller: phoneNumberController,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: Colors.orange,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'OR',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Register()),
                );
              },
              child: Center(
                child: Text(
                  'Register A New Account?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: () {
                _verifyPhoneNumber('${countryCodeController.text + phoneNumber}');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: Text(
                'Send OTP',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),

          ],
        ),
      ),
    );
  }
  void _sendOTP(String phoneNumber, String generatedOTP) async {
    final accountSid = 'ACe4cb64943355f783e3126cdbdce9e9ee';
    final authToken = 'ab47ff372fe110076ca009d309f0cec6';
    final twilioNumber = '+14108461447';

    // Generate a random OTP (4 digits)
    final random = Random();
    final generatedOTP = random.nextInt(900000) + 100000; // Generate random 6-digit OTP

    final response = await http.post(
      Uri.parse('https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json'),
      headers: <String, String>{
        'Authorization': 'Basic ' + base64Encode(utf8.encode('$accountSid:$authToken')),
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'To': phoneNumber,
        'From': twilioNumber,
        'Body': 'Your OTP is $generatedOTP', // Replace the static OTP with the generated OTP
      },
    );

    if (response.statusCode == 201) {
      print('OTP sent successfully');
    } else {
      print('Failed to send OTP');
    }
  }
  void _verifyPhoneNumber(String phoneNumber) async {
    try {
      // Prepend the country code if it's not already included
      if (!phoneNumber.startsWith('+')) {
        phoneNumber = '+91' + phoneNumber; // Adjust the country code as necessary
      }

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Driver')
          .where('phone_number', isEqualTo: phoneNumber)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var userData = querySnapshot.docs.first;
        var status = userData['status'];

        if (status == 'pending') {
          // Display an alert message for pending verification
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                content: Text(
                  "Your verification is currently in progress. Please wait for some time.",
                ),
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
        } else if (status == 'Verified') {
          // Generate a random OTP (6 digits)
          final generatedOTP = _generateOTP();
          // Proceed with sending OTP

          _sendOTP(phoneNumber, generatedOTP); // Call OTP sending function
          // Navigate to OTP screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OTP(
                phoneNumber: widget.phoneNumber,
                generatedOTP: generatedOTP,
                enteredName: '',
              ),
            ),
          );
        } else if (status == 'Rejected') {
          // Display rejected message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Your number is rejected . please contact transmaa +911234567890.'),
            ),
          );
        }
      } else {
        // Display warning message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('This phone number is not registered. Please register first.'),
          ),
        );
      }
    } catch (e) {
      print("Error verifying phone number: $e");
      // Handle error verifying phone number
    }
  }

// Function to generate a random OTP (6 digits)
  String _generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }


}
class APIs {
  static FirebaseAuth auth = FirebaseAuth.instance;

  static FirebaseFirestore firestore = FirebaseFirestore.instance;

  static Future<bool> phoneNumberExists(String phoneNumber) async {
    try {
      // Query Firestore to check if the phone number exists
      QuerySnapshot querySnapshot = await firestore
          .collection('number')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .where('status', isEqualTo: phoneNumber)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print("Error checking phone number existence: $e");
      // Handle error checking phone number existence
      return false;
    }
  }

  static Future<String> getVerificationStatus(String phoneNumber) async {
    try {
      // Query Firestore to get the verification status
      DocumentSnapshot documentSnapshot =
      await firestore.collection('Driver').doc(phoneNumber).get();

      if (documentSnapshot.exists) {
        return documentSnapshot.get('status');
      } else {
        return 'Pending'; // Assuming pending if not found
      }
    } catch (e) {
      print("Error getting verification status: $e");
      // Handle error getting verification status
      return 'error';
    }
  }
}
