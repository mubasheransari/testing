import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_bloc.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_state.dart';
import 'package:taskoon/Models/services_model.dart';
import 'package:taskoon/Models/services_ui_model.dart';
import 'package:taskoon/Realtime/dispatch_hub_service.dart';
import 'package:taskoon/Repository/auth_repository.dart';
import 'package:taskoon/Screens/User_booking/select_service.dart';
import 'package:taskoon/Screens/User_booking/service_booking_form_screen.dart';
import 'package:taskoon/Screens/User_booking/service_inprogress_screen.dart';
import 'dart:async';
import 'package:taskoon/widgets/greetingWithLocation_widget.dart';



class UserBookingHome extends StatefulWidget {
  const UserBookingHome({super.key});

  @override
  State<UserBookingHome> createState() => _UserBookingHomeState();
}

class _UserBookingHomeState extends State<UserBookingHome>
    with WidgetsBindingObserver {
  final GetStorage _box = GetStorage();

  String? _selectedChip;
  CertificationGroup? _selectedGroup;
  ServiceDto? servicesdto;

  String? userId;
  String? name;

  static const String _baseUrl = ApiConfig.baseUrl;

  bool _hubConfigured = false;
  bool _hubConnecting = false;

  StreamSubscription? _hubSub;

  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    userId = _box.read('userId')?.toString();
    name = _box.read('name')?.toString() ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await _configureHubIfPossible();
      await _ensureHubConnected();
      _attachHubListener();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    if (state == AppLifecycleState.resumed) {
      debugPrint("🔁 UserBookingHome resumed -> ensure hub connected");
      _ensureHubConnected();
    }
  }

  Future<void> _configureHubIfPossible() async {
    final freshUserId = _box.read('userId')?.toString();
    if (freshUserId == null || freshUserId.trim().isEmpty) {
      debugPrint("❌ UserBookingHome: userId missing (user id not loaded)");
      return;
    }

    userId = freshUserId;

    if (_hubConfigured) return;

    debugPrint(
      "🧩 UserBookingHome: configuring hub baseUrl=$_baseUrl userId=$userId",
    );

    DispatchHubSingleton.instance.configure(
      baseUrl: _baseUrl,
      userId: userId!,
    );

    _hubConfigured = true;
  }

  Future<void> _ensureHubConnected() async {
    if (!_hubConfigured) {
      await _configureHubIfPossible();
      if (!_hubConfigured) return;
    }

    if (DispatchHubSingleton.instance.isConnected == true) {
      debugPrint("✅ UserBookingHome: hub already connected");
      return;
    }

    if (_hubConnecting) {
      debugPrint("⏳ UserBookingHome: hub connect already running, skip");
      return;
    }

    _hubConnecting = true;

    try {
      debugPrint(
        "🔌 UserBookingHome: ensureConnected() starting... "
        "isConnected(before)=${DispatchHubSingleton.instance.isConnected}",
      );

      await DispatchHubSingleton.instance.ensureConnected();

      final connected = DispatchHubSingleton.instance.isConnected == true;
      debugPrint(
        "✅ UserBookingHome: hub ensureConnected done. isConnected=$connected",
      );
    } catch (e, st) {
      debugPrint("❌ UserBookingHome: ensureConnected FAILED => $e");
      debugPrint("$st");
    } finally {
      _hubConnecting = false;
    }
  }

  void _attachHubListener() {
    _hubSub?.cancel();

    debugPrint("🧩 UserBookingHome: attaching hub notifications listener");

    _hubSub = DispatchHubSingleton.instance.notifications.listen(
      (payload) {
        debugPrint("📩 USER HUB: $payload");
      },
      onError: (e, st) {
        debugPrint("❌ USER HUB stream error => $e");
        debugPrint("$st");
      },
      onDone: () {
        debugPrint("⚠️ USER HUB stream closed");
      },
      cancelOnError: false,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hubSub?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _q => _query.trim().toLowerCase();

  @override
  Widget build(BuildContext context) {
    final t = _UiTokens.of(context);

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: t.bg,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: t.primary,
          selectionColor: t.primary.withOpacity(.25),
          selectionHandleColor: t.primary,
        ),
      ),
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(child: _SupabaseBackground(t: t)),
            SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 64, 16, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HomeHeroCard(
                      t: t,
                      userName: name ?? '',
                      onPrimaryTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ServiceCertificatesGridScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    _SearchCardModern(
                      t: t,
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v),
                      onClear: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                      showClear: _query.trim().isNotEmpty,
                    ),
                    const SizedBox(height: 14),

                    _InfoCardModern(
                      t: t,
                      onTap: () {
                        // TODO: route to active booking details if needed
                      },
                    ),
                    const SizedBox(height: 22),

                    Text(
                      'What do you need today?',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        color: t.primaryText,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    BlocBuilder<AuthenticationBloc, AuthenticationState>(
                      buildWhen: (p, c) =>
                          p.serviceGroups != c.serviceGroups ||
                          p.servicesStatus != c.servicesStatus,
                      builder: (context, state) {
                        final allGroups = state.serviceGroups;

                        final visibleGroups = _q.isEmpty
                            ? allGroups
                            : allGroups.where((g) {
                                final groupMatch =
                                    g.name.toLowerCase().contains(_q);
                                final serviceMatch = g.services.any(
                                  (s) => s.name.toLowerCase().contains(_q),
                                );
                                return groupMatch || serviceMatch;
                              }).toList();

                        final chipLabels =
                            visibleGroups.map((e) => e.name).toList();

                        if (visibleGroups.isNotEmpty) {
                          final selectedStillVisible = _selectedChip != null &&
                              visibleGroups.any((g) => g.name == _selectedChip);

                          if (!selectedStillVisible) {
                            _selectedChip = visibleGroups.first.name;
                            _selectedGroup = visibleGroups.first;
                          } else {
                            _selectedGroup = visibleGroups.firstWhere(
                              (g) => g.name == _selectedChip,
                              orElse: () => visibleGroups.first,
                            );
                          }
                        } else {
                          _selectedChip = null;
                          _selectedGroup = null;
                        }

                        final selectedServices = (_selectedGroup == null)
                            ? <dynamic>[]
                            : (_q.isEmpty
                                ? _selectedGroup!.services
                                : _selectedGroup!.services
                                    .where((svc) =>
                                        svc.name.toLowerCase().contains(_q))
                                    .toList());

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 40,
                              child: (state.servicesStatus ==
                                          ServicesStatus.loading &&
                                      allGroups.isEmpty)
                                  ? _buildLoadingChipsModern(t)
                                  : ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: chipLabels.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 10),
                                      itemBuilder: (_, i) {
                                        final label = chipLabels[i];
                                        final sel =
                                            label == (_selectedChip ?? '');
                                        return _ChipPill(
                                          label: label,
                                          selected: sel,
                                          t: t,
                                          onTap: () {
                                            setState(() {
                                              _selectedChip = label;
                                              _selectedGroup =
                                                  visibleGroups.firstWhere(
                                                (g) => g.name == label,
                                                orElse: () =>
                                                    visibleGroups.first,
                                              );
                                            });
                                          },
                                        );
                                      },
                                    ),
                            ),
                            if (_selectedGroup != null &&
                                selectedServices.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Icon(
                                    Icons.grid_view_rounded,
                                    size: 18,
                                    color: t.mutedText,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Services in "${_selectedGroup!.name}"',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 13,
                                        color: t.mutedText,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: selectedServices.map((svc) {
                                  return _ServicePillTile(
                                    t: t,
                                    text: svc.name,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ServiceBookingFormScreen(
                                            group: _selectedGroup!,
                                            initialService: svc,
                                            serviceId: svc.id,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 22),
                    _buildActionRowModern(context, t),
                    const SizedBox(height: 24),
                    _buildPopularModern(context, t),
                    const SizedBox(height: 24),
                    _buildRecentModern(context, t),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingChipsModern(_UiTokens t) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemBuilder: (_, __) => Container(
        width: 92,
        height: 36,
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: t.border),
        ),
        child: Align(
          alignment: Alignment.center,
          child: Container(
            width: 42,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.08),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemCount: 4,
    );
  }

  Widget _buildActionRowModern(BuildContext context, _UiTokens t) {
    return Row(
      children: [
        Expanded(
          child: _ActionCardModern(
            t: t,
            title: 'Book a service',
            subtitle: 'Schedule instantly',
            icon: Icons.event_available_rounded,
            gradient: [t.primary, t.accent],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ServiceCertificatesGridScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCardModern(
            t: t,
            title: 'Track booking',
            subtitle: 'See live status',
            icon: Icons.radar_rounded,
            gradient: const [Color(0xFF1F9D68), Color(0xFF7CFFB2)],
            onTap: () {
              // TODO: navigate to booking tracking
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPopularModern(BuildContext context, _UiTokens t) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Popular near you',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: t.primaryText,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ServiceCertificatesGridScreen(),
                  ),
                );
              },
              icon: Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: t.primary,
              ),
              label: Text(
                'View all',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: t.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 174,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _ServiceHorizontalCardModern(
                t: t,
                title: 'House cleaning',
                price: 'From \$45',
                icon: Icons.cleaning_services_rounded,
                accent: t.primary,
              ),
              _ServiceHorizontalCardModern(
                t: t,
                title: 'AC repair',
                price: 'From \$60',
                icon: Icons.ac_unit_rounded,
                accent: const Color(0xFF59D8A1),
              ),
              _ServiceHorizontalCardModern(
                t: t,
                title: 'Furniture assemble',
                price: 'From \$35',
                icon: Icons.chair_alt_rounded,
                accent: const Color(0xFFB8F28C),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentModern(BuildContext context, _UiTokens t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent activity',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: t.primaryText,
          ),
        ),
        const SizedBox(height: 12),
        _Glass(
          radius: 24,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: t.primary.withOpacity(.10),
                    border: Border.all(color: t.primary.withOpacity(.20)),
                  ),
                  child: Icon(Icons.inbox_rounded, color: t.primary, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  'No bookings yet',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: t.primaryText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Start your first booking and everything will appear here.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12.5,
                    color: t.mutedText,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [t.primary, t.accent],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: t.primary.withOpacity(.24),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                 ServiceProgressScreen(totalMinutes: 30,) //ServiceCertificatesGridScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text(
                        'Start bookingg',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w900,
                          letterSpacing: .2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _UiTokens {
  final Color primary;
  final Color primaryDark;
  final Color accent;
  final Color bg;
  final Color bgSoft;
  final Color card;
  final Color card2;
  final Color border;
  final Color primaryText;
  final Color mutedText;
  final Color successGlow;

  const _UiTokens({
    required this.primary,
    required this.primaryDark,
    required this.accent,
    required this.bg,
    required this.bgSoft,
    required this.card,
    required this.card2,
    required this.border,
    required this.primaryText,
    required this.mutedText,
    required this.successGlow,
  });

  static _UiTokens of(BuildContext context) => const _UiTokens(
        primary: Color(0xFF3ECF8E),
        primaryDark: Color(0xFF2FBF7E),
        accent: Color(0xFF7CFFB2),
        bg: Color(0xFF0A0F0D),
        bgSoft: Color(0xFF111715),
        card: Color(0xFF101715),
        card2: Color(0xFF151D1A),
        border: Color(0xFF22302B),
        primaryText: Color(0xFFF3F8F5),
        mutedText: Color(0xFF9EB0A8),
        successGlow: Color(0xFF3ECF8E),
      );
}

class _SupabaseBackground extends StatelessWidget {
  const _SupabaseBackground({required this.t});

  final _UiTokens t;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: t.bg),
        Positioned(
          top: -80,
          left: -60,
          child: _GlowOrb(
            size: 220,
            color: t.primary.withOpacity(.10),
          ),
        ),
        Positioned(
          top: 120,
          right: -90,
          child: _GlowOrb(
            size: 240,
            color: const Color(0xFF1D8F63).withOpacity(.12),
          ),
        ),
        Positioned(
          bottom: 140,
          left: -70,
          child: _GlowOrb(
            size: 180,
            color: t.primary.withOpacity(.06),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _GridPainter(
                lineColor: Colors.white.withOpacity(.035),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(.02),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(.10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color lineColor;

  const _GridPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    const double gap = 28;
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = .8;

    for (double x = 0; x <= size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HomeHeroCard extends StatelessWidget {
  const _HomeHeroCard({
    required this.t,
    required this.userName,
    required this.onPrimaryTap,
  });

  final _UiTokens t;
  final String userName;
  final VoidCallback onPrimaryTap;

  String _firstName(String v) {
    final s = v.trim();
    if (s.isEmpty) return '';
    return s.split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context) {
    final fn = _firstName(userName);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF101715),
            Color(0xFF0D1311),
            Color(0xFF111A17),
          ],
        ),
        border: Border.all(color: t.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.32),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: t.primary.withOpacity(.08),
            blurRadius: 28,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    t.primary.withOpacity(.22),
                    t.primary.withOpacity(.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: t.primary.withOpacity(.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: t.primary.withOpacity(.24)),
                ),
                child: Text(
                  fn.isEmpty ? 'Welcome to Taskoon' : 'Hi, $fn',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: t.accent,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .3,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Book trusted\nservices faster.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: t.primaryText,
                  fontSize: 28,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.8,
                ),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Text(
                  'A premium home screen inspired by modern SaaS products — fast booking, trusted taskers, and live status in one place.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: t.mutedText,
                    fontSize: 13,
                    height: 1.55,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _HeroBadge(
                    t: t,
                    icon: Icons.flash_on_rounded,
                    text: 'Instant booking',
                  ),
                  _HeroBadge(
                    t: t,
                    icon: Icons.verified_rounded,
                    text: 'Verified taskers',
                  ),
                  _HeroBadge(
                    t: t,
                    icon: Icons.payments_rounded,
                    text: 'Secure payments',
                  ),
                  _HeroBadge(
                    t: t,
                    icon: Icons.schedule_rounded,
                    text: 'Flexible scheduling',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [t.primary, t.accent],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: t.primary.withOpacity(.30),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: onPrimaryTap,
                          child: const Center(
                            child: Text(
                              'Start booking',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: t.border),
                    ),
                    child: Icon(
                      Icons.arrow_outward_rounded,
                      color: t.primaryText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({
    required this.t,
    required this.icon,
    required this.text,
  });

  final _UiTokens t;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.03),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: t.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: t.primary),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Poppins',
              color: t.primaryText,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchCardModern extends StatelessWidget {
  const _SearchCardModern({
    required this.t,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.showClear,
  });

  final _UiTokens t;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool showClear;

  @override
  Widget build(BuildContext context) {
    return _Glass(
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: t.primary.withOpacity(.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: t.primary.withOpacity(.20)),
              ),
              child: Icon(Icons.search_rounded, color: t.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: t.primaryText,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Search services, categories, booking types...',
                  hintStyle: TextStyle(
                    fontFamily: 'Poppins',
                    color: t.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            if (showClear)
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onClear,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: t.mutedText,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: t.primary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: t.primary.withOpacity(.28),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCardModern extends StatelessWidget {
  const _InfoCardModern({
    required this.t,
    this.onTap,
  });

  final _UiTokens t;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _Glass(
      radius: 20,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: t.primary.withOpacity(.12),
                  border: Border.all(color: t.primary.withOpacity(.22)),
                ),
                child: Icon(Icons.bolt_rounded, color: t.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '1 active booking today. View details or reschedule in seconds.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12.8,
                    color: t.primaryText,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: t.mutedText),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipPill extends StatelessWidget {
  const _ChipPill({
    required this.label,
    required this.selected,
    required this.t,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final _UiTokens t;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? t.primary.withOpacity(.14) : t.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? t.primary.withOpacity(.45) : t.border,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: t.primary.withOpacity(.16),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 16,
              color: selected ? t.primary : t.mutedText,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: selected ? t.primaryText : t.mutedText,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServicePillTile extends StatelessWidget {
  const _ServicePillTile({
    required this.t,
    required this.text,
    required this.onTap,
  });

  final _UiTokens t;
  final String text;
  final VoidCallback onTap;

  IconData _pickIcon(String s) {
    final v = s.toLowerCase();
    if (v.contains('clean')) return Icons.cleaning_services_rounded;
    if (v.contains('ac')) return Icons.ac_unit_rounded;
    if (v.contains('plumb')) return Icons.plumbing_rounded;
    if (v.contains('electric')) return Icons.electrical_services_rounded;
    if (v.contains('car')) return Icons.directions_car_rounded;
    if (v.contains('garden')) return Icons.grass_rounded;
    if (v.contains('baby') || v.contains('nanny')) {
      return Icons.child_friendly_rounded;
    }
    return Icons.handyman_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: t.primary.withOpacity(.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: t.primary.withOpacity(.20)),
              ),
              child: Icon(_pickIcon(text), size: 16, color: t.primary),
            ),
            const SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12.5,
                color: t.primaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCardModern extends StatelessWidget {
  const _ActionCardModern({
    required this.t,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final _UiTokens t;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Glass(
      radius: 22,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          height: 126,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(colors: gradient),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.first.withOpacity(.22),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.black),
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: t.primaryText,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11.8,
                  color: t.mutedText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceHorizontalCardModern extends StatelessWidget {
  const _ServiceHorizontalCardModern({
    required this.t,
    required this.title,
    required this.price,
    required this.icon,
    required this.accent,
  });

  final _UiTokens t;
  final String title;
  final String price;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 176,
      margin: const EdgeInsets.only(right: 12),
      child: _Glass(
        radius: 22,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(13, 13, 13, 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: accent.withOpacity(.12),
                      border: Border.all(color: accent.withOpacity(.22)),
                    ),
                    child: Icon(icon, color: accent, size: 20),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.north_east_rounded,
                    size: 18,
                    color: t.mutedText,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: t.primaryText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                price,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: t.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: t.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Nearby',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: t.mutedText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconGlassButton extends StatelessWidget {
  const _IconGlassButton({
    required this.t,
    required this.icon,
    required this.onTap,
  });

  final _UiTokens t;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Glass(
      radius: 16,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, color: t.primary),
        ),
      ),
    );
  }
}

class _Glass extends StatelessWidget {
  const _Glass({required this.child, this.radius = 20});

  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final t = _UiTokens.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                t.card.withOpacity(.92),
                t.card2.withOpacity(.88),
              ],
            ),
            border: Border.all(
              color: t.border,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.28),
                blurRadius: 26,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: t.primary.withOpacity(.06),
                blurRadius: 18,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}




//   final box = GetStorage();
//       var userId=     box.read('userId');//Testing@123
//              var name = box.read("name");
// class UserBookingHome extends StatefulWidget {
//   const UserBookingHome({super.key});

//   @override
//   State<UserBookingHome> createState() => _UserBookingHomeState();
// }

// class _UserBookingHomeState extends State<UserBookingHome>
//     with WidgetsBindingObserver {
//   String? _selectedChip;
//   CertificationGroup? _selectedGroup;
//   ServiceDto? servicesdto;

//   static const String _baseUrl ="https://api.taskoon.com"; //"http://192.3.3.187:85";

//   bool _hubConfigured = false;

//   // ✅ hub listeners / watchdog
//   StreamSubscription? _hubSub;
//   Timer? _hubWatchdog;

//   // ✅ prevent multiple parallel connect attempts
//   bool _hubConnecting = false;

//   // ✅ backoff reconnect (2s -> 4s -> 8s -> ... -> 30s max)
//   int _reconnectAttempt = 0;
//   Timer? _reconnectTimer;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);

//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       if (!mounted) return;

//       // ✅ 1) configure hub when userId is available
//       await _configureHubIfPossible();

//       // ✅ 2) connect now (and keep it connected)
//       await _ensureHubConnected(force: true);

//       // ✅ 3) attach listener after ensureConnected
//       _attachHubListener();

//       // ✅ 4) start watchdog (always running)
//       _startHubWatchdog();
//     });
//   }

//   /// ✅ App lifecycle: when app resumes, reconnect immediately
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (!mounted) return;

//     if (state == AppLifecycleState.resumed) {
//       debugPrint("🔁 UserBookingHome resumed -> ensure hub connected");
//       _configureHubIfPossible().then((_) => _ensureHubConnected(force: true));
//     }
//   }

//   Future<void> _configureHubIfPossible() async {

//     if (userId == null) {
//       debugPrint("❌ UserBookingHome: userId missing (user id not loaded)");
//       return;
//     }

//     if (_hubConfigured) return;

//     debugPrint("🧩 UserBookingHome: configuring hub baseUrl=$_baseUrl userId=$userId");

//     DispatchHubSingleton.instance.configure(
//       baseUrl: _baseUrl,
//       userId: userId,
//     );

//     _hubConfigured = true;
//   }

//   /// ------------------------------------------------------------
//   /// ✅ ENSURE HUB CONNECTED (with retry + backoff)
//   /// ------------------------------------------------------------
//   Future<void> _ensureHubConnected({bool force = false}) async {
//     if (!_hubConfigured) {
//       await _configureHubIfPossible();
//       if (!_hubConfigured) return; // still no userId
//     }

//     // ✅ if already connected and not forced, stop here
//     if (!force && DispatchHubSingleton.instance.isConnected == true) {
//       return;
//     }

//     if (_hubConnecting) {
//       debugPrint("⏳ UserBookingHome: hub connect already running, skip");
//       return;
//     }

//     _hubConnecting = true;
//     _reconnectTimer?.cancel();
//     _reconnectTimer = null;

//     try {
//       debugPrint("🔌 UserBookingHome: ensureConnected() starting... "
//           "isConnected(before)=${DispatchHubSingleton.instance.isConnected}");

//       await DispatchHubSingleton.instance.ensureConnected();

//       final connected = DispatchHubSingleton.instance.isConnected == true;
//       debugPrint("✅ UserBookingHome: hub ensureConnected done. isConnected=$connected");

//       if (!connected) {
//         // ensureConnected returned but still not connected → retry
//         _scheduleReconnect("ensureConnected returned but still disconnected");
//       } else {
//         _reconnectAttempt = 0; // reset backoff on success
//       }
//     } catch (e, st) {
//       debugPrint("❌ UserBookingHome: ensureConnected FAILED => $e");
//       debugPrint("$st");
//       _scheduleReconnect("exception");
//     } finally {
//       _hubConnecting = false;
//     }
//   }

//   void _scheduleReconnect(String reason) {
//     _reconnectAttempt++;
//     final seconds = (_reconnectAttempt <= 1)
//         ? 2
//         : (_reconnectAttempt == 2)
//             ? 4
//             : (_reconnectAttempt == 3)
//                 ? 8
//                 : (_reconnectAttempt == 4)
//                     ? 16
//                     : 30;

//     debugPrint("🛡️ HUB WATCHDOG: disconnected -> reconnecting... "
//         "reason=$reason attempt=$_reconnectAttempt in ${seconds}s");

//     _reconnectTimer?.cancel();
//     _reconnectTimer = Timer(Duration(seconds: seconds), () {
//       if (!mounted) return;
//       _ensureHubConnected(force: true);
//     });
//   }

//   void _startHubWatchdog() {
//     _hubWatchdog?.cancel();
//     _hubWatchdog = Timer.periodic(const Duration(seconds: 3), (_) {
//       if (!mounted) return;

//       if (!_hubConfigured) {
//         _configureHubIfPossible();
//         return;
//       }

//       final isConnected = DispatchHubSingleton.instance.isConnected == true;

//       if (!isConnected) {
//         // Don’t spam reconnect if a connect is already running
//         if (_hubConnecting) return;

//         _scheduleReconnect("watchdog detected disconnected");
//       }
//     });
//   }

//   /// ------------------------------------------------------------
//   /// ✅ LISTENER (optional)
//   /// ------------------------------------------------------------
//   void _attachHubListener() {
//     _hubSub?.cancel();

//     debugPrint("🧩 UserBookingHome: attaching hub notifications listener");

//     _hubSub = DispatchHubSingleton.instance.notifications.listen(
//       (payload) {
//         debugPrint("📩 USER HUB: $payload");
//       },
//       onError: (e) {
//         debugPrint("❌ USER HUB stream error => $e");
//         _scheduleReconnect("stream error");
//       },
//       onDone: () {
//         debugPrint("⚠️ USER HUB stream closed");
//         _scheduleReconnect("stream closed");
//       },
//     );
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);

//     _hubSub?.cancel();
//     _hubWatchdog?.cancel();
//     _reconnectTimer?.cancel();

//     // ✅ IMPORTANT: Do NOT stop hub here (you said hub must stay connected).
//     // If you stop here, other screens will lose the connection.

//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: _buildAppBar(),
//       body: SafeArea(
//         top: false,
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildSearch(),
//               const SizedBox(height: 14),
//               _buildInfoCard(),
//               const SizedBox(height: 18),
//               const Text(
//                 'What do you need today?',
//                 style: TextStyle(
//                   fontFamily: 'Poppins',
//                   fontSize: 16,
//                   color: Color(0xFF3E1E69),
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//               const SizedBox(height: 10),

//               BlocBuilder<AuthenticationBloc, AuthenticationState>(
//                 buildWhen: (p, c) =>
//                     p.serviceGroups != c.serviceGroups ||
//                     p.servicesStatus != c.servicesStatus,
//                 builder: (context, state) {
//                   final groups = state.serviceGroups;
//                   final List<String> chipLabels =
//                       groups.map((e) => e.name).toList();

//                   return Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       SizedBox(
//                         height: 34,
//                         child: (state.servicesStatus == ServicesStatus.loading &&
//                                 groups.isEmpty)
//                             ? _buildLoadingChips()
//                             : ListView.separated(
//                                 scrollDirection: Axis.horizontal,
//                                 itemCount: chipLabels.length,
//                                 separatorBuilder: (_, __) =>
//                                     const SizedBox(width: 8),
//                                 itemBuilder: (_, i) {
//                                   final label = chipLabels[i];
//                                   final sel = label == (_selectedChip ?? '');
//                                   return GestureDetector(
//                                     onTap: () {
//                                       setState(() {
//                                         _selectedChip = label;
//                                         _selectedGroup = groups.firstWhere(
//                                           (g) => g.name == label,
//                                           orElse: () => groups.first,
//                                         );
//                                       });
//                                     },
//                                     child: Container(
//                                       padding: const EdgeInsets.symmetric(
//                                         horizontal: 12,
//                                         vertical: 6,
//                                       ),
//                                       decoration: BoxDecoration(
//                                         color: sel
//                                             ? const Color(0xFF5C2E91)
//                                             : Colors.white,
//                                         borderRadius:
//                                             BorderRadius.circular(999),
//                                         border: sel
//                                             ? null
//                                             : Border.all(
//                                                 color: const Color(0xFF5C2E91)
//                                                     .withOpacity(.3),
//                                               ),
//                                       ),
//                                       child: Text(
//                                         label,
//                                         style: TextStyle(
//                                           fontFamily: 'Poppins',
//                                           color: sel
//                                               ? Colors.white
//                                               : const Color(0xFF5C2E91),
//                                           fontWeight: FontWeight.w600,
//                                           fontSize: 12.5,
//                                         ),
//                                       ),
//                                     ),
//                                   );
//                                 },
//                               ),
//                       ),

//                       if (_selectedGroup != null &&
//                           _selectedGroup!.services.isNotEmpty) ...[
//                         const SizedBox(height: 12),
//                         Text(
//                           'Services in "${_selectedGroup!.name}"',
//                           style: const TextStyle(
//                             fontFamily: 'Poppins',
//                             fontSize: 13,
//                             color: Color(0xFF75748A),
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Wrap(
//                           spacing: 8,
//                           runSpacing: 8,
//                           children: _selectedGroup!.services.map((svc) {
//                             return GestureDetector(
//                               onTap: () {
//                                 Navigator.push(
//                                   context,
//                                   MaterialPageRoute(
//                                     builder: (_) => ServiceBookingFormScreen(
//                                       group: _selectedGroup!,
//                                       initialService: svc,
//                                       serviceId: svc.id,
//                                     ),
//                                   ),
//                                 );
//                               },
//                               child: Container(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 12,
//                                   vertical: 6,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   color: const Color(0xFF5C2E91)
//                                       .withOpacity(.06),
//                                   borderRadius: BorderRadius.circular(12),
//                                   border: Border.all(
//                                     color: const Color(0xFF5C2E91)
//                                         .withOpacity(.25),
//                                   ),
//                                 ),
//                                 child: Text(
//                                   svc.name,
//                                   style: const TextStyle(
//                                     fontFamily: 'Poppins',
//                                     fontSize: 12,
//                                     color: Color(0xFF3E1E69),
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                               ),
//                             );
//                           }).toList(),
//                         ),
//                       ],
//                     ],
//                   );
//                 },
//               ),

//               const SizedBox(height: 16),
//               _buildActionRow(context),
//               const SizedBox(height: 20),
//               _buildPopular(context),
//               const SizedBox(height: 20),
//               _buildRecent(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // ==================== UI HELPERS (UNCHANGED) ====================

//   AppBar _buildAppBar() {
//     return AppBar(
//       backgroundColor: Colors.white,
//       surfaceTintColor: Colors.transparent,
//       elevation: 0,
//       centerTitle: false,
//       titleSpacing: 16,
//       title: Padding(
//         padding: const EdgeInsets.all(16),
//         child:  GreetingText(name: name),
//       ),
//       actions: [
//         IconButton(
//           onPressed: () {},
//           icon: const Icon(
//             Icons.notifications_none_rounded,
//             color: Color(0xFF5C2E91),
//           ),
//         ),
//         const Padding(
//           padding: EdgeInsets.only(right: 16),
//           child: CircleAvatar(
//             radius: 18,
//             backgroundImage: NetworkImage('https://images.unsplash.com/photo-1607746882042-944635dfe10e?q=80&w=256&auto=format&fit=crop'),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSearch() {
//     return Material(
//       elevation: 0,
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(14),
//       child: TextField(
//         style: const TextStyle(fontFamily: 'Poppins'),
//         decoration: InputDecoration(
//           hintText: 'Search for services...',
//           hintStyle: TextStyle(
//             fontFamily: 'Poppins',
//             color: Colors.grey.shade500,
//             fontSize: 13.5,
//           ),
//           border: InputBorder.none,
//           prefixIcon: const Icon(Icons.search_rounded),
//           contentPadding:
//               const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoCard() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: const Color(0xFF5C2E91).withOpacity(.07)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(.03),
//             blurRadius: 14,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       padding: const EdgeInsets.all(14),
//       child: Row(
//         children: [
//           Container(
//             height: 40,
//             width: 40,
//             decoration: BoxDecoration(
//               color: const Color(0xFF5C2E91).withOpacity(.12),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: const Icon(Icons.flash_on_rounded,
//                 color: Color(0xFF5C2E91)),
//           ),
//           const SizedBox(width: 12),
//           const Expanded(
//             child: Text(
//               '1 active booking today. Tap to view or reschedule.',
//               style: TextStyle(
//                 fontFamily: 'Poppins',
//                 fontSize: 12.5,
//                 color: Color(0xFF5C2E91),
//               ),
//             ),
//           ),
//           const Icon(Icons.chevron_right_rounded,
//               color: Color(0xFF5C2E91)),
//         ],
//       ),
//     );
//   }

//   Widget _buildLoadingChips() {
//     return ListView.separated(
//       scrollDirection: Axis.horizontal,
//       itemBuilder: (_, __) => Container(
//         width: 80,
//         height: 28,
//         decoration: BoxDecoration(
//           color: Colors.grey.shade200,
//           borderRadius: BorderRadius.circular(999),
//         ),
//       ),
//       separatorBuilder: (_, __) => const SizedBox(width: 8),
//       itemCount: 4,
//     );
//   }

//   Widget _buildActionRow(BuildContext context) {
//     return Row(
//       children: [
//         Expanded(
//           child: _ActionCard(
//             title: 'Book a service',
//             subtitle: 'Schedule instantly',
//             icon: Icons.event_available_rounded,
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                     builder: (_) => const ServiceCertificatesGridScreen()),
//               );
//             },
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: _ActionCard(
//             title: 'Track booking',
//             subtitle: 'See status',
//             icon: Icons.schedule_rounded,
//             color: const Color(0xFF3DB38D),
//             onTap: () {},
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildPopular(BuildContext context) {
//     return Column(
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             const Text(
//               'Popular near you',
//               style: TextStyle(
//                 fontFamily: 'Poppins',
//                 fontSize: 15.5,
//                 fontWeight: FontWeight.w700,
//                 color: Color(0xFF3E1E69),
//               ),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                       builder: (_) => const ServiceCertificatesGridScreen()),
//                 );
//               },
//               child: const Text(
//                 'View all',
//                 style: TextStyle(
//                   fontFamily: 'Poppins',
//                   color: Color(0xFF5C2E91),
//                 ),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 10),
//         SizedBox(
//           height: 150,
//           child: ListView(
//             scrollDirection: Axis.horizontal,
//             children: const [
//               _ServiceHorizontalCard(
//                 title: 'House cleaning',
//                 price: 'From \$45',
//                 icon: Icons.cleaning_services_rounded,
//               ),
//               _ServiceHorizontalCard(
//                 title: 'AC repair',
//                 price: 'From \$60',
//                 icon: Icons.ac_unit_rounded,
//                 color: Color(0xFF3DB38D),
//               ),
//               _ServiceHorizontalCard(
//                 title: 'Furniture assemble',
//                 price: 'From \$35',
//                 icon: Icons.chair_alt_rounded,
//                 color: Color(0xFFEE8A41),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildRecent() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Recent activity',
//           style: TextStyle(
//             fontFamily: 'Poppins',
//             fontSize: 15.5,
//             fontWeight: FontWeight.w700,
//             color: Color(0xFF3E1E69),
//           ),
//         ),
//         const SizedBox(height: 12),
//         Container(
//           width: double.infinity,
//           padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(18),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(.02),
//                 blurRadius: 18,
//                 offset: const Offset(0, 12),
//               ),
//             ],
//           ),
//           child: const Column(
//             children: [
//               Icon(Icons.inbox_rounded, size: 40, color: Color(0xFF75748A)),
//               SizedBox(height: 8),
//               Text(
//                 'No bookings yet',
//                 style: TextStyle(
//                   fontFamily: 'Poppins',
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               SizedBox(height: 4),
//               Text(
//                 'Book a task to see it here.',
//                 style: TextStyle(
//                   fontFamily: 'Poppins',
//                   fontSize: 12.5,
//                   color: Color(0xFF75748A),
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _ActionCard extends StatelessWidget {
//   const _ActionCard({
//     required this.title,
//     required this.subtitle,
//     required this.icon,
//     required this.onTap,
//     this.color,
//   });

//   final String title;
//   final String subtitle;
//   final IconData icon;
//   final VoidCallback onTap;
//   final Color? color;

//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(16),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(16),
//         onTap: onTap,
//         child: Container(
//           height: 110,
//           padding: const EdgeInsets.all(14),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 height: 34,
//                 width: 34,
//                 decoration: BoxDecoration(
//                   color: (color ?? const Color(0xFF5C2E91)).withOpacity(.12),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Icon(icon, color: color ?? const Color(0xFF5C2E91)),
//               ),
//               const Spacer(),
//               Text(
//                 title,
//                 style: const TextStyle(
//                   fontFamily: 'Poppins',
//                   fontSize: 13.5,
//                   fontWeight: FontWeight.w700,
//                   color: Color(0xFF3E1E69),
//                 ),
//               ),
//               const SizedBox(height: 2),
//               Text(
//                 subtitle,
//                 style: const TextStyle(
//                   fontFamily: 'Poppins',
//                   fontSize: 11.5,
//                   color: Color(0xFF75748A),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _ServiceHorizontalCard extends StatelessWidget {
//   const _ServiceHorizontalCard({
//     required this.title,
//     required this.price,
//     required this.icon,
//     this.color,
//   });

//   final String title;
//   final String price;
//   final IconData icon;
//   final Color? color;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 150,
//       margin: const EdgeInsets.only(right: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(18),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(.03),
//             blurRadius: 16,
//             offset: const Offset(0, 10),
//           ),
//         ],
//       ),
//       padding: const EdgeInsets.all(12),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             height: 34,
//             width: 34,
//             decoration: BoxDecoration(
//               color: (color ?? const Color(0xFF5C2E91)).withOpacity(.12),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Icon(
//               icon,
//               color: color ?? const Color(0xFF5C2E91),
//               size: 18,
//             ),
//           ),
//           const SizedBox(height: 10),
//           Text(
//             title,
//             maxLines: 2,
//             overflow: TextOverflow.ellipsis,
//             style: const TextStyle(
//               fontFamily: 'Poppins',
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             price,
//             style: const TextStyle(
//               fontFamily: 'Poppins',
//               fontSize: 11.5,
//               color: Color(0xFF75748A),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

/*
final box = GetStorage();
var userId = box.read('userId'); 
var name = box.read("name");

class UserBookingHome extends StatefulWidget {
  const UserBookingHome({super.key});

  @override
  State<UserBookingHome> createState() => _UserBookingHomeState();
}

class _UserBookingHomeState extends State<UserBookingHome>
    with WidgetsBindingObserver {
  String? _selectedChip;
  CertificationGroup? _selectedGroup;
  ServiceDto? servicesdto;

  static const String _baseUrl = "https://api.taskoon.com";

  bool _hubConfigured = false;

  StreamSubscription? _hubSub;
  Timer? _hubWatchdog;

  bool _hubConnecting = false;

  int _reconnectAttempt = 0;
  Timer? _reconnectTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await _configureHubIfPossible();
      await _ensureHubConnected(force: true);
      _attachHubListener();
      _startHubWatchdog();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    if (state == AppLifecycleState.resumed) {
      debugPrint("🔁 UserBookingHome resumed -> ensure hub connected");
      _configureHubIfPossible().then((_) => _ensureHubConnected(force: true));
    }
  }

  Future<void> _configureHubIfPossible() async {
    if (userId == null) {
      debugPrint("❌ UserBookingHome: userId missing (user id not loaded)");
      return;
    }

    if (_hubConfigured) return;

    debugPrint("🧩 UserBookingHome: configuring hub baseUrl=$_baseUrl userId=$userId");

    DispatchHubSingleton.instance.configure(
      baseUrl: _baseUrl,
      userId: userId,
    );

    _hubConfigured = true;
  }

  Future<void> _ensureHubConnected({bool force = false}) async {
    if (!_hubConfigured) {
      await _configureHubIfPossible();
      if (!_hubConfigured) return;
    }

    if (!force && DispatchHubSingleton.instance.isConnected == true) {
      return;
    }

    if (_hubConnecting) {
      debugPrint("⏳ UserBookingHome: hub connect already running, skip");
      return;
    }

    _hubConnecting = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    try {
      debugPrint("🔌 UserBookingHome: ensureConnected() starting... "
          "isConnected(before)=${DispatchHubSingleton.instance.isConnected}");

      await DispatchHubSingleton.instance.ensureConnected();

      final connected = DispatchHubSingleton.instance.isConnected == true;
      debugPrint("✅ UserBookingHome: hub ensureConnected done. isConnected=$connected");

      if (!connected) {
        _scheduleReconnect("ensureConnected returned but still disconnected");
      } else {
        _reconnectAttempt = 0;
      }
    } catch (e, st) {
      debugPrint("❌ UserBookingHome: ensureConnected FAILED => $e");
      debugPrint("$st");
      _scheduleReconnect("exception");
    } finally {
      _hubConnecting = false;
    }
  }

  void _scheduleReconnect(String reason) {
    _reconnectAttempt++;
    final seconds = (_reconnectAttempt <= 1)
        ? 2
        : (_reconnectAttempt == 2)
            ? 4
            : (_reconnectAttempt == 3)
                ? 8
                : (_reconnectAttempt == 4)
                    ? 16
                    : 30;

    debugPrint("🛡️ HUB WATCHDOG: disconnected -> reconnecting... "
        "reason=$reason attempt=$_reconnectAttempt in ${seconds}s");

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: seconds), () {
      if (!mounted) return;
      _ensureHubConnected(force: true);
    });
  }

  void _startHubWatchdog() {
    _hubWatchdog?.cancel();
    _hubWatchdog = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;

      if (!_hubConfigured) {
        _configureHubIfPossible();
        return;
      }

      final isConnected = DispatchHubSingleton.instance.isConnected == true;

      if (!isConnected) {
        if (_hubConnecting) return;
        _scheduleReconnect("watchdog detected disconnected");
      }
    });
  }

  void _attachHubListener() {
    _hubSub?.cancel();

    debugPrint("🧩 UserBookingHome: attaching hub notifications listener");

    _hubSub = DispatchHubSingleton.instance.notifications.listen(
      (payload) {
        debugPrint("📩 USER HUB: $payload");
      },
      onError: (e) {
        debugPrint("❌ USER HUB stream error => $e");
        _scheduleReconnect("stream error");
      },
      onDone: () {
        debugPrint("⚠️ USER HUB stream closed");
        _scheduleReconnect("stream closed");
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _hubSub?.cancel();
    _hubWatchdog?.cancel();
    _reconnectTimer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _UiTokens.of(context);

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: t.bg,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      child: Scaffold(
        appBar: _buildAppBarModern(t),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ hero
                _HomeHeroCard(t: t),
                const SizedBox(height: 14),

                // ✅ search
                _SearchCardModern(t: t),
                const SizedBox(height: 14),

                // ✅ info card
                _InfoCardModern(t: t),
                const SizedBox(height: 18),

                Text(
                  'What do you need today?',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    color: t.primaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),

                BlocBuilder<AuthenticationBloc, AuthenticationState>(
                  buildWhen: (p, c) =>
                      p.serviceGroups != c.serviceGroups ||
                      p.servicesStatus != c.servicesStatus,
                  builder: (context, state) {
                    final groups = state.serviceGroups;
                    final List<String> chipLabels =
                        groups.map((e) => e.name).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 38,
                          child: (state.servicesStatus == ServicesStatus.loading &&
                                  groups.isEmpty)
                              ? _buildLoadingChipsModern(t)
                              : ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: chipLabels.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 10),
                                  itemBuilder: (_, i) {
                                    final label = chipLabels[i];
                                    final sel = label == (_selectedChip ?? '');
                                    return _ChipPill(
                                      label: label,
                                      selected: sel,
                                      t: t,
                                      onTap: () {
                                        setState(() {
                                          _selectedChip = label;
                                          _selectedGroup = groups.firstWhere(
                                            (g) => g.name == label,
                                            orElse: () => groups.first,
                                          );
                                        });
                                      },
                                    );
                                  },
                                ),
                        ),

                        if (_selectedGroup != null &&
                            _selectedGroup!.services.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.grid_view_rounded,
                                  size: 18, color: t.mutedText),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Services in "${_selectedGroup!.name}"',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    color: t.mutedText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _selectedGroup!.services.map((svc) {
                              return _ServicePillTile(
                                t: t,
                                text: svc.name,
                                onTap: () {
                                  // ✅ unchanged navigation
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ServiceBookingFormScreen(
                                        group: _selectedGroup!,
                                        initialService: svc,
                                        serviceId: svc.id,
                                      ),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    );
                  },
                ),

                const SizedBox(height: 18),
                _buildActionRowModern(context, t),
                const SizedBox(height: 20),
                _buildPopularModern(context, t),
                const SizedBox(height: 20),
                _buildRecentModern(t),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== APPBAR (MODERN THEME ONLY) ====================

  PreferredSizeWidget _buildAppBarModern(_UiTokens t) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(96),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 30, 16, 8),
          child: Row(
            children: [
              // greeting block (keeps your GreetingText)
              Expanded(
                child: _Glass(
                  radius: 18,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Row(
                      children: [
                        // Container(
                        //   width: 42,
                        //   height: 42,
                        //   decoration: BoxDecoration(
                        //     borderRadius: BorderRadius.circular(16),
                        //     gradient: LinearGradient(
                        //       begin: Alignment.topLeft,
                        //       end: Alignment.bottomRight,
                        //       colors: [t.primary, t.primaryDark],
                        //     ),
                        //     boxShadow: [
                        //       BoxShadow(
                        //         color: t.primary.withOpacity(.20),
                        //         blurRadius: 18,
                        //         offset: const Offset(0, 10),
                        //       ),
                        //     ],
                        //   ),
                        //   child: const Icon(Icons.person_rounded, color: Colors.white),
                        // ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GreetingText(name: name), // ✅ unchanged
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // actions
              _IconGlassButton(
                t: t,
                icon: Icons.notifications_none_rounded,
                onTap: () {}, // ✅ unchanged
              ),
              const SizedBox(width: 10),

              const CircleAvatar(
                radius: 19,
                backgroundImage: NetworkImage(
                  'https://images.unsplash.com/photo-1607746882042-944635dfe10e?q=80&w=256&auto=format&fit=crop',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== UI SECTIONS (MODERNIZED ONLY) ====================

  Widget _buildLoadingChipsModern(_UiTokens t) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemBuilder: (_, __) => Container(
        width: 88,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: t.primary.withOpacity(.10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.04),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Align(
          alignment: Alignment.center,
          child: Container(
            width: 40,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(.06),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemCount: 4,
    );
  }

  Widget _buildActionRowModern(BuildContext context, _UiTokens t) {
    return Row(
      children: [
        Expanded(
          child: _ActionCardModern(
            t: t,
            title: 'Book a service',
            subtitle: 'Schedule instantly',
            icon: Icons.event_available_rounded,
            gradient: [t.primary, t.primaryDark],
            onTap: () {
              // ✅ unchanged navigation
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ServiceCertificatesGridScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCardModern(
            t: t,
            title: 'Track booking',
            subtitle: 'See status',
            icon: Icons.radar_rounded,
            gradient: [const Color(0xFF3DB38D), const Color(0xFF1E8F6D)],
            onTap: () {}, // ✅ unchanged
          ),
        ),
      ],
    );
  }

  Widget _buildPopularModern(BuildContext context, _UiTokens t) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Popular near you',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: t.primaryText,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                // ✅ unchanged navigation
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ServiceCertificatesGridScreen()),
                );
              },
              icon: Icon(Icons.arrow_forward_rounded, size: 16, color: t.primary),
              label: Text(
                'View all',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: t.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 160,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _ServiceHorizontalCardModern(
                t: t,
                title: 'House cleaning',
                price: 'From \$45',
                icon: Icons.cleaning_services_rounded,
                accent: t.primary,
              ),
              _ServiceHorizontalCardModern(
                t: t,
                title: 'AC repair',
                price: 'From \$60',
                icon: Icons.ac_unit_rounded,
                accent: const Color(0xFF3DB38D),
              ),
              _ServiceHorizontalCardModern(
                t: t,
                title: 'Furniture assemble',
                price: 'From \$35',
                icon: Icons.chair_alt_rounded,
                accent: const Color(0xFFEE8A41),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentModern(_UiTokens t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent activity',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            color: t.primaryText,
          ),
        ),
        const SizedBox(height: 12),
        _Glass(
          radius: 22,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: t.primary.withOpacity(.10),
                    border: Border.all(color: t.primary.withOpacity(.12)),
                  ),
                  child: Icon(Icons.inbox_rounded, color: t.primaryDark),
                ),
                const SizedBox(height: 10),
                Text(
                  'No bookings yet',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w800,
                    color: t.primaryText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Book a task to see it here.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12.5,
                    color: t.mutedText,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // ✅ unchanged navigation destination you used earlier
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ServiceCertificatesGridScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: t.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text(
                      'Start booking',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w900,
                        letterSpacing: .2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/* ============================== TOKENS ============================== */

class _UiTokens {
  final Color primary;
  final Color primaryDark;
  final Color primaryText;
  final Color mutedText;
  final Color bg;

  const _UiTokens({
    required this.primary,
    required this.primaryDark,
    required this.primaryText,
    required this.mutedText,
    required this.bg,
  });

  static _UiTokens of(BuildContext context) => const _UiTokens(
        primary: Color(0xFF7841BA),
        primaryDark: Color(0xFF5C2E91),
        primaryText: Color(0xFF3E1E69),
        mutedText: Color(0xFF75748A),
        bg: Color(0xFFF8F7FB),
      );
}

/* ============================== HERO ============================== */

class _HomeHeroCard extends StatelessWidget {
  const _HomeHeroCard({required this.t});
  final _UiTokens t;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            t.primary.withOpacity(.14),
            t.primary.withOpacity(.06),
            Colors.white,
          ],
        ),
        border: Border.all(color: t.primary.withOpacity(.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Find the right tasker 👋',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: t.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose a category and book in minutes.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: t.mutedText,
                    fontSize: 13,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HeroBadge(t: t, icon: Icons.flash_on_rounded, text: 'Fast booking'),
                    _HeroBadge(t: t, icon: Icons.verified_rounded, text: 'Trusted taskers'),
                    _HeroBadge(t: t, icon: Icons.support_agent_rounded, text: 'Support'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _HeroMark(t: t),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.t, required this.icon, required this.text});
  final _UiTokens t;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: t.primary.withOpacity(.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: t.primary.withOpacity(.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: t.primaryDark),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Poppins',
              color: t.primaryText,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMark extends StatelessWidget {
  const _HeroMark({required this.t});
  final _UiTokens t;

  @override
  Widget build(BuildContext context) {
    Widget pill(Color col, {double w = 76, double h = 18}) {
      return Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: col,
          borderRadius: BorderRadius.circular(999),
        ),
      );
    }

    return SizedBox(
      width: 90,
      height: 70,
      child: Stack(
        children: [
          Positioned(top: 6, right: 0, child: pill(t.primary.withOpacity(.35))),
          Positioned(top: 28, right: 10, child: pill(t.primary.withOpacity(.22), w: 60)),
          Positioned(top: 50, right: 4, child: pill(t.primary.withOpacity(.16), w: 46, h: 16)),
        ],
      ),
    );
  }
}

/* ============================== SEARCH ============================== */

class _SearchCardModern extends StatelessWidget {
  const _SearchCardModern({required this.t});
  final _UiTokens t;

  @override
  Widget build(BuildContext context) {
    return _Glass(
      radius: 18,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: t.primary.withOpacity(.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: t.primary.withOpacity(.12)),
              ),
              child: Icon(Icons.search_rounded, color: t.primaryDark),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                style: const TextStyle(fontFamily: 'Poppins'),
                decoration: InputDecoration(
                  hintText: 'Search for services...',
                  hintStyle: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.grey.shade500,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [t.primary, t.primaryDark],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.tune_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

/* ============================== INFO CARD ============================== */

class _InfoCardModern extends StatelessWidget {
  const _InfoCardModern({required this.t});
  final _UiTokens t;

  @override
  Widget build(BuildContext context) {
    return _Glass(
      radius: 18,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [t.primary.withOpacity(.20), t.primary.withOpacity(.06)],
                ),
                border: Border.all(color: t.primary.withOpacity(.12)),
              ),
              child: Icon(Icons.flash_on_rounded, color: t.primaryDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '1 active booking today. Tap to view or reschedule.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.8,
                  color: t.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: t.primaryDark),
          ],
        ),
      ),
    );
  }
}

/* ============================== CHIPS ============================== */

class _ChipPill extends StatelessWidget {
  const _ChipPill({
    required this.label,
    required this.selected,
    required this.t,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final _UiTokens t;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(colors: [t.primaryDark, t.primary])
              : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? Colors.transparent : t.primary.withOpacity(.18),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: t.primary.withOpacity(.22),
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(.03),
                    blurRadius: 14,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 16,
              color: selected ? Colors.white : t.primaryDark.withOpacity(.55),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: selected ? Colors.white : t.primaryDark,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ============================== SERVICE PILLS ============================== */

class _ServicePillTile extends StatelessWidget {
  const _ServicePillTile({
    required this.t,
    required this.text,
    required this.onTap,
  });

  final _UiTokens t;
  final String text;
  final VoidCallback onTap;

  IconData _pickIcon(String s) {
    final v = s.toLowerCase();
    if (v.contains('clean')) return Icons.cleaning_services_rounded;
    if (v.contains('ac')) return Icons.ac_unit_rounded;
    if (v.contains('plumb')) return Icons.plumbing_rounded;
    if (v.contains('electric')) return Icons.electrical_services_rounded;
    if (v.contains('car')) return Icons.directions_car_rounded;
    if (v.contains('garden')) return Icons.grass_rounded;
    return Icons.handyman_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: t.primary.withOpacity(.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.primary.withOpacity(.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: t.primary.withOpacity(.10)),
              ),
              child: Icon(_pickIcon(text), size: 16, color: t.primaryDark),
            ),
            const SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12.5,
                color: t.primaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ============================== ACTION CARDS ============================== */

class _ActionCardModern extends StatelessWidget {
  const _ActionCardModern({
    required this.t,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final _UiTokens t;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Glass(
      radius: 18,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: 118,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.first.withOpacity(.18),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13.8,
                  fontWeight: FontWeight.w900,
                  color: t.primaryText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11.8,
                  color: t.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ============================== POPULAR CARDS ============================== */

class _ServiceHorizontalCardModern extends StatelessWidget {
  const _ServiceHorizontalCardModern({
    required this.t,
    required this.title,
    required this.price,
    required this.icon,
    required this.accent,
  });

  final _UiTokens t;
  final String title;
  final String price;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: _Glass(
        radius: 20,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: accent.withOpacity(.12),
                      border: Border.all(color: accent.withOpacity(.20)),
                    ),
                    child: Icon(icon, color: accent, size: 20),
                  ),
                  const Spacer(),
                  Icon(Icons.star_rounded, size: 18, color: t.primary.withOpacity(.45)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w800,
                  color: t.primaryText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                price,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: t.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(Icons.location_on_rounded, size: 16, color: t.mutedText),
                  const SizedBox(width: 6),
                  Text(
                    'Nearby',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: t.mutedText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ============================== SMALL UI COMPONENTS ============================== */

class _IconGlassButton extends StatelessWidget {
  const _IconGlassButton({
    required this.t,
    required this.icon,
    required this.onTap,
  });

  final _UiTokens t;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Glass(
      radius: 16,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, color: t.primaryDark),
        ),
      ),
    );
  }
}

class _Glass extends StatelessWidget {
  const _Glass({required this.child, this.radius = 18});
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final t = _UiTokens.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(.92),
                Colors.white.withOpacity(.78),
              ],
            ),
            border: Border.all(color: t.primary.withOpacity(.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.05),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
*/




// keep your own imports here
// import 'package:taskoon/...';
/*
class UserBookingHome extends StatefulWidget {
  const UserBookingHome({super.key});

  @override
  State<UserBookingHome> createState() => _UserBookingHomeState();
}

class _UserBookingHomeState extends State<UserBookingHome>
    with WidgetsBindingObserver {
  final GetStorage _box = GetStorage();

  String? _selectedChip;
  CertificationGroup? _selectedGroup;
  ServiceDto? servicesdto;

  String? userId;
  String? name;

  static const String _baseUrl = ApiConfig.baseUrl;

  bool _hubConfigured = false;
  bool _hubConnecting = false;

  StreamSubscription? _hubSub;

  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    userId = _box.read('userId')?.toString();
    name = _box.read('name')?.toString() ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await _configureHubIfPossible();
      await _ensureHubConnected();
      _attachHubListener();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    if (state == AppLifecycleState.resumed) {
      debugPrint("🔁 UserBookingHome resumed -> ensure hub connected");
      _ensureHubConnected();
    }
  }

  Future<void> _configureHubIfPossible() async {
    final freshUserId = _box.read('userId')?.toString();
    if (freshUserId == null || freshUserId.trim().isEmpty) {
      debugPrint("❌ UserBookingHome: userId missing (user id not loaded)");
      return;
    }

    userId = freshUserId;

    if (_hubConfigured) return;

    debugPrint(
      "🧩 UserBookingHome: configuring hub baseUrl=$_baseUrl userId=$userId",
    );

    DispatchHubSingleton.instance.configure(
      baseUrl: _baseUrl,
      userId: userId!,
    );

    _hubConfigured = true;
  }

  Future<void> _ensureHubConnected() async {
    if (!_hubConfigured) {
      await _configureHubIfPossible();
      if (!_hubConfigured) return;
    }

    if (DispatchHubSingleton.instance.isConnected == true) {
      debugPrint("✅ UserBookingHome: hub already connected");
      return;
    }

    if (_hubConnecting) {
      debugPrint("⏳ UserBookingHome: hub connect already running, skip");
      return;
    }

    _hubConnecting = true;

    try {
      debugPrint(
        "🔌 UserBookingHome: ensureConnected() starting... "
        "isConnected(before)=${DispatchHubSingleton.instance.isConnected}",
      );

      await DispatchHubSingleton.instance.ensureConnected();

      final connected = DispatchHubSingleton.instance.isConnected == true;
      debugPrint(
        "✅ UserBookingHome: hub ensureConnected done. isConnected=$connected",
      );
    } catch (e, st) {
      debugPrint("❌ UserBookingHome: ensureConnected FAILED => $e");
      debugPrint("$st");
    } finally {
      _hubConnecting = false;
    }
  }

  void _attachHubListener() {
    _hubSub?.cancel();

    debugPrint("🧩 UserBookingHome: attaching hub notifications listener");

    _hubSub = DispatchHubSingleton.instance.notifications.listen(
      (payload) {
        debugPrint("📩 USER HUB: $payload");
      },
      onError: (e, st) {
        debugPrint("❌ USER HUB stream error => $e");
        debugPrint("$st");
      },
      onDone: () {
        debugPrint("⚠️ USER HUB stream closed");
      },
      cancelOnError: false,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hubSub?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _q => _query.trim().toLowerCase();

  @override
  Widget build(BuildContext context) {
    final t = _UiTokens.of(context);

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: t.bg,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      child: Scaffold(
        // appBar: _buildAppBarModern(t),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 64, 16, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HomeHeroCard(
                  t: t,
                  userName: name ?? '',
                ),
                const SizedBox(height: 14),

                _SearchCardModern(
                  t: t,
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  onClear: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                  showClear: _query.trim().isNotEmpty,
                ),
                const SizedBox(height: 14),

                _InfoCardModern(t: t),
                const SizedBox(height: 18),

                Text(
                  'What do you need today?',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    color: t.primaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),

                BlocBuilder<AuthenticationBloc, AuthenticationState>(
                  buildWhen: (p, c) =>
                      p.serviceGroups != c.serviceGroups ||
                      p.servicesStatus != c.servicesStatus,
                  builder: (context, state) {
                    final allGroups = state.serviceGroups;

                    final visibleGroups = _q.isEmpty
                        ? allGroups
                        : allGroups.where((g) {
                            final groupMatch = g.name.toLowerCase().contains(_q);
                            final serviceMatch = g.services.any(
                              (s) => s.name.toLowerCase().contains(_q),
                            );
                            return groupMatch || serviceMatch;
                          }).toList();

                    final chipLabels = visibleGroups.map((e) => e.name).toList();

                    if (visibleGroups.isNotEmpty) {
                      final selectedStillVisible =
                          _selectedChip != null &&
                          visibleGroups.any((g) => g.name == _selectedChip);

                      if (!selectedStillVisible) {
                        _selectedChip = visibleGroups.first.name;
                        _selectedGroup = visibleGroups.first;
                      } else {
                        _selectedGroup = visibleGroups.firstWhere(
                          (g) => g.name == _selectedChip,
                          orElse: () => visibleGroups.first,
                        );
                      }
                    } else {
                      _selectedChip = null;
                      _selectedGroup = null;
                    }

                    final selectedServices = (_selectedGroup == null)
                        ? <dynamic>[]
                        : (_q.isEmpty
                              ? _selectedGroup!.services
                              : _selectedGroup!.services
                                    .where(
                                      (svc) =>
                                          svc.name.toLowerCase().contains(_q),
                                    )
                                    .toList());

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 38,
                          child:
                              (state.servicesStatus == ServicesStatus.loading &&
                                      allGroups.isEmpty)
                                  ? _buildLoadingChipsModern(t)
                                  : ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: chipLabels.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 10),
                                      itemBuilder: (_, i) {
                                        final label = chipLabels[i];
                                        final sel = label == (_selectedChip ?? '');
                                        return _ChipPill(
                                          label: label,
                                          selected: sel,
                                          t: t,
                                          onTap: () {
                                            setState(() {
                                              _selectedChip = label;
                                              _selectedGroup =
                                                  visibleGroups.firstWhere(
                                                (g) => g.name == label,
                                                orElse: () =>
                                                    visibleGroups.first,
                                              );
                                            });
                                          },
                                        );
                                      },
                                    ),
                        ),
                        if (_selectedGroup != null &&
                            selectedServices.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.grid_view_rounded,
                                size: 18,
                                color: t.mutedText,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Services in "${_selectedGroup!.name}"',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    color: t.mutedText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: selectedServices.map((svc) {
                              return _ServicePillTile(
                                t: t,
                                text: svc.name,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ServiceBookingFormScreen(
                                        group: _selectedGroup!,
                                        initialService: svc,
                                        serviceId: svc.id,
                                      ),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    );
                  },
                ),

                const SizedBox(height: 18),
                _buildActionRowModern(context, t),
                const SizedBox(height: 20),
                _buildPopularModern(context, t),
                const SizedBox(height: 20),
                _buildRecentModern(context, t),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBarModern(_UiTokens t) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(102),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: _Glass(
                  radius: 18,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                    child: Row(
                      children: [
                        const SizedBox(width: 10),
                        Expanded(child: GreetingText(name: name ?? '')),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _IconGlassButton(
                t: t,
                icon: Icons.notifications_none_rounded,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingChipsModern(_UiTokens t) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemBuilder: (_, __) => Container(
        width: 88,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: t.primary.withOpacity(.10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.04),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Align(
          alignment: Alignment.center,
          child: Container(
            width: 40,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(.06),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemCount: 4,
    );
  }

  Widget _buildActionRowModern(BuildContext context, _UiTokens t) {
    return Row(
      children: [
        Expanded(
          child: _ActionCardModern(
            t: t,
            title: 'Book a service',
            subtitle: 'Schedule instantly',
            icon: Icons.event_available_rounded,
            gradient: [t.primary, t.primaryDark],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ServiceCertificatesGridScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCardModern(
            t: t,
            title: 'Track booking',
            subtitle: 'See status',
            icon: Icons.radar_rounded,
            gradient: [const Color(0xFF3DB38D), const Color(0xFF1E8F6D)],
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildPopularModern(BuildContext context, _UiTokens t) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Popular near you',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: t.primaryText,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ServiceCertificatesGridScreen(),
                  ),
                );
              },
              icon: Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: t.primary,
              ),
              label: Text(
                'View all',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: t.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 160,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _ServiceHorizontalCardModern(
                t: t,
                title: 'House cleaning',
                price: 'From \$45',
                icon: Icons.cleaning_services_rounded,
                accent: t.primary,
              ),
              _ServiceHorizontalCardModern(
                t: t,
                title: 'AC repair',
                price: 'From \$60',
                icon: Icons.ac_unit_rounded,
                accent: const Color(0xFF3DB38D),
              ),
              _ServiceHorizontalCardModern(
                t: t,
                title: 'Furniture assemble',
                price: 'From \$35',
                icon: Icons.chair_alt_rounded,
                accent: const Color(0xFFEE8A41),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentModern(BuildContext context, _UiTokens t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent activity',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            color: t.primaryText,
          ),
        ),
        const SizedBox(height: 12),
        _Glass(
          radius: 22,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: t.primary.withOpacity(.10),
                    border: Border.all(color: t.primary.withOpacity(.12)),
                  ),
                  child: Icon(Icons.inbox_rounded, color: t.primaryDark),
                ),
                const SizedBox(height: 10),
                Text(
                  'No bookings yet',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w800,
                    color: t.primaryText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Book a task to see it here.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12.5,
                    color: t.mutedText,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ServiceCertificatesGridScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: t.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text(
                      'Start booking',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w900,
                        letterSpacing: .2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _UiTokens {
  final Color primary;
  final Color primaryDark;
  final Color primaryText;
  final Color mutedText;
  final Color bg;

  const _UiTokens({
    required this.primary,
    required this.primaryDark,
    required this.primaryText,
    required this.mutedText,
    required this.bg,
  });

  static _UiTokens of(BuildContext context) => const _UiTokens(
        primary: Color(0xFF7841BA),
        primaryDark: Color(0xFF5C2E91),
        primaryText: Color(0xFF3E1E69),
        mutedText: Color(0xFF75748A),
        bg: Color(0xFFF8F7FB),
      );
}

class _HomeHeroCard extends StatelessWidget {
  const _HomeHeroCard({
    required this.t,
    required this.userName,
  });

  final _UiTokens t;
  final String userName;

  String _firstName(String v) {
    final s = v.trim();
    if (s.isEmpty) return '';
    return s.split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context) {
    final fn = _firstName(userName);
    final greet = fn.isEmpty ? 'Find the right tasker 👋' : 'Hi, $fn 👋';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            t.primary.withOpacity(.14),
            t.primary.withOpacity(.06),
            Colors.white,
          ],
        ),
        border: Border.all(color: t.primary.withOpacity(.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greet,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: t.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .2,
                  ),
                ),
                Text(
                  'Find the right tasker 👋',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: t.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose a category and book in minutes.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: t.mutedText,
                    fontSize: 13,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HeroBadge(
                      t: t,
                      icon: Icons.flash_on_rounded,
                      text: 'Instant booking in minutes',
                    ),
                    _HeroBadge(
                      t: t,
                      icon: Icons.verified_rounded,
                      text: 'Top-rated taskers with real reviews',
                    ),
                    _HeroBadge(
                      t: t,
                      icon: Icons.support_agent_rounded,
                      text: 'Customer support when you need it',
                    ),
                    _HeroBadge(
                      t: t,
                      icon: Icons.badge_rounded,
                      text: 'ID verified for safety',
                    ),
                    _HeroBadge(
                      t: t,
                      icon: Icons.shield_rounded,
                      text: 'Police check',
                    ),
                    _HeroBadge(
                      t: t,
                      icon: Icons.schedule_rounded,
                      text:
                          'ASAP • Future • Multi-day • Daily \nWeekly • Monthly • Custom days',
                    ),
                    _HeroBadge(
                      t: t,
                      icon: Icons.payments_rounded,
                      text: 'Secure payments & transparent\npricing',
                    ),
                    _HeroBadge(
                      t: t,
                      icon: Icons.location_on_rounded,
                      text: 'Nearby taskers matched fast',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({
    required this.t,
    required this.icon,
    required this.text,
  });

  final _UiTokens t;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: t.primary.withOpacity(.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: t.primary.withOpacity(.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: t.primaryDark),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Poppins',
              color: t.primaryText,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMark extends StatelessWidget {
  const _HeroMark({required this.t});
  final _UiTokens t;

  @override
  Widget build(BuildContext context) {
    Widget pill(Color col, {double w = 76, double h = 18}) {
      return Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: col,
          borderRadius: BorderRadius.circular(999),
        ),
      );
    }

    return SizedBox(
      width: 90,
      height: 70,
      child: Stack(
        children: [
          Positioned(top: 6, right: 0, child: pill(t.primary.withOpacity(.35))),
          Positioned(
            top: 28,
            right: 10,
            child: pill(t.primary.withOpacity(.22), w: 60),
          ),
          Positioned(
            top: 50,
            right: 4,
            child: pill(t.primary.withOpacity(.16), w: 46, h: 16),
          ),
        ],
      ),
    );
  }
}

class _SearchCardModern extends StatelessWidget {
  const _SearchCardModern({
    required this.t,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.showClear,
  });

  final _UiTokens t;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool showClear;

  @override
  Widget build(BuildContext context) {
    return _Glass(
      radius: 18,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: t.primary.withOpacity(.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: t.primary.withOpacity(.12)),
              ),
              child: Icon(Icons.search_rounded, color: t.primaryDark),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: const TextStyle(fontFamily: 'Poppins'),
                decoration: InputDecoration(
                  hintText: 'Search for services...',
                  hintStyle: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.grey.shade500,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(width: 6),
            if (showClear)
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onClear,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: t.mutedText,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [t.primary, t.primaryDark],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.tune_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCardModern extends StatelessWidget {
  const _InfoCardModern({required this.t});
  final _UiTokens t;

  @override
  Widget build(BuildContext context) {
    return _Glass(
      radius: 18,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    t.primary.withOpacity(.20),
                    t.primary.withOpacity(.06),
                  ],
                ),
                border: Border.all(color: t.primary.withOpacity(.12)),
              ),
              child: Icon(Icons.flash_on_rounded, color: t.primaryDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '1 active booking today. Tap to view or reschedule.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.8,
                  color: t.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: t.primaryDark),
          ],
        ),
      ),
    );
  }
}

class _ChipPill extends StatelessWidget {
  const _ChipPill({
    required this.label,
    required this.selected,
    required this.t,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final _UiTokens t;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient:
              selected ? LinearGradient(colors: [t.primaryDark, t.primary]) : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? Colors.transparent : t.primary.withOpacity(.18),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: t.primary.withOpacity(.22),
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(.03),
                    blurRadius: 14,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 16,
              color: selected ? Colors.white : t.primaryDark.withOpacity(.55),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: selected ? Colors.white : t.primaryDark,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServicePillTile extends StatelessWidget {
  const _ServicePillTile({
    required this.t,
    required this.text,
    required this.onTap,
  });

  final _UiTokens t;
  final String text;
  final VoidCallback onTap;

  IconData _pickIcon(String s) {
    final v = s.toLowerCase();
    if (v.contains('clean')) return Icons.cleaning_services_rounded;
    if (v.contains('ac')) return Icons.ac_unit_rounded;
    if (v.contains('plumb')) return Icons.plumbing_rounded;
    if (v.contains('electric')) return Icons.electrical_services_rounded;
    if (v.contains('car')) return Icons.directions_car_rounded;
    if (v.contains('garden')) return Icons.grass_rounded;
    return Icons.handyman_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: t.primary.withOpacity(.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.primary.withOpacity(.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: t.primary.withOpacity(.10)),
              ),
              child: Icon(_pickIcon(text), size: 16, color: t.primaryDark),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                softWrap: true,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.5,
                  color: t.primaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCardModern extends StatelessWidget {
  const _ActionCardModern({
    required this.t,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final _UiTokens t;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Glass(
      radius: 18,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: 118,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.first.withOpacity(.18),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13.8,
                  fontWeight: FontWeight.w900,
                  color: t.primaryText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11.8,
                  color: t.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceHorizontalCardModern extends StatelessWidget {
  const _ServiceHorizontalCardModern({
    required this.t,
    required this.title,
    required this.price,
    required this.icon,
    required this.accent,
  });

  final _UiTokens t;
  final String title;
  final String price;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: _Glass(
        radius: 20,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: accent.withOpacity(.12),
                      border: Border.all(color: accent.withOpacity(.20)),
                    ),
                    child: Icon(icon, color: accent, size: 20),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.star_rounded,
                    size: 18,
                    color: t.primary.withOpacity(.45),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w800,
                  color: t.primaryText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                price,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: t.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(Icons.location_on_rounded, size: 16, color: t.mutedText),
                  const SizedBox(width: 6),
                  Text(
                    'Nearby',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: t.mutedText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconGlassButton extends StatelessWidget {
  const _IconGlassButton({
    required this.t,
    required this.icon,
    required this.onTap,
  });

  final _UiTokens t;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Glass(
      radius: 16,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, color: t.primaryDark),
        ),
      ),
    );
  }
}

class _Glass extends StatelessWidget {
  const _Glass({required this.child, this.radius = 18});

  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final t = _UiTokens.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(.92),
                Colors.white.withOpacity(.78),
              ],
            ),
            border: Border.all(color: t.primary.withOpacity(.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.05),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}


*/
































// final box = GetStorage();
// var userId = box.read('userId');
// var name = box.read("name");

// class UserBookingHome extends StatefulWidget {
//   const UserBookingHome({super.key});

//   @override
//   State<UserBookingHome> createState() => _UserBookingHomeState();
// }

// class _UserBookingHomeState extends State<UserBookingHome>
//     with WidgetsBindingObserver {
//   String? _selectedChip;
//   CertificationGroup? _selectedGroup;
//   ServiceDto? servicesdto;

//   static const String _baseUrl = ApiConfig.baseUrl; //"https://api.taskoon.com";

//   bool _hubConfigured = false;

//   StreamSubscription? _hubSub;
//   Timer? _hubWatchdog;

//   bool _hubConnecting = false;

//   int _reconnectAttempt = 0;
//   Timer? _reconnectTimer;

//   // ✅ SEARCH STATE (only functionality, UI stays the same)
//   final TextEditingController _searchCtrl = TextEditingController();
//   String _query = '';

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);

//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       if (!mounted) return;

//       await _configureHubIfPossible();
//       await _ensureHubConnected(force: true);
//       _attachHubListener();
//       _startHubWatchdog();
//     });
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (!mounted) return;

//     if (state == AppLifecycleState.resumed) {
//       debugPrint("🔁 UserBookingHome resumed -> ensure hub connected");
//       _configureHubIfPossible().then((_) => _ensureHubConnected(force: true));
//     }
//   }

//   Future<void> _configureHubIfPossible() async {
//     if (userId == null) {
//       debugPrint("❌ UserBookingHome: userId missing (user id not loaded)");
//       return;
//     }

//     if (_hubConfigured) return;

//     debugPrint(
//       "🧩 UserBookingHome: configuring hub baseUrl=$_baseUrl userId=$userId",
//     );

//     DispatchHubSingleton.instance.configure(baseUrl: _baseUrl, userId: userId);

//     _hubConfigured = true;
//   }

//   Future<void> _ensureHubConnected({bool force = false}) async {
//     if (!_hubConfigured) {
//       await _configureHubIfPossible();
//       if (!_hubConfigured) return;
//     }

//     if (!force && DispatchHubSingleton.instance.isConnected == true) {
//       return;
//     }

//     if (_hubConnecting) {
//       debugPrint("⏳ UserBookingHome: hub connect already running, skip");
//       return;
//     }

//     _hubConnecting = true;
//     _reconnectTimer?.cancel();
//     _reconnectTimer = null;

//     try {
//       debugPrint(
//         "🔌 UserBookingHome: ensureConnected() starting... "
//         "isConnected(before)=${DispatchHubSingleton.instance.isConnected}",
//       );

//       await DispatchHubSingleton.instance.ensureConnected();

//       final connected = DispatchHubSingleton.instance.isConnected == true;
//       debugPrint(
//         "✅ UserBookingHome: hub ensureConnected done. isConnected=$connected",
//       );

//       if (!connected) {
//         _scheduleReconnect("ensureConnected returned but still disconnected");
//       } else {
//         _reconnectAttempt = 0;
//       }
//     } catch (e, st) {
//       debugPrint("❌ UserBookingHome: ensureConnected FAILED => $e");
//       debugPrint("$st");
//       _scheduleReconnect("exception");
//     } finally {
//       _hubConnecting = false;
//     }
//   }

//   void _scheduleReconnect(String reason) {
//     _reconnectAttempt++;
//     final seconds = (_reconnectAttempt <= 1)
//         ? 2
//         : (_reconnectAttempt == 2)
//         ? 4
//         : (_reconnectAttempt == 3)
//         ? 8
//         : (_reconnectAttempt == 4)
//         ? 16
//         : 30;

//     debugPrint(
//       "🛡️ HUB WATCHDOG: disconnected -> reconnecting... "
//       "reason=$reason attempt=$_reconnectAttempt in ${seconds}s",
//     );

//     _reconnectTimer?.cancel();
//     _reconnectTimer = Timer(Duration(seconds: seconds), () {
//       if (!mounted) return;
//       _ensureHubConnected(force: true);
//     });
//   }

//   void _startHubWatchdog() {
//     _hubWatchdog?.cancel();
//     _hubWatchdog = Timer.periodic(const Duration(seconds: 3), (_) {
//       if (!mounted) return;

//       if (!_hubConfigured) {
//         _configureHubIfPossible();
//         return;
//       }

//       final isConnected = DispatchHubSingleton.instance.isConnected == true;

//       if (!isConnected) {
//         if (_hubConnecting) return;
//         _scheduleReconnect("watchdog detected disconnected");
//       }
//     });
//   }

//   void _attachHubListener() {
//     _hubSub?.cancel();

//     debugPrint("🧩 UserBookingHome: attaching hub notifications listener");

//     _hubSub = DispatchHubSingleton.instance.notifications.listen(
//       (payload) {
//         debugPrint("📩 USER HUB: $payload");
//       },
//       onError: (e) {
//         debugPrint("❌ USER HUB stream error => $e");
//         _scheduleReconnect("stream error");
//       },
//       onDone: () {
//         debugPrint("⚠️ USER HUB stream closed");
//         _scheduleReconnect("stream closed");
//       },
//     );
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);

//     _hubSub?.cancel();
//     _hubWatchdog?.cancel();
//     _reconnectTimer?.cancel();

//     _searchCtrl.dispose();

//     super.dispose();
//   }

//   // ✅ helper: normalized query
//   String get _q => _query.trim().toLowerCase();

//   @override
//   Widget build(BuildContext context) {
//     final t = _UiTokens.of(context);

//     return Theme(
//       data: Theme.of(context).copyWith(
//         scaffoldBackgroundColor: t.bg,
//         appBarTheme: const AppBarTheme(
//           backgroundColor: Colors.transparent,
//           surfaceTintColor: Colors.transparent,
//           elevation: 0,
//         ),
//       ),
//       child: Scaffold(
//        // appBar: _buildAppBarModern(t),
//         body: SafeArea(
//           top: false,
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.fromLTRB(16, 64, 16, 110),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [

//                 _HomeHeroCard(t: t,userName: name,),
//                 const SizedBox(height: 14),

//                 // ✅ search (NOW WORKS)
//                 _SearchCardModern(
//                   t: t,
//                   controller: _searchCtrl,
//                   onChanged: (v) => setState(() => _query = v),
//                   onClear: () {
//                     _searchCtrl.clear();
//                     setState(() => _query = '');
//                   },
//                   showClear: _query.trim().isNotEmpty,
//                 ),
//                 const SizedBox(height: 14),

//                 _InfoCardModern(t: t),
//                 const SizedBox(height: 18),

//                 Text(
//                   'What do you need today?',
//                   style: TextStyle(
//                     fontFamily: 'Poppins',
//                     fontSize: 16,
//                     color: t.primaryText,
//                     fontWeight: FontWeight.w800,
//                   ),
//                 ),
//                 const SizedBox(height: 10),

//                 BlocBuilder<AuthenticationBloc, AuthenticationState>(
//                   buildWhen: (p, c) =>
//                       p.serviceGroups != c.serviceGroups ||
//                       p.servicesStatus != c.servicesStatus,
//                   builder: (context, state) {
//                     final allGroups = state.serviceGroups;

//                     // ✅ FILTER GROUPS BY SEARCH (group name OR any service name)
//                     final visibleGroups = _q.isEmpty
//                         ? allGroups
//                         : allGroups.where((g) {
//                             final groupMatch = g.name.toLowerCase().contains(
//                               _q,
//                             );
//                             final serviceMatch = g.services.any(
//                               (s) => s.name.toLowerCase().contains(_q),
//                             );
//                             return groupMatch || serviceMatch;
//                           }).toList();

//                     final chipLabels = visibleGroups
//                         .map((e) => e.name)
//                         .toList();

//                     // ✅ keep selection valid without changing UI/behavior
//                     if (visibleGroups.isNotEmpty) {
//                       final selectedStillVisible =
//                           _selectedChip != null &&
//                           visibleGroups.any((g) => g.name == _selectedChip);

//                       if (!selectedStillVisible) {
//                         _selectedChip = visibleGroups.first.name;
//                         _selectedGroup = visibleGroups.first;
//                       } else {
//                         // refresh reference to selected group from visible list
//                         _selectedGroup = visibleGroups.firstWhere(
//                           (g) => g.name == _selectedChip,
//                           orElse: () => visibleGroups.first,
//                         );
//                       }
//                     } else {
//                       _selectedChip = null;
//                       _selectedGroup = null;
//                     }

//                     // ✅ FILTER SERVICES INSIDE SELECTED GROUP BY SEARCH
//                     final selectedServices = (_selectedGroup == null)
//                         ? <dynamic>[]
//                         : (_q.isEmpty
//                               ? _selectedGroup!.services
//                               : _selectedGroup!.services
//                                     .where(
//                                       (svc) =>
//                                           svc.name.toLowerCase().contains(_q),
//                                     )
//                                     .toList());

//                     return Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         SizedBox(
//                           height: 38,
//                           child:
//                               (state.servicesStatus == ServicesStatus.loading &&
//                                   allGroups.isEmpty)
//                               ? _buildLoadingChipsModern(t)
//                               : ListView.separated(
//                                   scrollDirection: Axis.horizontal,
//                                   itemCount: chipLabels.length,
//                                   separatorBuilder: (_, __) =>
//                                       const SizedBox(width: 10),
//                                   itemBuilder: (_, i) {
//                                     final label = chipLabels[i];
//                                     final sel = label == (_selectedChip ?? '');
//                                     return _ChipPill(
//                                       label: label,
//                                       selected: sel,
//                                       t: t,
//                                       onTap: () {
//                                         setState(() {
//                                           _selectedChip = label;
//                                           _selectedGroup = visibleGroups
//                                               .firstWhere(
//                                                 (g) => g.name == label,
//                                                 orElse: () =>
//                                                     visibleGroups.first,
//                                               );
//                                         });
//                                       },
//                                     );
//                                   },
//                                 ),
//                         ),

//                         if (_selectedGroup != null &&
//                             selectedServices.isNotEmpty) ...[
//                           const SizedBox(height: 12),
//                           Row(
//                             children: [
//                               Icon(
//                                 Icons.grid_view_rounded,
//                                 size: 18,
//                                 color: t.mutedText,
//                               ),
//                               const SizedBox(width: 8),
//                               Expanded(
//                                 child: Text(
//                                   'Services in "${_selectedGroup!.name}"',
//                                   style: TextStyle(
//                                     fontFamily: 'Poppins',
//                                     fontSize: 13,
//                                     color: t.mutedText,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 10),

//                           Wrap(
//                             spacing: 10,
//                             runSpacing: 10,
//                             children: selectedServices.map((svc) {
//                               return _ServicePillTile(
//                                 t: t,
//                                 text: svc.name,
//                                 onTap: () {
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder: (_) => ServiceBookingFormScreen(
//                                         group: _selectedGroup!,
//                                         initialService: svc,
//                                         serviceId: svc.id,
//                                       ),
//                                     ),
//                                   );
//                                 },
//                               );
//                             }).toList(),
//                           ),
//                         ],

//                         // Optional: if search yields nothing, show nothing (no UI change)
//                       ],
//                     );
//                   },
//                 ),

//                 const SizedBox(height: 18),
//                 _buildActionRowModern(context, t),
//                 const SizedBox(height: 20),
//                 _buildPopularModern(context, t),
//                 const SizedBox(height: 20),
//                 _buildRecentModern(t),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   PreferredSizeWidget _buildAppBarModern(_UiTokens t) {
//     return PreferredSize(
//       preferredSize: const Size.fromHeight(102),
//       child: SafeArea(
//         bottom: false,
//         child: Padding(
//           padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
//           child: Row(
//             children: [
//               Expanded(
//                 child: _Glass(
//                   radius: 18,
//                   child: Padding(
//                     padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
//                     child: Row(
//                       children: [
//                         const SizedBox(width: 10),
//                         Expanded(child: GreetingText(name: name)),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 10),
//               _IconGlassButton(
//                 t: t,
//                 icon: Icons.notifications_none_rounded,
//                 onTap: () {},
//               ),
//               // const SizedBox(width: 10),
//               // const CircleAvatar(
//               //   radius: 19,
//               //   backgroundImage: NetworkImage(
//               //     'https://images.unsplash.com/photo-1607746882042-944635dfe10e?q=80&w=256&auto=format&fit=crop',
//               //   ),
//               // ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // ==================== UI SECTIONS (same as your code) ====================

//   Widget _buildLoadingChipsModern(_UiTokens t) {
//     return ListView.separated(
//       scrollDirection: Axis.horizontal,
//       itemBuilder: (_, __) => Container(
//         width: 88,
//         height: 34,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(999),
//           border: Border.all(color: t.primary.withOpacity(.10)),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(.04),
//               blurRadius: 16,
//               offset: const Offset(0, 10),
//             ),
//           ],
//         ),
//         child: Align(
//           alignment: Alignment.center,
//           child: Container(
//             width: 40,
//             height: 10,
//             decoration: BoxDecoration(
//               color: Colors.black.withOpacity(.06),
//               borderRadius: BorderRadius.circular(999),
//             ),
//           ),
//         ),
//       ),
//       separatorBuilder: (_, __) => const SizedBox(width: 10),
//       itemCount: 4,
//     );
//   }

//   Widget _buildActionRowModern(BuildContext context, _UiTokens t) {
//     return Row(
//       children: [
//         Expanded(
//           child: _ActionCardModern(
//             t: t,
//             title: 'Book a service',
//             subtitle: 'Schedule instantly',
//             icon: Icons.event_available_rounded,
//             gradient: [t.primary, t.primaryDark],
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => const ServiceCertificatesGridScreen(),
//                 ),
//               );
//             },
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: _ActionCardModern(
//             t: t,
//             title: 'Track booking',
//             subtitle: 'See status',
//             icon: Icons.radar_rounded,
//             gradient: [const Color(0xFF3DB38D), const Color(0xFF1E8F6D)],
//             onTap: () {},
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildPopularModern(BuildContext context, _UiTokens t) {
//     return Column(
//       children: [
//         Row(
//           children: [
//             Expanded(
//               child: Text(
//                 'Popular near you',
//                 style: TextStyle(
//                   fontFamily: 'Poppins',
//                   fontSize: 15.5,
//                   fontWeight: FontWeight.w800,
//                   color: t.primaryText,
//                 ),
//               ),
//             ),
//             TextButton.icon(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => const ServiceCertificatesGridScreen(),
//                   ),
//                 );
//               },
//               icon: Icon(
//                 Icons.arrow_forward_rounded,
//                 size: 16,
//                 color: t.primary,
//               ),
//               label: Text(
//                 'View all',
//                 style: TextStyle(
//                   fontFamily: 'Poppins',
//                   color: t.primary,
//                   fontWeight: FontWeight.w800,
//                 ),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 10),
//         SizedBox(
//           height: 160,
//           child: ListView(
//             scrollDirection: Axis.horizontal,
//             children: [
//               _ServiceHorizontalCardModern(
//                 t: t,
//                 title: 'House cleaning',
//                 price: 'From \$45',
//                 icon: Icons.cleaning_services_rounded,
//                 accent: t.primary,
//               ),
//               _ServiceHorizontalCardModern(
//                 t: t,
//                 title: 'AC repair',
//                 price: 'From \$60',
//                 icon: Icons.ac_unit_rounded,
//                 accent: const Color(0xFF3DB38D),
//               ),
//               _ServiceHorizontalCardModern(
//                 t: t,
//                 title: 'Furniture assemble',
//                 price: 'From \$35',
//                 icon: Icons.chair_alt_rounded,
//                 accent: const Color(0xFFEE8A41),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildRecentModern(_UiTokens t) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Recent activity',
//           style: TextStyle(
//             fontFamily: 'Poppins',
//             fontSize: 15.5,
//             fontWeight: FontWeight.w800,
//             color: t.primaryText,
//           ),
//         ),
//         const SizedBox(height: 12),
//         _Glass(
//           radius: 22,
//           child: Padding(
//             padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
//             child: Column(
//               children: [
//                 Container(
//                   width: 52,
//                   height: 52,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(18),
//                     color: t.primary.withOpacity(.10),
//                     border: Border.all(color: t.primary.withOpacity(.12)),
//                   ),
//                   child: Icon(Icons.inbox_rounded, color: t.primaryDark),
//                 ),
//                 const SizedBox(height: 10),
//                 Text(
//                   'No bookings yet',
//                   style: TextStyle(
//                     fontFamily: 'Poppins',
//                     fontWeight: FontWeight.w800,
//                     color: t.primaryText,
//                   ),
//                 ),
//                 const SizedBox(height: 6),
//                 Text(
//                   'Book a task to see it here.',
//                   style: TextStyle(
//                     fontFamily: 'Poppins',
//                     fontSize: 12.5,
//                     color: t.mutedText,
//                     fontWeight: FontWeight.w600,
//                     height: 1.25,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 12),
//                 SizedBox(
//                   width: double.infinity,
//                   height: 44,
//                   child: ElevatedButton.icon(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => const ServiceCertificatesGridScreen(),
//                         ),
//                       );
//                     },
//                     style: ElevatedButton.styleFrom(
//                       elevation: 0,
//                       backgroundColor: t.primary,
//                       foregroundColor: Colors.white,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                     ),
//                     icon: const Icon(Icons.add_rounded, size: 18),
//                     label: const Text(
//                       'Start booking',
//                       style: TextStyle(
//                         fontFamily: 'Poppins',
//                         fontWeight: FontWeight.w900,
//                         letterSpacing: .2,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// /* ============================== TOKENS ============================== */

// class _UiTokens {
//   final Color primary;
//   final Color primaryDark;
//   final Color primaryText;
//   final Color mutedText;
//   final Color bg;

//   const _UiTokens({
//     required this.primary,
//     required this.primaryDark,
//     required this.primaryText,
//     required this.mutedText,
//     required this.bg,
//   });

//   static _UiTokens of(BuildContext context) => const _UiTokens(
//     primary: Color(0xFF7841BA),
//     primaryDark: Color(0xFF5C2E91),
//     primaryText: Color(0xFF3E1E69),
//     mutedText: Color(0xFF75748A),
//     bg: Color(0xFFF8F7FB),
//   );
// }

// /* ============================== HERO ============================== */
// class _HomeHeroCard extends StatelessWidget {
//   const _HomeHeroCard({
//     required this.t,
//     required this.userName,
//   });

//   final _UiTokens t;
//   final String userName;

//   String _firstName(String v) {
//     final s = v.trim();
//     if (s.isEmpty) return '';
//     return s.split(RegExp(r'\s+')).first;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final fn = _firstName(userName);
//     final greet = fn.isEmpty ? 'Find the right tasker 👋' : 'Hi, $fn 👋';

//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(24),
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [
//             t.primary.withOpacity(.14),
//             t.primary.withOpacity(.06),
//             Colors.white,
//           ],
//         ),
//         border: Border.all(color: t.primary.withOpacity(.14)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(.05),
//             blurRadius: 22,
//             offset: const Offset(0, 12),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   greet,
//                   style: TextStyle(
//                     fontFamily: 'Poppins',
//                     color: t.primaryText,
//                     fontSize: 18,
//                     fontWeight: FontWeight.w900,
//                     letterSpacing: .2,
//                   ),
//                 ),
//                 Text( 'Find the right tasker 👋', style: TextStyle( fontFamily: 'Poppins', color: t.primaryText, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: .2, ), ),
//                 const SizedBox(height: 6),
//                 Text(
//                   'Choose a category and book in minutes.',
//                   style: TextStyle(
//                     fontFamily: 'Poppins',
//                     color: t.mutedText,
//                     fontSize: 13,
//                     height: 1.2,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 Wrap(
//                   spacing: 8,
//                   runSpacing: 8,
//                   children: [
//                     _HeroBadge(t: t, icon: Icons.flash_on_rounded, text: 'Instant booking in minutes'),
//                     _HeroBadge(t: t, icon: Icons.verified_rounded, text: 'Top-rated taskers with real reviews'),
//                     _HeroBadge(t: t, icon: Icons.support_agent_rounded, text: 'Customer support when you need it'),
//                     _HeroBadge(t: t, icon: Icons.badge_rounded, text: 'ID verified for safety'),
//                     _HeroBadge(t: t, icon: Icons.shield_rounded, text: 'Police check'),
//                     _HeroBadge(
//                       t: t,
//                       icon: Icons.schedule_rounded,
//                       text: 'ASAP • Future • Multi-day • Daily \nWeekly • Monthly • Custom days',
//                     ),
//                     _HeroBadge(t: t, icon: Icons.payments_rounded, text: 'Secure payments & transparent\npricing'),
//                     _HeroBadge(t: t, icon: Icons.location_on_rounded, text: 'Nearby taskers matched fast'),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(width: 10),
//         ],
//       ),
//     );
//   }
// }

// /*
// class _HomeHeroCard extends StatelessWidget {
//   const _HomeHeroCard({required this.t});
//   final _UiTokens t;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(24),
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [
//             t.primary.withOpacity(.14),
//             t.primary.withOpacity(.06),
//             Colors.white,
//           ],
//         ),
//         border: Border.all(color: t.primary.withOpacity(.14)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(.05),
//             blurRadius: 22,
//             offset: const Offset(0, 12),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Find the right tasker 👋',
//                   style: TextStyle(
//                     fontFamily: 'Poppins',
//                     color: t.primaryText,
//                     fontSize: 18,
//                     fontWeight: FontWeight.w900,
//                     letterSpacing: .2,
//                   ),
//                 ),
//                 const SizedBox(height: 6),
//                 Text(
//                   'Choose a category and book in minutes.',
//                   style: TextStyle(
//                     fontFamily: 'Poppins',
//                     color: t.mutedText,
//                     fontSize: 13,
//                     height: 1.2,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 Wrap(
//                   spacing: 8,
//                   runSpacing: 8,
//                   children: [
//                     _HeroBadge(
//                       t: t,
//                       icon: Icons.flash_on_rounded,
//                       text: 'Instant booking in minutes',
//                     ),
//                     _HeroBadge(
//                       t: t,
//                       icon: Icons.verified_rounded,
//                       text: 'Top-rated taskers with real reviews',
//                     ),
//                     _HeroBadge(
//                       t: t,
//                       icon: Icons.support_agent_rounded,
//                       text: 'Customer support when you need it',
//                     ),
//                     _HeroBadge(
//                       t: t,
//                       icon: Icons.badge_rounded,
//                       text: 'ID verified for safety',
//                     ),
//                     _HeroBadge(
//                       t: t,
//                       icon: Icons.shield_rounded, // ✅ (instead of shield_moon)
//                       text: 'Police check',
//                     ),
//                     _HeroBadge(
//                       t: t,
//                       icon: Icons.schedule_rounded,
//                       text:
//                           'ASAP • Future • Multi-day • Daily \nWeekly • Monthly • Custom days',
//                     ),
//                     _HeroBadge(
//                       t: t,
//                       icon: Icons.payments_rounded,
//                       text: 'Secure payments & transparent\npricing',
//                     ),
//                     _HeroBadge(
//                       t: t,
//                       icon: Icons.location_on_rounded,
//                       text: 'Nearby taskers matched fast',
//                     ),
//                   ],
//                 ),

//                 /*  Wrap(
//                   spacing: 8,
//                   runSpacing: 8,
//                   children: [
//                     _HeroBadge(
//                         t: t, icon: Icons.flash_on_rounded, text: 'Fast booking'),
//                     _HeroBadge(
//                         t: t,
//                         icon: Icons.verified_rounded,
//                         text: 'Trusted taskers'),
//                     _HeroBadge(
//                         t: t,
//                         icon: Icons.support_agent_rounded,
//                         text: 'Customer Support'),
//                         _HeroBadge(
//                         t: t,
//                         icon: Icons.verified,
//                         text: 'ID Verified'),
//                         _HeroBadge(
//                         t: t,
//                         icon: Icons.shield_moon,
//                         text: 'Police Check'),
//                           _HeroBadge(
//                         t: t,
//                         icon: Icons.schedule,
//                         text: 'ASAP • Future • Multi-Day • Daily • Weekly\n• Monthly • Custom Days'),


//                   ],
//                 ),*/
//               ],
//             ),
//           ),
//           const SizedBox(width: 10),
//         ],
//       ),
//     );
//   }
// }*/
// class _HeroBadge extends StatelessWidget {
//   const _HeroBadge({required this.t, required this.icon, required this.text});
//   final _UiTokens t;
//   final IconData icon;
//   final String text;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
//       decoration: BoxDecoration(
//         color: t.primary.withOpacity(.08),
//         borderRadius: BorderRadius.circular(999),
//         border: Border.all(color: t.primary.withOpacity(.14)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 16, color: t.primaryDark),
//           const SizedBox(width: 6),
//           Text(
//             text,
//             style: TextStyle(
//               fontFamily: 'Poppins',
//               color: t.primaryText,
//               fontWeight: FontWeight.w800,
//               fontSize: 12,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _HeroMark extends StatelessWidget {
//   const _HeroMark({required this.t});
//   final _UiTokens t;

//   @override
//   Widget build(BuildContext context) {
//     Widget pill(Color col, {double w = 76, double h = 18}) {
//       return Container(
//         width: w,
//         height: h,
//         decoration: BoxDecoration(
//           color: col,
//           borderRadius: BorderRadius.circular(999),
//         ),
//       );
//     }

//     return SizedBox(
//       width: 90,
//       height: 70,
//       child: Stack(
//         children: [
//           Positioned(top: 6, right: 0, child: pill(t.primary.withOpacity(.35))),
//           Positioned(
//             top: 28,
//             right: 10,
//             child: pill(t.primary.withOpacity(.22), w: 60),
//           ),
//           Positioned(
//             top: 50,
//             right: 4,
//             child: pill(t.primary.withOpacity(.16), w: 46, h: 16),
//           ),
//         ],
//       ),
//     );
//   }
// }

// /* ============================== SEARCH (NOW WIRED) ============================== */

// class _SearchCardModern extends StatelessWidget {
//   const _SearchCardModern({
//     required this.t,
//     required this.controller,
//     required this.onChanged,
//     required this.onClear,
//     required this.showClear,
//   });

//   final _UiTokens t;
//   final TextEditingController controller;
//   final ValueChanged<String> onChanged;
//   final VoidCallback onClear;
//   final bool showClear;

//   @override
//   Widget build(BuildContext context) {
//     return _Glass(
//       radius: 18,
//       child: Padding(
//         padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
//         child: Row(
//           children: [
//             Container(
//               width: 42,
//               height: 42,
//               decoration: BoxDecoration(
//                 color: t.primary.withOpacity(.10),
//                 borderRadius: BorderRadius.circular(16),
//                 border: Border.all(color: t.primary.withOpacity(.12)),
//               ),
//               child: Icon(Icons.search_rounded, color: t.primaryDark),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: TextField(
//                 controller: controller,
//                 onChanged: onChanged,
//                 style: const TextStyle(fontFamily: 'Poppins'),
//                 decoration: InputDecoration(
//                   hintText: 'Search for services...',
//                   hintStyle: TextStyle(
//                     fontFamily: 'Poppins',
//                     color: Colors.grey.shade500,
//                     fontSize: 13.5,
//                     fontWeight: FontWeight.w600,
//                   ),
//                   border: InputBorder.none,
//                 ),
//               ),
//             ),
//             const SizedBox(width: 6),

//             // ✅ clear button (only appears when text exists)
//             if (showClear)
//               InkWell(
//                 borderRadius: BorderRadius.circular(999),
//                 onTap: onClear,
//                 child: Padding(
//                   padding: const EdgeInsets.all(6),
//                   child: Icon(
//                     Icons.close_rounded,
//                     size: 18,
//                     color: t.mutedText,
//                   ),
//                 ),
//               ),

//             const SizedBox(width: 8),

//             // keeping your tune icon as-is (not functional)
//             Container(
//               width: 42,
//               height: 42,
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                   colors: [t.primary, t.primaryDark],
//                 ),
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: const Icon(Icons.tune_rounded, color: Colors.white),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// /* ============================== INFO CARD ============================== */

// class _InfoCardModern extends StatelessWidget {
//   const _InfoCardModern({required this.t});
//   final _UiTokens t;

//   @override
//   Widget build(BuildContext context) {
//     return _Glass(
//       radius: 18,
//       child: Padding(
//         padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
//         child: Row(
//           children: [
//             Container(
//               height: 42,
//               width: 42,
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(16),
//                 gradient: LinearGradient(
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                   colors: [
//                     t.primary.withOpacity(.20),
//                     t.primary.withOpacity(.06),
//                   ],
//                 ),
//                 border: Border.all(color: t.primary.withOpacity(.12)),
//               ),
//               child: Icon(Icons.flash_on_rounded, color: t.primaryDark),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Text(
//                 '1 active booking today. Tap to view or reschedule.',
//                 style: TextStyle(
//                   fontFamily: 'Poppins',
//                   fontSize: 12.8,
//                   color: t.primaryDark,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//             ),
//             Icon(Icons.chevron_right_rounded, color: t.primaryDark),
//           ],
//         ),
//       ),
//     );
//   }
// }

// /* ============================== CHIPS ============================== */

// class _ChipPill extends StatelessWidget {
//   const _ChipPill({
//     required this.label,
//     required this.selected,
//     required this.t,
//     required this.onTap,
//   });

//   final String label;
//   final bool selected;
//   final _UiTokens t;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       borderRadius: BorderRadius.circular(999),
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 180),
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         decoration: BoxDecoration(
//           gradient: selected
//               ? LinearGradient(colors: [t.primaryDark, t.primary])
//               : null,
//           color: selected ? null : Colors.white,
//           borderRadius: BorderRadius.circular(999),
//           border: Border.all(
//             color: selected ? Colors.transparent : t.primary.withOpacity(.18),
//           ),
//           boxShadow: selected
//               ? [
//                   BoxShadow(
//                     color: t.primary.withOpacity(.22),
//                     blurRadius: 16,
//                     offset: const Offset(0, 10),
//                   ),
//                 ]
//               : [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(.03),
//                     blurRadius: 14,
//                     offset: const Offset(0, 10),
//                   ),
//                 ],
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               selected ? Icons.check_circle_rounded : Icons.circle_outlined,
//               size: 16,
//               color: selected ? Colors.white : t.primaryDark.withOpacity(.55),
//             ),
//             const SizedBox(width: 8),
//             Text(
//               label,
//               style: TextStyle(
//                 fontFamily: 'Poppins',
//                 color: selected ? Colors.white : t.primaryDark,
//                 fontWeight: FontWeight.w800,
//                 fontSize: 12.5,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// /* ============================== SERVICE PILLS ============================== */

// class _ServicePillTile extends StatelessWidget {
//   const _ServicePillTile({
//     required this.t,
//     required this.text,
//     required this.onTap,
//   });

//   final _UiTokens t;
//   final String text;
//   final VoidCallback onTap;

//   IconData _pickIcon(String s) {
//     final v = s.toLowerCase();
//     if (v.contains('clean')) return Icons.cleaning_services_rounded;
//     if (v.contains('ac')) return Icons.ac_unit_rounded;
//     if (v.contains('plumb')) return Icons.plumbing_rounded;
//     if (v.contains('electric')) return Icons.electrical_services_rounded;
//     if (v.contains('car')) return Icons.directions_car_rounded;
//     if (v.contains('garden')) return Icons.grass_rounded;
//     return Icons.handyman_rounded;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       borderRadius: BorderRadius.circular(16),
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//         decoration: BoxDecoration(
//           color: t.primary.withOpacity(.06),
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: t.primary.withOpacity(.18)),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 28,
//               height: 28,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(10),
//                 border: Border.all(color: t.primary.withOpacity(.10)),
//               ),
//               child: Icon(_pickIcon(text), size: 16, color: t.primaryDark),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//       child: Text(
//         text,
//         softWrap: true,
//         // remove maxLines to allow full wrap
//         style: TextStyle(
//           fontFamily: 'Poppins',
//           fontSize: 12.5,
//           color: t.primaryText,
//           fontWeight: FontWeight.w700,
//         ),
//       ),
//     ),
//     //      Expanded(
//     //   child: Text(
//     //     text,
//     //     maxLines: 1, // or 2
//     //     overflow: TextOverflow.ellipsis,
//     //     style: TextStyle(
//     //       fontFamily: 'Poppins',
//     //       fontSize: 12.5,
//     //       color: t.primaryText,
//     //       fontWeight: FontWeight.w700,
//     //     ),
//     //   ),
//     // ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// /* ============================== ACTION CARDS ============================== */

// class _ActionCardModern extends StatelessWidget {
//   const _ActionCardModern({
//     required this.t,
//     required this.title,
//     required this.subtitle,
//     required this.icon,
//     required this.gradient,
//     required this.onTap,
//   });

//   final _UiTokens t;
//   final String title;
//   final String subtitle;
//   final IconData icon;
//   final List<Color> gradient;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     return _Glass(
//       radius: 18,
//       child: InkWell(
//         borderRadius: BorderRadius.circular(18),
//         onTap: onTap,
//         child: Container(
//           height: 118,
//           padding: const EdgeInsets.all(14),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 width: 42,
//                 height: 42,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(16),
//                   gradient: LinearGradient(
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                     colors: gradient,
//                   ),
//                   boxShadow: [
//                     BoxShadow(
//                       color: gradient.first.withOpacity(.18),
//                       blurRadius: 18,
//                       offset: const Offset(0, 10),
//                     ),
//                   ],
//                 ),
//                 child: Icon(icon, color: Colors.white),
//               ),
//               const Spacer(),
//               Text(
//                 title,
//                 style: TextStyle(
//                   fontFamily: 'Poppins',
//                   fontSize: 13.8,
//                   fontWeight: FontWeight.w900,
//                   color: t.primaryText,
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 subtitle,
//                 style: TextStyle(
//                   fontFamily: 'Poppins',
//                   fontSize: 11.8,
//                   color: t.mutedText,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// /* ============================== POPULAR CARDS ============================== */

// class _ServiceHorizontalCardModern extends StatelessWidget {
//   const _ServiceHorizontalCardModern({
//     required this.t,
//     required this.title,
//     required this.price,
//     required this.icon,
//     required this.accent,
//   });

//   final _UiTokens t;
//   final String title;
//   final String price;
//   final IconData icon;
//   final Color accent;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 160,
//       margin: const EdgeInsets.only(right: 12),
//       child: _Glass(
//         radius: 20,
//         child: Padding(
//           padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Container(
//                     height: 38,
//                     width: 38,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(14),
//                       color: accent.withOpacity(.12),
//                       border: Border.all(color: accent.withOpacity(.20)),
//                     ),
//                     child: Icon(icon, color: accent, size: 20),
//                   ),
//                   const Spacer(),
//                   Icon(
//                     Icons.star_rounded,
//                     size: 18,
//                     color: t.primary.withOpacity(.45),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 title,
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//                 style: TextStyle(
//                   fontFamily: 'Poppins',
//                   fontWeight: FontWeight.w800,
//                   color: t.primaryText,
//                 ),
//               ),
//               const SizedBox(height: 6),
//               Text(
//                 price,
//                 style: TextStyle(
//                   fontFamily: 'Poppins',
//                   fontSize: 12,
//                   color: t.mutedText,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               const Spacer(),
//               Row(
//                 children: [
//                   Icon(Icons.location_on_rounded, size: 16, color: t.mutedText),
//                   const SizedBox(width: 6),
//                   Text(
//                     'Nearby',
//                     style: TextStyle(
//                       fontFamily: 'Poppins',
//                       fontSize: 12,
//                       color: t.mutedText,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// /* ============================== SMALL UI COMPONENTS ============================== */

// class _IconGlassButton extends StatelessWidget {
//   const _IconGlassButton({
//     required this.t,
//     required this.icon,
//     required this.onTap,
//   });

//   final _UiTokens t;
//   final IconData icon;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     return _Glass(
//       radius: 16,
//       child: InkWell(
//         borderRadius: BorderRadius.circular(16),
//         onTap: onTap,
//         child: SizedBox(
//           width: 46,
//           height: 46,
//           child: Icon(icon, color: t.primaryDark),
//         ),
//       ),
//     );
//   }
// }

// class _Glass extends StatelessWidget {
//   const _Glass({required this.child, this.radius = 18});
//   final Widget child;
//   final double radius;

//   @override
//   Widget build(BuildContext context) {
//     final t = _UiTokens.of(context);

//     return ClipRRect(
//       borderRadius: BorderRadius.circular(radius),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
//         child: Container(
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(radius),
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [
//                 Colors.white.withOpacity(.92),
//                 Colors.white.withOpacity(.78),
//               ],
//             ),
//             border: Border.all(color: t.primary.withOpacity(.10)),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(.05),
//                 blurRadius: 18,
//                 offset: const Offset(0, 10),
//               ),
//             ],
//           ),
//           child: child,
//         ),
//       ),
//     );
//   }
// }
