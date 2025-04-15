import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eat_wise/Utils/Apis_utils.dart';
import 'package:flutter/material.dart';

class UsersHistory extends StatelessWidget {
  const UsersHistory({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User's History"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ApisUtils.users
            .doc(ApisUtils.auth.currentUser!.uid)
            .collection("userDetails")
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          // Check if the snapshot has data
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
              final docData = documents[index].data() as Map<String, dynamic>;
              return ListTile(
                tileColor: Colors.grey[200],
                title: Text("Name " + docData['name'] ?? "No Name"),
                subtitle: Text(docData['age']?.toString() ?? "No Age"),
                trailing: Text("age " + docData['disease'] ?? "No Condition"),
              );
            },
          );
        },
      ),
    );
  }
}
