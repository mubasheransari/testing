import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taskoon/Constants/constants.dart';

// task_alert_glass_map.dart
import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taskoon/widgets/booking_accept_dialog.dart';
import 'package:taskoon/widgets/booking_wait_longer_dialog.dart';

/// New Task Alert — Glassmorphism + Google Maps (AU)
/// - Real Google Map as background
/// - Initial camera & job marker in Australia (default: Sydney)
/// - Extra random markers scattered across Australia
/// - Fully interactive map (pan/zoom/tilt/rotate)
/// - Glass top bar, details panel, bottom bar

class TaskAlertGlassScreen extends StatefulWidget {
  const TaskAlertGlassScreen({
    super.key,
    this.onAccept,
    this.job = const LatLng(-33.8688, 151.2093), // Sydney
    this.randomMarkersCount = 18,
  });

  /// Task/job location (Australia)
  final LatLng job;

  /// Number of extra random markers placed across Australia
  final int randomMarkersCount;

  final VoidCallback? onAccept;

  @override
  State<TaskAlertGlassScreen> createState() => _TaskAlertGlassScreenState();
}

class _TaskAlertGlassScreenState extends State<TaskAlertGlassScreen> {
  final Set<Marker> _markers = <Marker>{};
  GoogleMapController? _controller;

  // Australia bounds (rough)
  static const double _minLat = -43.6;
  static const double _maxLat = -10.7;
  static const double _minLng = 113.3;
  static const double _maxLng = 153.6;

  static const Color _purple = Color(0xFF5C2E91);

  // Greyscale map style similar to your mock
  static const String _greyMapStyle = '''
  [
    {"elementType":"geometry","stylers":[{"color":"#ebe3cd"}]},
    {"elementType":"labels.text.fill","stylers":[{"color":"#523735"}]},
    {"elementType":"labels.text.stroke","stylers":[{"color":"#f5f1e6"}]},
    {"featureType":"administrative.land_parcel","stylers":[{"visibility":"off"}]},
    {"featureType":"poi","stylers":[{"visibility":"off"}]},
    {"featureType":"road","elementType":"geometry","stylers":[{"color":"#f5f1e6"}]},
    {"featureType":"road.local","stylers":[{"visibility":"simplified"}]},
    {"featureType":"transit","stylers":[{"visibility":"off"}]},
    {"featureType":"water","elementType":"geometry.fill","stylers":[{"color":"#b9d3c2"}]}
  ]
  ''';

  @override
  void initState() {
    super.initState();
    _seedMarkers();
  }

  void _seedMarkers() {
    final rnd = Random();

    // Primary job marker
    _markers.add(
      Marker(
        markerId: const MarkerId('job'),
        position: widget.job,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      ),
    );

    // Random markers across Australia
    for (int i = 0; i < widget.randomMarkersCount; i++) {
      final lat = _minLat + rnd.nextDouble() * (_maxLat - _minLat);
      final lng = _minLng + rnd.nextDouble() * (_maxLng - _minLng);
      _markers.add(
        Marker(
          markerId: MarkerId('rnd_$i'),
          position: LatLng(lat, lng),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F12) : const Color(0xFFF7F7FA),
      body: Stack(
        children: [
          // --- GOOGLE MAP (fully interactive) ---
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: widget.job, zoom: 11.8),
              markers: _markers,
              // Explicit gesture enables
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              rotateGesturesEnabled: true,
              tiltGesturesEnabled: true,
              zoomControlsEnabled: true, // + / - buttons on Android
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              buildingsEnabled: true,
              // Claim gestures even if under translucent layers/scrollables
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer()),
              },
              onMapCreated: (c) async {
                _controller = c;
                await c.setMapStyle(_greyMapStyle);
              },
            ),
          ),

          // Contrast overlay that DOES NOT block touches
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.10),
                      Colors.transparent,
                      Colors.black.withOpacity(0.18),
                    ],
                    stops: const [0, .5, 1],
                  ),
                ),
              ),
            ),
          ),

          // --- FOREGROUND UI ---
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _GlassBar(
                    child: Row(
                      children: [
                        _IconButtonGlass(
                          icon: Icons.arrow_back_rounded,
                          onTap: () => Navigator.maybePop(context),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'New task alert',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.10),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: Colors.white.withOpacity(.22)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.notifications_active_rounded,
                                  size: 16, color: Colors.white),
                              SizedBox(width: 6),
                              Text('Live',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _GlassPanel(
                    child: const _TaskDetails(),
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

/* ---------------------------- Glass Widgets --------------------------- */

class _GlassBar extends StatelessWidget {
  const _GlassBar({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.22),
                Colors.white.withOpacity(0.10),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final radius = w >= 640 ? 28.0 : 22.0;
        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: w >= 400 ? 18 : 14, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.22),
                    Colors.white.withOpacity(0.10),
                  ],
                ),
                border: Border.all(color: Colors.white.withOpacity(0.28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.18),
                    blurRadius: 26,
                    offset: const Offset(0, 14),
                  )
                ],
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _IconButtonGlass extends StatelessWidget {
  const _IconButtonGlass({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              border: Border.all(color: Colors.white.withOpacity(.24)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

/* ------------------------------ Details UI ---------------------------- */

class _TaskDetails extends StatelessWidget {
  const _TaskDetails();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = Colors.grey.shade700;

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final isNarrow = w < 360;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New orders',
              style: text.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF4C2A86),
                fontSize: isNarrow ? 18 : 20,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text('Earnings',
                    style: text.bodyMedium
                        ?.copyWith(color: muted, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Text('\$12.00',
                    style: text.titleLarge?.copyWith(
                        color: const Color(0xFF12B76A),
                        fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 12),
            const _InfoRow(icon: Icons.person_rounded, label: 'Susan P'),
            const SizedBox(height: 8),
            const _InfoRow(icon: Icons.qr_code_rounded, label: 'Moving help'),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _InfoIcon(icon: Icons.access_time_rounded),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Today, 2:00',
                      style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w600)),
                ),
                SizedBox(width: 8),
                _RightStat(value: '2 hours'),
                SizedBox(width: 16),
                _RightStat(value: '0.5 km'),
              ],
            ),
            const SizedBox(height: 8),
            const _InfoRow(
                icon: Icons.location_on_rounded, label: 'Resto Padang Gahar'),
            Padding(
              padding: const EdgeInsets.only(left: 28, top: 2),
              child: Text(
                'JJ central road across No 20padgol village',
                style: text.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  showBookingAcceptDialog(
                    context,
                    topBadgeAsset: 'assets/accept_icon.png',
                    watermarkAsset: 'assets/taskoon_logo.png',
                    downloadIconAsset: 'assets/taskoon_logo.png',
                    shareIconAsset: 'assets/taskoon_logo.png',
                    accept: () {
                       print("click");
//  showDialogBookingWaitLonger(
//                     context,
//                     topBadgeAsset: 'assets/accept_icon.png',
//                     watermarkAsset: 'assets/taskoon_logo.png',
//                     downloadIconAsset: 'assets/taskoon_logo.png',
//                     shareIconAsset: 'assets/taskoon_logo.png',
//                     accept: () {

                      
//                     },
//                     cancel: () {/* share file */},
//                   );

                    },
                    cancel: () {/* share file */},
                  );
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: Constants.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('ACCEPT BOOKING',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, letterSpacing: .4)),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    final muted = Colors.grey.shade700;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoIcon(icon: icon),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: muted, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _InfoIcon extends StatelessWidget {
  const _InfoIcon({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFEEE8F5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 14, color: const Color(0xFF4C2A86)),
    );
  }
}

class _RightStat extends StatelessWidget {
  const _RightStat({required this.value});
  final String value;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.18),
        border: Border.all(color: Colors.white.withOpacity(.28)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        value,
        style: const TextStyle(
            fontWeight: FontWeight.w800, color: Color(0xFF383B45)),
      ),
    );
  }
}
