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

  /// 🔥 GET USERNAME (SAFE)
  Future<String> getUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return "User";

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = doc.data();
    return data?['username'] ?? "User";
  }

  /// 🔥 GET GROUP ID (SAFE)
  Future<String?> getGroupId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = userDoc.data();
    List groupIds = data?['groupIds'] ?? [];

    if (groupIds.isEmpty) return null;

    return groupIds[0];
  }

  /// 🔥 GET GROUP CODE (SAFE)
  Future<String?> getGroupCode() async {
    final groupId = await getGroupId();
    if (groupId == null) return null;

    final groupDoc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .get();

    return groupDoc.data()?['joinCode'];
  }

  /// 🔥 CREATE GROUP
  Future<void> createGroup(BuildContext context) async {
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

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Group created! Code: $code")));
  }

  /// 🔥 JOIN GROUP
  Future<void> joinGroup(BuildContext context, String code) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final result = await FirebaseFirestore.instance
        .collection('groups')
        .where('joinCode', isEqualTo: code)
        .get();

    if (result.docs.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Invalid code")));
      return;
    }

    final group = result.docs.first;

    await FirebaseFirestore.instance.collection('groups').doc(group.id).update({
      'members': FieldValue.arrayUnion([user.uid]),
    });

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'groupIds': [group.id],
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Joined group!")));
  }

  /// 🔥 GROUP DIALOG
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

  /// 🔥 SETTINGS
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
                  final cred = EmailAuthProvider.credential(
                    email: user.email!,
                    password: current.text.trim(),
                  );

                  await user.reauthenticateWithCredential(cred);
                  await user.updatePassword(newPass.text.trim());

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Password updated!")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text("$e")));
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
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: const Color(0xFF31436f)),
      ),
    );
  }

  /// 🔥 DASHBOARD CARD (FIXED LOADING)
  Widget dashboardCard() {
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<String?>(
      future: getGroupId(),
      builder: (context, groupSnap) {
        if (groupSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final groupId = groupSnap.data;

        if (groupId == null) {
          return const Center(child: Text("Join or create a group"));
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('expenses')
              .where('groupId', isEqualTo: groupId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final expenses = snapshot.data?.docs ?? [];

            double total = 0;
            double myBalance = 0;

            for (var e in expenses) {
              final data = e.data() as Map<String, dynamic>;

              double amount = (data['amount'] ?? 0).toDouble();
              String payer = data['paidBy'] ?? "";

              total += amount;

              if (payer == user?.uid) {
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
                      const Text("Total Expenses"),
                      Text("₱${total.toStringAsFixed(2)}"),
                      const SizedBox(height: 10),
                      Text(
                        myBalance >= 0
                            ? "You are owed ₱${myBalance.toStringAsFixed(2)}"
                            : "You owe ₱${myBalance.abs().toStringAsFixed(2)}",
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: expenses.isEmpty
                      ? const Center(child: Text("No expenses yet"))
                      : ListView.builder(
                          itemCount: expenses.length,
                          itemBuilder: (context, index) {
                            final data =
                                expenses[index].data() as Map<String, dynamic>;

                            return ListTile(
                              title:
                                  Text(data['description'] ?? "No description"),
                              subtitle: Text("₱${data['amount'] ?? 0}"),
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
                  const Text("Dashboard",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
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
                if (!snapshot.hasData) {
                  return const SizedBox();
                }

                final username = snapshot.data![0];
                final groupCode = snapshot.data![1];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Hello, $username 👋",
                          style: const TextStyle(fontSize: 22)),
                      if (groupCode != null) Text("Group Code: $groupCode"),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            /// 🔥 DASHBOARD
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
