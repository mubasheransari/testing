import 'dart:ui';
import 'package:flutter/material.dart';

Future<void> showReportDownloadDialog(
  BuildContext context, {
  // Assets
  required String topBadgeAsset, // e.g. 'assets/dialog/badge_doc.png'
  required String watermarkAsset, // e.g. 'assets/dialog/watermark_wheel.png'
  String? downloadIconAsset, // e.g. 'assets/dialog/ic_download.png'
  String? shareIconAsset, // e.g. 'assets/dialog/ic_share.png'

  // Text
  String title = 'Accept Booking',
  String subtitle = 'Do you want to accept the booking?',

  // Actions
  VoidCallback? onDownload,
  VoidCallback? onShare,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withOpacity(.15),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) {
      final width = MediaQuery.of(context).size.width * 0.80; // responsive
      return Stack(
        fit: StackFit.expand,
        children: [
          // Frosted scrim
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: const SizedBox.expand(),
          ),
          // Dialog card
          Center(
            child: _DownloadDialogCard(
              width: width,
              title: title,
              subtitle: subtitle,
              topBadgeAsset: topBadgeAsset,
              watermarkAsset: watermarkAsset,
              downloadIconAsset: downloadIconAsset,
              shareIconAsset: shareIconAsset,
              onDownload: () {
                onDownload?.call();
                Navigator.of(context).maybePop(); // close after download
              },
              onShare: onShare, // keep open; caller can close if desired
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

/* -------------------------------------------------------------------------- */
/*                         PRIVATE WIDGETS (same file)                         */
/* -------------------------------------------------------------------------- */

// Glassmorphic dialog card used by showReportDownloadDialog()
class _DownloadDialogCard extends StatelessWidget {
  const _DownloadDialogCard({
    required this.width,
    required this.title,
    required this.subtitle,
    required this.topBadgeAsset,
    required this.watermarkAsset,
    this.downloadIconAsset,
    this.shareIconAsset,
    this.onDownload,
    this.onShare,
  });

  final double width;
  final String title;
  final String subtitle;

  // Assets
  final String topBadgeAsset;
  final String watermarkAsset;
  final String? downloadIconAsset;
  final String? shareIconAsset;

  // Actions
  final VoidCallback? onDownload;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clampedW = width.clamp(300.0, 420.0);

    return Material(
      color: Colors.white.withOpacity(0.10),
      child: Container(
        width: clampedW,
        constraints: const BoxConstraints(minWidth: 300, maxWidth: 420),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Glass card
            ClipRRect(
              // borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                    // border: Border.all(
                    //   color: Colors.white.withOpacity(isDark ? 0.20 : 0.30),
                    // ),
                    // boxShadow: [
                    //   BoxShadow(
                    //     color: Colors.black.withOpacity(0.20),
                    //     blurRadius: 28,
                    //     offset: const Offset(0, 16),
                    //   ),
                    // ],
                    // borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      // Watermark (bottom-right, non-interactive)
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
                            const SizedBox(
                                height: 26), // space for the top badge overlap
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
                            const SizedBox(height: 8),
                            Text(
                              'Cancellations may effect your future bookings',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 14.5,
                                  height: 1.35,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                // Expanded(
                                //   child: _ActionButton(
                                //     label: 'Download PDF',
                                //     iconAsset: downloadIconAsset,
                                //     fallbackIcon: Icons.download_rounded,
                                //     onPressed: onDownload,
                                //   ),
                                // ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _ActionButton(
                                    label: 'Cancel',
                                    iconAsset: null,
                                    fallbackIcon: Icons.cancel,
                                    outlined: true,
                                    onPressed: onShare,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _ActionButton(
                                    label: 'Accept',
                                    iconAsset: null,
                                    fallbackIcon: Icons.task_alt,
                                    onPressed: onDownload,
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

            // Top circular badge that overlaps the card
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
    this.iconAsset,
    this.onPressed,
    this.outlined = false,
  });

  final String label;
  final String? iconAsset;
  final IconData fallbackIcon;
  final VoidCallback? onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = outlined
        ? Colors.white.withOpacity(isDark ? 0.02 : 0.06)
        : const Color(0xFF5C2E91);
    final fg =
        outlined ? (isDark ? Colors.white : Colors.black87) : Colors.white;
    final borderColor = outlined
        ? Colors.white.withOpacity(isDark ? 0.25 : 0.28)
        : Colors.transparent;

    return SizedBox(
      height: 48,
      child: TextButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: MaterialStatePropertyAll<Color>(bg),
          foregroundColor: MaterialStatePropertyAll<Color>(fg),
          overlayColor: MaterialStatePropertyAll<Color>(
            Colors.white.withOpacity(0.08),
          ),
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
            if (iconAsset != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Image.asset(
                  iconAsset!,
                  width: 18,
                  height: 18,
                  fit: BoxFit.contain,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(fallbackIcon, size: 20),
              ),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
