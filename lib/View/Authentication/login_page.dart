import 'package:eat_wise/Utils/Apis_utils.dart';
import 'package:eat_wise/Utils/app_colors.dart';
import 'package:eat_wise/View/Authentication/signup_page.dart';
import 'package:eat_wise/View/HomePage/home_page.dart';
import 'package:eat_wise/Widgets/Buttons/ls_button.dart';
import 'package:eat_wise/Widgets/TextFields/login/ls_textfield.dart';
import 'package:eat_wise/main.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Email validation regex
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Save user data to Firestore
  Future<void> _saveUserToFirestore(String uid,
      {String? email, bool isGuest = false}) async {
    // Check if user already exists to avoid overwriting
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      await _firestore.collection('users').doc(uid).set({
        'email': email ?? 'guest_${uid}@eatwise.com',
        'isGuest': isGuest,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Handle Guest Login
  Future<void> _handleGuestLogin() async {
    setState(() => _isLoading = true);
    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      final user = userCredential.user;
      if (user != null) {
        await _saveUserToFirestore(user.uid, isGuest: true);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      }
    } catch (e) {
      Get.snackbar("Error", "Guest login failed: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Handle Email/Password Login
  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final userCredential = await ApisUtils.auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      final user = userCredential.user;
      if (user != null) {
        await _saveUserToFirestore(user.uid,
            email: emailController.text.trim());
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;

    return SafeArea(
      child: Scaffold(
        body: Container(
          height: mq.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue.shade700, Colors.grey.shade400],
            ),
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: mq.height * 0.03),
                  // App Logo
                  Image.asset(
                    'assets/animations/EatwiseLogo-removebg-preview.png',
                    height: 150,
                    width: 150,
                  ),
                  // SizedBox(height: mq.height * 0.015),
                  // Text(
                  //   "EatWise",
                  //   style: TextStyle(
                  //     fontSize: 32,
                  //     fontWeight: FontWeight.w600,
                  //     color: Colors.white,
                  //     letterSpacing: 1.5,
                  //   ),
                  // ),
                  Text(
                    "Log In to Your Account",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: mq.height * 0.06),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: mq.width * 0.06),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          spreadRadius: 3,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LsTextField(
                          hintText: "john123",
                          labelText: "username",
                          controller: emailController,
                          secure: false,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please enter your username";
                            }
                            if (!_isValidEmail(value)) {
                              return "Please enter a valid username";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: mq.height * 0.025),
                        LsTextField(
                          labelText: "Password",
                          controller: passwordController,
                          secure: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please enter your password";
                            }
                            if (value.length < 6) {
                              return "Password must be at least 6 characters";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: mq.height * 0.035),
                        _isLoading
                            ? const CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.blue),
                              )
                            : LsButton(
                                text: "Log In",
                                ontap: _handleEmailLogin,
                              ),
                        SizedBox(height: mq.height * 0.02),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignupPage(),
                              ),
                            );
                          },
                          child: Text(
                            "Don't have an account? Sign Up",
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: mq.height * 0.035),
                  // Guest Login Button
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: mq.width * 0.06),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleGuestLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text("Continue as Guest"),
                    ),
                  ),
                  SizedBox(height: mq.height * 0.06),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
