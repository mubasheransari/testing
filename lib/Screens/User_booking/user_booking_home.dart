import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_bloc.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_event.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_state.dart';
import 'package:taskoon/Models/services_ui_model.dart';
import 'package:taskoon/Screens/User_booking/select_service.dart';
import 'package:taskoon/Screens/User_booking/service_booking_form_screen.dart';
import 'dart:async';
import 'package:taskoon/widgets/greetingWithLocation_widget.dart';
import 'package:signalr_netcore/signalr_client.dart';





import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:signalr_netcore/signalr_client.dart';

// ✅ Your blocs/models/screens used below (already in your project)
/// AuthenticationBloc, AuthenticationState, ServicesStatus, LoadServicesRequested
/// UserBookingBloc, UpdateUserLocationRequested
/// GreetingWithLocation, ServiceBookingFormScreen, ServiceCertificatesGridScreen
/// CertificationGroup etc.

class LocationHubService {
  LocationHubService({
    required this.hubUrl,
    this.onLog,
  });

  final String hubUrl;
  final void Function(String msg)? onLog;

  HubConnection? _conn;

  bool _isStarting = false;
  bool _isStopping = false;
  bool _isReconnecting = false;

  Timer? _reconnectTimer;

  // -------------------------
  // Helpers
  // -------------------------
  void _log(String msg) {
    onLog?.call(msg);
    // ignore: avoid_print
    print(msg);
  }

  HubConnectionState get state =>
      _conn?.state ?? HubConnectionState.Disconnected;

  bool get isConnected => state == HubConnectionState.Connected;

  // -------------------------
  // Build connection
  // -------------------------
  HubConnection _buildConnection() {
    return HubConnectionBuilder()
        .withUrl(
          hubUrl,
          options: HttpConnectionOptions(
            skipNegotiation: false,
            transport: HttpTransportType.LongPolling, // ✅ IMPORTANT
          ),
        )
        .build();
  }

  void _wireHandlers(HubConnection c) {
    // ✅ Correct ClosedCallback signature in your version (signalr_netcore)
    c.onclose(({Exception? error}) {
      _log("🔌 LocationHub onclose: ${error?.toString() ?? 'none'}");

      // same guard logic as DispatchToggleScreen
      if (_isStarting || _isStopping) return;

      _startReconnect();
    });
  }

  // ------------------------------
  // Safe Stop (critical)
  // ------------------------------
  Future<void> _safeStop() async {
    if (_isStopping) return;
    _isStopping = true;

    final old = _conn;
    _conn = null;

    try {
      if (old != null && old.state != HubConnectionState.Disconnected) {
        await old.stop();
      }
    } catch (e) {
      _log("⚠️ LocationHub stop() ignored: $e");
    } finally {
      _isStopping = false;
    }
  }

  // -------------------------
  // Start
  // -------------------------
  Future<void> start() async {
    if (_isStarting || _isReconnecting) {
      _log("⏳ LocationHub already starting/reconnecting, skip start()");
      return;
    }

    if (_conn != null && _conn!.state != HubConnectionState.Disconnected) {
      _log("⚠️ LocationHub cannot start because state=${_conn!.state}");
      return;
    }

    _isStarting = true;

    _reconnectTimer?.cancel();
    _isReconnecting = false;

    _log("🔌 Starting LocationHub → $hubUrl");

    try {
      await _safeStop(); // ensure clean

      final c = _buildConnection();
      _wireHandlers(c);
      _conn = c;

      // ✅ protect from double-stop / future already completed
      try {
        await c.start();
      } catch (e) {
        try {
          await c.stop();
        } catch (_) {}
        rethrow;
      }

      _log("✅ LocationHub connected (LongPolling)");
    } catch (e) {
      _log("❌ LocationHub start failed: $e");
      _startReconnect();
    } finally {
      _isStarting = false;
    }
  }

  // -------------------------
  // Stop
  // -------------------------
  Future<void> stop() async {
    _reconnectTimer?.cancel();
    _isReconnecting = false;

    await _safeStop();

    _log("🛑 LocationHub disconnected");
  }

  // -------------------------
  // Reconnect loop
  // -------------------------
  void _startReconnect() {
    if (_isReconnecting) return;
    _isReconnecting = true;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(const Duration(seconds: 5), (t) async {
      // stop reconnecting if start/stop in progress
      if (_isStarting || _isStopping) return;

      _log("🔁 LocationHub reconnecting...");

      try {
        await _safeStop();

        final c = _buildConnection();
        _wireHandlers(c);
        _conn = c;

        await c.start();

        _log("✅ LocationHub reconnected (LongPolling)");
        _isReconnecting = false;
        t.cancel();
      } catch (e) {
        _log("⏳ LocationHub reconnect failed: $e");
      }
    });
  }

  // -------------------------
  // Dispose
  // -------------------------
  void dispose() {
    _reconnectTimer?.cancel();
  }
}

class UserBookingHome extends StatefulWidget {
  const UserBookingHome({super.key});

  @override
  State<UserBookingHome> createState() => _UserBookingHomeState();
}

class _UserBookingHomeState extends State<UserBookingHome> {
  String _selectedChip = 'All';
  CertificationGroup? _selectedGroup;

  late final LocationHubService _hubService;

  Timer? _locationTimer;

  // ✅ Same interval style you used before
  static const Duration _locationInterval = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();

    // 1️⃣ Init hub service (customer/user hub URL)
    _hubService = LocationHubService(
      hubUrl:
          'http://192.3.3.187:85/hubs/dispatch?userId=${context.read<AuthenticationBloc>().state.userDetails!.userId.toString()}',
      onLog: (m) => debugPrint(m),
    );

    // 2️⃣ After first frame: load services if needed + start hub connection loop
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authBloc = context.read<AuthenticationBloc>();
      final s = authBloc.state;

      final bool alreadyLoaded =
          s.servicesStatus == ServicesStatus.success && s.serviceGroups.isNotEmpty;

      if (!alreadyLoaded && s.servicesStatus != ServicesStatus.loading) {
        authBloc.add(LoadServicesRequested());
        debugPrint('📦 UserBookingHome: LoadServicesRequested fired from screen');
      } else {
        debugPrint(
          '📦 UserBookingHome: services already loaded (status=${s.servicesStatus}, groups=${s.serviceGroups.length})',
        );
      }

      // ✅ Start hub + start periodic "work" (no invoke, only ensure connected)
      _connectHubAndStartTimer();
    });
  }

  Future<void> _connectHubAndStartTimer() async {
    debugPrint('▶️ UserBookingHome: _connectHubAndStartTimer');

    // connect hub once
    try {
      await _hubService.start();
    } catch (e) {
      debugPrint('🔥 UserBookingHome: hub start failed: $e');
      return;
    }

    // start periodic timer like DispatchToggle logic
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(_locationInterval, (_) async {
      // ✅ If hub disconnected, attempt start() again (safe guards inside service)
      if (!_hubService.isConnected) {
        debugPrint('⚠️ UserBookingHome: hub not connected → calling start()');
        await _hubService.start();
      }

      // ✅ Since you said: "i didnt have any invoke method in my sample code"
      // we DO NOT call invoke/sendLocation here.
      // If you want: you can still dispatch REST API event here (optional).
      // _dispatchLocationUpdateToApi();
    });

    debugPrint('✅ UserBookingHome: timer started: $_locationInterval');
  }

  @override
  void dispose() {
    debugPrint('🧹 UserBookingHome.dispose() — stopping hub & timer');
    _locationTimer?.cancel();
    _hubService.stop();
    _hubService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearch(),
              const SizedBox(height: 14),
              _buildInfoCard(),
              const SizedBox(height: 18),
              const Text(
                'What do you need today?',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: Color(0xFF3E1E69),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),

              BlocBuilder<AuthenticationBloc, AuthenticationState>(
                buildWhen: (p, c) =>
                    p.serviceGroups != c.serviceGroups ||
                    p.servicesStatus != c.servicesStatus,
                builder: (context, state) {
                  final groups = state.serviceGroups;
                  final List<String> chipLabels = ['All'];
                  if (groups.isNotEmpty) {
                    chipLabels.addAll(groups.map((e) => e.name));
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 34,
                        child: (state.servicesStatus == ServicesStatus.loading &&
                                groups.isEmpty)
                            ? _buildLoadingChips()
                            : ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: chipLabels.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (_, i) {
                                  final label = chipLabels[i];
                                  final sel = label == _selectedChip;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedChip = label;
                                        _selectedGroup = label == 'All'
                                            ? null
                                            : groups.firstWhere(
                                                (g) => g.name == label,
                                                orElse: () => groups.first,
                                              );
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: sel
                                            ? const Color(0xFF5C2E91)
                                            : Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        border: sel
                                            ? null
                                            : Border.all(
                                                color: const Color(0xFF5C2E91)
                                                    .withOpacity(.3),
                                              ),
                                      ),
                                      child: Text(
                                        label,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          color: sel
                                              ? Colors.white
                                              : const Color(0xFF5C2E91),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),

                      if (_selectedGroup == null && groups.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'All services',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: Color(0xFF75748A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final g in groups)
                              for (final svc in g.services)
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ServiceBookingFormScreen(
                                          group: g,
                                          initialService: svc,
                                          subCategoryId: g.id.toString(),
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF5C2E91)
                                          .withOpacity(.06),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFF5C2E91)
                                            .withOpacity(.25),
                                      ),
                                    ),
                                    child: Text(
                                      svc.name,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        color: Color(0xFF3E1E69),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ],

                      if (_selectedGroup != null &&
                          _selectedGroup!.services.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Services in "${_selectedGroup!.name}"',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: Color(0xFF75748A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedGroup!.services.map((svc) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ServiceBookingFormScreen(
                                      group: _selectedGroup!,
                                      initialService: svc,
                                      subCategoryId: svc.id.toString(),
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5C2E91)
                                      .withOpacity(.06),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF5C2E91)
                                        .withOpacity(.25),
                                  ),
                                ),
                                child: Text(
                                  svc.name,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: Color(0xFF3E1E69),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),
              _buildActionRow(context),
              const SizedBox(height: 20),
              _buildPopular(context),
              const SizedBox(height: 20),
              _buildRecent(),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== UI HELPERS (unchanged) ====================

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 16,
      title: Padding(
        padding: const EdgeInsets.all(16),
        child: const GreetingWithLocation(),
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded,
              color: Color(0xFF5C2E91)),
        ),
        const Padding(
          padding: EdgeInsets.only(right: 16),
          child: CircleAvatar(
            radius: 18,
            backgroundImage: AssetImage('assets/avatar.png'),
          ),
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return Material(
      elevation: 0,
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: TextField(
        style: const TextStyle(fontFamily: 'Poppins'),
        decoration: InputDecoration(
          hintText: 'Search for services...',
          hintStyle: TextStyle(
            fontFamily: 'Poppins',
            color: Colors.grey.shade500,
            fontSize: 13.5,
          ),
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.search_rounded),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF5C2E91).withOpacity(.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          )
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF5C2E91).withOpacity(.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.flash_on_rounded,
                color: Color(0xFF5C2E91)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '1 active booking today. Tap to view or reschedule.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12.5,
                color: Color(0xFF5C2E91),
              ),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF5C2E91)),
        ],
      ),
    );
  }

  Widget _buildLoadingChips() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemBuilder: (_, __) => Container(
        width: 80,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemCount: 4,
    );
  }

  Widget _buildActionRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            title: 'Book a service',
            subtitle: 'Schedule instantly',
            icon: Icons.event_available_rounded,
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
          child: _ActionCard(
            title: 'Track booking',
            subtitle: 'See status',
            icon: Icons.schedule_rounded,
            color: const Color(0xFF3DB38D),
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildPopular(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Popular near you',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3E1E69),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ServiceCertificatesGridScreen(),
                  ),
                );
              },
              child: const Text(
                'View all',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Color(0xFF5C2E91),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 150,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              _ServiceHorizontalCard(
                title: 'House cleaning',
                price: 'From \$45',
                icon: Icons.cleaning_services_rounded,
              ),
              _ServiceHorizontalCard(
                title: 'AC repair',
                price: 'From \$60',
                icon: Icons.ac_unit_rounded,
                color: Color(0xFF3DB38D),
              ),
              _ServiceHorizontalCard(
                title: 'Furniture assemble',
                price: 'From \$35',
                icon: Icons.chair_alt_rounded,
                color: Color(0xFFEE8A41),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent activity',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF3E1E69),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.02),
                blurRadius: 18,
                offset: const Offset(0, 12),
              )
            ],
          ),
          child: const Column(
            children: [
              Icon(Icons.inbox_rounded, size: 40, color: Color(0xFF75748A)),
              SizedBox(height: 8),
              Text(
                'No bookings yet',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Book a task to see it here.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.5,
                  color: Color(0xFF75748A),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// ==================== SMALL UI WIDGETS ====================

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 110,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: (color ?? const Color(0xFF5C2E91)).withOpacity(.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color ?? const Color(0xFF5C2E91)),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3E1E69),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11.5,
                  color: Color(0xFF75748A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceHorizontalCard extends StatelessWidget {
  const _ServiceHorizontalCard({
    required this.title,
    required this.price,
    required this.icon,
    this.color,
  });

  final String title;
  final String price;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: (color ?? const Color(0xFF5C2E91)).withOpacity(.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color ?? const Color(0xFF5C2E91), size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            price,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11.5,
              color: Color(0xFF75748A),
            ),
          ),
        ],
      ),
    );
  }
}



// class LocationHubService {
//   LocationHubService({
//     required this.hubUrl,
//     this.onLog,
//   });

//   final String hubUrl;
//   final void Function(String msg)? onLog;

//   HubConnection? _conn;

//   bool _isStarting = false;
//   bool _isStopping = false;
//   bool _isReconnecting = false;

//   Timer? _reconnectTimer;

//   // -------------------------
//   // Helpers
//   // -------------------------
//   void _log(String msg) {
//     onLog?.call(msg);
//     // ignore: avoid_print
//     print(msg);
//   }

//   HubConnectionState get state =>
//       _conn?.state ?? HubConnectionState.Disconnected;

//   bool get isConnected => state == HubConnectionState.Connected;

//   // -------------------------
//   // Build connection
//   // -------------------------
//   HubConnection _buildConnection() {
//     return HubConnectionBuilder()
//         .withUrl(
//           hubUrl,
//           options: HttpConnectionOptions(
//             skipNegotiation: false,
//             transport: HttpTransportType.LongPolling, // ✅ IMPORTANT
//           ),
//         )
//         .build();
//   }

//   void _wireHandlers(HubConnection c) {
//     // ✅ Correct ClosedCallback signature in your version
//     c.onclose(({Exception? error}) {
//       _log("🔌 LocationHub onclose: ${error?.toString() ?? 'none'}");

//       // same guard logic as DispatchToggleScreen
//       if (_isStarting || _isStopping) return;

//       _startReconnect();
//     });
//   }

//   // ------------------------------
//   // Safe Stop (critical)
//   // ------------------------------
//   Future<void> _safeStop() async {
//     if (_isStopping) return;
//     _isStopping = true;

//     final old = _conn;
//     _conn = null;

//     try {
//       if (old != null && old.state != HubConnectionState.Disconnected) {
//         await old.stop();
//       }
//     } catch (e) {
//       _log("⚠️ LocationHub stop() ignored: $e");
//     } finally {
//       _isStopping = false;
//     }
//   }

//   // -------------------------
//   // Start
//   // -------------------------
//   Future<void> start() async {
//     if (_isStarting || _isReconnecting) {
//       _log("⏳ LocationHub already starting/reconnecting, skip start()");
//       return;
//     }

//     if (_conn != null && _conn!.state != HubConnectionState.Disconnected) {
//       _log("⚠️ LocationHub cannot start because state=${_conn!.state}");
//       return;
//     }

//     _isStarting = true;

//     _reconnectTimer?.cancel();
//     _isReconnecting = false;

//     _log("🔌 Starting LocationHub → $hubUrl");

//     try {
//       await _safeStop(); // ensure clean

//       final c = _buildConnection();
//       _wireHandlers(c);
//       _conn = c;

//       // ✅ protect from double-stop / future already completed
//       try {
//         await c.start();
//       } catch (e) {
//         try {
//           await c.stop();
//         } catch (_) {}
//         rethrow;
//       }

//       _log("✅ LocationHub connected (LongPolling)");
//     } catch (e) {
//       _log("❌ LocationHub start failed: $e");
//       _startReconnect();
//     } finally {
//       _isStarting = false;
//     }
//   }

//   // -------------------------
//   // Stop
//   // -------------------------
//   Future<void> stop() async {
//     _reconnectTimer?.cancel();
//     _isReconnecting = false;

//     await _safeStop();

//     _log("🛑 LocationHub disconnected");
//   }

//   // -------------------------
//   // Reconnect loop
//   // -------------------------
//   void _startReconnect() {
//     if (_isReconnecting) return;
//     _isReconnecting = true;

//     _reconnectTimer?.cancel();
//     _reconnectTimer = Timer.periodic(const Duration(seconds: 5), (t) async {
//       // stop reconnecting if start/stop in progress
//       if (_isStarting || _isStopping) return;

//       _log("🔁 LocationHub reconnecting...");

//       try {
//         await _safeStop();

//         final c = _buildConnection();
//         _wireHandlers(c);
//         _conn = c;

//         await c.start();

//         _log("✅ LocationHub reconnected (LongPolling)");
//         _isReconnecting = false;
//         t.cancel();
//       } catch (e) {
//         _log("⏳ LocationHub reconnect failed: $e");
//       }
//     });
//   }

//   // -------------------------
//   // Dispose
//   // -------------------------
//   void dispose() {
//     _reconnectTimer?.cancel();
//   }
// }


// class UserBookingHome extends StatefulWidget {
//   const UserBookingHome({super.key});

//   @override
//   State<UserBookingHome> createState() => _UserBookingHomeState();
// }

// class _UserBookingHomeState extends State<UserBookingHome> {
//   String _selectedChip = 'All';
//   CertificationGroup? _selectedGroup; // to show its services

//   late final LocationHubService _hubService;

//   Timer? _locationTimer;

//   // static const String _demoUserId =
//   //     '54748461-018e-4a05-95b5-d490d07c5ab2'; // resident/user
//   // static const double _demoLat = 24.435; // Karachi demo
//   // static const double _demoLng = 67.435;
  
//   @override
// void initState() {
//   super.initState();

//   // 1️⃣ Init hub service (customer / user hub URL)
//   _hubService = LocationHubService(
//     hubUrl: 'http://192.3.3.187:85/hubs/dispatch?userId=${context.read<AuthenticationBloc>().state.userDetails!.userId.toString()}',
//   );

//   // 2️⃣ After first frame: check if services are already loaded; if not, load them
//   WidgetsBinding.instance.addPostFrameCallback((_) {
//     final authBloc = context.read<AuthenticationBloc>();
//     final s = authBloc.state;

//     // 🔍 Already have data loaded successfully?
//     final bool alreadyLoaded =
//         s.servicesStatus == ServicesStatus.success &&
//         s.serviceGroups.isNotEmpty;

//     // ❗ Should we trigger loading from this screen?
//     // - Not already loaded
//     // - Not currently loading
//     if (!alreadyLoaded && s.servicesStatus != ServicesStatus.loading) {
//       authBloc.add(LoadServicesRequested());
//       debugPrint('📦 UserBookingHome: LoadServicesRequested fired from screen');
//     } else {
//       debugPrint(
//           '📦 UserBookingHome: services already loaded (status=${s.servicesStatus}, groups=${s.serviceGroups.length})');
//     }

//     // 🔁 Hub + location stuff
//   //  _connectHubAndSendLocationOnce();
//   });
// }


//  /* @override
//   void initState() { Testing@123
//     super.initState();

//     // 1️⃣ Init hub service (customer / user hub URL)
//     _hubService = LocationHubService(
//       hubUrl:
//           'http://192.3.3.187:85/hubs/dispatch?userId=$_demoUserId',
//     );

//     // 2️⃣ Existing post-frame callback for loading services + starting hub
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       // ---- existing services loading logic ----
//       final bloc = context.read<AuthenticationBloc>();
//       final s = bloc.state;
//       final hasData =
//           s.serviceGroups.isNotEmpty && s.servicesStatus == ServicesStatus.success;
//       if (!hasData && s.servicesStatus == ServicesStatus.initial) {
//         bloc.add(LoadServicesRequested());
//       }

//       // ---- NEW: connect hub and send location + fire Bloc event ----
//       _connectHubAndSendLocationOnce();
//     });
//   }*/

//   /// 👉 Dispatch REST API update to Bloc (UserBookingBloc)
//  /* void _dispatchLocationUpdateToApi() {
//     if (!mounted) return;

//     print(
//         '🛰 [UI] Dispatching UpdateUserLocationRequested to UserBookingBloc (userId=$_demoUserId, lat=$_demoLat, lng=$_demoLng)');

//     context.read<UserBookingBloc>().add(
//         const  UpdateUserLocationRequested(
//             userId: _demoUserId,
//             latitude: _demoLat,
//             longitude: _demoLng,
//           ),
//         );
//   }

//   /// 🚀 Connect hub and send location once on screen open
//   Future<void> _connectHubAndSendLocationOnce() async {
//     print('▶️ _connectHubAndSendLocationOnce called');

//     try {
//       await _hubService.start();
//     } catch (e) {
//       print('🔥 Error connecting hub in UserBookingHome: $e');
//       // Optional: show UI error
//       return;
//     }

//     if (!_hubService.isConnected) {
//       print('⚠️ Hub not connected after start(), skipping sendLocation');
//       return;
//     }

//     // ✅ 1) Hit REST API via Bloc (same pattern as TaskerHome)
//     _dispatchLocationUpdateToApi();

//     // ✅ 2) Send via SignalR hub
//     try {
//       await _hubService.sendLocation(
//         userId: _demoUserId,
//         latitude: _demoLat,
//         longitude: _demoLng,
//       );
//       print('✅ Initial location sent from UserBookingHome');
//     } catch (e) {
//       print('🔥 Error sending location from UserBookingHome: $e');
//     }

//   }

//   void _startPeriodicLocationUpdates(
//       String userId, double lat, double lng) {
//     _locationTimer?.cancel();
//     _locationTimer =
//         Timer.periodic(const Duration(seconds: 30), (timer) async {
//       print(
//           '⏰ UserBookingHome tick #${timer.tick} — sending location via SignalR');
//       if (!_hubService.isConnected) {
//         print('⚠️ Hub disconnected, trying to reconnect...');
//         try {
//           await _hubService.start();
//         } catch (e) {
//           print('🔥 Reconnect failed: $e');
//           return;
//         }
//       }
//       try {
//         await _hubService.sendLocation(
//           userId: userId,
//           latitude: lat,
//           longitude: lng,
//         );
//       } catch (e) {
//         print('🔥 Error sending periodic location: $e');
//       }

//     });
//   }
// */
//   @override
//   void dispose() {
//     print('🧹 UserBookingHome.dispose() — stopping hub & timer');
//     _locationTimer?.cancel();
//     _hubService.stop();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: _buildAppBar(),
//       body: SafeArea(
//         top: false,
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
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

//               // ⬇️ chips + below selected certificate services
//               BlocBuilder<AuthenticationBloc, AuthenticationState>(
//                 buildWhen: (p, c) =>
//                     p.serviceGroups != c.serviceGroups ||
//                     p.servicesStatus != c.servicesStatus,
//                 builder: (context, state) {
//                   final groups = state.serviceGroups;
//                   final List<String> chipLabels = ['All'];
//                   if (groups.isNotEmpty) {
//                     chipLabels.addAll(groups.map((e) => e.name));
//                   }

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
//                                   final sel = label == _selectedChip;
//                                   return GestureDetector(
//                                     onTap: () {
//                                       setState(() {
//                                         _selectedChip = label;
//                                         _selectedGroup = label == 'All'
//                                             ? null
//                                             : groups.firstWhere(
//                                                 (g) => g.name == label,
//                                                 orElse: () => groups.first,
//                                               );
//                                       });
//                                     },
//                                     child: Container(
//                                       padding: const EdgeInsets.symmetric(
//                                           horizontal: 12, vertical: 6),
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

//                       // ⬇️ when "All" is selected, show ALL services from ALL groups
//                       if (_selectedGroup == null && groups.isNotEmpty) ...[
//                         const SizedBox(height: 12),
//                         const Text(
//                           'All services',
//                           style: TextStyle(
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
//                           children: [
//                             for (final g in groups)
//                               for (final svc in g.services)
//                                 GestureDetector(
//                                   onTap: () {
//                                     Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder: (_) =>
//                                             ServiceBookingFormScreen(
//                                           group: g,
//                                           initialService: svc,
//                                           subCategoryId: g.id.toString(),
//                                         ),
//                                       ),
//                                     );
//                                   },
//                                   child: Container(
//                                     padding: const EdgeInsets.symmetric(
//                                         horizontal: 12, vertical: 6),
//                                     decoration: BoxDecoration(
//                                       color: const Color(0xFF5C2E91)
//                                           .withOpacity(.06),
//                                       borderRadius: BorderRadius.circular(12),
//                                       border: Border.all(
//                                         color: const Color(0xFF5C2E91)
//                                             .withOpacity(.25),
//                                       ),
//                                     ),
//                                     child: Text(
//                                       svc.name,
//                                       style: const TextStyle(
//                                         fontFamily: 'Poppins',
//                                         fontSize: 12,
//                                         color: Color(0xFF3E1E69),
//                                         fontWeight: FontWeight.w500,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                           ],
//                         ),
//                       ],

//                       // ⬇️ when a specific group is selected, show only that group's services
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
//                                       subCategoryId: svc.id.toString(),
//                                     ),
//                                   ),
//                                 );
//                               },
//                               child: Container(
//                                 padding: const EdgeInsets.symmetric(
//                                     horizontal: 12, vertical: 6),
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

//   // ==================== UI HELPERS (unchanged) ====================

//   AppBar _buildAppBar() {
//     return AppBar(
//       backgroundColor: Colors.white,
//       surfaceTintColor: Colors.transparent,
//       elevation: 0,
//       centerTitle: false,
//       titleSpacing: 16,
//       title: Padding(
//         padding: const EdgeInsets.all(16),
//         child: const GreetingWithLocation(),
//       ),
      
//      /* Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: const [
//           Text(
//             'Good morning 👋',
//             style: TextStyle(
//               fontFamily: 'Poppins',
//               fontSize: 16,
//               color: Color(0xFF5C2E91),
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           SizedBox(height: 3),
//           Row(
//             children: [
//               Icon(Icons.location_on_rounded,
//                   size: 15, color: Color(0xFF5C2E91)),
//               SizedBox(width: 4),
//               Text(
//                 'Melbourne, AU',
//                 style: TextStyle(
//                   fontFamily: 'Poppins',
//                   fontSize: 12.5,
//                   color: Color(0xFF75748A),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),*/
//       actions: [
//         IconButton(
//           onPressed: () {},
//           icon: const Icon(Icons.notifications_none_rounded,
//               color: Color(0xFF5C2E91)),
//         ),
//         const Padding(
//           padding: EdgeInsets.only(right: 16),
//           child: CircleAvatar(
//             radius: 18,
//             backgroundImage: AssetImage('assets/avatar.png'),
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
//           )
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
//           const Icon(Icons.chevron_right_rounded, color: Color(0xFF5C2E91)),
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
//                   builder: (_) => const ServiceCertificatesGridScreen(),
//                 ),
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
//                     builder: (_) => const ServiceCertificatesGridScreen(),
//                   ),
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
//               )
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

// /// ==================== SMALL UI WIDGETS ====================

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
//             child: Icon(icon, color: color ?? const Color(0xFF5C2E91), size: 18),
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
