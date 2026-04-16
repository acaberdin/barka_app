import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  /// 🔥 GENERATE JOIN CODE
  String generateJoinCode() {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const numbers = '0123456789';
    final random = Random();

    String code = '';

    for (int i = 0; i < 3; i++) {
      code += letters[random.nextInt(letters.length)];
    }

    for (int i = 0; i < 3; i++) {
      code += numbers[random.nextInt(numbers.length)];
    }

    return code;
  }

  /// 🔥 GET USERNAME
  Future<String> getUsername() async {
    final user = FirebaseAuth.instance.currentUser!;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return doc['username'] ?? "User";
  }

  /// 🔥 GET GROUP CODE
  Future<String?> getGroupCode() async {
    final user = FirebaseAuth.instance.currentUser!;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    List groupIds = userDoc['groupIds'] ?? [];

    if (groupIds.isEmpty) return null;

    final groupDoc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupIds[0])
        .get();

    return groupDoc['joinCode'];
  }

  /// 🔥 CREATE GROUP
  Future<void> createGroup(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser!;
    final userId = user.uid;

    final code = generateJoinCode();

    final doc = await FirebaseFirestore.instance.collection('groups').add({
      'name': 'New Group',
      'joinCode': code,
      'createdBy': userId,
      'members': [userId],
      'createdAt': Timestamp.now(),
    });

    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'groupIds': FieldValue.arrayUnion([doc.id]),
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Group created! Code: $code")));
  }

  /// 🔥 JOIN GROUP
  Future<void> joinGroup(BuildContext context, String code) async {
    final user = FirebaseAuth.instance.currentUser!;
    final userId = user.uid;

    final result = await FirebaseFirestore.instance
        .collection('groups')
        .where('joinCode', isEqualTo: code)
        .get();

    if (result.docs.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid code")));
      return;
    }

    final group = result.docs.first;

    await FirebaseFirestore.instance.collection('groups').doc(group.id).update({
      'members': FieldValue.arrayUnion([userId]),
    });

    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'groupIds': FieldValue.arrayUnion([group.id]),
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Joined group!")));
  }

  /// 🔥 GROUP POPUP
  void showGroupDialog(BuildContext context) {
    final TextEditingController codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Group Options"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                decoration: const InputDecoration(hintText: "Enter Group Code"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  joinGroup(context, codeController.text.trim());
                  Navigator.pop(context);
                },
                child: const Text("Join Group"),
              ),
              const Divider(),
              ElevatedButton(
                onPressed: () {
                  createGroup(context);
                  Navigator.pop(context);
                },
                child: const Text("Create Group"),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 🔥 CHANGE PASSWORD (FIXED WITH RE-AUTH)
  void showSettingsDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Change Password"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(hintText: "Current Password"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(hintText: "New Password"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  final user = FirebaseAuth.instance.currentUser!;
                  final email = user.email!;

                  final credential = EmailAuthProvider.credential(
                    email: email,
                    password: currentPasswordController.text.trim(),
                  );

                  await user.reauthenticateWithCredential(credential);

                  await user.updatePassword(newPasswordController.text.trim());

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Password updated!")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  /// 🔥 ICON BUTTON WITH FEEDBACK
  Widget iconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: const Color(0xFF31436f)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFccefff),

      body: SafeArea(
        child: Column(
          children: [
            /// 🔝 TOP BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset("assets/images/logo.png", height: 45),

                  Row(
                    children: [
                      iconButton(Icons.receipt_long, () {
                        Navigator.pushNamed(context, '/split');
                      }),
                      const SizedBox(width: 10),

                      iconButton(Icons.photo, () {
                        Navigator.pushNamed(context, '/photos');
                      }),
                      const SizedBox(width: 10),

                      iconButton(Icons.group, () {
                        showGroupDialog(context);
                      }),
                      const SizedBox(width: 10),

                      iconButton(Icons.settings, () {
                        showSettingsDialog(context);
                      }),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// 👋 HELLO + GROUP CODE
            FutureBuilder(
              future: Future.wait([getUsername(), getGroupCode()]),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();

                final username = snapshot.data![0];
                final groupCode = snapshot.data![1];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hello, $username",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      if (groupCode != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF98d7f4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "Group Code: $groupCode",
                            style: const TextStyle(
                              color: Color(0xFF31436f),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                      if (groupCode == null)
                        const Text(
                          "No group joined yet",
                          style: TextStyle(color: Colors.grey),
                        ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            const Expanded(
              child: Center(
                child: Text(
                  "Dashboard Content Coming Next",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
