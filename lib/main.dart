import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'pages/onboarding.dart';
import 'pages/login.dart';
import 'pages/register.dart';
import 'pages/dashboard.dart';
import 'pages/split.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
        '/dashboard': (context) => const DashboardPage(), // ✅ FIXED
      },
    );
  }
}
