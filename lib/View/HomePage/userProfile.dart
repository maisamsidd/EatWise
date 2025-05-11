import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eat_wise/View/Authentication/login_page.dart';
import 'package:eat_wise/View/HomePage/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart'; // For haptic feedback

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  String userName = '';
  String userEmail = '';
  bool isLoading = true;
  bool isDarkMode = false;

  int _currentIndex = 1;

  // Animation for profile avatar
  late AnimationController _avatarController;
  late Animation<double> _avatarScale;

  @override
  void initState() {
    super.initState();
    fetchUserData();
    loadThemePreference();

    // Initialize avatar animation
    _avatarController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _avatarScale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _avatarController, curve: Curves.easeInOut),
    );
  }

  // Load theme preference from SharedPreferences
  void loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  // Save theme preference
  void saveThemePreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    setState(() {
      isDarkMode = value;
    });
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
    const maxLength = 500;
    int currentLength = 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Send Feedback",
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
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
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: "Write your feedback here...",
                    hintStyle: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  ),
                  onChanged: (value) {
                    setState(() {
                      currentLength = value.length;
                    });
                  },
                ),
                SizedBox(height: 8),
                Text(
                  "${currentLength}/$maxLength",
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
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
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
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
                  backgroundColor:
                  isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  colorText: isDarkMode ? Colors.white : Colors.black87,
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
    return Theme(
      data: isDarkMode ? _darkTheme : _lightTheme,
      child: Scaffold(
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
        appBar: AppBar(
          iconTheme: IconThemeData(
              color: isDarkMode ? Colors.white : Colors.black87),
          automaticallyImplyLeading: true,
          centerTitle: true,
          backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
          elevation: 0,
          title: Text(
            "My Profile",
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
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
                    colors: isDarkMode
                        ? [Colors.blue.shade900, Colors.teal.shade900]
                        : [Colors.blue.shade200, Colors.teal.shade200],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
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
                      valueColor:
                      AlwaysStoppedAnimation(Colors.blue.shade700),
                    )
                        : Column(
                      children: [
                        Text(
                          userName,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color:
                            isDarkMode ? Colors.white : Colors.black87,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          userEmail,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  children: [
                    _buildSettingsItem(
                      icon: Icons.dark_mode_outlined,
                      title: "Dark Mode",
                      trailing: Switch(
                        value: isDarkMode,
                        activeColor: Colors.blue.shade700,
                        onChanged: (value) {
                          saveThemePreference(value);
                          HapticFeedback.lightImpact();
                        },
                      ),
                      onTap: () {
                        saveThemePreference(!isDarkMode);
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
                          backgroundColor:
                          isDarkMode ? Colors.grey[900] : Colors.white,
                          content: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              "This app provides dietary suggestions for users with health conditions like diabetes, hypertension, or obesity. "
                                  "Guidance is based on scanned restaurant menus and user preferences. "
                                  "This does not substitute medical advice. Use responsibly.",
                              textAlign: TextAlign.justify,
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
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
                        color: isDarkMode ? Colors.grey[850] : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
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
                        title: Text(
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
      ),
    );
  }

  // Define light and dark themes
  final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.blue.shade700,
    scaffoldBackgroundColor: Colors.grey[50],
    textTheme: TextTheme(
      bodyMedium: TextStyle(color: Colors.black87, fontFamily: 'Poppins'),
      titleLarge: TextStyle(
          color: Colors.black87, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
    ),
    iconTheme: IconThemeData(color: Colors.black87),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );

  final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.blue.shade900,
    scaffoldBackgroundColor: Colors.grey[900],
    textTheme: TextTheme(
      bodyMedium: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
      titleLarge: TextStyle(
          color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
    ),
    iconTheme: IconThemeData(color: Colors.white),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
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
            color: isDarkMode ? Colors.white : Colors.black87,
            fontFamily: 'Poppins',
          ),
        ),
        trailing: trailing ??
            Icon(
              Icons.chevron_right,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}