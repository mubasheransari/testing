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
  final String id;
  FindingYourTaskerScreen({super.key, required this.bookingid,required this.id});

  static const Color bgPurple = Color(0xFF43106F);

  @override
  State<FindingYourTaskerScreen> createState() => _FindingYourTaskerScreenState();
}

class _FindingYourTaskerScreenState extends State<FindingYourTaskerScreen> {
  Timer? _timer;

  // ✅ SignalR
  DispatchHubService? _hub;

  // ✅ signalr latest
  dynamic _lastRawNotification;

  // ✅ popup guard
  bool _dialogOpen = false;
  String? _lastDialogKey;

  // ✅ prevent multiple navigations
  bool _navigated = false;

  static const Color kPrimary = Color(0xFF5C2E91);
  static const Color kTextDark = Color(0xFF1B1B1B);
  static const Color kMuted = Color(0xFF75748A);

  @override
  void initState() {
    super.initState();

    // your existing request
    _fireFindTasker();

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
          setState(() => _lastRawNotification = payload);

          // ✅ Start timer once only (poll check every 2 seconds)
          _timer ??= Timer.periodic(const Duration(seconds: 2), (t) {
            if (!mounted) {
              t.cancel();
              return;
            }

            final type = (_lastRawNotification?['type'] ?? '').toString();

            // ✅ 1) BookingAssigned → navigate once
            if (type == "BookingAssigned" && !_navigated) {
              _navigated = true;
              t.cancel();
              _timer = null;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TaskerConfirmationScreen(
                    name: (_lastRawNotification?['data']?['taskerName'] ?? '')
                        .toString(),
                    cost: (_lastRawNotification?['data']?['cost'] ?? 0).toString(),
                    rating: (_lastRawNotification?['data']?['taskerRating'] ?? 0)
                        .toString(),
                    distance:
                        (_lastRawNotification?['data']?['distanceInKM'] ?? 0)
                            .toString(),
                  ),
                ),
              );
              return;
            }

            // ✅ 2) OfferExpired → show popup (EVERY TIME it expires)
            if (type == "OfferExpired") {
              // ✅ make a UNIQUE key for each expire event
              final rawDate = (_lastRawNotification?['date'] ?? '').toString();
              final expireKey = rawDate.isNotEmpty
                  ? "expired:${widget.bookingid}:$rawDate"
                  : "expired:${widget.bookingid}:${DateTime.now().microsecondsSinceEpoch}";

              _showOfferExpiredPopup(expireKey);

              // stop timer (so it doesn't keep firing)
              t.cancel();
              _timer = null;
              return;
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

  void _fireFindTasker() {
    context.read<UserBookingBloc>().add(
          FindingTaskerRequested(bookingId: widget.bookingid),
        );
  }

  Future<void> _showOfferExpiredPopup(String dialogKey) async {
    if (!mounted) return;

    // ✅ if dialog already open, ignore
    if (_dialogOpen) return;

    // ✅ show dialog again if key is different (new expiry)
    if (_lastDialogKey == dialogKey) return;
    _lastDialogKey = dialogKey;

    _dialogOpen = true;

    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) {
        const kGold = Color(0xFFF4C847);

        Widget infoTile({
          required IconData icon,
          required String label,
          required String value,
        }) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kPrimary.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: kPrimary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11.5,
                          color: kMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13.5,
                          color: kTextDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        void closeDialog() {
              var userId = context.read<AuthenticationBloc>().state.userDetails?.userId.toString();
          context.read<UserBookingBloc>().add(CancelBooking(userId: userId.toString(), bookingDetailId: widget.id, reason: 'not want right now'));
          if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
        }

        void retry() {
          closeDialog();

          // ✅ reset state for retry
          setState(() {
            _lastRawNotification = null;
            _navigated = false;

            // ✅ IMPORTANT: allow next OfferExpired popup again
            // (because next expiry will have a different key anyway,
            // but clearing is safe + fixes edge cases)
            _lastDialogKey = null;
          });

          _timer?.cancel();
          _timer = null;

          _fireFindTasker();
        }

        return WillPopScope(
          onWillPop: () async => false,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(ctx).size.width * 0.88,
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: kGold.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.error_outline_rounded,
                            color: kPrimary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "Offer Expired",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              color: kTextDark,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Icon(Icons.close_rounded,
                            color: Colors.transparent),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kPrimary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kPrimary.withOpacity(0.12)),
                      ),
                      child: Text(
                        (_lastRawNotification?['message'] ??
                                "The booking offer expired. Please retry to find another tasker.")
                            .toString(),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: kTextDark,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Row(
                    //   children: [
                    //     Expanded(
                    //       child: infoTile(
                    //         icon: Icons.receipt_long_rounded,
                    //         label: "Booking Id",
                    //         value: widget.bookingid,
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    // const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: closeDialog,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kPrimary,
                              side:
                                  BorderSide(color: kPrimary.withOpacity(0.35)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              "Close",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: retry,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              "Retry",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    // ✅ always reset open flag
    _dialogOpen = false;
  }

  @override
  void dispose() {
    _timer?.cancel();
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

/// bottom organic shape (darker/layered)
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

/*
class FindingYourTaskerScreen extends StatefulWidget {
  final String bookingid;
  FindingYourTaskerScreen({super.key, required this.bookingid});

  static const Color bgPurple = Color(0xFF43106F);

  @override
  State<FindingYourTaskerScreen> createState() => _FindingYourTaskerScreenState();
}

class _FindingYourTaskerScreenState extends State<FindingYourTaskerScreen> {
  Timer? _timer;

  // ✅ SignalR
  DispatchHubService? _hub;

  // ✅ signalr latest
  dynamic _lastRawNotification;

  // ✅ popup guard
  bool _dialogOpen = false;
  String? _lastDialogKey;

  // ✅ prevent multiple navigations
  bool _navigated = false;

  static const Color kPrimary = Color(0xFF5C2E91);
  static const Color kTextDark = Color(0xFF1B1B1B);
  static const Color kMuted = Color(0xFF75748A);

  @override
  void initState() {
    super.initState();

    // your existing request
    _fireFindTasker();

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
          setState(() => _lastRawNotification = payload);

          // ✅ Start timer once only (poll check every 2 seconds)
          _timer ??= Timer.periodic(const Duration(seconds: 2), (t) {
            if (!mounted) {
              t.cancel();
              return;
            }

            final type = (_lastRawNotification?['type'] ?? '').toString();

            // ✅ 1) BookingAssigned → navigate once
            if (type == "BookingAssigned" && !_navigated) {
              _navigated = true;
              t.cancel();
              _timer = null;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TaskerConfirmationScreen(
                    name: (_lastRawNotification?['data']?['taskerName'] ?? '')
                        .toString(),
                    cost: (_lastRawNotification?['data']?['cost'] ?? 0).toString(),
                    rating: (_lastRawNotification?['data']?['taskerRating'] ?? 0)
                        .toString(),
                    distance:
                        (_lastRawNotification?['data']?['distanceInKM'] ?? 0)
                            .toString(),
                  ),
                ),
              );
              return;
            }

            // ✅ 2) OfferExpired → show popup (EVERY TIME it expires)
            if (type == "OfferExpired") {
              // ✅ make a UNIQUE key for each expire event
              final rawDate = (_lastRawNotification?['date'] ?? '').toString();
              final expireKey = rawDate.isNotEmpty
                  ? "expired:${widget.bookingid}:$rawDate"
                  : "expired:${widget.bookingid}:${DateTime.now().microsecondsSinceEpoch}";

              _showOfferExpiredPopup(expireKey);

              // stop timer (so it doesn't keep firing)
              t.cancel();
              _timer = null;
              return;
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

  void _fireFindTasker() {
    context.read<UserBookingBloc>().add(
          FindingTaskerRequested(bookingId: widget.bookingid),
        );
  }

  Future<void> _showOfferExpiredPopup(String dialogKey) async {
    if (!mounted) return;

    // ✅ if dialog already open, ignore
    if (_dialogOpen) return;

    // ✅ show dialog again if key is different (new expiry)
    if (_lastDialogKey == dialogKey) return;
    _lastDialogKey = dialogKey;

    _dialogOpen = true;

    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) {
        const kGold = Color(0xFFF4C847);

        Widget infoTile({
          required IconData icon,
          required String label,
          required String value,
        }) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kPrimary.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: kPrimary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11.5,
                          color: kMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13.5,
                          color: kTextDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        void closeDialog() {
          if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
        }

        void retry() {
          closeDialog();

          // ✅ reset state for retry
          setState(() {
            _lastRawNotification = null;
            _navigated = false;

            // ✅ IMPORTANT: allow next OfferExpired popup again
            // (because next expiry will have a different key anyway,
            // but clearing is safe + fixes edge cases)
            _lastDialogKey = null;
          });

          _timer?.cancel();
          _timer = null;

          _fireFindTasker();
        }

        return WillPopScope(
          onWillPop: () async => false,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(ctx).size.width * 0.88,
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: kGold.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.error_outline_rounded,
                            color: kPrimary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "Offer Expired",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              color: kTextDark,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Icon(Icons.close_rounded,
                            color: Colors.transparent),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kPrimary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kPrimary.withOpacity(0.12)),
                      ),
                      child: Text(
                        (_lastRawNotification?['message'] ??
                                "The booking offer expired. Please retry to find another tasker.")
                            .toString(),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: kTextDark,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: infoTile(
                            icon: Icons.receipt_long_rounded,
                            label: "Booking Id",
                            value: widget.bookingid,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: closeDialog,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kPrimary,
                              side:
                                  BorderSide(color: kPrimary.withOpacity(0.35)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              "Close",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: retry,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              "Retry",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    // ✅ always reset open flag
    _dialogOpen = false;
  }

  @override
  void dispose() {
    _timer?.cancel();
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

/// bottom organic shape (darker/layered)
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
}*/



// class FindingYourTaskerScreen extends StatefulWidget {
//   final String bookingid;
//   FindingYourTaskerScreen({super.key, required this.bookingid});

//   static const Color bgPurple = Color(0xFF43106F);

//   @override
//   State<FindingYourTaskerScreen> createState() => _FindingYourTaskerScreenState();
// }

// class _FindingYourTaskerScreenState extends State<FindingYourTaskerScreen> {
//   Timer? _timer;

//   // ✅ SignalR
//   DispatchHubService? _hub;

//   // ✅ signalr latest
//   dynamic _lastRawNotification;

//   // ✅ popup guard
//   bool _dialogOpen = false;
//   String? _lastDialogKey;

//   // ✅ prevent multiple navigations
//   bool _navigated = false;

//   static const Color kPrimary = Color(0xFF5C2E91);
//   static const Color kTextDark = Color(0xFF1B1B1B);
//   static const Color kMuted = Color(0xFF75748A);

//   @override
//   void initState() {
//     super.initState();

//     // your existing request
//     _fireFindTasker();

//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       if (!mounted) return;

//       final userDetails = context.read<AuthenticationBloc>().state.userDetails;
//       final userId = userDetails?.userId?.toString();

//       if (userId == null || userId.isEmpty) {
//         debugPrint("❌ FindingYourTaskerScreen: userId missing");
//         return;
//       }

//       _hub = DispatchHubService(
//         baseUrl: "http://192.3.3.187:85",
//         userId: userId,
//         onLog: (m) => debugPrint("FINDING HUB: $m"),
//         onNotification: (payload) {
//           if (!mounted) return;

//           debugPrint("📩 FINDING RAW NOTIFICATION => $payload");

//           setState(() => _lastRawNotification = payload);

//           // ✅ Start timer once only (poll check every 2 seconds)
//           _timer ??= Timer.periodic(const Duration(seconds: 2), (t) {
//             if (!mounted) {
//               t.cancel();
//               return;
//             }

//             final type = (_lastRawNotification?['type'] ?? '').toString();

//             // ✅ 1) BookingAssigned → navigate once
//             if (type == "BookingAssigned" && !_navigated) {
//               _navigated = true;
//               t.cancel();

//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => TaskerConfirmationScreen(
//                     name: (_lastRawNotification?['data']?['taskerName'] ?? '').toString(),
//                     cost: (_lastRawNotification?['data']?['cost'] ?? 0).toString(),
//                     rating: (_lastRawNotification?['data']?['taskerRating'] ?? 0).toString(),
//                     distance: (_lastRawNotification?['data']?['distanceInKM'] ?? 0).toString(),
//                   ),
//                 ),
//               );
//               return;
//             }

//             // ✅ 2) OfferExpired → show popup with Retry
//             if (type == "OfferExpired") {
//               // show only once per booking
//               _showOfferExpiredPopupOnce();
//               // stop timer if you want (optional). I keep it stopped to prevent spam.
//               t.cancel();
//               _timer = null;
//               return;
//             }
//           });
//         },
//       );

//       try {
//         await _hub!.start();
//         debugPrint("✅ HUB STARTED");
//       } catch (e) {
//         debugPrint("❌ HUB START FAILED: $e");
//       }
//     });
//   }

//   void _fireFindTasker() {
//     context.read<UserBookingBloc>().add(
//           FindingTaskerRequested(bookingId: widget.bookingid),
//         );
//   }

//   Future<void> _showOfferExpiredPopupOnce() async {
//     if (!mounted) return;
//     if (_dialogOpen) return;

//     final key = "expired:${widget.bookingid}";
//     if (_lastDialogKey == key) return;
//     _lastDialogKey = key;

//     _dialogOpen = true;

//     await showDialog(
//       context: context,
//       barrierDismissible: false,
//       barrierColor: Colors.black.withOpacity(0.55),
//       builder: (ctx) {
//         const kGold = Color(0xFFF4C847);

//         Widget infoTile({
//           required IconData icon,
//           required String label,
//           required String value,
//         }) {
//           return Container(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//             decoration: BoxDecoration(
//               color: kPrimary.withOpacity(0.06),
//               borderRadius: BorderRadius.circular(14),
//               border: Border.all(color: kPrimary.withOpacity(0.15)),
//             ),
//             child: Row(
//               children: [
//                 Container(
//                   width: 34,
//                   height: 34,
//                   decoration: BoxDecoration(
//                     color: kPrimary.withOpacity(0.12),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Icon(icon, color: kPrimary, size: 18),
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         label,
//                         style: const TextStyle(
//                           fontFamily: 'Poppins',
//                           fontSize: 11.5,
//                           color: kMuted,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       const SizedBox(height: 2),
//                       Text(
//                         value,
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                         style: const TextStyle(
//                           fontFamily: 'Poppins',
//                           fontSize: 13.5,
//                           color: kTextDark,
//                           fontWeight: FontWeight.w700,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }

//         void closeDialog() {
//           if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
//         }

//         void retry() {
//           closeDialog();

//           // ✅ reset state
//           setState(() {
//             _lastRawNotification = null;
//             _navigated = false;
//           });

//           // ✅ restart polling timer (2 sec)
//           _timer?.cancel();
//           _timer = null;

//           // ✅ fire request again
//           _fireFindTasker();
//         }

//         return WillPopScope(
//           onWillPop: () async => false,
//           child: Center(
//             child: Material(
//               color: Colors.transparent,
//               child: Container(
//                 width: MediaQuery.of(ctx).size.width * 0.88,
//                 constraints: const BoxConstraints(maxWidth: 420),
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(22),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.12),
//                       blurRadius: 24,
//                       offset: const Offset(0, 14),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Row(
//                       children: [
//                         Container(
//                           width: 42,
//                           height: 42,
//                           decoration: BoxDecoration(
//                             color: kGold.withOpacity(0.25),
//                             borderRadius: BorderRadius.circular(14),
//                           ),
//                           child: const Icon(
//                             Icons.error_outline_rounded,
//                             color: kPrimary,
//                             size: 24,
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         const Expanded(
//                           child: Text(
//                             "Offer Expired",
//                             style: TextStyle(
//                               fontFamily: 'Poppins',
//                               fontSize: 16,
//                               color: kTextDark,
//                               fontWeight: FontWeight.w800,
//                             ),
//                           ),
//                         ),
//                         const Icon(Icons.close_rounded, color: Colors.transparent),
//                       ],
//                     ),
//                     const SizedBox(height: 12),

//                     Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: kPrimary.withOpacity(0.06),
//                         borderRadius: BorderRadius.circular(16),
//                         border: Border.all(color: kPrimary.withOpacity(0.12)),
//                       ),
//                       child: Text(
//                         (_lastRawNotification?['message'] ??
//                                 "The booking offer expired. Please retry to find another tasker.")
//                             .toString(),
//                         style: const TextStyle(
//                           fontFamily: 'Poppins',
//                           fontSize: 13,
//                           color: kTextDark,
//                           fontWeight: FontWeight.w600,
//                           height: 1.35,
//                         ),
//                       ),
//                     ),

//                     const SizedBox(height: 12),

//                     // optional info tiles
//                     Row(
//                       children: [
//                         Expanded(
//                           child: infoTile(
//                             icon: Icons.receipt_long_rounded,
//                             label: "Booking Id",
//                             value: widget.bookingid,
//                           ),
//                         ),
//                       ],
//                     ),

//                     const SizedBox(height: 14),

//                     Row(
//                       children: [
//                         Expanded(
//                           child: OutlinedButton(
//                             onPressed: closeDialog,
//                             style: OutlinedButton.styleFrom(
//                               foregroundColor: kPrimary,
//                               side: BorderSide(color: kPrimary.withOpacity(0.35)),
//                               padding: const EdgeInsets.symmetric(vertical: 12),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(14),
//                               ),
//                             ),
//                             child: const Text(
//                               "Close",
//                               style: TextStyle(
//                                 fontFamily: 'Poppins',
//                                 fontWeight: FontWeight.w700,
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: ElevatedButton(
//                             onPressed: retry,
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: kPrimary,
//                               foregroundColor: Colors.white,
//                               padding: const EdgeInsets.symmetric(vertical: 12),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(14),
//                               ),
//                               elevation: 0,
//                             ),
//                             child: const Text(
//                               "Retry",
//                               style: TextStyle(
//                                 fontFamily: 'Poppins',
//                                 fontWeight: FontWeight.w800,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );

//     _dialogOpen = false;
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     _hub?.stop();
//     _hub?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;

//     return Scaffold(
//       backgroundColor: FindingYourTaskerScreen.bgPurple,
//       body: Stack(
//         children: [
//           Positioned(
//             top: 0,
//             left: 0,
//             right: 0,
//             height: size.height * 0.32,
//             child: CustomPaint(painter: _TopWavePainter()),
//           ),
//           Positioned(
//             bottom: 0,
//             left: 0,
//             right: 0,
//             height: size.height * 0.30,
//             child: CustomPaint(painter: _BottomWavePainter()),
//           ),
//           Center(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 SizedBox(
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

// /// top organic shape (light-purple overlay)
// class _TopWavePainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = const Color(0xFF542383).withOpacity(0.55)
//       ..style = PaintingStyle.fill;

//     final path = Path()
//       ..moveTo(0, size.height * 0.55)
//       ..quadraticBezierTo(
//         size.width * 0.25,
//         size.height * 0.20,
//         size.width * 0.55,
//         size.height * 0.35,
//       )
//       ..quadraticBezierTo(
//         size.width * 0.78,
//         size.height * 0.48,
//         size.width,
//         size.height * 0.28,
//       )
//       ..lineTo(size.width, 0)
//       ..lineTo(0, 0)
//       ..close();

//     canvas.drawPath(path, paint);
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }

// /// bottom organic shape (darker/layered)
// class _BottomWavePainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint1 = Paint()
//       ..color = const Color(0xFF341157).withOpacity(0.65)
//       ..style = PaintingStyle.fill;

//     final path1 = Path()
//       ..moveTo(0, size.height * 0.35)
//       ..quadraticBezierTo(
//         size.width * 0.25,
//         size.height * 0.15,
//         size.width * 0.45,
//         size.height * 0.35,
//       )
//       ..quadraticBezierTo(
//         size.width * 0.72,
//         size.height * 0.68,
//         size.width,
//         size.height * 0.40,
//       )
//       ..lineTo(size.width, size.height)
//       ..lineTo(0, size.height)
//       ..close();

//     canvas.drawPath(path1, paint1);

//     final paint2 = Paint()
//       ..color = const Color(0xFF4B1475).withOpacity(0.5)
//       ..style = PaintingStyle.fill;

//     final path2 = Path()
//       ..moveTo(size.width * 0.35, size.height * 0.50)
//       ..quadraticBezierTo(
//         size.width * 0.65,
//         size.height * 0.15,
//         size.width,
//         size.height * 0.35,
//       )
//       ..lineTo(size.width, size.height)
//       ..lineTo(size.width * 0.35, size.height)
//       ..close();

//     canvas.drawPath(path2, paint2);
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }























/*

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
  MaterialPageRoute(
    builder: (_) => TaskerConfirmationScreen(
      name: (_lastRawNotification?['data']?['taskerName'] ?? '').toString(),
      cost: (_lastRawNotification?['data']?['cost'] ?? 0).toString(),
      rating: (_lastRawNotification?['data']?['taskerRating'] ?? 0).toString(),
      distance: (_lastRawNotification?['data']?['distanceInKM'] ?? 0).toString(),
    ),
  ),
);


            // Navigator.push(
            //   context,
            //   MaterialPageRoute(builder: (_) => TaskerConfirmationScreen(
            //     name:_lastRawNotification['data']['taskerName'] ,
            //       cost:_lastRawNotification['data']['cost'] ,
            //         rating:_lastRawNotification['data']['taskerRating'] ,
            //           distance:_lastRawNotification['data']['distanceInKM'] ,
            //   )),
            // );
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
*/


// class _TopWavePainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = const Color(0xFF542383).withOpacity(0.55)
//       ..style = PaintingStyle.fill;

//     final path = Path()
//       ..moveTo(0, size.height * 0.55)
//       ..quadraticBezierTo(
//         size.width * 0.25,
//         size.height * 0.20,
//         size.width * 0.55,
//         size.height * 0.35,
//       )
//       ..quadraticBezierTo(
//         size.width * 0.78,
//         size.height * 0.48,
//         size.width,
//         size.height * 0.28,
//       )
//       ..lineTo(size.width, 0)
//       ..lineTo(0, 0)
//       ..close();

//     canvas.drawPath(path, paint);
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }

// /// bottom organic shape (darker/layered like screenshot)
// class _BottomWavePainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint1 = Paint()
//       ..color = const Color(0xFF341157).withOpacity(0.65)
//       ..style = PaintingStyle.fill;

//     final path1 = Path()
//       ..moveTo(0, size.height * 0.35)
//       ..quadraticBezierTo(
//         size.width * 0.25,
//         size.height * 0.15,
//         size.width * 0.45,
//         size.height * 0.35,
//       )
//       ..quadraticBezierTo(
//         size.width * 0.72,
//         size.height * 0.68,
//         size.width,
//         size.height * 0.40,
//       )
//       ..lineTo(size.width, size.height)
//       ..lineTo(0, size.height)
//       ..close();

//     canvas.drawPath(path1, paint1);

//     // a second subtle blob on the right
//     final paint2 = Paint()
//       ..color = const Color(0xFF4B1475).withOpacity(0.5)
//       ..style = PaintingStyle.fill;

//     final path2 = Path()
//       ..moveTo(size.width * 0.35, size.height * 0.50)
//       ..quadraticBezierTo(
//         size.width * 0.65,
//         size.height * 0.15,
//         size.width,
//         size.height * 0.35,
//       )
//       ..lineTo(size.width, size.height)
//       ..lineTo(size.width * 0.35, size.height)
//       ..close();

//     canvas.drawPath(path2, paint2);
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }
