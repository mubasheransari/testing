import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_bloc.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_bloc.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_event.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'dart:convert';



class DispatchHubService {
  DispatchHubService({
    required this.baseUrl,
    required this.userId,
    this.onNotification,
    this.onBookingOffer, // ✅ NEW (popup trigger)
    this.onLog,
  });

  final String baseUrl; // e.g. http://192.3.3.187:85
  final String userId; // GUID

  final void Function(dynamic payload)? onNotification;
  final void Function(TaskerBookingOffer offer)? onBookingOffer; // ✅ NEW
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
            transport: HttpTransportType.LongPolling, // ✅ your stable transport
          ),
        )
        .build();
  }

  void _wireHandlers(HubConnection c) {
    // ✅ server -> client event
    c.on("receivenotification", (args) {
      final payload = (args != null && args.isNotEmpty) ? args[0] : args;
      _log("📩 receivenotification RAW → ${_pretty(payload)}");

      onNotification?.call(payload);

      // ✅ Parse your booking offer format:
      // {
      //  type: "ReceiveBookingOffer",
      //  message: "...",
      //  date: "...",
      //  data: { bookingDetailId, lat, lng, estimatedCost }
      // }
      final offer = TaskerBookingOffer.tryParse(payload);
      if (offer != null) {
        _log("✅ BookingOffer parsed → bookingDetailId=${offer.bookingDetailId}");
        onBookingOffer?.call(offer);
      }
    });

    // ✅ ClosedCallback signature (named parameter)
    c.onclose(({Exception? error}) {
      _log("🔌 onclose: ${error?.toString() ?? 'none'}");
      if (!_isStarting && !_isStopping) {
        _startReconnect();
      }
    });
  }

  String _pretty(dynamic v) {
    try {
      if (v is String) return v;
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

/// ✅ parses your exact SignalR payload
class TaskerBookingOffer {
  final String bookingDetailId;
  final double lat;
  final double lng;
  final double estimatedCost;
  final String message;
  final String type;
  final String dateIso;

  const TaskerBookingOffer({
    required this.bookingDetailId,
    required this.lat,
    required this.lng,
    required this.estimatedCost,
    required this.message,
    required this.type,
    required this.dateIso,
  });

  static TaskerBookingOffer? tryParse(dynamic payload) {
    try {
      dynamic data = payload;

      // if server sends JSON string
      if (data is String) {
        data = jsonDecode(data);
      }

      // if server sends args list
      if (data is List && data.isNotEmpty) {
        data = data[0];
      }

      if (data is! Map) return null;

      final type = (data["type"] ?? "").toString();
      if (type != "ReceiveBookingOffer") return null;

      final msg = (data["message"] ?? "New booking offer").toString();
      final date = (data["date"] ?? "").toString();

      final inner = data["data"];
      if (inner is! Map) return null;

      final bookingDetailId = (inner["bookingDetailId"] ?? "").toString();
      if (bookingDetailId.isEmpty) return null;

      final lat = (inner["lat"] as num?)?.toDouble() ?? 0.0;
      final lng = (inner["lng"] as num?)?.toDouble() ?? 0.0;
      final cost = (inner["estimatedCost"] as num?)?.toDouble() ?? 0.0;

      return TaskerBookingOffer(
        bookingDetailId: bookingDetailId,
        lat: lat,
        lng: lng,
        estimatedCost: cost,
        message: msg,
        type: type,
        dateIso: date,
      );
    } catch (_) {
      return null;
    }
  }
}



class TaskerBooking {
  final String bookingDetailId;
  final double lat;
  final double lng;
  final double estimatedCost;
  final String message;

  const TaskerBooking({
    required this.bookingDetailId,
    required this.lat,
    required this.lng,
    required this.estimatedCost,
    required this.message,
  });

  static TaskerBooking? tryParse(dynamic payload) {
    try {
      dynamic data = payload;

      if (data is String) data = jsonDecode(data);
      if (data is! Map) return null;

      if (data['type'] != 'ReceiveBookingOffer') return null;

      final inner = data['data'];
      if (inner is! Map) return null;

      final id = inner['bookingDetailId']?.toString();
      if (id == null || id.isEmpty) return null;

      return TaskerBooking(
        bookingDetailId: id,
        lat: (inner['lat'] ?? 0).toDouble(),
        lng: (inner['lng'] ?? 0).toDouble(),
        estimatedCost: (inner['estimatedCost'] ?? 0).toDouble(),
        message: data['message'] ?? 'New booking',
      );
    } catch (_) {
      return null;
    }
  }
}


// class TaskerBooking {
//   final String bookingDetailId;
//   final double lat;
//   final double lng;
//   final double estimatedCost;
//   final String message;

//   const TaskerBooking({
//     required this.bookingDetailId,
//     required this.lat,
//     required this.lng,
//     required this.estimatedCost,
//     required this.message,
//   });

//   static TaskerBooking? tryParse(dynamic payload) {
//     try {
//       dynamic data = payload;

//       if (data is String) {
//         data = jsonDecode(data);
//       }

//       if (data is List && data.isNotEmpty) {
//         data = data[0];
//       }

//       if (data is! Map) return null;

//       // ✅ ONLY react to booking offers
//       if (data['type'] != 'ReceiveBookingOffer') return null;

//       final inner = data['data'];
//       if (inner is! Map) return null;

//       final bookingId = inner['bookingDetailId']?.toString();
//       if (bookingId == null || bookingId.isEmpty) return null;

//       return TaskerBooking(
//         bookingDetailId: bookingId,
//         lat: (inner['lat'] ?? 0).toDouble(),
//         lng: (inner['lng'] ?? 0).toDouble(),
//         estimatedCost: (inner['estimatedCost'] ?? 0).toDouble(),
//         message: data['message'] ?? 'New booking offer',
//       );
//     } catch (_) {
//       return null;
//     }
//   }Testing@123
// }






class TaskerHomeRedesign extends StatefulWidget {
  const TaskerHomeRedesign({super.key});

  @override
  State<TaskerHomeRedesign> createState() => _TaskerHomeRedesignState();
}

class _TaskerHomeRedesignState extends State<TaskerHomeRedesign> {
  bool available = false;
  String period = 'Week';
  var box = GetStorage();

  static const String _kAvailabilityKey = 'tasker_available';
bool _restored = false; // prevents double-start

  late final DispatchHubService _hubService;

  Timer? _locationTimer;
  static const Duration _locationInterval = Duration(seconds: 5);

  // ✅ Popup guards
  bool _dialogOpen = false;
  String? _lastPopupBookingDetailId;

  // MOCK UI DATA (same as your code)
  final _avatarUrl =
      'https://images.unsplash.com/photo-1607746882042-944635dfe10e?q=80&w=256&auto=format&fit=crop';
  final _title = 'Handyman, Pro';
  final _badges = const [
    _Badge(
      label: 'ID',
      icon: Icons.verified,
      bg: Color(0xFFE8F5E9),
      fg: Color(0xFF2E7D32),
    ),
    _Badge(
      label: 'Police\nCheck',
      icon: Icons.shield_moon,
      bg: Color(0xFFE3F2FD),
      fg: Color(0xFF1565C0),
    ),
  ];

  double rating = 4.9;
  int reviews = 124;
  int acceptanceRate = 91;
  int completionRate = 98;
  int weeklyEarning = 820;
  int monthlyEarning = 3280;

  final List<_Task> upcoming = const [
    _Task(
      title: 'Furniture assembly',
      date: 'Apr 24',
      time: '10:30',
      location: 'East Perth',
    ),
  ];

  final List<_Task> current = const [
    _Task(
      title: 'TV wall mount',
      date: 'Apr 24',
      time: '09:00',
      location: 'Perth CBD',
    ),
  ];

  // THEME TOKENS
  static const Color kPrimary = Color(0xFF5C2E91);
  static const Color kPrimaryDark = Color(0xFF411C6E);
  static const Color kAccentGold = Color(0xFFF4C847);
  static const double kRadius = 20;

  @override
  void initState() {
    super.initState();

    final userId = context
        .read<AuthenticationBloc>()
        .state
        .userDetails!
        .userId
        .toString();

    _hubService = DispatchHubService(
      baseUrl: "http://192.3.3.187:85",
      userId: userId,
      onLog: (m) => debugPrint("HUB: $m"),
      onNotification: (payload) =>
          debugPrint("📩 HUB NOTIFICATION: $payload"),

      // ✅ THIS IS THE MAIN THING
      onBookingOffer: (offer) {
        debugPrint("🎯 OFFER RECEIVED IN UI: ${offer.bookingDetailId}");
        _showBookingPopup(offer);
      },
    );

      WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (!mounted) return;

    final saved = box.read(_kAvailabilityKey) == true;

    setState(() {
      available = saved;
      _restored = true;
    });

    // ✅ if it was ON, auto-start hub + timer
    if (saved) {
      await _startLocationUpdates();
    }
  });
  }

  /// ✅ POPUP (runs safely even if signalr fires in background)
  void _showBookingPopup(TaskerBookingOffer offer) {
    if (!mounted) return;

    // avoid duplicates
    if (_dialogOpen) return;
    if (_lastPopupBookingDetailId == offer.bookingDetailId) return;

    _lastPopupBookingDetailId = offer.bookingDetailId;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (_dialogOpen) return;

      _dialogOpen = true;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            title: const Text("New Booking Offer"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(offer.message),
                const SizedBox(height: 10),
                Text("BookingDetailId: ${offer.bookingDetailId}"),
                Text("Estimated Cost: \$${offer.estimatedCost.toStringAsFixed(0)}"),
                Text("Lat: ${offer.lat}"),
                Text("Lng: ${offer.lng}"),
                const SizedBox(height: 10),
                const Text(
                  "Please respond within 1 minute",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);

                  // ✅ TODO: call your decline API / bloc event here
                  // context.read<UserBookingBloc>().add(DeclineOfferRequested(offer.bookingDetailId));
                },
                child: const Text("Decline"),
              ),
              ElevatedButton(
                onPressed: () {
                   context.read<UserBookingBloc>().add(AcceptBooking(userId:"2b6bb0c3-6f05-4d04-948e-a2bbf5320f0a", //context.read<UserBookingBloc>().state.bookingFindResponse!.result.first.userId,
                    bookingDetailId: offer.bookingDetailId));
                 // Navigator.pop(ctx);
                  

                  // ✅ TODO: call your accept API / bloc event here
                  // context.read<UserBookingBloc>().add(AcceptOfferRequested(offer.bookingDetailId));
                },
                child: const Text("Accept"),
              ),
            ],
          );
        },
      );

      if (mounted) {
        _dialogOpen = false;
      }
    });
  }

  Future<void> _onAvailabilityToggle(bool value) async {
  // ✅ save immediately
  await box.write(_kAvailabilityKey, value);

  if (!value) {
    setState(() => available = false);
    _stopLocationUpdates();
    await _hubService.stop();
    return;
  }

  setState(() => available = true);
  await _startLocationUpdates();
}


  // Future<void> _onAvailabilityToggle(bool value) async {
  //   if (!value) {
  //     setState(() => available = false);
  //     _stopLocationUpdates();
  //     await _hubService.stop();
  //     return;
  //   }

  //   setState(() => available = true);
  //   await _startLocationUpdates();
  // }

  void _dispatchLocationUpdateToApi() {
    final userId = context
        .read<AuthenticationBloc>()
        .state
        .userDetails!
        .userId
        .toString();

    const double lat = 67.00;
    const double lng = 70.00;

    if (!mounted) return;

    context.read<UserBookingBloc>().add(
          UpdateUserLocationRequested(
            userId: userId,
            latitude: lat,
            longitude: lng,
          ),
        );

    context.read<UserBookingBloc>().add(
          ChangeAvailabilityStatus(userId: userId),
        );
  }

  Future<void> _startLocationUpdates() async {
  if (!_restored) return; // ✅ avoids starting before init restore finishes

  try {
    await _hubService.start();
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect SignalR hub: $e')),
      );
    }

    // ✅ rollback + persist OFF if start fails
    await box.write(_kAvailabilityKey, false);
    setState(() => available = false);
    return;
  }

  _dispatchLocationUpdateToApi();

  _locationTimer?.cancel();
  _locationTimer = Timer.periodic(_locationInterval, (_) {
    _dispatchLocationUpdateToApi();
  });
}


 /* Future<void> _startLocationUpdates() async {
    try {
      await _hubService.start();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect SignalR hub: $e')),
        );
      }
      setState(() => available = false);
      return;
    }

    _dispatchLocationUpdateToApi();

    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(_locationInterval, (_) {
      _dispatchLocationUpdateToApi();
    });
  }*/

  void _stopLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _hubService.stop();
    _hubService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = context
        .read<AuthenticationBloc>()
        .state
        .userDetails!
        .fullName
        .toString();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenH = MediaQuery.of(context).size.height;
    final expanded = (screenH * 0.28).clamp(220.0, 320.0);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F12) : const Color(0xFFF8F7FB),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: expanded,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: _Header(
                name: name,
                available: available,
                onToggle: _onAvailabilityToggle,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -30),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _GlassCard(
                            child: _ProfileCard(
                              avatarUrl: _avatarUrl,
                              name: 'Mark',
                              title: _title,
                              badges: _badges,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _GlassCard(
                            child: _EarningCard(
                              amount: period == 'Week' ? weeklyEarning : monthlyEarning,
                              sub: 'Earnings per ${period.toLowerCase()}',
                              period: period,
                              onChangePeriod: (p) => setState(() => period = p),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _GlassCard(
                      child: _KpiRow(
                        rating: rating,
                        reviews: reviews,
                        acceptance: acceptanceRate,
                        completion: completionRate,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Upcoming Tasks',
                      onViewMore: _onViewMoreUpcoming,
                      child: Column(
                        children: [
                          for (final t in upcoming) _TaskTile(task: t),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Current Tasks',
                      onViewMore: _onViewMoreCurrent,
                      child: Column(
                        children: [
                          for (final t in current)
                            _TaskTile(
                              task: t,
                              trailing: _PrimaryButton(
                                label: 'DIRECTION',
                                icon: Icons.arrow_forward_rounded,
                                onTap: _onDirectionTap,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onViewMoreUpcoming() {}
  void _onViewMoreCurrent() {}
  void _onDirectionTap() {}
}

/* ===================== UI PARTS (same as before) ===================== */

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.available,
    required this.onToggle,
  });

  final String name;
  final bool available;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipPath(
          clipper: _HeaderClipper(),
          child: Container(
            // ✅ FIX: remove const so it won’t complain
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _TaskerHomeRedesignState.kPrimaryDark,
                  _TaskerHomeRedesignState.kPrimary,
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello $name,',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Gigs are rolling in, let's go!!",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withOpacity(0.18)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Available',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
                          Switch.adaptive(
                            value: available,
                            onChanged: onToggle,
                            activeColor: _TaskerHomeRedesignState.kAccentGold,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// باقي UI widgets same as your code (GlassCard/ProfileCard/Earning/KPI/Section/TaskTile/Button/Badge/Clipper)
// ✅ Keep them unchanged — you can paste your existing ones as-is


class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final compact = w < 360;
        final wide = w > 720;

        final radius =
            compact ? 16.0 : (wide ? 24.0 : 26);
        final padAll = compact ? 12.0 : (wide ? 18.0 : 14.0);
        final marginV = compact ? 4.0 : 6.0;
        final blur = wide ? 22.0 : 18.0;
        final offsetY = wide ? 10.0 : 8.0;

        return Container(
          margin: EdgeInsets.symmetric(vertical: marginV),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1B20) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: blur,
                offset: Offset(0, offsetY),
              ),
            ],
            border: Border.all(
              color: isDark ? const Color(0xFF2A2C33) : const Color(0xFFF0ECF6),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(padAll),
            child: child,
          ),
        );
      },
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.avatarUrl,
    required this.name,
    required this.title,
    required this.badges,
  });

  final String avatarUrl;
  final String name;
  final String title;
  final List<_Badge> badges;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final narrow = w < 340;
        final wide = w > 600;

        final avatarR = narrow ? 24.0 : (wide ? 32.0 : 28.0);
        final gap = narrow ? 10.0 : 12.0;
        final nameStyle = TextStyle(
          fontSize: narrow ? 15 : (wide ? 18 : 16),
          fontWeight: FontWeight.w700,
        );
        final titleStyle = TextStyle(
          color: Colors.grey.shade600,
          fontSize: narrow ? 11 : (wide ? 13 : 12),
        );

        final info = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: nameStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(title, style: titleStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final b in badges) _BadgeChip(badge: b),
              ],
            ),
          ],
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(radius: avatarR, backgroundImage: NetworkImage(avatarUrl)),
            SizedBox(width: gap),
            Expanded(child: info),
          ],
        );
      },
    );
  }
}

class _EarningCard extends StatelessWidget {
  const _EarningCard({
    required this.amount,
    required this.sub,
    required this.period,
    required this.onChangePeriod,
  });

  final int amount;
  final String sub;
  final String period;
  final ValueChanged<String> onChangePeriod;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final isNarrow = w < 340;
        final isMedium = w < 420;

        final titleStyle = TextStyle(
          fontSize: isMedium ? 11 : 12,
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w600,
        );

        final switcher = Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F1F8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SegmentPill(
                label: 'Week',
                selected: period == 'Week',
                onTap: () => onChangePeriod('Week'),
              ),
              _SegmentPill(
                label: 'Month',
                selected: period == 'Month',
                onTap: () => onChangePeriod('Month'),
              ),
            ],
          ),
        );

        final header = isNarrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Earnings', style: titleStyle),
                  const SizedBox(height: 8),
                  switcher,
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Earnings', style: titleStyle),
                  switcher,
                ],
              );

        final amountText = FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            '\$${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: isMedium ? 24 : 26,
              fontWeight: FontWeight.w800,
            ),
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [Expanded(child: amountText)],
            ),
            const SizedBox(height: 4),
            Text(
              sub,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: isMedium ? 11 : 12,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SegmentPill extends StatelessWidget {
  const _SegmentPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _TaskerHomeRedesignState.kAccentGold : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({
    required this.rating,
    required this.reviews,
    required this.acceptance,
    required this.completion,
  });

  final double rating;
  final int reviews;
  final int acceptance;
  final int completion;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final maxW = c.maxWidth;
        final isNarrow = maxW < 360;
        final itemW = isNarrow ? maxW : ((maxW - 16) / 3);
        final tiles = [
          SizedBox(
            width: itemW,
            child: _KpiTile(
              icon: Icons.star_rate_rounded,
              color: const Color(0xFFFFE082),
              title: rating.toStringAsFixed(1),
              sub: '$reviews reviews',
            ),
          ),
          SizedBox(
            width: itemW,
            child: _KpiTile(
              icon: Icons.bolt,
              color: const Color(0xFFC5E1A5),
              title: '$acceptance%',
              sub: 'acceptance',
            ),
          ),
          SizedBox(
            width: itemW,
            child: _KpiTile(
              icon: Icons.check_circle_rounded,
              color: const Color(0xFFB3E5FC),
              title: '$completion%',
              sub: 'completion',
            ),
          ),
        ];
        return Wrap(spacing: 8, runSpacing: 8, children: tiles);
      },
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.sub,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF202127)
            : const Color(0xFFF8F7FB),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: const Icon(Icons.star_rate_rounded, size: 20, color: Colors.black87),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              Text(sub, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.onViewMore,
  });

  final String title;
  final Widget child;
  final VoidCallback? onViewMore;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const Spacer(),
              if (onViewMore != null)
                TextButton(onPressed: onViewMore, child: const Text('View more')),
            ],
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    this.trailing,
  });

  final _Task task;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final isNarrow = c.maxWidth < 380;
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.calendar_month, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(task.date, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                const SizedBox(width: 14),
                Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(task.time, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                const SizedBox(width: 14),
                Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    task.location,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        );

        Widget row;
        if (!isNarrow) {
          row = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: content),
              if (trailing != null) const SizedBox(width: 12),
              if (trailing != null)
                Flexible(
                  fit: FlexFit.loose,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints.tightFor(width: 160, height: 44),
                      child: trailing!,
                    ),
                  ),
                ),
            ],
          );
        } else {
          row = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              content,
              if (trailing != null) const SizedBox(height: 10),
              if (trailing != null)
                SizedBox(width: double.infinity, height: 44, child: trailing!),
            ],
          );
        }

        return Column(
          children: [
            row,
            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    this.icon,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints.tightFor(width: 160, height: 44),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _TaskerHomeRedesignState.kPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (icon != null) const SizedBox(width: 8),
            if (icon != null) Icon(icon, size: 20),
          ],
        ),
      ),
    );
  }
}

class _Badge {
  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;

  const _Badge({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
  });
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.badge});
  final _Badge badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: badge.bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badge.icon, size: 14, color: badge.fg),
          const SizedBox(width: 3),
          Text(
            badge.label,
            style: TextStyle(fontSize: 11, color: badge.fg, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _Task {
  final String title;
  final String date;
  final String time;
  final String location;

  const _Task({
    required this.title,
    required this.date,
    required this.time,
    required this.location,
  });
}

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 80);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height - 30,
      size.width * 0.5,
      size.height - 40,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height - 50,
      size.width,
      size.height - 10,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

