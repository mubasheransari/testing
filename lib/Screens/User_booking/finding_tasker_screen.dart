import 'package:flutter/material.dart';
import 'package:taskoon/Screens/User_booking/tasker_confirmation_screen.dart';

class FindingYourTaskerScreen extends StatefulWidget {
  const FindingYourTaskerScreen({super.key});

  // colors picked from screenshot
  static const Color bgPurple = Color(0xFF43106F);
  static const Color ringGold1 = Color(0xFFF9DB75);
  static const Color ringGold2 = Color(0xFFD7A939);

  @override
  State<FindingYourTaskerScreen> createState() => _FindingYourTaskerScreenState();
}

class _FindingYourTaskerScreenState extends State<FindingYourTaskerScreen> {

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      
      // Navigator.of(context).pushReplacement(
      //   MaterialPageRoute(
      //     builder: (_) => const TaskerConfirmationScreen(), // <- your real screen
      //   ),
      // );
    });
  }
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: FindingYourTaskerScreen.bgPurple,
      body: Stack(
        children: [
          // top wave
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.32,
            child: CustomPaint(
              painter: _TopWavePainter(),
            ),
          ),
          // bottom wave
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: size.height * 0.30,
            child: CustomPaint(
              painter: _BottomWavePainter(),
            ),
          ),

          // center logo + text
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // double golden ring with purple inside
                Container(
                  width: 190,
                  height: 190,
                
                  child: Center(
                    child: Image.asset('assets/user_finding_tasker.png')
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Finding your tasker',
                  style: TextStyle(
                           fontFamily: 'Poppins',
                    fontSize: 23,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// top organic shape (light-purple overlay)
class _TopWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF542383).withOpacity(0.55)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0.55)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.20,
          size.width * 0.55, size.height * 0.35)
      ..quadraticBezierTo(size.width * 0.78, size.height * 0.48,
          size.width, size.height * 0.28)
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// bottom organic shape (darker/layered like screenshot)
class _BottomWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = const Color(0xFF341157).withOpacity(0.65)
      ..style = PaintingStyle.fill;

    final path1 = Path()
      ..moveTo(0, size.height * 0.35)
      ..quadraticBezierTo(
          size.width * 0.25, size.height * 0.15, size.width * 0.45, size.height * 0.35)
      ..quadraticBezierTo(
          size.width * 0.72, size.height * 0.68, size.width, size.height * 0.40)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path1, paint1);

    // a second subtle blob on the right
    final paint2 = Paint()
      ..color = const Color(0xFF4B1475).withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final path2 = Path()
      ..moveTo(size.width * 0.35, size.height * 0.50)
      ..quadraticBezierTo(
          size.width * 0.65, size.height * 0.15, size.width, size.height * 0.35)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * 0.35, size.height)
      ..close();

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
