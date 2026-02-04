// ✅ Animated "Sharing Location" dialog (theme-matching)
// - Creative pulse + wave rings + subtle gradient
// - Buttons: Call emergency number, Stop sharing
// - Optional: shows coords + address label
//
// Usage:
// showSharingLocationDialog(
//   context,
//   emergencyNumber: '000',
//   locationText: _locationLabel, // e.g. "Lat -33..., Lng 151..."
//   onCall: () => _call(widget.emergencyNumber),
//   onStopSharing: () { /* stop your stream/timer */ },
// );

import 'dart:math' as math;
import 'package:flutter/material.dart';

const Color kPrimary = Color(0xFF5C2E91);
const Color kTextDark = Color(0xFF3E1E69);
const Color kMuted = Color(0xFF75748A);

Future<Future<Object?>> showSharingLocationDialog(
  BuildContext context, {
  required String emergencyNumber,
  required String locationText,
  String title = "Sharing your location",
  String subtitle = "Taskoon Support can see your live location.\nStay calm — help is on the way.",
  VoidCallback? onCall,
  VoidCallback? onStopSharing,
  bool barrierDismissible = false,
}) async {
  return showGeneralDialog(
    context: context,
    barrierLabel: "sharing_location",
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black.withOpacity(.55),
    transitionDuration: const Duration(milliseconds: 340),
    pageBuilder: (_, __, ___) {
      return Center(
        child: _SharingLocationDialogBody(
          emergencyNumber: emergencyNumber,
          title: title,
          subtitle: subtitle,
          locationText: locationText,
          onCall: onCall,
          onStopSharing: onStopSharing,
        ),
      );
    },
    transitionBuilder: (_, anim, __, child) {
      // Smooth scale + fade + slight slide
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(curved),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}

class _SharingLocationDialogBody extends StatefulWidget {
  const _SharingLocationDialogBody({
    required this.emergencyNumber,
    required this.title,
    required this.subtitle,
    required this.locationText,
    this.onCall,
    this.onStopSharing,
  });

  final String emergencyNumber;
  final String title;
  final String subtitle;
  final String locationText;
  final VoidCallback? onCall;
  final VoidCallback? onStopSharing;

  @override
  State<_SharingLocationDialogBody> createState() => _SharingLocationDialogBodyState();
}

class _SharingLocationDialogBodyState extends State<_SharingLocationDialogBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
        ..repeat();

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _close() {
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: w * 0.88,
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kPrimary.withOpacity(.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.14),
              blurRadius: 26,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top row (badge + close)
            Row(
              children: [
                _PillBadge(
                  icon: Icons.location_on_rounded,
                  label: "Live",
                  bg: kPrimary.withOpacity(.10),
                  fg: kPrimary,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Close',
                  onPressed: _close,
                  icon: Icon(Icons.close_rounded, color: kMuted.withOpacity(.85)),
                ),
              ],
            ),

            const SizedBox(height: 2),

            // Animated center orb (creative)
            SizedBox(
              height: 140,
              child: AnimatedBuilder(
                animation: _ctl,
                builder: (context, _) {
                  final t = _ctl.value; // 0..1
                  return CustomPaint(
                    painter: _PulsePainter(progress: t),
                    child: Center(
                      child: Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              kPrimary,
                              kPrimary.withOpacity(.75),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: kPrimary.withOpacity(.28),
                              blurRadius: 18,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 30),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 4),

            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16.5,
                fontWeight: FontWeight.w900,
                color: kTextDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: kMuted,
                height: 1.25,
              ),
            ),

            const SizedBox(height: 12),

            // Location card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: kPrimary.withOpacity(.12)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.place_rounded, color: kPrimary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Current location",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: kMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.locationText,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: kTextDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Call emergency
                      widget.onCall?.call();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE53935),
                      side: BorderSide(color: const Color(0xFFE53935).withOpacity(.55)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.call_rounded, size: 18),
                    label: Text(
                      "Call ${widget.emergencyNumber}",
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w900,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Stop sharing + close
                      widget.onStopSharing?.call();
                      _close();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.stop_circle_outlined, size: 18),
                    label: const Text(
                      "Stop sharing",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w900,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Small hint row (optional)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kPrimary.withOpacity(.10)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline_rounded, size: 18, color: kPrimary.withOpacity(.8)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Only Taskoon Support can view your shared location.",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11.8,
                        fontWeight: FontWeight.w700,
                        color: kMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ===================== Small UI Helpers ===================== */

class _PillBadge extends StatelessWidget {
  const _PillBadge({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
  });

  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/* ===================== Animated Painter (pulse rings) ===================== */

class _PulsePainter extends CustomPainter {
  _PulsePainter({required this.progress});
  final double progress; // 0..1

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Ring counts and sizes
    final rings = 3;
    final baseRadius = 40.0;

    for (int i = 0; i < rings; i++) {
      final phase = (progress + (i * 0.22)) % 1.0;
      final radius = baseRadius + (phase * 38.0);
      final opacity = (1.0 - phase).clamp(0.0, 1.0);

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = kPrimary.withOpacity(0.22 * opacity);

      canvas.drawCircle(center, radius, paint);
    }

    // subtle rotating dots around (creative)
    final dotCount = 10;
    final dotRadius = 2.2;
    final orbit = 62.0;
    for (int i = 0; i < dotCount; i++) {
      final angle = ((i / dotCount) * math.pi * 2) + (progress * math.pi * 2);
      final p = Offset(center.dx + orbit * math.cos(angle), center.dy + orbit * math.sin(angle));
      final paint = Paint()..color = kPrimary.withOpacity(0.14);
      canvas.drawCircle(p, dotRadius, paint);
    }

    // soft glow behind center
    final glowPaint = Paint()
      ..color = kPrimary.withOpacity(.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(center, 46, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _PulsePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
