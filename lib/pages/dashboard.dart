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

    return List.generate(3, (_) => letters[random.nextInt(26)]).join() +
        List.generate(3, (_) => numbers[random.nextInt(10)]).join();
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

  /// 🔥 GET GROUP ID
  Future<String?> getGroupId() async {
    final user = FirebaseAuth.instance.currentUser!;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    List groupIds = userDoc['groupIds'] ?? [];
    if (groupIds.isEmpty) return null;

    return groupIds[0];
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
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Group Options"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: "Enter Group Code"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  joinGroup(context, controller.text.trim());
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

  /// 🔥 SETTINGS (CHANGE PASSWORD)
  void showSettingsDialog(BuildContext context) {
    final current = TextEditingController();
    final newPass = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Change Password"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: current,
                obscureText: true,
                decoration: const InputDecoration(hintText: "Current Password"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: newPass,
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
                    password: current.text.trim(),
                  );

                  await user.reauthenticateWithCredential(credential);
                  await user.updatePassword(newPass.text.trim());

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

  /// 🔥 ICON BUTTON
  Widget iconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      splashColor: const Color(0xFF98d7f4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: const Color(0xFF31436f)),
      ),
    );
  }

  /// 🔥 DASHBOARD CARD (REAL-TIME + GROUP FILTERED)
  Widget dashboardCard() {
    final user = FirebaseAuth.instance.currentUser!;

    return FutureBuilder(
      future: getGroupId(),
      builder: (context, groupSnap) {
        if (!groupSnap.hasData) return const SizedBox();

        final groupId = groupSnap.data;

        return StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('expenses')
              .where('groupId', isEqualTo: groupId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }

            final expenses = snapshot.data!.docs;

            double total = 0;
            double myBalance = 0;

            for (var e in expenses) {
              double amount = (e['amount'] ?? 0).toDouble();
              String payer = e['paidBy'];

              Map weights = e['weights'] ?? {};

              if (weights.isEmpty) {
                weights[user.uid] = 1;
              }

              int totalWeight = weights.values.fold(
                0,
                (a, b) => a + (b as int),
              );

              total += amount;

              for (var uid in weights.keys) {
                double share = amount * (weights[uid] / totalWeight);

                if (uid == user.uid) {
                  myBalance -= share;
                }
              }

              if (payer == user.uid) {
                myBalance += amount;
              }
            }

            return Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Total Expenses",
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        "₱${total.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        myBalance >= 0
                            ? "You are owed ₱${myBalance.toStringAsFixed(2)}"
                            : "You owe ₱${myBalance.abs().toStringAsFixed(2)}",
                        style: TextStyle(
                          color: myBalance >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// 🔥 RECENT EXPENSES
                Expanded(
                  child: ListView.builder(
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      final e = expenses[index];

                      return ListTile(
                        title: Text(e['description'] ?? ""),
                        subtitle: Text("₱${e['amount']}"),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFccefff),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF31436f),
        onPressed: () {
          Navigator.pushNamed(context, '/add-expense');
        },
        child: const Icon(Icons.add),
      ),

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
                      iconButton(Icons.photo, () {
                        Navigator.pushNamed(context, '/photos');
                      }),
                      iconButton(Icons.group, () {
                        showGroupDialog(context);
                      }),
                      iconButton(Icons.settings, () {
                        showSettingsDialog(context);
                      }),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// 👋 USER + GROUP
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
                        "Hello, $username 👋",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      if (groupCode != null) Text("Group Code: $groupCode"),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            /// 🔥 DASHBOARD CONTENT
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: dashboardCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
