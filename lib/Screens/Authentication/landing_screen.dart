import 'package:flutter/material.dart';
import 'package:taskoon/Screens/Authentication/role_selection_screen.dart';
import 'login_screen.dart';

class TaskoonLandingScreen extends StatelessWidget {
  const TaskoonLandingScreen({super.key});

  static const purple = Color(0xFF4C1D95); // main brand purple
  static const gold = Color(0xFFB98F22); // card border gold
  static const arcPurple = Color(0xFF5A1FBF); // top arc

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _HeroHeader(width: w),
              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: gold, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
                    child: Column(
                      children: [
                        const Text(
                          'Welcome to Taskoon',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .2,
                          ),
                        ),
                        const SizedBox(height: 18),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: purple,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => LoginScreen()));
                            },
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.black,
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () {},
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: Colors.black.withOpacity(.75),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Signup (outlined pill)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: purple, width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          RoleSelectScreen()));
                            },
                            child: Text(
                              'Signup',
                              style: TextStyle(
                                color: purple,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Footer links
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _footerLink('Privacy Policy', onTap: () {}),
                            _footerLink('Terms and Conditions', onTap: () {}),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footerLink(String text, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );
  }
}

/* --------------------- Hero Header --------------------- */
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({Key? key, required this.width}) : super(key: key);
  final double width;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo
        Padding(
          padding: const EdgeInsets.only(top: 40, bottom: 20),
          child: Image.asset(
            'assets/taskoon_logo.png',
            height: 150,
            width: 150,
          ),
        ),

        // Title
        const Text(
          'Trained Cleaners',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 34,
            height: 1.1,
            fontWeight: FontWeight.w900,
          ),
        ),

        const SizedBox(height: 10),

        // Subtitle
        Text(
          'Verified cleaners delivering\nspotless results you can trust',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            height: 1.25,
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/* -------------------- Painters -------------------- */

class _TopArcPainter extends CustomPainter {
  _TopArcPainter({required this.color, required this.stroke});
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(-size.width * .1, size.height * .12,
        size.width * 1.2, size.height * .9);
    final start = 200 * 3.14159 / 180; // ~200°
    final sweep = 140 * 3.14159 / 180; // ~140°
    canvas.drawArc(rect, start, sweep, false, paint);
  }

  @override
  bool shouldRepaint(covariant _TopArcPainter old) =>
      old.color != color || old.stroke != stroke;
}
