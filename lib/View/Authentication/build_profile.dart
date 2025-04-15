import 'package:eat_wise/Utils/Apis_utils.dart';
import 'package:eat_wise/Utils/app_colors.dart';
import 'package:eat_wise/View/HomePage/Users_details.dart';
import 'package:eat_wise/Widgets/Buttons/profile_build_button.dart';
import 'package:eat_wise/Widgets/TextFields/login/profile_build_textfield.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../main.dart';

class SignUpBuild extends StatefulWidget {
  const SignUpBuild({super.key});

  @override
  State<SignUpBuild> createState() => _SignUpBuildState();
}

class _SignUpBuildState extends State<SignUpBuild> {
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final diseaseController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;
    return SafeArea(
      child: Scaffold(
        backgroundColor: MyColors.greyColor,
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                height: 80,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: const Center(
                  child: Text(
                    "Add a Profile",
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: mq.height * 0.1),

              // Profile Form Card
              Container(
                padding: const EdgeInsets.all(20),
                width: mq.width * 0.9,
                decoration: BoxDecoration(
                  color: MyColors.whiteColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ProfileBuildTextfield(
                      hintText: "John Doe",
                      labelText: "Full Name",
                      controller: nameController,
                    ),
                    const SizedBox(height: 16),
                    ProfileBuildTextfield(
                      hintText: "24",
                      labelText: "Age",
                      controller: ageController,
                    ),
                    const SizedBox(height: 16),
                    ProfileBuildTextfield(
                      hintText: "e.g Diabetes",
                      labelText: "Condition",
                      controller: diseaseController,
                    ),
                    const SizedBox(height: 24),
                    ProfileBuildButton(
                      ontap: () async {
                        // Input Validation
                        if (nameController.text.isEmpty ||
                            ageController.text.isEmpty ||
                            diseaseController.text.isEmpty) {
                          Get.snackbar(
                            "Error",
                            "All fields are required",
                            snackPosition: SnackPosition.BOTTOM,
                          );
                          return;
                        }

                        try {
                          // Firestore Write Operation
                          await ApisUtils.users
                              .doc(ApisUtils.auth.currentUser!.uid)
                              .collection("userDetails")
                              .add({
                            "name": nameController.text.trim(),
                            "age": int.tryParse(ageController.text.trim()) ?? 0,
                            "disease": diseaseController.text.trim(),
                          });

                          // Navigate to UsersHistory
                          Get.to(() => const UsersHistory());

                          // Clear text fields
                          nameController.clear();
                          ageController.clear();
                          diseaseController.clear();
                        } catch (e) {
                          Get.snackbar(
                            "Error",
                            "Failed to add data: $e",
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: mq.height * 0.05),
            ],
          ),
        ),
      ),
    );
  }
}
