import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:animate_gradient/animate_gradient.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eat_wise/Controllers/splash_services.dart';
import 'package:eat_wise/Controllers/theme_controller.dart';
import 'package:get/get.dart';
import 'dart:ui';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  SplashServices splash = SplashServices();
  double opacityLevel = 0.0;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _textSlideController;
  late Animation<Offset> _titleSlideAnimation;
  late Animation<Offset> _taglineSlideAnimation;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  final ThemeController themeController = Get.find<ThemeController>(); // Access ThemeController

  @override
  void initState() {
    super.initState();
    splash.SplashFunction();

    // Initialize animations
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    _textSlideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _titleSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textSlideController, curve: Curves.easeOutCubic),
    );
    _taglineSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textSlideController, curve: Curves.easeOutCubic),
    );

    _progressController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // Start animations
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        opacityLevel = 1.0;
      });
      _scaleController.forward();
      _textSlideController.forward();
      _progressController.forward();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _textSlideController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;

    // Wrap the Scaffold with Obx to react to theme changes
    return Obx(() => Scaffold(
      body: AnimateGradient(
        primaryColors: [
          themeController.isDarkMode.value
              ? Colors.blue.shade900.withOpacity(0.7) // Match HomePage dark mode gradient
              : Colors.blue.shade400.withOpacity(0.8), // Match HomePage light mode gradient
          themeController.isDarkMode.value
              ? Colors.grey[900]!.withOpacity(0.8) // Match HomePage dark mode background
              : Colors.white.withOpacity(0.9), // Match HomePage light mode background
        ],
        secondaryColors: [
          themeController.isDarkMode.value
              ? Colors.blue.shade700.withOpacity(0.7) // Consistent with HomePage AppBar
              : Colors.blue.shade200.withOpacity(0.8), // Lighter blue for light mode
          themeController.isDarkMode.value
              ? Colors.grey[900]!.withOpacity(0.8)
              : Colors.white.withOpacity(0.9),
        ],
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Lottie.asset(
                      themeController.isDarkMode.value
                          ? 'assets/animations/Splash.json'
                          : 'assets/animations/Splash.json',
                      height: mq.height * 0.3,
                      fit: BoxFit.cover,
                      repeat: true,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        'assets/images/fallback_logo.png',
                        height: mq.height * 0.3,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Text(
                          "Image not found!",
                          style: TextStyle(
                            color: themeController.isDarkMode.value
                                ? Colors.red[400]
                                : Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: mq.height * 0.02),
                  AnimatedOpacity(
                    duration: const Duration(seconds: 2),
                    opacity: opacityLevel,
                    child: SlideTransition(
                      position: _titleSlideAnimation,
                      child: Text(
                        "EatWise",
                        style: GoogleFonts.poppins(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: themeController.isDarkMode.value
                              ? Colors.blue.shade200 // Dark mode text
                              : Colors.blue.shade700, // Light mode text
                          shadows: [
                            Shadow(
                              blurRadius: 10,
                              color: themeController.isDarkMode.value
                                  ? Colors.black.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.2),
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: mq.height * 0.01),
                  AnimatedOpacity(
                    duration: const Duration(seconds: 2),
                    opacity: opacityLevel,
                    child: SlideTransition(
                      position: _taglineSlideAnimation,
                      child: Text(
                        "Your personal nutrition guide",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: themeController.isDarkMode.value
                              ? Colors.grey[400]!.withOpacity(0.7)
                              : Colors.grey[600]!.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: mq.height * 0.03),
                  AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      return Container(
                        width: mq.width * 0.6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: themeController.isDarkMode.value
                              ? Colors.grey[800]!.withOpacity(0.2)
                              : Colors.grey[300]!.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _progressAnimation.value,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  themeController.isDarkMode.value
                                      ? const Color(0xFF6DD5FA).withOpacity(0.8)
                                      : const Color(0xFF6DD5FA),
                                  themeController.isDarkMode.value
                                      ? const Color(0xFF2980B9).withOpacity(0.8)
                                      : const Color(0xFF2980B9),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: mq.height * 0.03,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: themeController.isDarkMode.value
                      ? Colors.grey[850]!.withOpacity(0.3)
                      : Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: themeController.isDarkMode.value
                          ? Colors.black.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Text(
                      "@2025 EatWise, All rights reserved",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: themeController.isDarkMode.value
                            ? Colors.grey[400]!.withOpacity(0.7)
                            : Colors.grey[600]!.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }
}