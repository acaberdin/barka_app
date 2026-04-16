import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  late AnimationController waveController;
  late AnimationController riseController;

  late Animation<double> waterRise;

  int step = 0;
  bool showBrand = true;

  @override
  void initState() {
    super.initState();

    waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    riseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();

    waterRise = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: riseController, curve: Curves.easeOut));

    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() {
        showBrand = false;
      });
    });
  }

  @override
  void dispose() {
    waveController.dispose();
    riseController.dispose();
    super.dispose();
  }

  void nextStep() {
    if (!mounted) return;

    if (step < 2) {
      setState(() {
        step++;
      });
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  String get title {
    switch (step) {
      case 0:
        return "FRIENDS & FUN";
      case 1:
        return "HASSLE FREE";
      case 2:
        return "MEMORIES";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF98d7f4),
      body: AnimatedBuilder(
        animation: waveController,
        builder: (context, child) {
          return Stack(
            children: [
              /// 🌊 BACK WAVE
              Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  height: height * waterRise.value,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: WavePainter(
                      waveController.value,
                      speed: 0.6,
                      height: 25,
                      opacity: 0.5,
                    ),
                  ),
                ),
              ),

              /// 🌊 FRONT WAVE
              Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  height: height * waterRise.value,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: WavePainter(
                      waveController.value,
                      speed: 1.2,
                      height: 35,
                      opacity: 1,
                    ),
                  ),
                ),
              ),

              /// 🌟 CENTER CONTENT
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 800),
                  child: showBrand ? _buildBrand() : _buildText(),
                ),
              ),

              /// 🚀 BUTTON
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 50),
                  child: ElevatedButton(
                    onPressed: nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFCDCE),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 45,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      step < 2 ? "NEXT" : "GET STARTED",
                      style: GoogleFonts.leagueSpartan(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 🟣 BRAND SCREEN
  Widget _buildBrand() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/images/logo.png', height: 170, width: 170),
        const SizedBox(height: 10),
        Text(
          "BARKA",
          style: GoogleFonts.schoolbell(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }

  /// 🔵 ONBOARD TEXT
  Widget _buildText() {
    return Text(
      title,
      key: ValueKey(step),
      style: GoogleFonts.leagueSpartan(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: 4,
      ),
    );
  }
}

/// 🌊 WAVE PAINTER
class WavePainter extends CustomPainter {
  final double value;
  final double speed;
  final double height;
  final double opacity;

  WavePainter(
    this.value, {
    required this.speed,
    required this.height,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFccefff).withOpacity(opacity);

    final path = Path();

    path.moveTo(0, size.height * 0.7);

    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        size.height * 0.7 +
            sin((i / size.width * 2 * pi) + (value * 2 * pi * speed)) * height,
      );
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
