import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:taskoon/Constants/constants.dart';

Future<void> showDialogBookingWaitLonger(
  BuildContext context, {
  // Assets
  required String topBadgeAsset,
  required String watermarkAsset,
  String? downloadIconAsset,
  String? shareIconAsset,

  // Text
  String title = 'Service Extension Request',
  String subtitle = 'The user needs you a bit longer, are you up for it?',

  // Actions
  VoidCallback? onAccept,
  VoidCallback? onCancel,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withOpacity(.15),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) {
      final width = MediaQuery.of(context).size.width * 0.80;
      return Stack(
        fit: StackFit.expand,
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: const SizedBox.expand(),
          ),
          Center(
            child: _DecisionDialogCard(
              width: width,
              title: title,
              subtitle: subtitle,
              topBadgeAsset: topBadgeAsset,
              watermarkAsset: watermarkAsset,
              primaryLabel: "Yes, I'm Up!",
              primaryIcon: Icons.task_alt,
              onPrimary: () {
                Navigator.of(context).pop();
                onAccept?.call();
              },
              secondaryLabel: 'No',
              secondaryIcon: Icons.cancel,
              onSecondary: () {
                Navigator.of(context).pop();
                onCancel?.call();
              },
              secondaryOutlined: true,
              highlightText: 'Earn an extra \$12.50',
              highlightColor: Colors.green,
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

class _DecisionDialogCard extends StatelessWidget {
  const _DecisionDialogCard({
    required this.width,
    required this.title,
    required this.subtitle,
    required this.topBadgeAsset,
    required this.watermarkAsset,
    // Primary (right) action
    required this.primaryLabel,
    required this.primaryIcon,
    required this.onPrimary,
    // Secondary (left) action
    required this.secondaryLabel,
    required this.secondaryIcon,
    required this.onSecondary,
    this.secondaryOutlined = false,
    // Optional extra texts
    this.warningText,
    this.highlightText,
    this.highlightColor,
  });

  final double width;
  final String title;
  final String subtitle;

  final String topBadgeAsset;
  final String watermarkAsset;

  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback onPrimary;

  final String secondaryLabel;
  final IconData secondaryIcon;
  final VoidCallback onSecondary;
  final bool secondaryOutlined;

  final String? warningText;   // red line (optional)
  final String? highlightText; // green line (optional)
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double clampedW = width.clamp(300.0, 420.0) as double;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: clampedW,
        constraints: const BoxConstraints(minWidth: 300, maxWidth: 420),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Glass card
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(isDark ? 0.10 : 0.30),
                        Colors.white.withOpacity(isDark ? 0.06 : 0.18),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(isDark ? 0.20 : 0.30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.20),
                        blurRadius: 28,
                        offset: const Offset(0, 16),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      // Watermark
                      Positioned(
                        right: -8,
                        bottom: -8,
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: isDark ? 0.12 : 0.10,
                            child: Image.asset(
                              watermarkAsset,
                              width: 140,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 26, 18, 18),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 26), // space for top badge
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              subtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1.35,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            if (warningText != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                warningText!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  height: 1.35,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            if (highlightText != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                highlightText!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  height: 1.35,
                                  color: highlightColor ?? Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: _ActionButton(
                                    label: secondaryLabel,
                                    fallbackIcon: secondaryIcon,
                                    outlined: secondaryOutlined,
                                    onPressed: onSecondary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _ActionButton(
                                    label: primaryLabel,
                                    fallbackIcon: primaryIcon,
                                    onPressed: onPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Top circular badge
            Positioned(
              top: -28,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(isDark ? 0.18 : 0.32),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Image.asset(
                            topBadgeAsset,
                            fit: BoxFit.contain,
                            color: Constants.primaryDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.fallbackIcon,
    this.onPressed,
    this.outlined = false,
  });

  final String label;
  final IconData fallbackIcon;
  final VoidCallback? onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bg = outlined
        ? Colors.white.withOpacity(isDark ? 0.02 : 0.06)
        : Constants.primaryDark;
    final Color fg =
        outlined ? (isDark ? Colors.white : Colors.black87) : Colors.white;
    final Color borderColor = outlined
        ? Colors.white.withOpacity(isDark ? 0.25 : 0.28)
        : Colors.transparent;

    return SizedBox(
      height: 48,
      child: TextButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: MaterialStatePropertyAll<Color>(bg),
          foregroundColor: MaterialStatePropertyAll<Color>(fg),
          overlayColor:
              MaterialStatePropertyAll<Color>(Colors.white.withOpacity(0.08)),
          shape: MaterialStatePropertyAll<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: borderColor, width: outlined ? 1 : 0),
            ),
          ),
          padding: const MaterialStatePropertyAll<EdgeInsets>(
            EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(fallbackIcon, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600,fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

