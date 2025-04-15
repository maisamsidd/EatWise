import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eat_wise/Utils/Apis_utils.dart';
import 'package:eat_wise/View/Authentication/login_page.dart';
import 'package:eat_wise/View/Ai_related_work/ScanPage/scan_page.dart';
import 'package:eat_wise/View/Chatbot/chat_bot.dart';
import 'package:eat_wise/View/HomePage/userProfile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lottie/lottie.dart';

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
          title: const Text("Add User"),
          backgroundColor: Colors.white,
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Name"),
                    ),
                    TextField(
                      controller: ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Age"),
                    ),
                    const SizedBox(height: 10),
                    const Text("Diseases",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    CheckboxListTile(
                      title: const Text("Diabetes"),
                      value: Diabetes,
                      onChanged: (value) =>
                          setState(() => Diabetes = value ?? false),
                    ),
                    CheckboxListTile(
                      title: const Text("Hypertension"),
                      value: Hypertension,
                      onChanged: (value) =>
                          setState(() => Hypertension = value ?? false),
                    ),
                    CheckboxListTile(
                      title: const Text("Obesity"),
                      value: Obesity,
                      onChanged: (value) =>
                          setState(() => Obesity = value ?? false),
                    ),
                    CheckboxListTile(
                      title: const Text("High Cholesterol"),
                      value: HighCholesterol,
                      onChanged: (value) =>
                          setState(() => HighCholesterol = value ?? false),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text("Cancel", style: TextStyle(color: Colors.black)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty &&
                    ageController.text.isNotEmpty) {
                  await ApisUtils.users
                      .doc(ApisUtils.auth.currentUser!.uid)
                      .collection("userDetails")
                      .add({
                    'name': nameController.text,
                    'age': int.tryParse(ageController.text) ?? 0,
                    'Diabetes': Diabetes,
                    'Hypertension': Hypertension,
                    'Obesity': Obesity,
                    'HighCholesterol': HighCholesterol,
                  });
                  Navigator.pop(context);
                }
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              child: const Text("Add", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteUser(String userId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text("Delete User"),
          content: const Text("Are you sure you want to delete this user?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text("Cancel", style: TextStyle(color: Colors.black)),
            ),
            ElevatedButton(
              onPressed: () async {
                await ApisUtils.users
                    .doc(ApisUtils.auth.currentUser!.uid)
                    .collection("userDetails")
                    .doc(userId)
                    .delete();
                Navigator.pop(context);
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child:
                  const Text("Delete", style: TextStyle(color: Colors.black)),
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
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                  color: Colors.white),
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
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.logout),
        //     color: Colors.white,
        //     onPressed: () async {
        //       await ApisUtils.auth.signOut();
        //       Get.offAll(() => const LoginPage());
        //     },
        //   ),
        // ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: ApisUtils.users
                  .doc(ApisUtils.auth.currentUser!.uid)
                  .collection("userDetails")
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text("Error fetching data"));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No user history available"));
                }

                final documents = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    final doc = documents[index];
                    final docData = doc.data() as Map<String, dynamic>;
                    List<String> diseases = [];
                    if (docData['Diabetes'] == true) diseases.add("Diabetes");
                    if (docData['Hypertension'] == true) {
                      diseases.add("Hypertension");
                    }
                    if (docData['Obesity'] == true) diseases.add("Obesity");
                    if (docData['HighCholesterol'] == true) {
                      diseases.add("High Cholesterol");
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: Slidable(
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
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ],
                        ),
                        endActionPane: ActionPane(
                          motion: const StretchMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (context) => Get.to(() => ScanPage(
                                    userId: doc.id,
                                    name: docData['name'],
                                    healthConditions: {
                                      'Diabetes': docData['Diabetes'] ?? false,
                                      'Hypertension':
                                          docData['Hypertension'] ?? false,
                                      'Obesity': docData['Obesity'] ?? false,
                                      'HighCholesterol':
                                          docData['HighCholesterol'] ?? false,
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
                                        text:
                                            "${_capitalize(docData['name'])}\n",
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            "Age: ${docData['age']}\n${diseases.join("\n")}",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 15,
                              top: 15,
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_back_ios,
                                        size: 12,
                                        color: Colors.grey,
                                      ),
                                      Text(
                                        "Swipe",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 12,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                      onPressed: () {
                                        Get.to(() => ChatScreen(
                                              initialMessage:
                                                  "My name is ${docData['name']}, my age is ${docData['age']} and I have ${diseases.join(", ")}",
                                            ));
                                      },
                                      icon: Icon(Icons.chat))
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
                  color:
                      _currentIndex == 0 ? Colors.blue.shade200 : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _currentIndex = 0;
                  });
                  // Already on Home
                },
              ),
              const SizedBox(width: 48), // Space for FAB
              IconButton(
                icon: Icon(
                  Icons.person,
                  color:
                      _currentIndex == 1 ? Colors.blue.shade200 : Colors.grey,
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
        width: 65, // Increase width
        height: 65, // Increase height
        child: FloatingActionButton(
          onPressed: _addUser,
          backgroundColor: Colors.blue.shade200,
          elevation: 10,
          shape: const CircleBorder(), // Keeps it circular
          child: const Icon(Icons.add,
              color: Colors.white, size: 40), // Bigger icon
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
