import 'package:eat_wise/Utils/Apis_utils.dart';
import 'package:eat_wise/View/Authentication/login_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
            onPressed: () {
              ApisUtils.auth
                  .signOut()
                  .then((onValue) => Get.to(() => const LoginPage()));
            },
            child: const Text("Logout")),
      ),
    );
  }
}
