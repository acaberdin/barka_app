import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplitPage extends StatefulWidget {
  const SplitPage({super.key});

  @override
  State<SplitPage> createState() => _SplitPageState();
}

class _SplitPageState extends State<SplitPage> {
  String? groupId;
  Map<String, String> membersMap = {};

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

      for (String uid in members) {
        final userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();

        membersMap[uid] = userData['username'];
      }
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    loadGroup();
  }

  @override
  Widget build(BuildContext context) {
    if (groupId == null) {
      return const Scaffold(body: Center(child: Text("No group joined")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFccefff),
      appBar: AppBar(title: const Text("Split History")),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('expenses')
            .where('groupId', isEqualTo: groupId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final expenses = snapshot.data!.docs;

          double total = 0;
          Map<String, double> balance = {};

          for (var uid in membersMap.keys) {
            balance[uid] = 0;
          }

          for (var e in expenses) {
            double amount = (e['amount'] ?? 0).toDouble();
            String payer = e['paidBy'];

            Map weights = e['weights'] ?? {};

            if (weights.isEmpty) {
              for (var uid in membersMap.keys) {
                weights[uid] = 1;
              }
            }

            int totalWeight = weights.values.fold(0, (a, b) => a + (b as int));

            total += amount;

            for (var uid in weights.keys) {
              double share = amount * (weights[uid] / totalWeight);
              balance[uid] = (balance[uid] ?? 0) - share;
            }

            balance[payer] = (balance[payer] ?? 0) + amount;
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Total: ₱${total.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              ...membersMap.entries.map((entry) {
                final uid = entry.key;
                final name = entry.value;
                final bal = balance[uid] ?? 0;

                return ListTile(
                  title: Text(name),
                  trailing: Text(
                    bal >= 0
                        ? "+₱${bal.toStringAsFixed(2)}"
                        : "-₱${bal.abs().toStringAsFixed(2)}",
                    style: TextStyle(
                      color: bal >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }),

              const Divider(),

              Expanded(
                child: ListView.builder(
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final e = expenses[index];

                    final payerName = membersMap[e['paidBy']] ?? "Unknown";

                    return ListTile(
                      title: Text(e['description'] ?? ""),
                      subtitle: Text("₱${e['amount']}"),
                      trailing: Text(payerName),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
