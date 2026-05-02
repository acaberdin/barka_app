import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// FIXED IMPORTS
import 'dashboard.dart';
import 'camera.dart';
import 'split.dart';
import 'photos.dart'; // ✅ FIXED

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 1;

  final List<Widget> _pages = const [
    CameraPage(),   // ✅ make sure this exists
    DashboardPage(),
    SplitPage(),
    PhotosPage(),   // ✅ FIXED
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: Drawer(
        child: Column(
          children: [
            const SizedBox(height: 60),

            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Profile"),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text("Group"),
              onTap: () {
                Navigator.pushNamed(context, '/group');
              },
            ),

            const Spacer(),

            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text("Leave Group"),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Log Out"),
              onTap: logout,
            ),
          ],
        ),
      ),

      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.camera), label: "Camera"),
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: "Dashboard"),
          BottomNavigationBarItem(
              icon: Icon(Icons.call_split), label: "Split"),
          BottomNavigationBarItem(
              icon: Icon(Icons.photo), label: "Photos"), // ✅ renamed
        ],
      ),
    );
  }
}