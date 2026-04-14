import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'pages/onboarding.dart';
import 'pages/login.dart';
import 'pages/register.dart';

void main() {
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

      // ✅ START APP HERE
      initialRoute: '/',

      // ✅ ALL ROUTES MUST EXIST
      routes: {
        '/': (context) => const OnboardingPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/onboarding': (context) => const OnboardingPage(),
      },
    );
  }
}
