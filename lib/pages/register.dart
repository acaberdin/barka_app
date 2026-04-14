import 'package:flutter/material.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(decoration: const InputDecoration(hintText: "Username")),
            TextField(decoration: const InputDecoration(hintText: "Email")),
            TextField(decoration: const InputDecoration(hintText: "Password")),
            TextField(
              decoration: const InputDecoration(hintText: "Confirm Password"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: const Text("Create Account"),
            ),
          ],
        ),
      ),
    );
  }
}
