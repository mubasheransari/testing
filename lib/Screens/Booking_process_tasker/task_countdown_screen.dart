import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class TaskCountdownScreen extends StatefulWidget {
  const TaskCountdownScreen({
    super.key,
    this.total = const Duration(minutes: 10),          // total timer length
    this.extraButtonAfter = const Duration(minutes: 1) // show "Ask for extra time" after 1 min
  });

  final Duration total;
  final Duration extraButtonAfter;

  @override
  State<TaskCountdownScreen> createState() => _TaskCountdownScreenState();
}

class _TaskCountdownScreenState extends State<TaskCountdownScreen> {
  static const Color kPrimary = Color(0xFF4A287C);
  static const Color kPrimaryDark = Color(0xFF351D60);
  static const Color kAccentGold = Color(0xFFF4C847);

  late Duration _total;      // mutable total (can extend)
  late Duration _remaining;  // remaining time
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _total = widget.total;
    _remaining = _total;
    _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_remaining > Duration.zero) {
          _remaining -= const Duration(seconds: 1);
        } else {
          t.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Duration get _elapsed => _total - _remaining;

  bool get _showExtraButton =>
      _remaining > Duration.zero && _elapsed >= widget.extraButtonAfter;

  double get _progress {
    if (_total.inMilliseconds == 0) return 1;
    final p = 1 - (_remaining.inMilliseconds / _total.inMilliseconds);
    return p.clamp(0.0, 1.0);
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _onAskExtraTime() async {
    final added = await showModalBottomSheet<Duration?>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        Widget option(String label, Duration dur) => ListTile(
              title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              trailing: const Icon(Icons.add),
              onTap: () => Navigator.pop(ctx, dur),
            );
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),
              const Text('Add extra time',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              option('+ 5 minutes', const Duration(minutes: 5)),
              option('+ 10 minutes', const Duration(minutes: 10)),
              option('+ 15 minutes', const Duration(minutes: 15)),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );

    if (added != null && mounted) {
      setState(() {
        _total += added;
        _remaining += added;
      });
    }
  }

  void _onComplete() {
    _ticker?.cancel();
    // TODO: trigger your completion flow here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task marked complete')),
    );
  }

  void _onCancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel task?'),
        content: const Text(
            'Cancelling will void payment and may affect future bookings.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes, cancel')),
        ],
      ),
    );
    if (ok == true && mounted) {
      _ticker?.cancel();
      Navigator.maybePop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFFF7F5FB);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kPrimary),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      bottomNavigationBar: _BottomBar(primary: kPrimary, dark: kPrimaryDark),
      body: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final dialSize = w * 0.7; // responsive
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              children: [
                // Clock + progress ring
                Center(
                  child: SizedBox(
                    width: dialSize,
                    height: dialSize,
                    child: CustomPaint(
                      painter: _ClockRingPainter(
                        progress: _progress,
                        ringColor: kPrimary,
                        progressColor: kAccentGold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _format(_remaining),
                  style: const TextStyle(
                    color: kPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 54,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _remaining == Duration.zero ? null : _onComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'COMPLETE TASK',
                      style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: .4),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                if (_showExtraButton) ...[
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _onAskExtraTime,
                      icon: const Icon(Icons.more_time),
                      label: const Text(
                        'ASK FOR EXTRA TIME',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kPrimary,
                        side: const BorderSide(color: kPrimary, width: 1.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: const BorderSide(color: Color(0xFFCBC6D7)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'CANCEL TASK',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Cancelling will void payment and may affect future booking',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/* ----------------------------- Painters & UI ----------------------------- */

class _ClockRingPainter extends CustomPainter {
  _ClockRingPainter({
    required this.progress,
    required this.ringColor,
    required this.progressColor,
  });

  final double progress; // 0..1
  final Color ringColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 6;

    final ring = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.18
      ..strokeCap = StrokeCap.round;

    final arc = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.18
      ..strokeCap = StrokeCap.round;

    // Base ring
    canvas.drawCircle(center, radius, ring);

    // Progress arc (elapsed)
    final rect = Rect.fromCircle(center: center, radius: radius);
    final start = -math.pi / 2; // 12 o'clock
    final sweep = 2 * math.pi * progress;
    canvas.drawArc(rect, start, sweep, false, arc);

    // Minimal analog hands just for the look
    final dialStroke = (radius * 0.065).clamp(3.0, 8.0);
    final hand = Paint()
      ..color = ringColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = dialStroke;

    // Hour hand (fixed ~5 o'clock like your mock)
    final hLen = radius * 0.55;
    final hAngle = start + 2.6; // radians
    final hEnd = Offset(center.dx + hLen * math.cos(hAngle), center.dy + hLen * math.sin(hAngle));
    canvas.drawLine(center, hEnd, hand);

    // Minute hand (fixed)
    final mLen = radius * 0.78;
    final mAngle = start + 3.6;
    final mEnd = Offset(center.dx + mLen * math.cos(mAngle), center.dy + mLen * math.sin(mAngle));
    canvas.drawLine(center, mEnd, hand);

    // Center dot
    canvas.drawCircle(center, dialStroke * 0.9, hand);
  }

  @override
  bool shouldRepaint(covariant _ClockRingPainter old) =>
      old.progress != progress || old.ringColor != ringColor || old.progressColor != progressColor;
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.primary, required this.dark});
  final Color primary;
  final Color dark;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Container(
        color: primary,
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            _NavItem(icon: Icons.home_rounded, label: 'Home'),
            _NavItem(icon: Icons.attach_money_rounded, label: 'Earning'),
            _NavItem(icon: Icons.receipt_long_rounded, label: 'Tasks'),
            _NavItem(icon: Icons.menu_rounded, label: 'More'),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}



// class TaskCountdownScreen extends StatefulWidget {
//   const TaskCountdownScreen({
//     super.key,
//     this.total = const Duration(minutes: 1),
//   });

//   /// Total time for the tasker to arrive/complete.
//   final Duration total;

//   @override
//   State<TaskCountdownScreen> createState() => _TaskCountdownScreenState();
// }

// class _TaskCountdownScreenState extends State<TaskCountdownScreen> {
//   // Brand palette
//   static const kPrimary = Color(0xFF5C2E91);
//   static const kPrimaryDark = Color(0xFF411C6E);
//   static const kAccentGold = Color(0xFFF4C847);

//   late Duration _remaining;
//   Timer? _timer;
//   bool _extendedOnce = false;

//   int get _totalSeconds => widget.total.inSeconds;
//   int get _remainingSeconds => _remaining.inSeconds;
//   double get _progress => _remainingSeconds.clamp(0, _totalSeconds) / _totalSeconds;

//   @override
//   void initState() {
//     super.initState();
//     _remaining = widget.total;
//     _startTimer();
//   }

//   void _startTimer() {
//     _timer?.cancel();
//     _timer = Timer.periodic(const Duration(seconds: 1), (_) {
//       if (!mounted) return;
//       if (_remaining > Duration.zero) {
//         setState(() => _remaining -= const Duration(seconds: 1));
//       } else {
//         _timer?.cancel();
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }

//   String _fmt(Duration d) {
//     final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
//     final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
//     return '$m:$s';
//   }

//   bool get _shouldShowExtraButton =>
//       !_extendedOnce && _remaining <= const Duration(minutes: 2) && _remaining > Duration.zero;

//   Future<void> _askExtraTime() async {
//     final added = await showModalBottomSheet<Duration>(
//       context: context,
//       backgroundColor: Colors.white,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (ctx) {
//         Widget tile(String label, Duration value) => ListTile(
//               title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
//               onTap: () => Navigator.pop(ctx, value),
//             );
//         return SafeArea(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const SizedBox(height: 10),
//               Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(4))),
//               const SizedBox(height: 14),
//               const Text('Ask for extra time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
//               const SizedBox(height: 6),
//               const Text('Choose an extension (one time only)', style: TextStyle(color: Colors.black54)),
//               const SizedBox(height: 10),
//               tile('+ 5 minutes', const Duration(minutes: 5)),
//               tile('+ 10 minutes', const Duration(minutes: 10)),
//               const SizedBox(height: 6),
//             ],
//           ),
//         );
//       },
//     );

//     if (added != null && mounted) {
//       setState(() {
//         _remaining += added;
//         _extendedOnce = true;
//       });
//       _startTimer();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Added ${added.inMinutes} minutes')),
//       );
//     }
//   }

//   void _onComplete() {
//     _timer?.cancel();
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Task completed ✅')),
//     );
//     // TODO: navigate or submit completion
//   }

//   void _onCancel() async {
//     final ok = await showDialog<bool>(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text('Cancel task?'),
//         content: const Text('Cancelling will void payment and may affect future booking.'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
//           TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, cancel')),
//         ],
//       ),
//     );
//     if (ok == true && mounted) {
//       _timer?.cancel();
//       Navigator.maybePop(context);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDone = _remaining <= Duration.zero;

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Top bar
//             Padding(
//               padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
//               child: Row(
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.arrow_back, color: kPrimary),
//                     onPressed: () => Navigator.maybePop(context),
//                   ),
//                 ],
//               ),
//             ),

//             // Clock + time
//             const SizedBox(height: 12),
//             Expanded(
//               child: Center(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     _ClockRing(
//                       size: 260,
//                       trackColor: kPrimary,
//                       progressColor: kAccentGold,
//                       fraction: _progress,
//                     ),
//                     const SizedBox(height: 24),
//                     Text(
//                       _fmt(_remaining.isNegative ? Duration.zero : _remaining),
//                       style: const TextStyle(
//                         fontSize: 54,
//                         color: kPrimary,
//                         fontWeight: FontWeight.w700,
//                         letterSpacing: 1,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             // Buttons
//             Padding(
//               padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
//               child: Column(
//                 children: [
//                   // Complete Task (primary)
//                   SizedBox(
//                     height: 52,
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: _onComplete,
//                       style: ElevatedButton.styleFrom(
//                         elevation: 0,
//                         backgroundColor: kPrimary,
//                         foregroundColor: Colors.white,
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                       ),
//                       child: const Text('COMPLETE TASK', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: .4)),
//                     ),
//                   ),
//                   const SizedBox(height: 12),

//                   // Ask for extra time (appears near end, once)
//                   if (_shouldShowExtraButton) ...[
//                     SizedBox(
//                       height: 48,
//                       width: double.infinity,
//                       child: OutlinedButton(
//                         onPressed: _askExtraTime,
//                         style: OutlinedButton.styleFrom(
//                           foregroundColor: kPrimaryDark,
//                           side: const BorderSide(color: Color(0xFFCBC6D7)),
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                         ),
//                         child: const Text("ASK FOR EXTRA TIME", style: TextStyle(fontWeight: FontWeight.w800)),
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                   ],

//                   // Cancel Task (outlined)
//                   SizedBox(
//                     height: 52,
//                     width: double.infinity,
//                     child: OutlinedButton(
//                       onPressed: _onCancel,
//                       style: OutlinedButton.styleFrom(
//                         foregroundColor: Colors.black87,
//                         side: const BorderSide(color: Color(0xFFCBC6D7)),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                       ),
//                       child: const Text('CANCEL TASK',
//                           style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black87)),
//                     ),
//                   ),

//                   const SizedBox(height: 10),
//                   const Text(
//                     'Cancelling will void payment and may affect future booking',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(color: Colors.red, fontSize: 12.5),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// /// Big ring with progress arc (purple track + gold progress), plus simple clock hands.
// class _ClockRing extends StatelessWidget {
//   const _ClockRing({
//     required this.size,
//     required this.trackColor,
//     required this.progressColor,
//     required this.fraction, // 0..1 (remaining / total)
//   });

//   final double size;
//   final Color trackColor;
//   final Color progressColor;
//   final double fraction;

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: size,
//       height: size,
//       child: CustomPaint(
//         painter: _ClockPainter(
//           trackColor: trackColor,
//           progressColor: progressColor,
//           fraction: fraction.clamp(0, 1),
//         ),
//       ),
//     );
//   }
// }

// class _ClockPainter extends CustomPainter {
//   _ClockPainter({
//     required this.trackColor,
//     required this.progressColor,
//     required this.fraction,
//   });

//   final Color trackColor;
//   final Color progressColor;
//   final double fraction;

//   @override
//   void paint(Canvas canvas, Size size) {
//     final center = size.center(Offset.zero);
//     final radius = size.width / 2 - 8;
//     const stroke = 18.0;

//     // Outer purple ring (track)
//     final track = Paint()
//       ..color = trackColor
//       ..style = PaintingStyle.stroke
//       ..strokeCap = StrokeCap.round
//       ..strokeWidth = stroke;
//     canvas.drawCircle(center, radius, track);

//     // Progress arc (remaining)
//     final progress = Paint()
//       ..color = progressColor
//       ..style = PaintingStyle.stroke
//       ..strokeCap = StrokeCap.round
//       ..strokeWidth = stroke * .85;

//     final start = -math.pi / 2; // top
//     final sweep = 2 * math.pi * fraction;
//     if (sweep > 0) {
//       canvas.drawArc(
//         Rect.fromCircle(center: center, radius: radius),
//         start,
//         sweep,
//         false,
//         progress,
//       );
//     }

//     // Simple hands (purely decorative)
//     final inner = Paint()
//       ..color = trackColor.withOpacity(.12)
//       ..style = PaintingStyle.fill;
//     canvas.drawCircle(center, radius - 30, inner);

//     final hand = Paint()
//       ..color = trackColor
//       ..strokeWidth = 8
//       ..strokeCap = StrokeCap.round;

//     // Hour hand (~ at 2)
//     final hLen = radius * .45;
//     final hAngle = -math.pi / 3; // ~2 o'clock
//     canvas.drawLine(
//       center,
//       center + Offset(hLen * math.cos(hAngle), hLen * math.sin(hAngle)),
//       hand,
//     );

//     // Minute hand (~ at 5)
//     final mLen = radius * .70;
//     final mAngle = math.pi / 6; // ~5 o'clock
//     canvas.drawLine(
//       center,
//       center + Offset(mLen * math.cos(mAngle), mLen * math.sin(mAngle)),
//       hand..strokeWidth = 10,
//     );

//     // Center dot
//     final dot = Paint()..color = trackColor;
//     canvas.drawCircle(center, 10, dot);
//   }

//   @override
//   bool shouldRepaint(covariant _ClockPainter old) =>
//       old.fraction != fraction ||
//       old.trackColor != trackColor ||
//       old.progressColor != progressColor;
// }
