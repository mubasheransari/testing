import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:taskoon/Screens/Authentication/login_screen.dart';
import 'package:taskoon/Screens/Booking_process_tasker/bottom_nav_root_screen.dart';
import 'package:taskoon/Screens/Splash_Slider/slider_screen.dart';
import 'package:taskoon/Screens/Tasker_Onboarding/personal_info.dart';
import 'dart:math' as math;

import 'package:taskoon/Screens/User_booking/user_booking_home.dart';
import 'package:taskoon/Screens/User_booking/user_booking_nav_bar.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

/* ---------------------- Theme tokens (Purple) ---------------------- */
const _primary = Color(0xFF7841BA); // Taskoon purple
const _primaryAlt = Color(0xFF8B59C6); // lighter purple for gradients
const _underline = _primary; // used in tagline underline if needed
const _text = Color(0xFF1E1E1E);
const _muted = Color(0xFF707883);
const _card = Colors.white;

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoCtrl; // logo pop-in
  late final AnimationController _pillCtrl; // rotating/sweeping pills
  late final AnimationController _fadeCtrl; // tagline + content fade/slide
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _taglineOpacity;
  late final Animation<Offset> _taglineOffset;
  var storage = GetStorage();

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pillCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _logoScale = Tween(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack));
    _logoOpacity = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut));

    _taglineOpacity = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
    _taglineOffset = Tween(
      begin: const Offset(0, .15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic));

    // Sequence: start logo, then pills, then tagline, then navigate.
    _logoCtrl.forward().whenComplete(() {
      _pillCtrl.repeat(); // continuous sweep while splash shows
      _fadeCtrl.forward();
      Future.delayed(const Duration(milliseconds: 1500), _goHome);
    });
  }

  void _goHome() {
    if (!mounted) return;
    _pillCtrl.stop();

    var role = storage.read("role");

    Navigator.of(context).pushReplacement(
      _fadeRoute(
        role == "Tasker"
            ? TaskoonApp()//PersonalInfo() //TaskoonApp()
            : role == "Customer"
            ? UserBottomNavBar()
            : LoginScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _pillCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background gradient sweep (very subtle, now purple)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pillCtrl,
              builder: (_, __) {
                final a = _pillCtrl.value * 2 * math.pi;
                return CustomPaint(painter: _SoftSweepPainter(angle: a));
              },
            ),
          ),

          // Center content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // const SizedBox(height: 10),
                  // Transform.rotate(
                  //   angle: -12 * math.pi / 180,
                  //   child: _PurplePills(anim: _pillCtrl),
                  // ),
                  // const SizedBox(height: 24),

                  // Logo pop-in
                  ScaleTransition(
                    scale: _logoScale,
                    child: FadeTransition(
                      opacity: _logoOpacity,
                      child: _LogoCard(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            color: Colors.white,
                            padding: const EdgeInsets.all(18),
                            child: Transform.rotate(
                              angle: -12 * math.pi / 180, // same tilt as pills
                              child: Image.asset(
                                'assets/taskoon_logo.png',
                                height: 208,
                                width: 208,
                              ),
                              /* Text(
                                "Taskoon",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  foreground: Paint()
                                    ..shader = const LinearGradient(
                                      colors: [_primaryAlt, _primary],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ).createShader(
                                      Rect.fromLTWH(0, 0, 150, 40),
                                    ),
                                ),
                              ),*/
                            ),
                            // Or swap to your asset logo here
                            // Image.asset('assets/logo.png', width: 90, height: 90),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Brand name
                  // FadeTransition(
                  //   opacity: _logoOpacity,
                  //   child: Text(
                  //     "Motives",
                  //     style: t.headlineSmall?.copyWith(
                  //       color: _text,
                  //       fontWeight: FontWeight.w800,
                  //       letterSpacing: .6,
                  //     ),
                  //   ),
                  // ),
                  const SizedBox(height: 6),

                  // Tagline slide+fade
                  // FadeTransition(
                  //   opacity: _taglineOpacity,
                  //   child: SlideTransition(
                  //     position: _taglineOffset,
                  //     child: Text(
                  //       "Making your day smoother",
                  //       style: t.bodyMedium?.copyWith(
                  //         color: _muted,
                  //         fontWeight: FontWeight.w600,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* --------------------- Pieces (Purple look) --------------------- */

class _LogoCard extends StatelessWidget {
  const _LogoCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryAlt, _primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _PurplePills extends StatelessWidget {
  const _PurplePills({required this.anim});
  final AnimationController anim;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) {
        final shift = (anim.value - .5) * 10; // small breathing
        return Column(
          children: const [
            _Pill(color: Color(0x268B59C6), width: 52), // 15% opacity
            SizedBox(height: 6),
            _Pill(color: Color(0x558B59C6), width: 64), // 33% opacity
            SizedBox(height: 6),
            _Pill(color: _primary, width: 86),
          ],
        );
      },
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.color, required this.width});
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

// Soft rotating radial sweep in the background (very light, purple)
class _SoftSweepPainter extends CustomPainter {
  _SoftSweepPainter({required this.angle});
  final double angle;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.longestSide * .7;

    final sweep = Paint()
      ..shader = SweepGradient(
        startAngle: angle,
        endAngle: angle + math.pi * 2,
        colors: [
          _primary.withOpacity(.08),
          Colors.transparent,
          _primary.withOpacity(.06),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, sweep);

    // faint vignette
    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, Colors.black.withOpacity(.03)],
      ).createShader(Rect.fromCircle(center: center, radius: size.longestSide));
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(covariant _SoftSweepPainter oldDelegate) =>
      oldDelegate.angle != angle;
}

/* --------------------- Page transition --------------------- */
PageRouteBuilder _fadeRoute(Widget child) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 450),
    pageBuilder: (_, __, ___) => child,
    transitionsBuilder: (_, anim, __, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> {
//   @override
//   void initState() {
//     super.initState();
//     // 5 second delay before navigation
//     Timer(const Duration(seconds: 5), () {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//             builder: (context) =>
//                 OnboardingScreen()), // Replace with your screen
//       );
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Image.asset(
//           'assets/taskoon_logo.png',
//           height: 308,
//           width: 308,
//         ),
//       ),
//     );
//   }
// }
