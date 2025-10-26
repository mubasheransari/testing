

import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';




class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({
    super.key,
    this.emergencyNumber = '000', // change to 911/112 depending on region
    this.supportLabel = 'Notify Taskoon Support',
    this.supportSubtitle = 'Tap to alert us – we will step in quickly!',
    this.onSupportTap, // override to open your in-app support if desired
  });

  final String emergencyNumber;
  final String supportLabel;
  final String supportSubtitle;
  final VoidCallback? onSupportTap;

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen>
    with SingleTickerProviderStateMixin {

  final Completer<GoogleMapController> _mapCtl = Completer();
  GoogleMapController? _gmaps;

  LatLng _center = const LatLng(-33.8688, 151.2093); // fallback (Sydney)
  Marker? _meMarker;

  bool _loadingLocation = true;
  String _locationLabel = 'Locating…';

  // SOS pulse
  late final AnimationController _pulseCtl =
      AnimationController(vsync: this, duration: const Duration(seconds: 1))
        ..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _gmaps?.dispose();
    _pulseCtl.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      final canUse = await _ensurePermission();
      if (!canUse) {
        setState(() {
          _loadingLocation = false;
          _locationLabel = 'Location permission denied';
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final here = LatLng(pos.latitude, pos.longitude);

      setState(() {
        _center = here;
        _meMarker = Marker(
          markerId: const MarkerId('me'),
          position: here,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        );
        _loadingLocation = false;
        _locationLabel =
            'Lat ${here.latitude.toStringAsFixed(5)}, Lng ${here.longitude.toStringAsFixed(5)}';
      });

      _animateTo(here);
    } catch (e) {
      setState(() {
        _loadingLocation = false;
        _locationLabel = 'Location unavailable';
      });
    }
  }

  Future<bool> _ensurePermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return false;

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  Future<void> _animateTo(LatLng target) async {
    final c = _gmaps ?? await _mapCtl.future;
    c.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: target, zoom: 14.5),
    ));
  }

  Future<void> _onMapCreated(GoogleMapController c) async {
    _gmaps = c;
    if (!_mapCtl.isCompleted) _mapCtl.complete(c);
    await c.setMapStyle(_greyMapStyle);
  }

  /* --------------------------------- ACTIONS -------------------------------- */

  Future<void> _call(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _shareLocation() async {
    final link =
        'https://www.google.com/maps/search/?api=1&query=${_center.latitude},${_center.longitude}';
    await Share.share('My current location:\n$link');
  }

  void _onSupport() {
    if (widget.onSupportTap != null) {
      widget.onSupportTap!();
    } else {
      _shareLocation(); // default: share location to support
    }
  }

  void _onSOS() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _ConfirmSOSDialog(
        onConfirm: () => _call(widget.emergencyNumber),
      ),
    );
  }

  /* ----------------------------------- UI ----------------------------------- */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FB),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.06),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // IconButton(
                    //   icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    //       color: Color(0xFF5C2E91)),
                    //   onPressed: () => Navigator.of(context).maybePop(),
                    // ),
                    const SizedBox(width: 6),
                    const Text(
                      'Emergency',
                      style: TextStyle(
                        color: Color(0xFF5C2E91),
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // SOS pulse button
                    _SosButton(onTap: _onSOS, controller: _pulseCtl),
                    const SizedBox(height: 12),
                    const Text(
                      'Press the SOS button to activate\nemergency services',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF5C2E91),
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        height: 1.25,
                      ),
                    ),

                    const SizedBox(height: 26),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Quick Actions',
                        style: TextStyle(
                          color: Color(0xFF5C2E91),
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _GlassTile(
                      leadingBg: Color(0xFF5C2E91),
                      leadingIcon: Icons.light_mode_rounded,
                      title: 'Emergency services',
                      subtitle: widget.emergencyNumber,
                      trailingIcon: Icons.call_rounded,
                      onTap: () => _call(widget.emergencyNumber),
                    ),
                    const SizedBox(height: 12),
                    _GlassTile(
                      leadingBg: Color(0xFF5C2E91),
                      leadingIcon: Icons.notifications_active_rounded,
                      title: widget.supportLabel,
                      subtitle: widget.supportSubtitle,
                      trailingIcon: Icons.send_rounded,
                      onTap: _onSupport,
                    ),

                    const SizedBox(height: 18),

                    // Map card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        children: [
                          SizedBox(
                            height: 200,
                            width: double.infinity,
                            child: GoogleMap(
                              onMapCreated: _onMapCreated,
                              initialCameraPosition: CameraPosition(
                                target: _center,
                                zoom: 12.5,
                              ),
                              markers: {
                                if (_meMarker != null) _meMarker!,
                              },
                              myLocationEnabled: true,
                              myLocationButtonEnabled: false,
                              zoomControlsEnabled: false,
                              zoomGesturesEnabled: true,
                              scrollGesturesEnabled: true,
                              rotateGesturesEnabled: true,
                              tiltGesturesEnabled: true,
                              // Make gestures work inside scroll views:
                              gestureRecognizers: {
                                Factory<OneSequenceGestureRecognizer>(
                                    () => EagerGestureRecognizer()),
                              },
                            ),
                          ),
                          // recenter button
                          Positioned(
                            right: 10,
                            bottom: 10,
                            child: _CircleIconButton(
                              icon: Icons.my_location_rounded,
                              onTap: () => _animateTo(_center),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),
                    // Location text + copy
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _locationLabel,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.black.withOpacity(.70),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Copy',
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: _locationLabel));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Location copied')),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded,
                                color: Color(0xFF5C2E91), size: 20),
                          )
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),
                    SizedBox(
                      height: 54,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _shareLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF5C2E91),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'SHARE LOCATION',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, letterSpacing: .4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------- WIDGETS -------------------------------- */

class _SosButton extends StatelessWidget {
  const _SosButton({required this.onTap, required this.controller});

  final VoidCallback onTap;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final scale = 1 + (controller.value * 0.05);
          final shadow = (controller.value * 14) + 10;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 148,
              height: 148,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF3B30), Color(0xFFE53935)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF3B30).withOpacity(.35),
                    blurRadius: shadow,
                    spreadRadius: 6,
                  ),
                ],
                border: Border.all(color: Colors.white.withOpacity(.90), width: 6),
              ),
              alignment: Alignment.center,
              child: const Text(
                'SOS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 34,
                  letterSpacing: 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GlassTile extends StatelessWidget {
  const _GlassTile({
    required this.leadingBg,
    required this.leadingIcon,
    required this.title,
    required this.subtitle,
    required this.trailingIcon,
    this.onTap,
  });

  final Color leadingBg;
  final IconData leadingIcon;
  final String title;
  final String subtitle;
  final IconData trailingIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFE9E5F2)),
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: leadingBg,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: leadingBg.withOpacity(.28),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(leadingIcon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:  TextStyle(
                                color: Color(0xFF5C2E91),
                                fontWeight: FontWeight.w800,
                                fontSize: 18)),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.black.withOpacity(.62),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE9E5F2)),
                    ),
                    child: Icon(trailingIcon, color: Color(0xFF5C2E91), size: 20),
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

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: Color(0xFF5C2E91), size: 20),
        ),
      ),
    );
  }
}

class _ConfirmSOSDialog extends StatelessWidget {
  const _ConfirmSOSDialog({required this.onConfirm});
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm SOS'),
      content: const Text('This will call emergency services. Proceed?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF5C2E91)),
          child: const Text('Call now'),
        ),
      ],
    );
  }
}

/* ------------------------------- MAP STYLE ------------------------------ */

const String _greyMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#ebe3cd"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#523735"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#f5f1e6"}]},
  {"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#c9b2a6"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#dfd2ae"}]},
  {"featureType":"poi.park","elementType":"geometry.fill","stylers":[{"color":"#e6e6e6"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#f5f1e6"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#fdfcf8"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#f8c967"}]},
  {"featureType":"road.highway.controlled_access","elementType":"geometry","stylers":[{"color":"#e98d58"}]},
  {"featureType":"transit.line","elementType":"geometry","stylers":[{"color":"#dfd2ae"}]},
  {"featureType":"water","elementType":"geometry.fill","stylers":[{"color":"#c9c9c9"}]}
]
''';
