import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eat_wise/View/Authentication/login_page.dart';
import 'package:eat_wise/View/HomePage/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String userName = '';
  String userEmail = '';
  bool isLoading = true;

  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  void fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('userdetail')
            .doc('profile')
            .get();

        setState(() {
          userName = doc.data()?['name'] ?? 'No Name';
          userEmail = doc.data()?['email'] ?? 'No Email';
          isLoading = false;
        });
      } catch (e) {
        print('Error fetching user data: $e');
        setState(() => isLoading = false);
      }
    }
  }

  void logout() async {
    final auth = FirebaseAuth.instance;
    try {
      await auth.signOut();
      Get.offAll(() => const LoginPage());
    } catch (e) {
      print('Logout failed: $e');
    }
  }

  void _showFeedbackDialog() {
    final TextEditingController feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Send Feedback"),
        backgroundColor: Colors.white,
        content: TextField(
          controller: feedbackController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: "Write your feedback here...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white
            ),
            child: const Text("Submit"),
            onPressed: () async {
              final message = feedbackController.text.trim();
              if (message.isNotEmpty) {
                final uid = FirebaseAuth.instance.currentUser?.uid;
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('feedback')
                    .add({
                  'message': message,
                  'timestamp': Timestamp.now(),
                });
                Get.back();
                Get.snackbar("Feedback Sent", "Thanks for your feedback!",
                    snackPosition: SnackPosition.BOTTOM);
              }
            },
          ),

        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black87),
        automaticallyImplyLeading: true,
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "My Profile",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.shade700.withOpacity(0.2),
                      border: Border.all(
                        color: Colors.blue.shade700,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  isLoading
                      ? const CircularProgressIndicator()
                      : Column(
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        userEmail,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildSettingsItem(
                    icon: Icons.feedback_outlined,
                    title: "Feedback",
                    onTap: _showFeedbackDialog,
                  ),
                  _buildSettingsItem(
                    icon: Icons.description_outlined,
                    title: "Terms and Conditions",
                    onTap: () {
                      Get.defaultDialog(
                        title: "Terms & Conditions",
                        backgroundColor: Colors.white,
                        content: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "This app provides dietary suggestions for users with health conditions like diabetes, hypertension, or obesity. "
                                "Guidance is based on scanned restaurant menus and user preferences. "
                                "This does not substitute medical advice. Use responsibly.",
                            textAlign: TextAlign.justify,
                          ),
                        ),
                        textConfirm: "OK",
                        onConfirm: () => Get.back(),
                      );
                    },
                  ),
                  _buildSettingsItem(
                    icon: Icons.settings_outlined,
                    title: "App Settings",
                    onTap: () {
                      Get.snackbar(
                        "Coming Soon",
                        "You'll soon be able to customize your dietary preferences!",
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.logout,
                        color: Colors.red[400],
                      ),
                      title: const Text(
                        "Logout",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: logout,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        color: Colors.blue.shade700,
        notchMargin: 8.0,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(
                  Icons.home,
                  color: _currentIndex == 0
                      ? Colors.blue.shade200
                      : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _currentIndex = 0;
                  });
                  Get.to(() => const HomePage());
                },
              ),
              const SizedBox(width: 48),
              IconButton(
                icon: Icon(
                  Icons.person,
                  color: _currentIndex == 1
                      ? Colors.blue.shade200
                      : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _currentIndex = 1;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.blue.shade700,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
