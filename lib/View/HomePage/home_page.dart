import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eat_wise/Controllers/theme_controller.dart';
import 'package:eat_wise/Utils/Apis_utils.dart';
import 'package:eat_wise/View/Ai_related_work/ScanPage/scan_page.dart';
import 'package:eat_wise/View/HomePage/userProfile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../Ai_related_work/ScanPage/output.dart';
import '../Chatbot/chat_bot.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;
  late AnimationController _fabVanishController;
  late Animation<double> _fabVanishAnimation;
  bool _isAnimationInitialized = false;
  bool _showSwipeHint = false; // Flag for swipe hint
  bool _isFirstLogin = false; // Flag for first login

  bool diabetes = false;
  bool hypertension = false;
  bool obesity = false;
  bool highCholesterol = false;

  final ThemeController themeController = Get.find<ThemeController>();

  @override
  void initState() {
    super.initState();
    // Glow animation for FAB
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Vanishing animation for FAB
    _fabVanishController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fabVanishAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fabVanishController, curve: Curves.easeInOut),
    );

    // Mark animations as initialized
    _isAnimationInitialized = true;

    // Check for first-time user and swipe hint status
    _checkFirstTimeUser();
    _checkSwipeHintStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabVanishController.dispose();
    nameController.dispose();
    ageController.dispose();
    super.dispose();
  }

  String _capitalize(String name) {
    if (name.isEmpty) return name;
    return name[0].toUpperCase() + name.substring(1).toLowerCase();
  }

  // Check if user has no profiles
  void _checkFirstTimeUser() async {
    try {
      final snapshot = await ApisUtils.users
          .doc(ApisUtils.auth.currentUser?.uid)
          .collection("profiles")
          .get();
      if (snapshot.docs.isEmpty && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showOnboardingDialog();
        });
      }
    } catch (e) {
      debugPrint("Error checking first-time user: $e");
    }
  }

  // Check if it's the first login and if swipe hint has been shown
  void _checkSwipeHintStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenSwipeHint = prefs.getBool('hasSeenSwipeHint') ?? false;
    final isFirstLogin = prefs.getBool('isFirstLogin') ??
        true; // Default to true for first login

    if (isFirstLogin && !hasSeenSwipeHint && mounted) {
      final snapshot = await ApisUtils.users
          .doc(ApisUtils.auth.currentUser?.uid)
          .collection("profiles")
          .get();
      if (snapshot.docs.isNotEmpty) {
        // Only show if there are profiles
        setState(() {
          _isFirstLogin = true;
          _showSwipeHint = true;
        });
      }
      // Mark first login as false after checking
      await prefs.setBool('isFirstLogin', false);
    }
  }

  // Save swipe hint dismissal
  Future<void> _saveSwipeHintDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenSwipeHint', true);
    if (mounted) {
      setState(() {
        _showSwipeHint = false;
      });
    }
  }

  // Show onboarding dialog for first-time users
  void _showOnboardingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: themeController.isDarkMode.value
              ? Colors.grey[900]
              : Colors.white.withOpacity(0.95),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "Welcome to EatWise!",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Let's get started by adding your first profile.",
                style: TextStyle(
                  fontSize: 16,
                  color: themeController.isDarkMode.value
                      ? Colors.grey[400]
                      : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Tap the + button below to create a profile.",
                style: TextStyle(
                  fontSize: 14,
                  color: themeController.isDarkMode.value
                      ? Colors.grey[400]
                      : Colors.black87,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _addUser();
              },
              child: const Text("Add Profile",
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _addUser() {
    nameController.clear();
    ageController.clear();
    diabetes = false;
    hypertension = false;
    obesity = false;
    highCholesterol = false;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Text(
                "New Profile",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          backgroundColor: themeController.isDarkMode.value
              ? Colors.grey[900]
              : Colors.white.withOpacity(0.95),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tell Us About You",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: themeController.isDarkMode.value
                            ? Colors.grey[200]
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Name",
                      style: TextStyle(
                        fontSize: 16,
                        color: themeController.isDarkMode.value
                            ? Colors.grey[400]
                            : Colors.black54,
                      ),
                    ),
                    TextField(
                      controller: nameController,
                      style: TextStyle(
                        color: themeController.isDarkMode.value
                            ? Colors.grey[200]
                            : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: "Enter your name",
                        hintStyle: TextStyle(
                          color: themeController.isDarkMode.value
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                        filled: true,
                        fillColor: themeController.isDarkMode.value
                            ? Colors.grey[800]
                            : Colors.blue.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Age",
                      style: TextStyle(
                        fontSize: 16,
                        color: themeController.isDarkMode.value
                            ? Colors.grey[400]
                            : Colors.black54,
                      ),
                    ),
                    TextField(
                      controller: ageController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        color: themeController.isDarkMode.value
                            ? Colors.grey[200]
                            : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: "Enter your age",
                        hintStyle: TextStyle(
                          color: themeController.isDarkMode.value
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                        filled: true,
                        fillColor: themeController.isDarkMode.value
                            ? Colors.grey[800]
                            : Colors.blue.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Health Conditions",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: themeController.isDarkMode.value
                            ? Colors.grey[200]
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Select conditions that apply",
                      style: TextStyle(
                        fontSize: 14,
                        color: themeController.isDarkMode.value
                            ? Colors.grey[400]
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      title: Text(
                        "Hypertension",
                        style: TextStyle(
                          fontSize: 16,
                          color: themeController.isDarkMode.value
                              ? Colors.grey[200]
                              : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        "High blood pressure (watch sodium)",
                        style: TextStyle(
                          fontSize: 14,
                          color: themeController.isDarkMode.value
                              ? Colors.grey[400]
                              : Colors.grey,
                        ),
                      ),
                      value: hypertension,
                      onChanged: (value) =>
                          setState(() => hypertension = value ?? false),
                      contentPadding: EdgeInsets.zero,
                      activeColor: Colors.blue.shade700,
                      checkColor: Colors.white,
                    ),
                    CheckboxListTile(
                      title: Text(
                        "Diabetes",
                        style: TextStyle(
                          fontSize: 16,
                          color: themeController.isDarkMode.value
                              ? Colors.grey[200]
                              : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        "Manage carbs & sugar",
                        style: TextStyle(
                          fontSize: 14,
                          color: themeController.isDarkMode.value
                              ? Colors.grey[400]
                              : Colors.grey,
                        ),
                      ),
                      value: diabetes,
                      onChanged: (value) =>
                          setState(() => diabetes = value ?? false),
                      contentPadding: EdgeInsets.zero,
                      activeColor: Colors.blue.shade700,
                      checkColor: Colors.white,
                    ),
                    CheckboxListTile(
                      title: Text(
                        "Obesity",
                        style: TextStyle(
                          fontSize: 16,
                          color: themeController.isDarkMode.value
                              ? Colors.grey[200]
                              : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        "Focus on calorie control",
                        style: TextStyle(
                          fontSize: 14,
                          color: themeController.isDarkMode.value
                              ? Colors.grey[400]
                              : Colors.grey,
                        ),
                      ),
                      value: obesity,
                      onChanged: (value) =>
                          setState(() => obesity = value ?? false),
                      contentPadding: EdgeInsets.zero,
                      activeColor: Colors.blue.shade700,
                      checkColor: Colors.white,
                    ),
                    CheckboxListTile(
                      title: Text(
                        "High Cholesterol",
                        style: TextStyle(
                          fontSize: 16,
                          color: themeController.isDarkMode.value
                              ? Colors.grey[200]
                              : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        "Reduce fats, increase fiber",
                        style: TextStyle(
                          fontSize: 14,
                          color: themeController.isDarkMode.value
                              ? Colors.grey[400]
                              : Colors.grey,
                        ),
                      ),
                      value: highCholesterol,
                      onChanged: (value) =>
                          setState(() => highCholesterol = value ?? false),
                      contentPadding: EdgeInsets.zero,
                      activeColor: Colors.blue.shade700,
                      checkColor: Colors.white,
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: themeController.isDarkMode.value
                      ? Colors.grey[400]
                      : Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty &&
                    ageController.text.isNotEmpty) {
                  await ApisUtils.users
                      .doc(ApisUtils.auth.currentUser!.uid)
                      .collection("profiles")
                      .add({
                    'name': nameController.text,
                    'age': int.tryParse(ageController.text) ?? 0,
                    'healthConditions': {
                      'Diabetes': diabetes,
                      'Hypertension': hypertension,
                      'Obesity': obesity,
                      'HighCholesterol': highCholesterol,
                    },
                    'extractedDishes': [],
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  if (mounted) {
                    Navigator.pop(context);
                    // Ensure swipe hint is not shown after adding a new profile
                    final prefs = await SharedPreferences.getInstance();
                    final hasSeenSwipeHint =
                        prefs.getBool('hasSeenSwipeHint') ?? false;
                    if (!hasSeenSwipeHint) {
                      final snapshot = await ApisUtils.users
                          .doc(ApisUtils.auth.currentUser?.uid)
                          .collection("profiles")
                          .get();
                      if (snapshot.docs.length == 1) {
                        // Only for the first profile
                        setState(() {
                          _showSwipeHint = true;
                        });
                      }
                    }
                  }
                }
              },
              child: const Text("Add", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteUser(String profileId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: themeController.isDarkMode.value
              ? Colors.grey[900]
              : Colors.white.withOpacity(0.95),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "Delete Profile",
            style: TextStyle(
              color: themeController.isDarkMode.value
                  ? Colors.grey[200]
                  : Colors.black87,
            ),
          ),
          content: Text(
            "Are you sure you want to delete this profile?",
            style: TextStyle(
              color: themeController.isDarkMode.value
                  ? Colors.grey[400]
                  : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: themeController.isDarkMode.value
                      ? Colors.grey[400]
                      : Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await ApisUtils.users
                    .doc(ApisUtils.auth.currentUser!.uid)
                    .collection("profiles")
                    .doc(profileId)
                    .delete();
                if (mounted) Navigator.pop(context);
              },
              child:
                  const Text("Delete", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteScan(String scanId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: themeController.isDarkMode.value
              ? Colors.grey[900]
              : Colors.white.withOpacity(0.95),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "Delete Scan",
            style: TextStyle(
              color: themeController.isDarkMode.value
                  ? Colors.grey[200]
                  : Colors.black87,
            ),
          ),
          content: Text(
            "Are you sure you want to delete this scan?",
            style: TextStyle(
              color: themeController.isDarkMode.value
                  ? Colors.grey[400]
                  : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: themeController.isDarkMode.value
                      ? Colors.grey[400]
                      : Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await ApisUtils.users
                    .doc(ApisUtils.auth.currentUser!.uid)
                    .collection('scans')
                    .doc(scanId)
                    .delete();
                if (mounted) Navigator.pop(context);
              },
              child:
                  const Text("Delete", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSwipeHintOverlay(Widget child, int index) {
    // Show hint only for the first profile (index == 0) and on first login
    if (index != 0 || !_showSwipeHint || !_isFirstLogin) return child;
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _showSwipeHint = false;
              });
              _saveSwipeHintDismissed(); // Save dismissal state
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Swipe Right to Delete",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      shadows: const [
                        Shadow(color: Colors.redAccent, blurRadius: 5)
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Swipe Left to Scan",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      shadows: const [
                        Shadow(color: Colors.green, blurRadius: 5)
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Tap to dismiss",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentScans() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Recent Scans",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: themeController.isDarkMode.value
                  ? Colors.blue.shade300
                  : Colors.blue.shade900,
              fontFamily: 'PlayfairDisplay',
              shadows: const [Shadow(color: Colors.blueAccent, blurRadius: 5)],
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: StreamBuilder<QuerySnapshot>(
            stream: ApisUtils.users
                .doc(ApisUtils.auth.currentUser!.uid)
                .collection('scans')
                .orderBy('timestamp', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> scanSnapshot) {
              if (scanSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.blue));
              }
              if (scanSnapshot.hasError ||
                  !scanSnapshot.hasData ||
                  scanSnapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "No recent scans available",
                        style: TextStyle(
                          fontSize: 16,
                          color: themeController.isDarkMode.value
                              ? Colors.grey[400]
                              : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Swipe right on a profile to start a scan!",
                        style: TextStyle(
                          fontSize: 14,
                          color: themeController.isDarkMode.value
                              ? Colors.grey[400]
                              : Colors.white70,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final scans = scanSnapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: scans.length,
                itemBuilder: (context, index) {
                  final scan = scans[index];
                  final scanData = scan.data() as Map<String, dynamic>;
                  final timestamp =
                      (scanData['timestamp'] as Timestamp?)?.toDate();
                  final formattedDate = timestamp != null
                      ? DateFormat('MMM dd, yyyy HH:mm').format(timestamp)
                      : 'Unknown date';
                  final profileId = scanData['profileId'];
                  final analyses = scanData['analyses'] as List<dynamic>? ?? [];
                  final dishes = List<String>.from(scanData['dishes'] ?? []);

                  return StreamBuilder<DocumentSnapshot>(
                    stream: ApisUtils.users
                        .doc(ApisUtils.auth.currentUser!.uid)
                        .collection('profiles')
                        .doc(profileId)
                        .snapshots(),
                    builder: (context,
                        AsyncSnapshot<DocumentSnapshot> profileSnapshot) {
                      if (!profileSnapshot.hasData)
                        return const SizedBox.shrink();
                      final profileData = profileSnapshot.data!.data()
                              as Map<String, dynamic>? ??
                          {};
                      final profileName = profileData['name'] ?? 'Unknown';
                      final healthConditions = profileData['healthConditions']
                              as Map<String, dynamic>? ??
                          {};

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Slidable(
                          key: ValueKey(scan.id),
                          startActionPane: ActionPane(
                            motion: const StretchMotion(),
                            children: [
                              SlidableAction(
                                onPressed: (context) =>
                                    _confirmDeleteScan(scan.id),
                                icon: Icons.delete_forever,
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ],
                          ),
                          child: GestureDetector(
                            onTap: () {
                              Get.to(() => Output(
                                    userId: ApisUtils.auth.currentUser!.uid,
                                    profileId: profileId,
                                    dishes: dishes,
                                    healthConditions: {
                                      'Diabetes':
                                          healthConditions['Diabetes'] ?? false,
                                      'Hypertension':
                                          healthConditions['Hypertension'] ??
                                              false,
                                      'Obesity':
                                          healthConditions['Obesity'] ?? false,
                                      'HighCholesterol':
                                          healthConditions['HighCholesterol'] ??
                                              false,
                                    },
                                    // savedAnalyses: analyses,
                                  ));
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: themeController.isDarkMode.value
                                    ? Colors.grey[800]
                                    : Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(
                                        themeController.isDarkMode.value
                                            ? 0.2
                                            : 0.1),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$profileName\'s Scan',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: themeController.isDarkMode.value
                                          ? Colors.blue.shade300
                                          : Colors.blue.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Date: $formattedDate',
                                    style: TextStyle(
                                      color: themeController.isDarkMode.value
                                          ? Colors.grey[400]
                                          : Colors.grey[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _navigateToSettings() async {
    await _fabVanishController.forward();
    Get.to(() => const SettingsPage());
    _fabVanishController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
          decoration: BoxDecoration(
            image: const DecorationImage(
              image: AssetImage('assets/animations/background.png'),
              fit: BoxFit.cover,
              opacity: 0.2,
            ),
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade400.withOpacity(0.8),
                themeController.isDarkMode.value
                    ? Colors.blue.shade900.withOpacity(0.7)
                    : Colors.white.withOpacity(0.9),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Image.asset(
                      'assets/animations/EatwiseLogo-removebg-preview.png',
                      height: 100,
                      width: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.blue.shade700,
              shape: const RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(50)),
              ),
              toolbarHeight: 100,
            ),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "My Profiles",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: themeController.isDarkMode.value
                            ? Colors.blue.shade300
                            : Colors.blue.shade900,
                        fontFamily: 'PlayfairDisplay',
                        shadows: const [
                          Shadow(color: Colors.blueAccent, blurRadius: 5)
                        ],
                      ),
                    ),
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: ApisUtils.users
                        .doc(ApisUtils.auth.currentUser!.uid)
                        .collection("profiles")
                        .snapshots(),
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child:
                                CircularProgressIndicator(color: Colors.blue));
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "Error fetching data",
                            style: TextStyle(
                              color: themeController.isDarkMode.value
                                  ? Colors.red[300]
                                  : Colors.red,
                            ),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "No profiles yet. Add a profile!",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: themeController.isDarkMode.value
                                      ? Colors.grey[400]
                                      : Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Tap the + button below to get started",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: themeController.isDarkMode.value
                                      ? Colors.grey[400]
                                      : Colors.white70,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final documents = snapshot.data!.docs;

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: documents.length,
                        itemBuilder: (context, index) {
                          final doc = documents[index];
                          final docData = doc.data() as Map<String, dynamic>;
                          final healthConditions = docData['healthConditions']
                                  as Map<String, dynamic>? ??
                              {};

                          List<String> diseases = [];
                          if (healthConditions['Diabetes'] == true)
                            diseases.add("Diabetes");
                          if (healthConditions['Hypertension'] == true)
                            diseases.add("Hypertension");
                          if (healthConditions['Obesity'] == true)
                            diseases.add("Obesity");
                          if (healthConditions['HighCholesterol'] == true)
                            diseases.add("High Cholesterol");

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: _buildSwipeHintOverlay(
                              Slidable(
                                key: ValueKey(doc.id),
                                startActionPane: ActionPane(
                                  motion: const StretchMotion(),
                                  children: [
                                    SlidableAction(
                                      onPressed: (context) =>
                                          _confirmDeleteUser(doc.id),
                                      icon: Icons.delete_forever,
                                      foregroundColor: Colors.white,
                                      backgroundColor: Colors.red,
                                      label: "Delete",
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ],
                                ),
                                endActionPane: ActionPane(
                                  motion: const StretchMotion(),
                                  children: [
                                    SlidableAction(
                                      onPressed: (context) => Get.to(() =>
                                          ScanPage(
                                            userId:
                                                ApisUtils.auth.currentUser!.uid,
                                            profileId: doc.id,
                                            name: docData['name']?.toString() ??
                                                'Unknown',
                                            healthConditions: {
                                              'Diabetes': healthConditions[
                                                      'Diabetes'] ??
                                                  false,
                                              'Hypertension': healthConditions[
                                                      'Hypertension'] ??
                                                  false,
                                              'Obesity':
                                                  healthConditions['Obesity'] ??
                                                      false,
                                              'HighCholesterol':
                                                  healthConditions[
                                                          'HighCholesterol'] ??
                                                      false,
                                            },
                                          )),
                                      icon: Icons.document_scanner_outlined,
                                      foregroundColor: Colors.white,
                                      backgroundColor: Colors.green,
                                      label: "Scan",
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ],
                                ),
                                child: AnimatedBuilder(
                                  animation: _animationController,
                                  builder: (context, child) {
                                    double glow = _glowAnimation.value;
                                    return Transform(
                                      transform: Matrix4.identity()
                                        ..rotateY(math.sin(
                                                _animationController.value *
                                                    2 *
                                                    math.pi) *
                                            0.02),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.blue.shade700.withOpacity(
                                                  themeController
                                                          .isDarkMode.value
                                                      ? 0.1
                                                      : 0.2),
                                              themeController.isDarkMode.value
                                                  ? Colors.grey[800]!
                                                      .withOpacity(0.8)
                                                  : Colors.white
                                                      .withOpacity(0.5),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.blueAccent
                                                  .withOpacity(0.3 * glow),
                                              blurRadius: 15,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: BackdropFilter(
                                            filter: ui.ImageFilter.blur(
                                                sigmaX: 10, sigmaY: 10),
                                            child: Container(
                                              padding: const EdgeInsets.all(15),
                                              child: Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 30,
                                                    backgroundColor:
                                                        Colors.blue.shade700,
                                                    child: Text(
                                                      _capitalize(
                                                          docData['name'] ??
                                                              '')[0],
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 24,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 15),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          _capitalize(
                                                              docData['name'] ??
                                                                  'Unknown'),
                                                          style: TextStyle(
                                                            color: themeController
                                                                    .isDarkMode
                                                                    .value
                                                                ? Colors.blue
                                                                    .shade300
                                                                : Colors.blue
                                                                    .shade900,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 20,
                                                            fontFamily:
                                                                'PlayfairDisplay',
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 4),
                                                        Text(
                                                          "Age: ${docData['age'] ?? 'N/A'}",
                                                          style: TextStyle(
                                                            color: themeController
                                                                    .isDarkMode
                                                                    .value
                                                                ? Colors
                                                                    .grey[400]
                                                                : Colors
                                                                    .black54,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 8),
                                                        Wrap(
                                                          spacing: 6,
                                                          runSpacing: 6,
                                                          children: diseases
                                                              .map(
                                                                  (disease) =>
                                                                      Container(
                                                                        padding: const EdgeInsets
                                                                            .symmetric(
                                                                            horizontal:
                                                                                8,
                                                                            vertical:
                                                                                4),
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          gradient:
                                                                              LinearGradient(
                                                                            colors: themeController.isDarkMode.value
                                                                                ? [
                                                                                    Colors.green.shade700,
                                                                                    Colors.green.shade900
                                                                                  ]
                                                                                : [
                                                                                    Colors.green.shade100,
                                                                                    Colors.green.shade200
                                                                                  ],
                                                                            begin:
                                                                                Alignment.topLeft,
                                                                            end:
                                                                                Alignment.bottomRight,
                                                                          ),
                                                                          borderRadius:
                                                                              BorderRadius.circular(10),
                                                                          boxShadow: [
                                                                            BoxShadow(
                                                                              color: Colors.green.withOpacity(0.2),
                                                                              blurRadius: 5,
                                                                            ),
                                                                          ],
                                                                        ),
                                                                        child:
                                                                            Text(
                                                                          disease,
                                                                          style:
                                                                              TextStyle(
                                                                            color: themeController.isDarkMode.value
                                                                                ? Colors.green.shade200
                                                                                : Colors.green.shade800,
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                            fontSize:
                                                                                12,
                                                                          ),
                                                                        ),
                                                                      ))
                                                              .toList(),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .arrow_back_ios,
                                                            size: 12,
                                                            color: themeController
                                                                    .isDarkMode
                                                                    .value
                                                                ? Colors
                                                                    .grey[400]
                                                                : Colors
                                                                    .white70,
                                                          ),
                                                          Text(
                                                            "Swipe",
                                                            style: TextStyle(
                                                              color: themeController
                                                                      .isDarkMode
                                                                      .value
                                                                  ? Colors
                                                                      .grey[400]
                                                                  : Colors
                                                                      .white70,
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                          Icon(
                                                            Icons
                                                                .arrow_forward_ios,
                                                            size: 12,
                                                            color: themeController
                                                                    .isDarkMode
                                                                    .value
                                                                ? Colors
                                                                    .grey[400]
                                                                : Colors
                                                                    .white70,
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      GestureDetector(
                                                        onTap: () {
                                                          Get.to(
                                                              () => ChatScreen(
                                                                    initialMessage:
                                                                        "My name is ${docData['name'] ?? 'Unknown'}, my age is ${docData['age'] ?? 'N/A'} and I have ${diseases.join(", ")}",
                                                                  ));
                                                        },
                                                        child: AnimatedBuilder(
                                                          animation:
                                                              _animationController,
                                                          builder:
                                                              (context, child) {
                                                            return Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(8),
                                                              decoration:
                                                                  BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                gradient:
                                                                    RadialGradient(
                                                                  colors: [
                                                                    Colors.blue
                                                                        .shade200,
                                                                    Colors.blue
                                                                        .shade700,
                                                                  ],
                                                                  radius: 0.8,
                                                                ),
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                    color: Colors
                                                                        .blueAccent
                                                                        .withOpacity(0.5 *
                                                                            _glowAnimation.value),
                                                                    blurRadius:
                                                                        10,
                                                                    spreadRadius:
                                                                        2,
                                                                  ),
                                                                ],
                                                              ),
                                                              child:
                                                                  Image.asset(
                                                                'assets/animations/chat-bot_icon.png',
                                                                width: 30,
                                                                height: 30,
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              index,
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildRecentScans(),
                ],
              ),
            ),
            bottomNavigationBar: BottomAppBar(
              shape: CircularNotchedRectangle(),
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
                        size: 28,
                      ),
                      onPressed: () {
                        setState(() {
                          _currentIndex = 0;
                        });
                      },
                    ),
                    const SizedBox(width: 48),
                    IconButton(
                      icon: Icon(
                        Icons.person,
                        color: _currentIndex == 1
                            ? Colors.blue.shade200
                            : Colors.grey,
                        size: 28,
                      ),
                      onPressed: () {
                        setState(() {
                          _currentIndex = 1;
                        });
                        _navigateToSettings();
                      },
                    ),
                  ],
                ),
              ),
            ),
            floatingActionButton: _isAnimationInitialized
                ? ScaleTransition(
                    scale: _fabVanishAnimation,
                    child: AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        double glow = _glowAnimation.value;
                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    Colors.blueAccent.withOpacity(0.5 * glow),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: SizedBox(
                            width: 65,
                            height: 65,
                            child: FloatingActionButton(
                              onPressed: _addUser,
                              backgroundColor: Colors.blue.shade200,
                              elevation: 10,
                              shape: const CircleBorder(),
                              child: const Icon(Icons.add,
                                  color: Colors.white, size: 40),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : const SizedBox.shrink(),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
          ),
        ));
  }
}
