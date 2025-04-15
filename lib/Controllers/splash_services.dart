import 'package:eat_wise/View/HomePage/home_page.dart';
import 'package:get/get.dart';

import '../Utils/Apis_utils.dart';
import '../View/Authentication/login_page.dart';

class SplashServices extends GetxController {
  void SplashFunction() async {
    Future.delayed(const Duration(seconds: 7), () {
      if (ApisUtils.auth.currentUser == null) {
        // Navigate to LoginPage
        Get.off(() => const LoginPage());
      } else {
        // Navigate to HomePage
        Get.off(() => const HomePage());
      }
    });
  }
}
