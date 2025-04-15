import 'package:eat_wise/Utils/app_colors.dart';
import 'package:eat_wise/View/Chatbot/chat_bot.dart';
import 'package:eat_wise/View/SplashScreen/Splash_screen.dart';
import 'package:eat_wise/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

late Size mq;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          appBarTheme: AppBarTheme(
              titleTextStyle: TextStyle(color: MyColors.BlackColor),
              backgroundColor: const Color.fromARGB(255, 138, 203, 233))),
      home: const SplashScreen(),
    );
  }
}
