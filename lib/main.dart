import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'pages/home.dart';
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

      initialRoute: '/',

      routes: {
        '/': (context) => const Home(),
        '/login': (context) => const Login(),
        '/register': (context) => const Register(),
      },
    );
  }
}