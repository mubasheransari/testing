import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_bloc.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_bloc.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_event.dart';
import 'package:taskoon/Screens/User_booking/tasker_confirmation_screen.dart';
import 'package:taskoon/Screens/User_booking/user_booking_home.dart';



class FindingYourTaskerScreen extends StatefulWidget {
  final String bookingid;
  FindingYourTaskerScreen({super.key, required this.bookingid});

  static const Color bgPurple = Color(0xFF43106F);
  static const Color ringGold1 = Color(0xFFF9DB75);
  static const Color ringGold2 = Color(0xFFD7A939);

  @override
  State<FindingYourTaskerScreen> createState() => _FindingYourTaskerScreenState();
}

class _FindingYourTaskerScreenState extends State<FindingYourTaskerScreen> {
  Timer? _timer;

  // ✅ SignalR
  DispatchHubService? _hub;
  bool _hubStarted = false;

  // ✅ to "get data" in this screen
  dynamic _lastRawNotification;        // raw payload
  TaskerBookingOffer? _lastOffer;      // parsed offer

  // ✅ optional popup guards
  bool _dialogOpen = false;
  String? _lastDialogKey;

@override
void initState() {
  super.initState();

  context.read<UserBookingBloc>().add(
    FindingTaskerRequested(bookingId: widget.bookingid),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (!mounted) return;

    final userDetails = context.read<AuthenticationBloc>().state.userDetails;
    final userId = userDetails?.userId?.toString();

    if (userId == null || userId.isEmpty) {
      debugPrint("❌ FindingYourTaskerScreen: userId missing");
      return;
    }

    _hub = DispatchHubService(
      baseUrl: "http://192.3.3.187:85",
      userId: userId,
      onLog: (m) => debugPrint("FINDING HUB: $m"),
      onNotification: (payload) {
        if (!mounted) return;

        debugPrint("📩 FINDING RAW NOTIFICATION => $payload");

        setState(() {
          _lastRawNotification = payload;
        });

        // ✅ Start timer once only
        _timer ??= Timer.periodic(const Duration(seconds: 2), (t) {
          if (!mounted) {
            t.cancel();
            return;
          }

          if (_lastRawNotification != null && _lastRawNotification['type'] == "BookingAssigned") {
      
            t.cancel();

            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TaskerConfirmationScreen()),
            );
          }
        });
      },
    );
    try {
      await _hub!.start();
      debugPrint("✅ HUB STARTED");
    } catch (e) {
      debugPrint("❌ HUB START FAILED: $e");
    }
  });
}


  // Future<void> _startHubOnce() async {
  //   if (_hubStarted) return;
  //   _hubStarted = true;

  //   try {
  //     await _hub?.start();
  //   } catch (e) {
  //     debugPrint("🔥 FindingYourTaskerScreen: hub start failed: $e");
  //     _hubStarted = false;
  //   }
  // }

  void _showPopup(String text, {String? key}) {
    if (!mounted) return;
    if (_dialogOpen) return;

    if (key != null && _lastDialogKey == key) return;
    if (key != null) _lastDialogKey = key;

    _dialogOpen = true;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        title: const Text("SignalR Notification"),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    ).then((_) {
      _dialogOpen = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();

    // ✅ stop hub
    _hub?.stop();
    _hub?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: FindingYourTaskerScreen.bgPurple,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.32,
            child: CustomPaint(painter: _TopWavePainter()),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: size.height * 0.30,
            child: CustomPaint(painter: _BottomWavePainter()),
          ),

          // ✅ UI SAME (no changes)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 190,
                  height: 190,
                  child: Center(
                    child: Image.asset('assets/user_finding_tasker.png'),
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

                // ✅ OPTIONAL: show some live SignalR data (remove if you don't want UI change)
                if (_lastOffer != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    "Offer: \$${_lastOffer!.estimatedCost.toStringAsFixed(0)}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// class FindingYourTaskerScreen extends StatefulWidget {
//   String bookingid;
//   FindingYourTaskerScreen({super.key, required this.bookingid});

//   // colors picked from screenshot
//   static const Color bgPurple = Color(0xFF43106F);
//   static const Color ringGold1 = Color(0xFFF9DB75);
//   static const Color ringGold2 = Color(0xFFD7A939);

//   @override
//   State<FindingYourTaskerScreen> createState() =>
//       _FindingYourTaskerScreenState();
// }

// class _FindingYourTaskerScreenState extends State<FindingYourTaskerScreen> {
//   Timer? _timer;

//   @override
//   void initState() {
//     super.initState();
//     context.read<UserBookingBloc>().add(
//       FindingTaskerRequested(bookingId: widget.bookingid),

//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;

//     return Scaffold(
//       backgroundColor: FindingYourTaskerScreen.bgPurple,
//       body: Stack(
//         children: [
//           // top wave
//           Positioned(
//             top: 0,
//             left: 0,
//             right: 0,
//             height: size.height * 0.32,
//             child: CustomPaint(painter: _TopWavePainter()),
//           ),
//           // bottom wave
//           Positioned(
//             bottom: 0,
//             left: 0,
//             right: 0,
//             height: size.height * 0.30,
//             child: CustomPaint(painter: _BottomWavePainter()),
//           ),

//           // center logo + text
//           Center(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // double golden ring with purple inside
//                 Container(
//                   width: 190,
//                   height: 190,

//                   child: Center(
//                     child: Image.asset('assets/user_finding_tasker.png'),
//                   ),
//                 ),
//                 const SizedBox(height: 28),
//                 const Text(
//                   'Finding your tasker',
//                   style: TextStyle(
//                     fontFamily: 'Poppins',
//                     fontSize: 23,
//                     color: Colors.white,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

/// top organic shape (light-purple overlay)
class _TopWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF542383).withOpacity(0.55)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.20,
        size.width * 0.55,
        size.height * 0.35,
      )
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.48,
        size.width,
        size.height * 0.28,
      )
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
        size.width * 0.25,
        size.height * 0.15,
        size.width * 0.45,
        size.height * 0.35,
      )
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.68,
        size.width,
        size.height * 0.40,
      )
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
        size.width * 0.65,
        size.height * 0.15,
        size.width,
        size.height * 0.35,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * 0.35, size.height)
      ..close();

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
