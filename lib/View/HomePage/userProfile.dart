import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eat_wise/Controllers/theme_controller.dart';
import 'package:eat_wise/View/Authentication/login_page.dart';
import 'package:eat_wise/View/HomePage/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with SingleTickerProviderStateMixin {
  String userName = '';
  String accountCreated = '';
  bool isLoading = true;
  int _currentIndex = 1;
  late AnimationController _avatarController;
  late Animation<double> _avatarScale;
  final ThemeController themeController = Get.find<ThemeController>();

  @override
  void initState() {
    super.initState();
    fetchUserData();
    _avatarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _avatarScale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _avatarController, curve: Curves.easeInOut),
    );
  }

  void fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        String displayName = 'No Email';
        String formattedDate = 'Unknown';

        if (doc.exists) {
          bool isGuest = doc.data()?['isGuest'] ?? false;
          displayName = isGuest ? 'Guest' : doc.data()?['email'] ?? user.email ?? 'No Email';
          final createdAt = doc.data()?['createdAt'] as Timestamp?;
          if (createdAt != null) {
            formattedDate = DateFormat('MMM dd, yyyy').format(createdAt.toDate());
          } else {
            final creationTime = user.metadata.creationTime;
            if (creationTime != null) {
              formattedDate = DateFormat('MMM dd, yyyy').format(creationTime);
            }
          }
        } else {
          displayName = user.email ?? 'No Email';
          final creationTime = user.metadata.creationTime;
          if (creationTime != null) {
            formattedDate = DateFormat('MMM dd, yyyy').format(creationTime);
          }
        }

        setState(() {
          userName = displayName;
          accountCreated = formattedDate;
          isLoading = false;
        });
      } catch (e) {
        print('Error fetching user data: $e');
        setState(() {
          userName = user.email ?? 'No Email';
          final creationTime = user.metadata.creationTime;
          accountCreated = creationTime != null ? DateFormat('MMM dd, yyyy').format(creationTime) : 'Unknown';
          isLoading = false;
        });
      }
    } else {
      setState(() {
        userName = 'No User';
        accountCreated = 'Unknown';
        isLoading = false;
      });
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
    const maxLength = 500;
    int currentLength = 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeController.isDarkMode.value ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Send Feedback",
          style: TextStyle(
            color: themeController.isDarkMode.value ? Colors.grey[200] : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: feedbackController,
                  maxLines: 5,
                  maxLength: maxLength,
                  style: TextStyle(
                    color: themeController.isDarkMode.value ? Colors.grey[200] : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: "Write your feedback here...",
                    hintStyle: TextStyle(
                      color: themeController.isDarkMode.value ? Colors.grey[400] : Colors.grey[600],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: themeController.isDarkMode.value ? Colors.grey[800] : Colors.grey[100],
                  ),
                  onChanged: (value) {
                    setState(() {
                      currentLength = value.length;
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  "$currentLength/$maxLength",
                  style: TextStyle(
                    color: themeController.isDarkMode.value ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            child: Text(
              "Cancel",
              style: TextStyle(
                color: themeController.isDarkMode.value ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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
                Get.snackbar(
                  "Feedback Sent",
                  "Thanks for your feedback!",
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: themeController.isDarkMode.value ? Colors.grey[800] : Colors.grey[200],
                  colorText: themeController.isDarkMode.value ? Colors.grey[200] : Colors.black87,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _avatarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
      backgroundColor: themeController.isDarkMode.value ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        iconTheme: IconThemeData(color: themeController.isDarkMode.value ? Colors.grey[200] : Colors.black87),
        automaticallyImplyLeading: true,
        centerTitle: true,
        backgroundColor: themeController.isDarkMode.value ? Colors.blue.shade900 : Colors.blue.shade700,
        elevation: 0,
        title: Text(
          "My Profile",
          style: TextStyle(
            color: themeController.isDarkMode.value ? Colors.grey[200] : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: themeController.isDarkMode.value
                      ? [Colors.blue.shade900, Colors.teal.shade900]
                      : [Colors.blue.shade200, Colors.teal.shade200],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(themeController.isDarkMode.value ? 0.3 : 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _avatarController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _avatarScale.value,
                        child: Container(
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
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  isLoading
                      ? CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Colors.blue.shade700),
                  )
                      : Column(
                    children: [
                      Text(
                        userName,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: themeController.isDarkMode.value ? Colors.grey[200] : Colors.black87,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Account Created: $accountCreated',
                        style: TextStyle(
                          fontSize: 16,
                          color: themeController.isDarkMode.value ? Colors.grey[400] : Colors.grey[600],
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  _buildSettingsItem(
                    icon: Icons.dark_mode_outlined,
                    title: "Dark Mode",
                    trailing: Switch(
                      value: themeController.isDarkMode.value,
                      activeColor: Colors.blue.shade700,
                      onChanged: (value) {
                        themeController.toggleTheme();
                        HapticFeedback.lightImpact();
                      },
                    ),
                    onTap: () {
                      themeController.toggleTheme();
                      HapticFeedback.lightImpact();
                    },
                  ),
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
                        backgroundColor: themeController.isDarkMode.value ? Colors.grey[900] : Colors.white,
                        content: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "This app provides dietary suggestions for users with health conditions like diabetes, hypertension, or obesity. "
                                "Guidance is based on scanned restaurant menus and user preferences. "
                                "This does not substitute medical advice. Use responsibly.",
                            textAlign: TextAlign.justify,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        textConfirm: "OK",
                        confirmTextColor: Colors.white,
                        buttonColor: Colors.blue.shade700,
                        onConfirm: () => Get.back(),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: themeController.isDarkMode.value ? Colors.grey[850] : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(themeController.isDarkMode.value ? 0.3 : 0.05),
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
                          fontFamily: 'Poppins',
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
                  color: _currentIndex == 0 ? Colors.blue.shade200 : Colors.grey,
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
    ));
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: themeController.isDarkMode.value ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(themeController.isDarkMode.value ? 0.3 : 0.05),
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
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: themeController.isDarkMode.value ? Colors.grey[200] : Colors.black87,
            fontFamily: 'Poppins',
          ),
        ),
        trailing: trailing ??
            Icon(
              Icons.chevron_right,
              color: themeController.isDarkMode.value ? Colors.grey[400] : Colors.grey[600],
            ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}