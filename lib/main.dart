import 'package:eat_wise/Controllers/theme_controller.dart';
import 'package:eat_wise/View/SplashScreen/Splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:eat_wise/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register ThemeController with GetX
  Get.put(ThemeController());

  runApp(const MyApp());
}

late Size mq;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();

    return Obx(() => GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.blue.shade700,
        scaffoldBackgroundColor: Colors.transparent, // Ensure transparency for background images
        appBarTheme: AppBarTheme(
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          backgroundColor: Colors.blue.shade700,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black54),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blue.shade900,
        scaffoldBackgroundColor: Colors.transparent, // Ensure transparency for background images
        appBarTheme: AppBarTheme(
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          backgroundColor: Colors.blue.shade900,
          elevation: 0,
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.grey[200]),
          bodyMedium: TextStyle(color: Colors.grey[400]),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade900,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        iconTheme: IconThemeData(color: Colors.grey[200]),
      ),
      themeMode: themeController.isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
    ));
  }
}