import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final amountController = TextEditingController();
  final descController = TextEditingController();

  String? groupId;

  /// 🔥 UID → USERNAME
  Map<String, String> membersMap = {};

  /// 🔥 WEIGHTS
  Map<String, int> weights = {};

  String? selectedPayer;

  /// 🔥 LOAD GROUP + USERNAMES
  Future<void> loadGroup() async {
    final user = FirebaseAuth.instance.currentUser!;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    List groupIds = userDoc['groupIds'] ?? [];

    if (groupIds.isNotEmpty) {
      groupId = groupIds[0];

      final groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .get();

      List members = groupDoc['members'] ?? [];

      /// 🔥 FETCH USERNAMES + INIT WEIGHTS
      for (String uid in members) {
        final userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();

        membersMap[uid] = userData['username'];
        weights[uid] = 1; // default 1x
      }

      selectedPayer = membersMap.keys.first;
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    loadGroup();
  }

  /// 🔥 SAVE EXPENSE
  Future<void> saveExpense() async {
    if (amountController.text.isEmpty ||
        descController.text.isEmpty ||
        selectedPayer == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Fill all fields")));
      return;
    }

    final amount = double.tryParse(amountController.text);

    if (amount == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid amount")));
      return;
    }

    await FirebaseFirestore.instance.collection('expenses').add({
      'groupId': groupId,
      'amount': amount,
      'description': descController.text.trim(),
      'paidBy': selectedPayer, // UID
      'weights': weights, // 🔥 NEW
      'createdAt': Timestamp.now(),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (groupId == null) {
      return const Scaffold(body: Center(child: Text("No group found")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFccefff),
      appBar: AppBar(title: const Text("Add Expense")),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// 💰 AMOUNT
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Amount"),
            ),

            const SizedBox(height: 10),

            /// 📝 DESCRIPTION
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: "Description"),
            ),

            const SizedBox(height: 10),

            /// 👤 PAID BY
            DropdownButtonFormField(
              value: selectedPayer,
              items: membersMap.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedPayer = value as String;
                });
              },
              decoration: const InputDecoration(labelText: "Paid by"),
            ),

            const SizedBox(height: 20),

            /// 🔥 WEIGHTED SPLIT UI
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Split Weight",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            Column(
              children: membersMap.entries.map((entry) {
                final uid = entry.key;
                final name = entry.value;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name),
                    DropdownButton<int>(
                      value: weights[uid],
                      items: [1, 2, 3, 4].map((w) {
                        return DropdownMenuItem(value: w, child: Text("${w}x"));
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          weights[uid] = val!;
                        });
                      },
                    ),
                  ],
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            /// ✅ SAVE
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveExpense,
                child: const Text("Save Expense"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
