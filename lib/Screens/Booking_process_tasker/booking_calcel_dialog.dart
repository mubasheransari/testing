import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:taskoon/Screens/Booking_process_tasker/bottom_nav_root_screen.dart';
import 'package:taskoon/Screens/Booking_process_tasker/tasker_home_screen.dart';

enum TaskerCancelledAction { findAnother, cancelTask, viewRefund, closed }

/// Shows the "Tasker cancelled" dialog and returns the user action.
Future<TaskerCancelledAction?> showTaskerCancelledDialog(
  BuildContext context, {
  String title = 'Tasker cancelled',
  String message =
      "We're sorry your tasker had to cancel, but don't worry you can "
          "find another or reschedule.",
  String primaryLabel = 'FIND ANOTHER TASKER',
  String secondaryLabel = 'CANCEL TASK',
  Color brand = const Color(0xFF5C2E91),
}) {
  return showGeneralDialog<TaskerCancelledAction>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withOpacity(.20),
    transitionDuration: const Duration(milliseconds: 230),
    pageBuilder: (rootCtx, __, ___) {
      final width = MediaQuery.of(rootCtx).size.width * 0.86;
      return Stack(
        fit: StackFit.expand,
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: const SizedBox.expand(),
          ),
          Center(
            child: _TaskerCancelledDialogCard(
              width: width,
              title: title,
              message: message,
              brand: brand,
              onPrimary: () {
                Navigator.of(rootCtx, rootNavigator: true)
                    .pop(TaskerCancelledAction.closed);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const TaskoonApp()),
                  (route) => false,
                );
              },
              onSecondary: () {
                Navigator.of(rootCtx, rootNavigator: true)
                    .pop(TaskerCancelledAction.closed);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const TaskoonApp()),
                  (route) => false,
                );
              },
              onRefund: () => Navigator.of(rootCtx, rootNavigator: true)
                  .pop(TaskerCancelledAction.viewRefund),
              onClose: () => Navigator.of(rootCtx, rootNavigator: true)
                  .pop(TaskerCancelledAction.closed),
              primaryLabel: primaryLabel,
              secondaryLabel: secondaryLabel,
            ),
          ),
        ],
      );
    },
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, .06), end: Offset.zero)
              .animate(curved),
          child: child,
        ),
      );
    },
  );
}

/* ============================ INTERNAL WIDGET ============================ */

class _TaskerCancelledDialogCard extends StatelessWidget {
  const _TaskerCancelledDialogCard({
    required this.width,
    required this.title,
    required this.message,
    required this.brand,
    required this.onPrimary,
    required this.onSecondary,
    required this.onRefund,
    required this.onClose,
    required this.primaryLabel,
    required this.secondaryLabel,
  });

  final double width;
  final String title;
  final String message;
  final Color brand;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;
  final VoidCallback onRefund;
  final VoidCallback onClose;
  final String primaryLabel;
  final String secondaryLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final w = width.clamp(300.0, 420.0) as double;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.18),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(isDark ? 0.10 : 0.90),
                    Colors.white.withOpacity(isDark ? 0.08 : 0.82),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(isDark ? 0.25 : 0.30),
                ),
              ),
              child: Stack(
                children: [
                  // Close button
                  Positioned(
                    top: 4,
                    right: 4,
                    child: InkWell(
                      onTap: onClose,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFB8C3CC)),
                        ),
                        child: const Icon(Icons.close, size: 16),
                      ),
                    ),
                  ),
                  // Content
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: brand,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: brand.withOpacity(.10),
                          shape: BoxShape.circle,
                        ),
                        child:
                            Icon(Icons.shield_outlined, color: brand, size: 36),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black.withOpacity(.75),
                          height: 1.35,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 48,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onPrimary,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brand,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            primaryLabel,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 48,
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: onSecondary,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            side: BorderSide(
                                color: Colors.black.withOpacity(.25)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            secondaryLabel,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: onRefund,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF405364),
                        ),
                        child: const Text(
                          'View refund details',
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w700,
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
      ),
    );
  }
}
