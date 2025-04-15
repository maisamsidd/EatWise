import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:eat_wise/Controllers/splash_services.dart';
import 'package:eat_wise/Utils/app_colors.dart';
import 'package:eat_wise/main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  SplashServices splash = SplashServices();
  double opacityLevel = 0.0;

  @override
  void initState() {
    super.initState();
    splash.SplashFunction();

    // Start fade-in animation
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        opacityLevel = 1.0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: MyColors.whiteColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/Splash.json',
              height: mq.height * 0.3,
              fit: BoxFit.cover,
              repeat: true,
              errorBuilder: (context, error, stackTrace) => const Text(
                "Animation not found!",
                style: TextStyle(color: Colors.red),
              ),
            ),
            const SizedBox(height: 20),

            // Animated Fade-in Text
            AnimatedOpacity(
              duration: const Duration(seconds: 3),
              opacity: opacityLevel,
              child: const Text(
                "EatWise",
                style: TextStyle(fontSize: 45, fontWeight: FontWeight.bold),
              ),
            ),
            // SizedBox(height: mq.height * 0.01),

            AnimatedOpacity(
              duration: const Duration(seconds: 3),
              opacity: opacityLevel,
              child: const Text(
                "Your personal nutrition guide",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: mq.height * 0.03),

            // const CircularProgressIndicator(),
            // SizedBox(height: mq.height * 0.03),
            //
            // const Text(
            //   "@2025 Eat Wise, All rights reserved",
            //   style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            // ),
          ],
        ),
      ),
    );
  }
}
