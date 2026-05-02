import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupPage extends StatefulWidget {
  const GroupPage({super.key});

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  final TextEditingController codeController = TextEditingController();

  /// 🔥 GENERATE JOIN CODE
  String generateJoinCode() {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const numbers = '0123456789';
    final random = Random();

    return List.generate(3, (_) => letters[random.nextInt(26)]).join() +
        List.generate(3, (_) => numbers[random.nextInt(10)]).join();
  }

  /// 🔥 GET CURRENT GROUP CODE
  Future<String?> getGroupCode() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    List groupIds = userDoc.data()?['groupIds'] ?? [];

    if (groupIds.isEmpty) return null;

    final groupDoc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupIds[0])
        .get();

    return groupDoc.data()?['joinCode'];
  }

  /// 🔥 CREATE GROUP
  Future<void> createGroup() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final code = generateJoinCode();

    final doc = await FirebaseFirestore.instance.collection('groups').add({
      'name': 'New Group',
      'joinCode': code,
      'createdBy': user.uid,
      'members': [user.uid],
      'createdAt': Timestamp.now(),
    });

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'groupIds': [doc.id],
    }, SetOptions(merge: true));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Group created! Code: $code")),
    );

    setState(() {});
  }

  /// 🔥 JOIN GROUP
  Future<void> joinGroup() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final code = codeController.text.trim();

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a group code")),
      );
      return;
    }

    final result = await FirebaseFirestore.instance
        .collection('groups')
        .where('joinCode', isEqualTo: code)
        .get();

    if (result.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid code")),
      );
      return;
    }

    final group = result.docs.first;

    await FirebaseFirestore.instance.collection('groups').doc(group.id).update({
      'members': FieldValue.arrayUnion([user.uid]),
    });

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'groupIds': [group.id],
    }, SetOptions(merge: true));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Joined group!")),
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Group"),
        backgroundColor: const Color(0xFF68bde5),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// 🔹 CURRENT GROUP
            FutureBuilder<String?>(
              future: getGroupCode(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox();
                }

                final code = snapshot.data;

                return Column(
                  children: [
                    const Text(
                      "Your Group Code",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      code ?? "No group yet",
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),

            /// 🔹 JOIN GROUP
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: "Enter Group Code",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: joinGroup,
                child: const Text("Join Group"),
              ),
            ),

            const SizedBox(height: 20),

            const Divider(),

            const SizedBox(height: 20),

            /// 🔹 CREATE GROUP
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: createGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text("Create New Group"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}