

import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:taskoon/Screens/Booking_process_tasker/emergency_form_tabs.dart';
import 'package:taskoon/widgets/share_location_dialog.dart';
import 'package:url_launcher/url_launcher.dart';



const Color kPrimary = Color(0xFF5C2E91);
const Color kTextDark = Color(0xFF3E1E69);
const Color kMuted = Color(0xFF75748A);
const Color kBg = Color(0xFFF8F7FB);

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

class _EmergencyScreenState extends State<EmergencyScreen> with SingleTickerProviderStateMixin {
  final Completer<GoogleMapController> _mapCtl = Completer();
  GoogleMapController? _gmaps;

  LatLng _center = const LatLng(-33.8688, 151.2093); // fallback (Sydney)
  Marker? _meMarker;

  bool _loadingLocation = true;
  String _locationLabel = 'Locating…';

  // SOS pulse
  late final AnimationController _pulseCtl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 950))
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

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final here = LatLng(pos.latitude, pos.longitude);

      setState(() {
        _center = here;
        _meMarker = Marker(
          markerId: const MarkerId('me'),
          position: here,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        );
        _loadingLocation = false;
        _locationLabel =
            'Lat ${here.latitude.toStringAsFixed(5)}, Lng ${here.longitude.toStringAsFixed(5)}';
      });

      _animateTo(here);
    } catch (_) {
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
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();

    return perm == LocationPermission.always || perm == LocationPermission.whileInUse;
  }

  Future<void> _animateTo(LatLng target) async {
    final c = _gmaps ?? await _mapCtl.future;
    c.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: target, zoom: 14.5)),
    );
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
    // keep your existing nav
    Navigator.push(context, MaterialPageRoute(builder: (_) => EmergencyFormTabsScreen()));
  }

  void _onSupport() {
    if (widget.onSupportTap != null) {
      widget.onSupportTap!();
    } else {
      _shareLocation();
    }
  }

  void _onSOS() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _ConfirmSOSDialog(
        number: widget.emergencyNumber,
        onConfirm: () => _call(widget.emergencyNumber),
      ),
    );
  }

  /* ----------------------------------- UI ----------------------------------- */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 10,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Emergency',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: kTextDark,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top hero
              _HeroCard(
                loading: _loadingLocation,
                locationLabel: _locationLabel,
                onCopy: () {
                  Clipboard.setData(ClipboardData(text: _locationLabel));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Location copied')),
                  );
                },
              ),

              const SizedBox(height: 14),

              // SOS center
              Center(
                child: _SosButton(
                  onTap: ()async{
                    await showSharingLocationDialog(
  context,
  emergencyNumber: widget.emergencyNumber,
  locationText: _locationLabel, // or "Lat..., Lng..." or resolved address
  onCall: () => _call(widget.emergencyNumber),
  onStopSharing: () {
    // ✅ stop your sharing logic here (timer/stream/etc.)
    // e.g. _sharingTimer?.cancel(); setState(() => _isSharing = false);
  },
);

                  },
                  controller: _pulseCtl,
                ),
              ),
              const SizedBox(height: 18),
              // Center(
              //   child: const Text(
              //           'Press the SOS button to activate\nemergency services',
              //           textAlign: TextAlign.center,
              //           style: TextStyle(
              //             color: Color(0xFF5C2E91),
              //             fontWeight: FontWeight.w800,
              //             fontSize: 16,
              //             height: 1.25,
              //           ),
              //         ),
              // ),
              const Center(
                child: Text(
                  'Press the SOS button to activate\nemergency services',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: kMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    height: 1.25,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'Quick actions',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: kTextDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),

              _ActionTile(
                icon: Icons.local_police_rounded,
                title: 'Emergency services',
                subtitle: widget.emergencyNumber,
                badge: 'Call',
                badgeBg: const Color(0xFFFFF0F0),
                badgeFg: const Color(0xFFE53935),
                onTap: () => _call(widget.emergencyNumber),
              ),
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.support_agent_rounded,
                title: widget.supportLabel,
                subtitle: widget.supportSubtitle,
                badge: 'Notify',
                badgeBg: kPrimary.withOpacity(.08),
                badgeFg: kPrimary,
                onTap: _onSupport,
              ),

              const SizedBox(height: 14),

              // Map card
              _WhiteCard(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.map_rounded, color: kPrimary, size: 18),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Your live location',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: kTextDark,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        _SmallPill(
                          label: _loadingLocation ? 'Locating' : 'Ready',
                          fg: _loadingLocation ? const Color(0xFFEE8A41) : const Color(0xFF1E8E66),
                          bg: _loadingLocation ? const Color(0xFFFFF4E8) : const Color(0xFFEFF8F4),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        children: [
                          SizedBox(
                            height: 210,
                            width: double.infinity,
                            child: GoogleMap(
                              onMapCreated: _onMapCreated,
                              initialCameraPosition: CameraPosition(target: _center, zoom: 12.5),
                              markers: {if (_meMarker != null) _meMarker!},
                              myLocationEnabled: true,
                              myLocationButtonEnabled: false,
                              zoomControlsEnabled: false,
                              zoomGesturesEnabled: true,
                              scrollGesturesEnabled: true,
                              rotateGesturesEnabled: true,
                              tiltGesturesEnabled: true,
                              gestureRecognizers: {
                                Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                              },
                            ),
                          ),
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
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _locationLabel,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12.5,
                              height: 1.25,
                              color: kMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Copy',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _locationLabel));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Location copied')),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, color: kPrimary, size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                height: 54,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _shareLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.share_location_rounded),
                  label: const Text(
                    'SHARE LOCATION',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w900,
                      letterSpacing: .3,
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

/* ============================== UI PARTS ============================== */

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.loading,
    required this.locationLabel,
    required this.onCopy,
  });

  final bool loading;
  final String locationLabel;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kPrimary.withOpacity(.16),
            kPrimary.withOpacity(.08),
            Colors.white,
          ],
        ),
        border: Border.all(color: kPrimary.withOpacity(.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: kPrimary.withOpacity(.14)),
            ),
            child: Icon(
              loading ? Icons.location_searching_rounded : Icons.location_on_rounded,
              color: kPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stay safe',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    color: kTextDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loading ? 'Fetching your current location…' : 'Your location is ready to share.',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12.5,
                    color: kMuted,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
           /*    const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        locationLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: kMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: onCopy,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(.08),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: kPrimary.withOpacity(.16)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.copy_rounded, size: 16, color: kPrimary),
                            SizedBox(width: 6),
                            Text(
                              'Copy',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: kPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),*/
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
          final t = controller.value;
          final scale = 1 + (t * 0.055);
          final glow = (t * 16) + 10;

          return Transform.scale(
            scale: scale,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFF5A52), Color(0xFFE53935)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF3B30).withOpacity(.28),
                    blurRadius: glow,
                    spreadRadius: 6,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(color: Colors.white.withOpacity(.92), width: 7),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'SOS',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 34,
                      letterSpacing: 1,
                      height: 1.0,
                    ),
                  ),
                  // SizedBox(height: 6),
                  // Text(
                  //   'Tap to call',
                  //   style: TextStyle(
                  //     fontFamily: 'Poppins',
                  //     color: Colors.white,
                  //     fontWeight: FontWeight.w700,
                  //     fontSize: 12.5,
                  //   ),
                  // ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeBg,
    required this.badgeFg,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeBg;
  final Color badgeFg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(.10),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: kPrimary, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: kTextDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: kMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: badgeFg.withOpacity(.20)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chevron_right_rounded, size: 18, color: badgeFg),
                  const SizedBox(width: 6),
                  Text(
                    badge,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: badgeFg,
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

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child, this.padding = const EdgeInsets.all(14)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kPrimary.withOpacity(.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SmallPill extends StatelessWidget {
  const _SmallPill({required this.label, required this.fg, required this.bg});
  final String label;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
          color: fg,
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
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.my_location_rounded, color: kPrimary, size: 20),
        ),
      ),
    );
  }
}

class _ConfirmSOSDialog extends StatelessWidget {
  const _ConfirmSOSDialog({
    required this.onConfirm,
    required this.number,
  });

  final VoidCallback onConfirm;
  final String number;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Confirm SOS',
        style: TextStyle(
          fontFamily: 'Poppins',
          color: kTextDark,
          fontWeight: FontWeight.w900,
        ),
      ),
      content: Text(
        'This will call emergency services ($number). Proceed?',
        style: const TextStyle(
          fontFamily: 'Poppins',
          color: kMuted,
          fontWeight: FontWeight.w600,
          height: 1.25,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text(
            'Call now',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w900),
          ),
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


/*
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
    // final link =
    //     'https://www.google.com/maps/search/?api=1&query=${_center.latitude},${_center.longitude}';
    // await Share.share('My current location:\n$link');

    Navigator.push(context, MaterialPageRoute(builder: (context)=> EmergencyFormTabsScreen()));
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
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Color(0xFF5C2E91)),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Emergency1',
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
*/