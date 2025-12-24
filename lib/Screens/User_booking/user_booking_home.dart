import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_bloc.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_state.dart';
import 'package:taskoon/Models/services_model.dart';
import 'package:taskoon/Models/services_ui_model.dart';
import 'package:taskoon/Screens/User_booking/select_service.dart';
import 'package:taskoon/Screens/User_booking/service_booking_form_screen.dart';
import 'dart:async';
import 'package:taskoon/widgets/greetingWithLocation_widget.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'dart:convert';

class TaskerBookingOffer {
  final String bookingDetailId;
  final double lat;
  final double lng;
  final double estimatedCost;
  final String message;
  final String? type;
  final String? date;

  TaskerBookingOffer({
    required this.bookingDetailId,
    required this.lat,
    required this.lng,
    required this.estimatedCost,
    required this.message,
    this.type,
    this.date,
  });

  static TaskerBookingOffer? tryParse(dynamic payload) {
    try {
      dynamic obj = payload;

      // If server sends JSON string
      if (obj is String) {
        obj = jsonDecode(obj);
      }

      if (obj is! Map) return null;
      final map = Map<String, dynamic>.from(obj);

      // common: { type, message, date, data: {...} }
      final dataAny = map['data'];
      if (dataAny is Map) {
        final data = Map<String, dynamic>.from(dataAny);

        final bookingDetailId =
            (data['bookingDetailId'] ?? data['BookingDetailId'])?.toString();
        if (bookingDetailId == null || bookingDetailId.isEmpty) return null;

        return TaskerBookingOffer(
          bookingDetailId: bookingDetailId,
          lat: _toDouble(data['lat'] ?? data['Lat']),
          lng: _toDouble(data['lng'] ?? data['Lng']),
          estimatedCost: _toDouble(
            data['estimatedCost'] ?? data['EstimatedCost'] ?? 0,
          ),
          message: (map['message'] ?? '').toString(),
          type: map['type']?.toString(),
          date: map['date']?.toString(),
        );
      }

      // fallback: payload itself contains fields
      final bookingDetailId = (map['bookingDetailId'] ?? map['BookingDetailId'])
          ?.toString();
      if (bookingDetailId == null || bookingDetailId.isEmpty) return null;

      return TaskerBookingOffer(
        bookingDetailId: bookingDetailId,
        lat: _toDouble(map['lat'] ?? map['Lat']),
        lng: _toDouble(map['lng'] ?? map['Lng']),
        estimatedCost: _toDouble(
          map['estimatedCost'] ?? map['EstimatedCost'] ?? 0,
        ),
        message: (map['message'] ?? '').toString(),
        type: map['type']?.toString(),
        date: map['date']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

/// ===============================================================
/// ✅ SIGNALR SERVICE (ONLY)
/// ===============================================================
class DispatchHubService {
  DispatchHubService({
    required this.baseUrl,
    required this.userId,
    this.onNotification,
    this.onBookingOffer, // popup trigger
    this.onLog,
  });

  final String baseUrl; // e.g. http://192.3.3.187:85
  final String userId; // GUID

  final void Function(dynamic payload)? onNotification;
  final void Function(TaskerBookingOffer offer)? onBookingOffer;
  final void Function(String msg)? onLog;

  HubConnection? _conn;

  bool _isStarting = false;
  bool _isStopping = false;
  bool _isReconnecting = false;
  Timer? _reconnectTimer;

  String get hubUrl {
    final clean = baseUrl.endsWith("/")
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return "$clean/hubs/dispatch?userId=$userId";
  }

  HubConnectionState get state =>
      _conn?.state ?? HubConnectionState.Disconnected;

  bool get isConnected => state == HubConnectionState.Connected;

  void _log(String s) {
    onLog?.call(s);
    // ignore: avoid_print
    print(s);
  }

  HubConnection _buildConnection() {
    return HubConnectionBuilder()
        .withUrl(
          hubUrl,
          options: HttpConnectionOptions(
            skipNegotiation: false,
            transport: HttpTransportType.LongPolling, // ✅ stable
          ),
        )
        .build();
  }

  void _wireHandlers(HubConnection c) {
    c.on("receivenotification", (args) {
      final payload = (args != null && args.isNotEmpty) ? args[0] : args;
      _log("📩 receivenotification RAW → ${_pretty(payload)}");

      onNotification?.call(payload);

      final offer = TaskerBookingOffer.tryParse(payload);
      if (offer != null) {
        _log(
          "✅ BookingOffer parsed → bookingDetailId=${offer.bookingDetailId}",
        );
        onBookingOffer?.call(offer);
      }
    });

    c.on("ReceiveNotification", (args) {
      final payload = (args != null && args.isNotEmpty) ? args[0] : args;
      _log("📩 ReceiveNotification RAW → ${_pretty(payload)}");

      onNotification?.call(payload);

      final offer = TaskerBookingOffer.tryParse(payload);
      if (offer != null) {
        _log(
          "✅ BookingOffer parsed → bookingDetailId=${offer.bookingDetailId}",
        );
        onBookingOffer?.call(offer);
      }
    });

    c.onclose(({Exception? error}) {
      _log("🔌 onclose: ${error?.toString() ?? 'none'}");
      if (!_isStarting && !_isStopping) {
        _startReconnect();
      }
    });
  }

  String _pretty(dynamic v) {
    try {
      if (v is String) {
        try {
          final decoded = jsonDecode(v);
          return const JsonEncoder.withIndent("  ").convert(decoded);
        } catch (_) {
          return v;
        }
      }
      return const JsonEncoder.withIndent("  ").convert(v);
    } catch (_) {
      return v?.toString() ?? 'null';
    }
  }

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
      _log("⚠️ stop() ignored: $e");
    } finally {
      _isStopping = false;
    }
  }

  Future<void> start() async {
    if (_isStarting || _isReconnecting) {
      _log("⏳ Already starting/reconnecting, skip start()");
      return;
    }

    if (_conn != null && _conn!.state != HubConnectionState.Disconnected) {
      _log("⚠️ Cannot start because state is: ${_conn!.state}");
      return;
    }

    _isStarting = true;
    _reconnectTimer?.cancel();
    _isReconnecting = false;

    _log("🔌 Starting hub: $hubUrl");

    try {
      await _safeStop();

      final c = _buildConnection();
      _wireHandlers(c);
      _conn = c;

      try {
        await c.start();
      } catch (e) {
        try {
          await c.stop();
        } catch (_) {}
        rethrow;
      }

      _log("✅ Hub connected (LongPolling)");
    } catch (e) {
      _log("❌ start() failed: $e");
      _startReconnect();
    } finally {
      _isStarting = false;
    }
  }

  Future<void> stop() async {
    _reconnectTimer?.cancel();
    _isReconnecting = false;
    await _safeStop();
    _log("🛑 Disconnected");
  }

  void _startReconnect() {
    if (_isReconnecting) return;
    _isReconnecting = true;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(const Duration(seconds: 5), (t) async {
      if (_isStarting || _isStopping) return;

      _log("🔁 Reconnecting...");

      try {
        await _safeStop();

        final c = _buildConnection();
        _wireHandlers(c);
        _conn = c;

        await c.start();

        _log("✅ Reconnected (LongPolling)");
        _isReconnecting = false;
        t.cancel();
      } catch (e) {
        _log("⏳ Reconnect failed: $e");
      }
    });
  }

  void dispose() {
    _reconnectTimer?.cancel();
  }
}

/// ===============================================================
/// ✅ USER HOME SCREEN (UI SAME, ONLY SIGNALR ADDED)
/// ===============================================================
///
///
class UserBookingHome extends StatefulWidget {
  const UserBookingHome({super.key});

  @override
  State<UserBookingHome> createState() => _UserBookingHomeState();
}

class _UserBookingHomeState extends State<UserBookingHome> {
  String? _selectedChip;
  CertificationGroup? _selectedGroup;
  ServiceDto? servicesdto;

  DispatchHubService? _hub;
  bool _hubStarted = false;

  bool _dialogOpen = false;
  String? _lastDialogKey;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final userDetails = context.read<AuthenticationBloc>().state.userDetails;
      final userId = userDetails?.userId?.toString();

      if (userId == null || userId.isEmpty) {
        debugPrint("❌ UserBookingHome: userId missing (userDetails not loaded)");
        return;
      }

      _hub = DispatchHubService(
        baseUrl: "http://192.3.3.187:85",
        userId: userId,
        onLog: (m) => debugPrint("USER HUB: $m"),
      );

      await _startHubOnce();
    });
  }

  Future<void> _startHubOnce() async {
    if (_hubStarted) return;
    _hubStarted = true;

    try {
      await _hub?.start();
    } catch (e) {
      debugPrint("🔥 UserBookingHome: hub start failed: $e");
      _hubStarted = false;
    }
  }

  @override
  void dispose() {
    _hub?.stop();
    _hub?.dispose();
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
                  final List<String> chipLabels = groups.map((e) => e.name).toList();

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
                                separatorBuilder: (_, __) => const SizedBox(width: 8),
                                itemBuilder: (_, i) {
                                  final label = chipLabels[i];
                                  final sel = label == (_selectedChip ?? '');
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedChip = label;
                                        _selectedGroup = groups.firstWhere(
                                          (g) => g.name == label,
                                          orElse: () => groups.first,
                                        );
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: sel ? const Color(0xFF5C2E91) : Colors.white,
                                        borderRadius: BorderRadius.circular(999),
                                        border: sel
                                            ? null
                                            : Border.all(
                                                color: const Color(0xFF5C2E91).withOpacity(.3),
                                              ),
                                      ),
                                      child: Text(
                                        label,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          color: sel ? Colors.white : const Color(0xFF5C2E91),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),

                      if (_selectedGroup != null && _selectedGroup!.services.isNotEmpty) ...[
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

                                      // ✅ svc.id is SERVICE ID (not certificate id)
                                      serviceId: svc.id, 
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5C2E91).withOpacity(.06),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF5C2E91).withOpacity(.25),
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

  // ==================== UI HELPERS (UNCHANGED) ====================

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
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: Color(0xFF5C2E91),
          ),
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
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
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
          ),
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
            child: const Icon(Icons.flash_on_rounded, color: Color(0xFF5C2E91)),
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
                MaterialPageRoute(builder: (_) => const ServiceCertificatesGridScreen()),
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
                  MaterialPageRoute(builder: (_) => const ServiceCertificatesGridScreen()),
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
              ),
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
 
/*
class UserBookingHome extends StatefulWidget {
  const UserBookingHome({super.key});

  @override
  State<UserBookingHome> createState() => _UserBookingHomeState();
}

class _UserBookingHomeState extends State<UserBookingHome> {
  String? _selectedChip;
  CertificationGroup? _selectedGroup;
  ServiceDto ? servicesdto;

  DispatchHubService? _hub;
  bool _hubStarted = false;

  bool _dialogOpen = false;
  String? _lastDialogKey; // avoid duplicate spam

  @override
  void initState() {
    super.initState();

    // start after first frame (context ready)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final userDetails = context.read<AuthenticationBloc>().state.userDetails;
      final userId = userDetails?.userId?.toString();

      if (userId == null || userId.isEmpty) {
        debugPrint(
          "❌ UserBookingHome: userId missing (userDetails not loaded)",
        );
        return;
      }

      _hub = DispatchHubService(
        baseUrl: "http://192.3.3.187:85",
        userId: userId,
        onLog: (m) => debugPrint("USER HUB: $m"),
        // onNotification: (payload) {
        //   // show raw notification popup
        //   _showPopup("Notification:\n${payload.toString()}");
        // },
        // onBookingOffer: (offer) {
        //   // if it's a booking offer, show formatted popup
        //   _showPopup(
        //     "New Booking Offer\n\n"
        //     "Message: ${offer.message}\n"
        //     "BookingDetailId: ${offer.bookingDetailId}\n"
        //     "Estimated: ${offer.estimatedCost}\n"
        //     "Lat: ${offer.lat}\n"
        //     "Lng: ${offer.lng}\n",
        //     key: offer.bookingDetailId,
        //   );
        // },
      );

      await _startHubOnce();
    });
  }

  Future<void> _startHubOnce() async {
    if (_hubStarted) return;
    _hubStarted = true;

    try {
      await _hub?.start();
    } catch (e) {
      debugPrint("🔥 UserBookingHome: hub start failed: $e");
      _hubStarted = false;
    }
  }

  /* void _showPopup(String text, {String? key}) {
    if (!mounted) return;
    if (_dialogOpen) return;

    // avoid repeating same popup
    if (key != null && _lastDialogKey == key) return;
    if (key != null) _lastDialogKey = key;

    _dialogOpen = true;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        title: const Text("SignalR Notification"),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    ).then((_) {
      _dialogOpen = false;
    });
  }*/

  @override
  void dispose() {
    _hub?.stop();
    _hub?.dispose();
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
                  final List<String> chipLabels = groups
                      .map((e) => e.name)
                      .toList();

                  // final List<String> chipLabels = ['All'];
                  // if (groups.isNotEmpty) {
                  //   chipLabels.addAll(groups.map((e) => e.name));
                  // }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 34,
                        child:
                            (state.servicesStatus == ServicesStatus.loading &&
                                groups.isEmpty)
                            ? _buildLoadingChips()
                            : ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: chipLabels.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (_, i) {
                                  final label = chipLabels[i];
                                  final sel =
                                      label ==
                                      (_selectedChip ??
                                          ''); //final sel = label == _selectedChip;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedChip = label;
                                        _selectedGroup = groups.firstWhere(
                                          (g) => g.name == label,
                                          orElse: () => groups.first,
                                        );
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: sel
                                            ? const Color(0xFF5C2E91)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: sel
                                            ? null
                                            : Border.all(
                                                color: const Color(
                                                  0xFF5C2E91,
                                                ).withOpacity(.3),
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
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF5C2E91,
                                  ).withOpacity(.06),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF5C2E91,
                                    ).withOpacity(.25),
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

  // ==================== UI HELPERS (UNCHANGED) ====================

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
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: Color(0xFF5C2E91),
          ),
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
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 4,
          ),
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
          ),
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
            child: const Icon(Icons.flash_on_rounded, color: Color(0xFF5C2E91)),
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
              ),
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
}*/

/// ==================== SMALL UI WIDGETS (UNCHANGED) ====================

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
            child: Icon(
              icon,
              color: color ?? const Color(0xFF5C2E91),
              size: 18,
            ),
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
