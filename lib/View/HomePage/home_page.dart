import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eat_wise/Utils/Apis_utils.dart';
import 'package:eat_wise/View/Ai_related_work/ScanPage/scan_page.dart';
import 'package:eat_wise/View/HomePage/userProfile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lottie/lottie.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../Chatbot/chat_bot.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;

  bool diabetes = false;
  bool hypertension = false;
  bool obesity = false;
  bool highCholesterol = false;

  @override
  void initState() {
    super.initState();
    // Initialize AnimationController
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    // Initialize glow animation
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    nameController.dispose();
    ageController.dispose();
    super.dispose();
  }

  String _capitalize(String name) {
    if (name.isEmpty) return name;
    return name[0].toUpperCase() + name.substring(1).toLowerCase();
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
              const Text(
                "New Profile",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.white.withOpacity(0.95),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Tell Us About You",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    const Text("Name", style: TextStyle(fontSize: 16, color: Colors.black54)),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: "Enter your name",
                        filled: true,
                        fillColor: Colors.blue.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text("Age", style: TextStyle(fontSize: 16, color: Colors.black54)),
                    TextField(
                      controller: ageController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "Enter your age",
                        filled: true,
                        fillColor: Colors.blue.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Health Conditions",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Select conditions that apply",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      title: const Text("Hypertension", style: TextStyle(fontSize: 16, color: Colors.black87)),
                      subtitle: const Text(
                        "High blood pressure (watch sodium)",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      value: hypertension,
                      onChanged: (value) => setState(() => hypertension = value ?? false),
                      contentPadding: EdgeInsets.zero,
                      activeColor: Colors.blue,
                    ),
                    CheckboxListTile(
                      title: const Text("Diabetes", style: TextStyle(fontSize: 16, color: Colors.black87)),
                      subtitle: const Text(
                        "Manage carbs & sugar",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      value: diabetes,
                      onChanged: (value) => setState(() => diabetes = value ?? false),
                      contentPadding: EdgeInsets.zero,
                      activeColor: Colors.blue,
                    ),
                    CheckboxListTile(
                      title: const Text("Obesity", style: TextStyle(fontSize: 16, color: Colors.black87)),
                      subtitle: const Text(
                        "Focus on calorie control",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      value: obesity,
                      onChanged: (value) => setState(() => obesity = value ?? false),
                      contentPadding: EdgeInsets.zero,
                      activeColor: Colors.blue,
                    ),
                    CheckboxListTile(
                      title: const Text("High Cholesterol", style: TextStyle(fontSize: 16, color: Colors.black87)),
                      subtitle: const Text(
                        "Reduce fats, increase fiber",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      value: highCholesterol,
                      onChanged: (value) => setState(() => highCholesterol = value ?? false),
                      contentPadding: EdgeInsets.zero,
                      activeColor: Colors.blue,
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty && ageController.text.isNotEmpty) {
                  await ApisUtils.users.doc(ApisUtils.auth.currentUser!.uid).collection("profiles").add({
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
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text("Add", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          backgroundColor: Colors.white.withOpacity(0.95),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Delete Profile", style: TextStyle(color: Colors.black87)),
          content: const Text("Are you sure you want to delete this profile?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                await ApisUtils.users.doc(ApisUtils.auth.currentUser!.uid).collection("profiles").doc(profileId).delete();
                if (mounted) Navigator.pop(context);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Text(
              "EatWise",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 30,
                color: Colors.white,
                shadows: [Shadow(color: Colors.blueAccent, blurRadius: 10)],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade700,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(50)),
        ),
        toolbarHeight: 100,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage('assets/animations/image-removebg-preview.png'),
            fit: BoxFit.cover,
            opacity: 0.3,
          ),
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade700.withOpacity(0.1),
              Colors.white.withOpacity(0.8),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
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
                  color: Colors.blue.shade900,
                  fontFamily: 'PlayfairDisplay',
                  shadows: const [Shadow(color: Colors.blueAccent, blurRadius: 5)],
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: ApisUtils.users.doc(ApisUtils.auth.currentUser!.uid).collection("profiles").snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.blue));
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text("Error fetching data", style: TextStyle(color: Colors.red)));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No profiles yet. Add a profile!",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  final documents = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      final doc = documents[index];
                      final docData = doc.data() as Map<String, dynamic>;
                      final healthConditions = docData['healthConditions'] as Map<String, dynamic>? ?? {};

                      List<String> diseases = [];
                      if (healthConditions['Diabetes'] == true) diseases.add("Diabetes");
                      if (healthConditions['Hypertension'] == true) diseases.add("Hypertension");
                      if (healthConditions['Obesity'] == true) diseases.add("Obesity");
                      if (healthConditions['HighCholesterol'] == true) diseases.add("High Cholesterol");

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Slidable(
                          key: ValueKey(doc.id),
                          startActionPane: ActionPane(
                            motion: const StretchMotion(),
                            children: [
                              SlidableAction(
                                onPressed: (context) => _confirmDeleteUser(doc.id),
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
                                onPressed: (context) => Get.to(() => ScanPage(
                                  userId: ApisUtils.auth.currentUser!.uid,
                                  profileId: doc.id,
                                  name: docData['name'],
                                  healthConditions: {
                                    'Diabetes': healthConditions['Diabetes'] ?? false,
                                    'Hypertension': healthConditions['Hypertension'] ?? false,
                                    'Obesity': healthConditions['Obesity'] ?? false,
                                    'HighCholesterol': healthConditions['HighCholesterol'] ?? false,
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
                                  ..rotateY(math.sin(_animationController.value * 2 * math.pi) * 0.02),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.blue.shade700.withOpacity(0.2),
                                        Colors.white.withOpacity(0.5),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blueAccent.withOpacity(0.3 * glow),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: BackdropFilter(
                                      filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                      child: Container(
                                        padding: const EdgeInsets.all(15),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 30,
                                              backgroundColor: Colors.blue.shade700,
                                              child: Text(
                                                _capitalize(docData['name'] ?? '')[0],
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 15),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    _capitalize(docData['name'] ?? 'Unknown'),
                                                    style: TextStyle(
                                                      color: Colors.blue.shade900,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 20,
                                                      fontFamily: 'PlayfairDisplay',
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    "Age: ${docData['age'] ?? 'N/A'}",
                                                    style: const TextStyle(
                                                      color: Colors.black54,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Wrap(
                                                    spacing: 6,
                                                    runSpacing: 6,
                                                    children: diseases.map((disease) => Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          colors: [Colors.green.shade100, Colors.green.shade200],
                                                          begin: Alignment.topLeft,
                                                          end: Alignment.bottomRight,
                                                        ),
                                                        borderRadius: BorderRadius.circular(10),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.green.withOpacity(0.2),
                                                            blurRadius: 5,
                                                          ),
                                                        ],
                                                      ),
                                                      child: Text(
                                                        disease,
                                                        style: TextStyle(
                                                          color: Colors.green.shade800,
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    )).toList(),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: const [
                                                    Icon(
                                                      Icons.arrow_back_ios,
                                                      size: 12,
                                                      color: Colors.white70,
                                                    ),
                                                    Text(
                                                      "Swipe",
                                                      style: TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                    Icon(
                                                      Icons.arrow_forward_ios,
                                                      size: 12,
                                                      color: Colors.white70,
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                GestureDetector(
                                                  onTap: () {
                                                    Get.to(() => ChatScreen(
                                                      initialMessage:
                                                      "My name is ${docData['name'] ?? 'Unknown'}, my age is ${docData['age'] ?? 'N/A'} and I have ${diseases.join(", ")}",
                                                    ));
                                                  },
                                                  child: AnimatedBuilder(
                                                    animation: _animationController,
                                                    builder: (context, child) {
                                                      return Container(
                                                        padding: const EdgeInsets.all(8),
                                                        decoration: BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          gradient: RadialGradient(
                                                            colors: [
                                                              Colors.blue.shade200,
                                                              Colors.blue.shade700,
                                                            ],
                                                            radius: 0.8,
                                                          ),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors.blueAccent.withOpacity(0.5 * glow),
                                                              blurRadius: 10,
                                                              spreadRadius: 2,
                                                            ),
                                                          ],
                                                        ),
                                                        child: Image.asset(
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
                      );
                    },
                  );
                },
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
                  color: _currentIndex == 1 ? Colors.blue.shade200 : Colors.grey,
                  size: 28,
                ),
                onPressed: () {
                  setState(() {
                    _currentIndex = 1;
                  });
                  Get.to(() => const SettingsPage());
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          double glow = _glowAnimation.value;
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.5 * glow),
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
                child: const Icon(Icons.add, color: Colors.white, size: 40),
              ),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}