import 'dart:math';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(); // 🔁 infinite loop for wave

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _bounceAnimation = Tween<double>(begin: 0.85, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double wave(double value, double speed, double height) {
    return sin(value * 2 * pi + _controller.value * 2 * pi * speed) * height;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFccefff),

      body: Stack(
        children: [

          // 🌊 BACK WAVE (slow + deep movement)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Positioned(
                bottom: 0,
                left: wave(1, 0.5, 20),
                right: wave(1, 0.5, 20),
                child: Opacity(
                  opacity: 0.4,
                  child: Image.asset(
                    'assets/images/wave.png',
                    width: size.width * 1.2,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),

          // 🌊 FRONT WAVE (faster + stronger movement)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Positioned(
                bottom: 0,
                left: wave(1.5, 1.2, 35),
                right: wave(1.5, 1.2, 35),
                child: Image.asset(
                  'assets/images/wave.png',
                  width: size.width * 1.2,
                  fit: BoxFit.cover,
                ),
              );
            },
          ),

          // 🌟 MAIN CONTENT
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _bounceAnimation,
                child: Padding(
                  padding: EdgeInsets.only(bottom: size.height * 0.10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      Image.asset(
                        'assets/images/logo.png',
                        height: 240,
                      ),

                      const SizedBox(height: 15),

                      const Text(
                        "BARKA",
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),

                      const SizedBox(height: 35),

                      SizedBox(
                        width: 260,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/login');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFCDCE),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 5,
                          ),
                          child: const Text("LOGIN"),
                        ),
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: 260,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/register');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFCDCE),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 5,
                          ),
                          child: const Text("REGISTER"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}