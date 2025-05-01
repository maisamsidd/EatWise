import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eat_wise/Utils/Apis_utils.dart';
import 'package:eat_wise/View/Ai_related_work/ScanPage/scan_page.dart';
import 'package:eat_wise/View/HomePage/userProfile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lottie/lottie.dart';

import '../Chatbot/chat_bot.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  int _currentIndex = 0;

  String _capitalize(String name) {
    if (name.isEmpty) return name;
    return name[0].toUpperCase() + name.substring(1).toLowerCase();
  }

  bool Diabetes = false;
  bool Hypertension = false;
  bool Obesity = false;
  bool HighCholesterol = false;

  void _addUser() {
    nameController.clear();
    ageController.clear();
    Diabetes = false;
    Hypertension = false;
    Obesity = false;
    HighCholesterol = false;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("New Profile",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Basic Information",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    const Text("Name",
                        style: TextStyle(fontSize: 16)),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        hintText: "Enter name",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text("Age",
                        style: TextStyle(fontSize: 16)),
                    TextField(
                      controller: ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: "Enter age",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text("Health Conditions",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text("Select all health conditions that apply",
                        style: TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      title: const Text("Hypertension",
                          style: TextStyle(fontSize: 16)),
                      subtitle: const Text("High blood pressure requiring sodium restriction",
                          style: TextStyle(fontSize: 14, color: Colors.grey)),
                      value: Hypertension,
                      onChanged: (value) =>
                          setState(() => Hypertension = value ?? false),
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      title: const Text("Diabetes",
                          style: TextStyle(fontSize: 16)),
                      subtitle: const Text("Requires careful carbohydrate management and blood sugar control",
                          style: TextStyle(fontSize: 14, color: Colors.grey)),
                      value: Diabetes,
                      onChanged: (value) =>
                          setState(() => Diabetes = value ?? false),
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      title: const Text("Obesity",
                          style: TextStyle(fontSize: 16)),
                      subtitle: const Text("Requires calorie control and balanced nutrition",
                          style: TextStyle(fontSize: 14, color: Colors.grey)),
                      value: Obesity,
                      onChanged: (value) =>
                          setState(() => Obesity = value ?? false),
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      title: const Text("High Cholesterol",
                          style: TextStyle(fontSize: 16)),
                      subtitle: const Text("Requires reduced saturated fat and increased fiber intake",
                          style: TextStyle(fontSize: 14, color: Colors.grey)),
                      value: HighCholesterol,
                      onChanged: (value) =>
                          setState(() => HighCholesterol = value ?? false),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.black)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty && ageController.text.isNotEmpty) {
                  await ApisUtils.users.doc(ApisUtils.auth.currentUser!.uid)
                      .collection("profiles")
                      .add({
                    'name': nameController.text,
                    'age': int.tryParse(ageController.text) ?? 0,
                    'healthConditions': {
                      'Diabetes': Diabetes,
                      'Hypertension': Hypertension,
                      'Obesity': Obesity,
                      'HighCholesterol': HighCholesterol,
                    },
                    'extractedDishes': [],
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Add", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
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
          backgroundColor: Colors.white,
          title: const Text("Delete Profile"),
          content: const Text("Are you sure you want to delete this profile?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.black)),
            ),
            ElevatedButton(
              onPressed: () async {
                await ApisUtils.users.doc(ApisUtils.auth.currentUser!.uid)
                    .collection("profiles").doc(profileId).delete();
                Navigator.pop(context);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
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
              " EatWise",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30, color: Colors.white),
            ),
            Lottie.asset(
              'assets/animations/Home.json',
              height: 60,
              width: 60,
              repeat: false,
              fit: BoxFit.contain,
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
          image: DecorationImage(
            image: AssetImage('assets/animations/image-removebg-preview.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Profiles",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: ApisUtils.users
                    .doc(ApisUtils.auth.currentUser!.uid)
                    .collection("profiles")
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text("Error fetching data"));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No profiles available"));
                  }

                  final documents = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      final doc = documents[index];
                      final docData = doc.data() as Map<String, dynamic>;
                      final healthConditions = docData['healthConditions'] as Map<String, dynamic>;

                      List<String> diseases = [];
                      if (healthConditions['Diabetes'] == true) diseases.add("Diabetes");
                      if (healthConditions['Hypertension'] == true) diseases.add("Hypertension");
                      if (healthConditions['Obesity'] == true) diseases.add("Obesity");
                      if (healthConditions['HighCholesterol'] == true) diseases.add("High Cholesterol");

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                                borderRadius: BorderRadius.circular(12),
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
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                color: Colors.white70,
                                elevation: 3,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(15),
                                  title: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: "${_capitalize(docData['name'])}\n",
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        TextSpan(
                                          text: "Age: ${docData['age']}\n",
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        ...diseases.map((disease) => WidgetSpan(
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            margin: EdgeInsets.only(bottom: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.green[100],
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              disease,
                                              style: TextStyle(
                                                color: Colors.green[800],
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                        )).toList(),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 18,
                                top: 15,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.arrow_back_ios,
                                          size: 12,
                                          color: Colors.grey,
                                        ),
                                        const Text(
                                          "Swipe",
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 12,
                                          color: Colors.grey,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20), // Add space between swipe hint and button
                                    GestureDetector(
                                      onTap: () {
                                        Get.to(() => ChatScreen(
                                          initialMessage:
                                          "My name is ${docData['name']}, my age is ${docData['age']} and I have ${diseases.join(", ") }",
                                        ));
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade400,
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(0.3),
                                              spreadRadius: 1,
                                              blurRadius: 3,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Image.asset(
                                          'assets/animations/chat-bot_icon.png', // Your image path
                                          width: 30,
                                          height: 30,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
      floatingActionButton: SizedBox(
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}