import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_bloc.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_state.dart';
import 'package:taskoon/Screens/Authentication/login_screen.dart';
import 'package:taskoon/Screens/Booking_process_tasker/bottom_nav_root_screen.dart';
import 'package:taskoon/Screens/Tasker_Onboarding/personal_info.dart';
import 'dart:math' as math;
import 'package:taskoon/Screens/User_booking/user_booking_nav_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// const _primary = Color(0xFF7841BA);
// const _primaryAlt = Color(0xFF8B59C6);
// const _underline = _primary;
// const _text = Color(0xFF1E1E1E);
// const _muted = Color(0xFF707883);
// const _card = Colors.white;

// class _SplashScreenState extends State<SplashScreen>
//     with TickerProviderStateMixin {
//   late final AnimationController _logoCtrl;
//   late final AnimationController _pillCtrl;
//   late final AnimationController _fadeCtrl;
//   late final Animation<double> _logoScale;
//   late final Animation<double> _logoOpacity;
//   late final Animation<double> _taglineOpacity;
//   late final Animation<Offset> _taglineOffset;

//   final storage = GetStorage();

//   bool _navigated = false;
//   Timer? _maxWaitTimer;

//   @override
//   void initState() {
//     super.initState();

//     _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
//     _pillCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
//     _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

//     _logoScale = Tween(begin: 0.85, end: 1.0)
//         .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack));
//     _logoOpacity = Tween(begin: 0.0, end: 1.0)
//         .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut));

//     _taglineOpacity = Tween(begin: 0.0, end: 1.0)
//         .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
//     _taglineOffset = Tween(begin: const Offset(0, .15), end: Offset.zero)
//         .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic));

//     // ✅ max fallback so you never get stuck
//     _maxWaitTimer = Timer(const Duration(seconds: 8), () {
//       _tryNavigate(force: true);
//     });

//     // Sequence: start logo, then pills, then fade.
//     _logoCtrl.forward().whenComplete(() {
//       _pillCtrl.repeat();
//       _fadeCtrl.forward();

//       // ✅ DO NOT navigate here
//       // We will navigate only when data is ready via BlocListener below.
//     });
//   }

//   bool _isInitDone(AuthenticationState s) {
//     final servicesDone = s.servicesStatus == ServicesStatus.success ||
//         s.servicesStatus == ServicesStatus.failure;

//     final docsDone = s.documentsStatus == DocumentsStatus.success ||
//         s.documentsStatus == DocumentsStatus.failure;

//     final videosDone = s.trainingVideosStatus == TrainingVideosStatus.success ||
//         s.trainingVideosStatus == TrainingVideosStatus.failure;

//     final savedUserId = storage.read<String>('userId');
//     final needsUserDetails = savedUserId != null && savedUserId.isNotEmpty;

//     final userDone = !needsUserDetails ||
//         s.userDetailsStatus == UserDetailsStatus.success ||
//         s.userDetailsStatus == UserDetailsStatus.failure;

//     return servicesDone && docsDone && videosDone && userDone;
//   }

//   void _tryNavigate({bool force = false}) {
//     if (!mounted || _navigated) return;

//     final authState = context.read<AuthenticationBloc>().state;

//     if (!force && !_isInitDone(authState)) {
//       return;
//     }

//     _navigated = true;
//     _maxWaitTimer?.cancel();
//     _pillCtrl.stop();

//     final role = storage.read("role");
//     print("ROLE $role");
//      print("ROLE $role");
//       print("ROLE $role");

//     Navigator.of(context).pushReplacement(
//       _fadeRoute(
//         role == "Tasker"
//             ? PersonalInfo()// TaskoonApp()
//             : role == "Customer"
//                 ? UserBottomNavBar()
//                 : LoginScreen(),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _maxWaitTimer?.cancel();
//     _logoCtrl.dispose();
//     _pillCtrl.dispose();
//     _fadeCtrl.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;

//     return BlocListener<AuthenticationBloc, AuthenticationState>(
//       listenWhen: (prev, curr) {
//         // ✅ only re-check when these statuses change
//         return prev.servicesStatus != curr.servicesStatus ||
//             prev.documentsStatus != curr.documentsStatus ||
//             prev.trainingVideosStatus != curr.trainingVideosStatus ||
//             prev.userDetailsStatus != curr.userDetailsStatus;
//       },
//       listener: (context, state) {
//         if (_isInitDone(state)) {
//           _tryNavigate();
//         }
//       },
//       child: Scaffold(
//         backgroundColor: Colors.white,
//         body: Stack(
//           children: [
//             Positioned.fill(
//               child: AnimatedBuilder(
//                 animation: _pillCtrl,
//                 builder: (_, __) {
//                   final a = _pillCtrl.value * 2 * math.pi;
//                   return CustomPaint(painter: _SoftSweepPainter(angle: a));
//                 },
//               ),
//             ),
//             SafeArea(
//               child: Center(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     ScaleTransition(
//                       scale: _logoScale,
//                       child: FadeTransition(
//                         opacity: _logoOpacity,
//                         child: _LogoCard(
//                           child: ClipRRect(
//                             borderRadius: BorderRadius.circular(18),
//                             child: Container(
//                               color: Colors.white,
//                               padding: const EdgeInsets.all(18),
//                               child: Transform.rotate(
//                                 angle: -12 * math.pi / 180,
//                                 child: Image.asset(
//                                   'assets/taskoon_logo.png',
//                                   height: 208,
//                                   width: 208,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 18),

//                     // OPTIONAL: tiny loading text / spinner (won't change UI much)
//                     FadeTransition(
//                       opacity: _taglineOpacity,
//                       child: SlideTransition(
//                         position: _taglineOffset,
//                         child: Column(
//                           children: [
//                             const SizedBox(height: 8),
//                             const SizedBox(
//                               width: 18,
//                               height: 18,
//                               child: CircularProgressIndicator(strokeWidth: 2),
//                             ),
//                             const SizedBox(height: 10),
//                             Text(
//                               "Preparing your experience...",
//                               style: t.bodyMedium?.copyWith(
//                                 color: _muted,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// /* --------------------- Pieces (Purple look) --------------------- */

// class _LogoCard extends StatelessWidget {
//   const _LogoCard({required this.child});
//   final Widget child;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           colors: [_primaryAlt, _primary],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.all(Radius.circular(20)),
//       ),
//       child: Container(
//         margin: const EdgeInsets.all(2),
//         decoration: BoxDecoration(
//           color: _card,
//           borderRadius: BorderRadius.circular(18),
//           boxShadow: const [
//             BoxShadow(
//               color: Color(0x14000000),
//               blurRadius: 14,
//               offset: Offset(0, 8),
//             ),
//           ],
//         ),
//         child: child,
//       ),
//     );
//   }
// }

// // Soft rotating radial sweep in the background (very light, purple)
// class _SoftSweepPainter extends CustomPainter {
//   _SoftSweepPainter({required this.angle});
//   final double angle;

//   @override
//   void paint(Canvas canvas, Size size) {
//     final center = size.center(Offset.zero);
//     final radius = size.longestSide * .7;

//     final sweep = Paint()
//       ..shader = SweepGradient(
//         startAngle: angle,
//         endAngle: angle + math.pi * 2,
//         colors: [
//           _primary.withOpacity(.08),
//           Colors.transparent,
//           _primary.withOpacity(.06),
//         ],
//         stops: const [0.0, 0.55, 1.0],
//       ).createShader(Rect.fromCircle(center: center, radius: radius));

//     canvas.drawCircle(center, radius, sweep);

//     final vignette = Paint()
//       ..shader = RadialGradient(
//         colors: [Colors.transparent, Colors.black.withOpacity(.03)],
//       ).createShader(Rect.fromCircle(center: center, radius: size.longestSide));
//     canvas.drawRect(Offset.zero & size, vignette);
//   }

//   @override
//   bool shouldRepaint(covariant _SoftSweepPainter oldDelegate) =>
//       oldDelegate.angle != angle;
// }

// /* --------------------- Page transition --------------------- */
// PageRouteBuilder _fadeRoute(Widget child) {
//   return PageRouteBuilder(
//     transitionDuration: const Duration(milliseconds: 450),
//     pageBuilder: (_, __, ___) => child,
//     transitionsBuilder: (_, anim, __, child) {
//       return FadeTransition(
//         opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
//         child: child,
//       );
//     },
//   );
// }


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

const _primary = Color(0xFF7841BA);
const _primaryAlt = Color(0xFF8B59C6);
const _text = Color(0xFF1E1E1E);
const _muted = Color(0xFF707883);
const _card = Colors.white;

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final AnimationController _pillCtrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _taglineOpacity;
  late final Animation<Offset> _taglineOffset;

  final storage = GetStorage();

  bool _navigated = false;
  Timer? _maxWaitTimer;

  @override
  void initState() {
    super.initState();

    _logoCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _pillCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
    _fadeCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

    _logoScale = Tween(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack),
    );
    _logoOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut),
    );

    _taglineOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut),
    );
    _taglineOffset = Tween(begin: const Offset(0, .15), end: Offset.zero).animate(
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic),
    );

    // ✅ max fallback so you never get stuck
    _maxWaitTimer = Timer(const Duration(seconds: 8), () {
      _tryNavigate(force: true);
    });

    // Sequence: start logo, then background loop, then fade.
    _logoCtrl.forward().whenComplete(() {
      _pillCtrl.repeat();
      _fadeCtrl.forward();
      // ✅ DO NOT navigate here
    });
  }

  bool _isInitDone(AuthenticationState s) {
    final servicesDone = s.servicesStatus == ServicesStatus.success ||
        s.servicesStatus == ServicesStatus.failure;

    final docsDone = s.documentsStatus == DocumentsStatus.success ||
        s.documentsStatus == DocumentsStatus.failure;

    final videosDone = s.trainingVideosStatus == TrainingVideosStatus.success ||
        s.trainingVideosStatus == TrainingVideosStatus.failure;

    final savedUserId = storage.read<String>('userId');
    final needsUserDetails = savedUserId != null && savedUserId.isNotEmpty;

    final userDone = !needsUserDetails ||
        s.userDetailsStatus == UserDetailsStatus.success ||
        s.userDetailsStatus == UserDetailsStatus.failure;

    return servicesDone && docsDone && videosDone && userDone;
  }

  void _tryNavigate({bool force = false}) {
    if (!mounted || _navigated) return;

    final authState = context.read<AuthenticationBloc>().state;

    if (!force && !_isInitDone(authState)) {
      return;
    }

    _navigated = true;
    _maxWaitTimer?.cancel();
    _pillCtrl.stop();

    final role = storage.read("role");
    debugPrint("ROLE $role");

    Navigator.of(context).pushReplacement(
      _fadeRoute(
        role == "Tasker"
            ? PersonalInfo()
            : role == "Customer"
                ? UserBottomNavBar()
                : LoginScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _maxWaitTimer?.cancel();
    _logoCtrl.dispose();
    _pillCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return BlocListener<AuthenticationBloc, AuthenticationState>(
      listenWhen: (prev, curr) {
        return prev.servicesStatus != curr.servicesStatus ||
            prev.documentsStatus != curr.documentsStatus ||
            prev.trainingVideosStatus != curr.trainingVideosStatus ||
            prev.userDetailsStatus != curr.userDetailsStatus;
      },
      listener: (context, state) {
        if (_isInitDone(state)) {
          _tryNavigate();
        }
      },
      child: Theme(
        data: Theme.of(context).copyWith(
          textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Poppins'),
        ),
        child: Scaffold(
          body: Stack(
            children: [
              // ✅ Premium gradient background
              const Positioned.fill(child: _PremiumGradientBackground()),

              // ✅ Animated subtle sweep
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _pillCtrl,
                  builder: (_, __) {
                    final a = _pillCtrl.value * 2 * math.pi;
                    return CustomPaint(painter: _SoftSweepPainter(angle: a));
                  },
                ),
              ),

              // ✅ Floating blur blobs (stylish)
              Positioned(
                top: -80,
                left: -60,
                child: _BlurBlob(
                  color: Colors.white.withOpacity(.14),
                  size: 220,
                ),
              ),
              Positioned(
                bottom: -90,
                right: -70,
                child: _BlurBlob(
                  color: Colors.white.withOpacity(.10),
                  size: 260,
                ),
              ),

              SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ✅ Logo card (same asset, same logic)
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
                                    angle: -10 * math.pi / 180,
                                    child: Image.asset(
                                      'assets/taskoon_logo.png',
                                      height: 200,
                                      width: 200,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ✅ Brand text (new stylish)
                        FadeTransition(
                          opacity: _taglineOpacity,
                          child: SlideTransition(
                            position: _taglineOffset,
                            child: Column(
                              children: [
                                Text(
                                  "TASKOON",
                                  style: t.titleLarge?.copyWith(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 3,
                                    color: Colors.white.withOpacity(.95),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                               "Hire Smart. Work Smarter.", //  "Your services, your way.",
                                  style: t.bodyMedium?.copyWith(
                                    fontFamily: 'Poppins',
                                    color: Colors.white.withOpacity(.80),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // ✅ Loader pill (stylish)
                                _LoadingPill(
                                  text: "Making things ready, just for you…",
                                ),

                                const SizedBox(height: 14),

                                // ✅ tiny hint (optional, no logic)
                                Text(
                                  "Just a moment",
                                  style: t.bodySmall?.copyWith(
                                    fontFamily: 'Poppins',
                                    color: Colors.white.withOpacity(.70),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* --------------------- Stylish Background --------------------- */

class _PremiumGradientBackground extends StatelessWidget {
  const _PremiumGradientBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _primaryAlt,
            _primary,
            const Color(0xFF1B1B1F),
          ],
        ),
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
        borderRadius: BorderRadius.all(Radius.circular(22)),
      ),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.12),
              blurRadius: 26,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _LoadingPill extends StatelessWidget {
  const _LoadingPill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlurBlob extends StatelessWidget {
  const _BlurBlob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
    final radius = size.longestSide * .75;

    final sweep = Paint()
      ..shader = SweepGradient(
        startAngle: angle,
        endAngle: angle + math.pi * 2,
        colors: [
          Colors.white.withOpacity(.10),
          Colors.transparent,
          Colors.white.withOpacity(.06),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, sweep);

    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, Colors.black.withOpacity(.10)],
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
