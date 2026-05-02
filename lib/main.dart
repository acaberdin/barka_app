import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

// PAGES
import 'pages/onboarding.dart';
import 'pages/login.dart';
import 'pages/register.dart';
import 'pages/main_layout.dart';
import 'pages/add_expense.dart';
import 'pages/photos.dart';
import 'pages/split.dart';
import 'pages/group.dart'; // ✅ ADD THIS

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const BarkaApp());
}

class BarkaApp extends StatelessWidget {
  const BarkaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFccefff),
        textTheme: GoogleFonts.schoolbellTextTheme(),
      ),

      initialRoute: '/onboarding',

      routes: {
        '/onboarding': (context) => const OnboardingPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),

        // ✅ MAIN APP
        '/main': (context) => const MainLayout(),

        // ✅ FEATURE PAGES
        '/add-expense': (context) => const AddExpensePage(),
        '/photos': (context) => const PhotosPage(),
        '/split': (context) => const SplitPage(),

        // ✅ FIXED GROUP ROUTE
        '/group': (context) => const GroupPage(),
      },
    );
  }
}