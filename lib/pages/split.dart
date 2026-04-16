import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SplitPage extends StatelessWidget {
  const SplitPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Split History")),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('expenses')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final expenses = snapshot.data!.docs;

          double total = 0;

          for (var e in expenses) {
            total += (e['amount'] ?? 0);
          }

          return Column(
            children: [
              /// TOTAL
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Total: ₱$total",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              /// LIST
              Expanded(
                child: ListView.builder(
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final e = expenses[index];

                    return ListTile(
                      title: Text(e['description'] ?? "No desc"),
                      subtitle: Text("₱${e['amount']}"),
                      trailing: Text(e['paidBy']),
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
