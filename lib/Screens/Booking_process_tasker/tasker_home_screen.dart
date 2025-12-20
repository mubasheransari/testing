import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_bloc.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_bloc.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_event.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'dart:convert';
enum PopupCloseReason { autoTimeout, declined, accepted }


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

      // Sometimes signalR gives list wrapper
      if (obj is List && obj.isNotEmpty) {
        obj = obj[0];
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
          estimatedCost:
              _toDouble(data['estimatedCost'] ?? data['EstimatedCost'] ?? 0),
          message: (map['message'] ?? '').toString(),
          type: map['type']?.toString(),
          date: map['date']?.toString(),
        );
      }

      // fallback: payload itself contains fields
      final bookingDetailId =
          (map['bookingDetailId'] ?? map['BookingDetailId'])?.toString();
      if (bookingDetailId == null || bookingDetailId.isEmpty) return null;

      return TaskerBookingOffer(
        bookingDetailId: bookingDetailId,
        lat: _toDouble(map['lat'] ?? map['Lat']),
        lng: _toDouble(map['lng'] ?? map['Lng']),
        estimatedCost:
            _toDouble(map['estimatedCost'] ?? map['EstimatedCost'] ?? 0),
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
/// ✅ SIGNALR SERVICE (LongPolling + reconnect) - your style
/// ===============================================================
class DispatchHubService {
  DispatchHubService({
    required this.baseUrl,
    required this.userId,
    this.onNotification,
    this.onBookingOffer,
    this.onLog,
  });

  final String baseUrl; // e.g. http://192.3.3.187:85
  final String userId;

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
    void handle(dynamic payload, String tag) {
      _log("📩 $tag RAW → ${_pretty(payload)}");
      onNotification?.call(payload);

      final offer = TaskerBookingOffer.tryParse(payload);
      if (offer != null) {
        _log("✅ BookingOffer parsed → bookingDetailId=${offer.bookingDetailId}");
        onBookingOffer?.call(offer);
      }
    }

    c.on("receivenotification", (args) {
      final payload = (args != null && args.isNotEmpty) ? args[0] : args;
      handle(payload, "receivenotification");
    });

    c.on("ReceiveNotification", (args) {
      final payload = (args != null && args.isNotEmpty) ? args[0] : args;
      handle(payload, "ReceiveNotification");
    });

    c.onclose(({Exception? error}) {
      _log("🔌 onclose: ${error?.toString() ?? 'none'}");
      if (!_isStarting && !_isStopping) _startReconnect();
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


class TaskerHomeRedesign extends StatefulWidget {
  const TaskerHomeRedesign({super.key});

  @override
  State<TaskerHomeRedesign> createState() => _TaskerHomeRedesignState();
}

class _TaskerHomeRedesignState extends State<TaskerHomeRedesign> {
  // theme tokens (same feel as UserBookingHome)
  static const Color kPrimary = Color(0xFF5C2E91);
  static const Color kTextDark = Color(0xFF3E1E69);
  static const Color kMuted = Color(0xFF75748A);
  static const Color kBg = Color(0xFFF8F7FB);

  bool available = false;
  String period = 'Week';
  final box = GetStorage();
  static const String _kAvailabilityKey = 'tasker_available';
  bool _restored = false;

  late final DispatchHubService _hubService;

  Timer? _locationTimer;
  static const Duration _locationInterval = Duration(seconds: 5);

  // popup guards
  bool _dialogOpen = false;
  String? _lastPopupBookingDetailId;

  // SAME CONTENT (your mock data)
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
    _Task(title: 'Furniture assembly', date: 'Apr 24', time: '10:30', location: 'East Perth'),
  ];

  final List<_Task> current = const [
    _Task(title: 'TV wall mount', date: 'Apr 24', time: '09:00', location: 'Perth CBD'),
  ];

  // UI chip filter (UserBookingHome style)
  String _selectedChip = 'All';
  final List<String> _chipLabels = const ['All', 'Upcoming', 'Current'];

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
      onLog: (m) => debugPrint("TASKER HUB: $m"),
      onNotification: (payload) => debugPrint("📩 TASKER HUB payload: $payload"),
      onBookingOffer: (offer) => _showBookingPopup(offer),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final saved = box.read(_kAvailabilityKey) == true;
      setState(() {
        available = saved;
        _restored = true;
      });

      if (saved) await _startLocationUpdates();
    });
  }

  void _showBookingPopup(TaskerBookingOffer offer) {
  if (!mounted) return;
  if (_dialogOpen) return;

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (!mounted || _dialogOpen) return;

    _dialogOpen = true;
    _lastPopupBookingDetailId = offer.bookingDetailId;

    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.55),
        builder: (ctx) {
          const kGold = Color(0xFFF4C847);
          const int totalSeconds = 60;

          int secondsLeft = totalSeconds;
          Timer? timer;
          bool closed = false;

          String mmss(int s) =>
              '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

          void closeDialog() {
            if (closed) return;
            closed = true;

            timer?.cancel();
            timer = null;

            if (Navigator.of(ctx, rootNavigator: true).canPop()) {
              Navigator.of(ctx, rootNavigator: true).pop();
            }
          }

          Widget infoTile({
            required IconData icon,
            required String label,
            required String value,
          }) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kPrimary.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: kPrimary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11.5,
                            color: kMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          value,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13.5,
                            color: kTextDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return StatefulBuilder(
            builder: (context, setState) {
              timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
                if (closed) return;

                if (secondsLeft <= 1) {
                  closeDialog(); // ✅ auto close at 0
                  return;
                }

                setState(() => secondsLeft--);
              });

              final progress =
                  (secondsLeft / totalSeconds).clamp(0.0, 1.0);

              return WillPopScope(
                onWillPop: () async => false,
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: MediaQuery.of(ctx).size.width * 0.88,
                      constraints: const BoxConstraints(maxWidth: 420),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 24,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: kGold.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.notifications_active_rounded,
                                  color: kPrimary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  "New Booking Offer",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                    color: kTextDark,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const Icon(Icons.close_rounded,
                                  color: Colors.transparent),
                            ],
                          ),

                          const SizedBox(height: 10),

                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: kPrimary.withOpacity(0.10),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                secondsLeft <= 10
                                    ? Colors.redAccent
                                    : (secondsLeft <= 25
                                        ? kGold
                                        : kPrimary),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: kPrimary.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: kPrimary.withOpacity(0.12)),
                            ),
                            child: Text(
                              offer.message,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: kTextDark,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: infoTile(
                                  icon: Icons.attach_money_rounded,
                                  label: "Estimated",
                                  value:
                                      "\$${offer.estimatedCost.toStringAsFixed(0)}",
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: infoTile(
                                  icon: Icons.timer_outlined,
                                  label: "Time Left",
                                  value: mmss(secondsLeft),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Expanded(
                                child: infoTile(
                                  icon: Icons.my_location_outlined,
                                  label: "Latitude",
                                  value: offer.lat.toStringAsFixed(4),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: infoTile(
                                  icon: Icons.my_location_outlined,
                                  label: "Longitude",
                                  value: offer.lng.toStringAsFixed(4),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: closeDialog,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: kPrimary,
                                    side: BorderSide(
                                        color: kPrimary.withOpacity(0.35)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    "Decline",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    context.read<UserBookingBloc>().add(
                                          AcceptBooking(
                                            userId: context
                                                .read<AuthenticationBloc>()
                                                .state
                                                .userDetails!
                                                .userId
                                                .toString(),
                                            bookingDetailId:
                                                offer.bookingDetailId,
                                          ),
                                        );
                                    closeDialog();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kPrimary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    "Accept",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w800,
                                    ),
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
              );
            },
          );
        },
      );
    } finally {
      // ✅ VERY IMPORTANT: reset guards so popup can show again
      _dialogOpen = false;
      _lastPopupBookingDetailId = null;
    }
  });
}



//   void _showBookingPopup(TaskerBookingOffer offer) {
//   if (!mounted) return;

//   // ❌ REMOVE permanent block
//   if (_dialogOpen) return;

//   WidgetsBinding.instance.addPostFrameCallback((_) async {
//     if (!mounted) return;
//     if (_dialogOpen) return;

//     _dialogOpen = true;
//     _lastPopupBookingDetailId = offer.bookingDetailId;

//     try {
//       await showDialog(
//         context: context,
//         barrierDismissible: false,
//         barrierColor: Colors.black.withOpacity(0.55),
//         builder: (ctx) {
//           const int totalSeconds = 60;
//           int secondsLeft = totalSeconds;
//           Timer? t;
//           bool closed = false;

//           void closeDialog(PopupCloseReason reason) {
//             if (closed) return;
//             closed = true;

//             t?.cancel();
//             t = null;

//             if (Navigator.of(ctx, rootNavigator: true).canPop()) {
//               Navigator.of(ctx, rootNavigator: true).pop();
//             }
//           }

//           return StatefulBuilder(
//             builder: (context, setState) {
//               t ??= Timer.periodic(const Duration(seconds: 1), (_) {
//                 if (closed) return;

//                 if (secondsLeft <= 1) {
//                   closeDialog(PopupCloseReason.autoTimeout);
//                   return;
//                 }
//                 setState(() => secondsLeft--);
//               });

//               final progress =
//                   (secondsLeft / totalSeconds).clamp(0.0, 1.0);

//               return WillPopScope(
//                 onWillPop: () async => false,
//                 child: Center(
//                   child: Material(
//                     color: Colors.transparent,
//                     child: Container(
//                       width: MediaQuery.of(ctx).size.width * 0.88,
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(22),
//                       ),
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           const Text(
//                             "New Booking Offer",
//                             style: TextStyle(
//                               fontFamily: 'Poppins',
//                               fontWeight: FontWeight.w800,
//                             ),
//                           ),

//                           const SizedBox(height: 12),

//                           LinearProgressIndicator(
//                             value: progress,
//                           ),

//                           const SizedBox(height: 16),

//                           Text(offer.message),

//                           const SizedBox(height: 20),

//                           Row(
//                             children: [
//                               Expanded(
//                                 child: OutlinedButton(
//                                   onPressed: () =>
//                                       closeDialog(PopupCloseReason.declined),
//                                   child: const Text("Decline"),
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: ElevatedButton(
//                                   onPressed: () {
//                                     context.read<UserBookingBloc>().add(
//                                           AcceptBooking(
//                                             userId: context
//                                                 .read<AuthenticationBloc>()
//                                                 .state
//                                                 .userDetails!
//                                                 .userId
//                                                 .toString(),
//                                             bookingDetailId:
//                                                 offer.bookingDetailId,
//                                           ),
//                                         );
//                                     closeDialog(PopupCloseReason.accepted);
//                                   },
//                                   child: const Text("Accept"),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       );
//     } finally {
//       // ✅ RESET GUARDS SO NEW OFFER CAN SHOW
//       _dialogOpen = false;
//       _lastPopupBookingDetailId = null;
//     }
//   });
// }



  Future<void> _onAvailabilityToggle(bool value) async {
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

  void _dispatchLocationUpdateToApi() {
    final userId = context
        .read<AuthenticationBloc>()
        .state
        .userDetails!
        .userId
        .toString();

    // ✅ replace with real GPS later
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
    if (!_restored) return;

    try {
      await _hubService.start();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect SignalR hub: $e')),
        );
      }

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

  /// ================== UI (UserBookingHome theme) ==================
  @override
  Widget build(BuildContext context) {
    final name = context
        .read<AuthenticationBloc>()
        .state
        .userDetails!
        .fullName
        .toString();

    final earnings = period == 'Week' ? weeklyEarning : monthlyEarning;

    final filteredTasks = _selectedChip == 'Upcoming'
        ? upcoming
        : _selectedChip == 'Current'
            ? current
            : [...current, ...upcoming];

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        title: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $name',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: kTextDark,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Ready for new gigs?',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: kMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Row(
              children: [
                const Text(
                  'Available',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: kPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Switch.adaptive(
                  value: available,
                  onChanged: _onAvailabilityToggle,
                  activeColor: kPrimary,
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //_SearchBar(),
              const SizedBox(height: 14),

              _InfoCard(
                icon: available ? Icons.wifi_tethering_rounded : Icons.wifi_off_rounded,
                text: available
                    ? 'You are online. New offers can arrive anytime.'
                    : 'You are offline. Turn on availability to receive offers.',
              ),
              const SizedBox(height: 14),

              // ✅ SAME CONTENT (profile + earnings) but in clean cards
              Row(
                children: [
                  // Expanded(
                  //   child: _WhiteCard(
                  //     child: _ProfileCard(
                  //       avatarUrl: _avatarUrl,
                  //       name: 'Mark',
                  //       title: _title,
                  //       badges: _badges,
                  //     ),
                  //   ),
                  // ),
                  // const SizedBox(width: 12),
                  Expanded(
                    child: _WhiteCard(
                      child: _EarningsCard(
                        period: period,
                        amount: earnings,
                        onChange: (p) => setState(() => period = p),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: MediaQuery.of(context).size.width *0.90,
                child: _WhiteCard(
                  child: _KpiRow(
                    rating: rating,
                    reviews: reviews,
                    acceptance: acceptanceRate,
                    completion: completionRate,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'Your jobs',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: kTextDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),

              _ChipsRow(
                labels: _chipLabels,
                selected: _selectedChip,
                onTap: (v) => setState(() => _selectedChip = v),
              ),

              const SizedBox(height: 14),

              _WhiteCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedChip == 'All' ? 'Recent activity' : '$_selectedChip tasks',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14.5,
                        color: kTextDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (filteredTasks.isEmpty)
                      const _EmptyState(text: 'No tasks yet. Turn on availability to get offers.')
                    else
                      Column(
                        children: [
                          for (int i = 0; i < filteredTasks.length; i++) ...[
                            _TaskTile(task: filteredTasks[i]),
                            if (i != filteredTasks.length - 1)
                              Divider(height: 18, color: Colors.grey.withOpacity(0.18)),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ===============================================================
/// ✅ SMALL UI WIDGETS (CLEAN THEME)
/// ===============================================================

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0,
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: TextField(
        style: const TextStyle(fontFamily: 'Poppins'),
        decoration: InputDecoration(
          hintText: 'Search jobs, bookings...',
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
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  static const Color kPrimary = Color(0xFF5C2E91);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimary.withOpacity(.07)),
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
              color: kPrimary.withOpacity(.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: kPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12.5,
                color: kPrimary,
              ),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: kPrimary),
        ],
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
        border: Border.all(color: const Color(0xFF5C2E91).withOpacity(0.06)),
      ),
      child: child,
    );
  }
}

class _ChipsRow extends StatelessWidget {
  const _ChipsRow({
    required this.labels,
    required this.selected,
    required this.onTap,
  });

  final List<String> labels;
  final String selected;
  final ValueChanged<String> onTap;

  static const Color kPrimary = Color(0xFF5C2E91);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final label = labels[i];
          final sel = label == selected;
          return GestureDetector(
            onTap: () => onTap(label),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? kPrimary : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: sel ? null : Border.all(color: kPrimary.withOpacity(.3)),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: sel ? Colors.white : kPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ),
          );
        },
      ),
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
    return Row(
      children: [
        CircleAvatar(radius: 26, backgroundImage: NetworkImage(avatarUrl)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: Color(0xFF3E1E69),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Color(0xFF75748A),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [for (final b in badges) _BadgeChip(badge: b)],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EarningsCard extends StatelessWidget {
  const _EarningsCard({
    required this.period,
    required this.amount,
    required this.onChange,
  });

  final String period;
  final int amount;
  final ValueChanged<String> onChange;

  static const Color kPrimary = Color(0xFF5C2E91);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Earnings',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: Color(0xFF75748A),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "\$${amount.toStringAsFixed(0)}",
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 24,
            color: Color(0xFF3E1E69),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'per ${period.toLowerCase()}',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: Color(0xFF75748A),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: kPrimary.withOpacity(0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Pill(
                label: 'Week',
                selected: period == 'Week',
                onTap: () => onChange('Week'),
              ),
              _Pill(
                label: 'Month',
                selected: period == 'Month',
                onTap: () => onChange('Month'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const Color kPrimary = Color(0xFF5C2E91);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? kPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : kPrimary,
          ),
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _KpiTile(
          icon: Icons.star_rate_rounded,
          title: rating.toStringAsFixed(1),
          sub: '$reviews reviews',
        ),
        _KpiTile(
          icon: Icons.bolt_rounded,
          title: '$acceptance%',
          sub: 'acceptance',
        ),
        _KpiTile(
          icon: Icons.check_circle_rounded,
          title: '$completion%',
          sub: 'completion',
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.icon,
    required this.title,
    required this.sub,
  });

  final IconData icon;
  final String title;
  final String sub;

  static const Color kPrimary = Color(0xFF5C2E91);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.of(context).size.width *0.90), // responsive-ish
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kPrimary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimary.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: kPrimary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: Color(0xFF3E1E69),
                  ),
                ),
                Text(
                  sub,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11.5,
                    color: Color(0xFF75748A),
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

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task});

  final _Task task;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          task.title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w800,
            fontSize: 14.5,
            color: Color(0xFF3E1E69),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.calendar_month_rounded, size: 16, color: Color(0xFF75748A)),
            const SizedBox(width: 6),
            Text(task.date, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF75748A))),
            const SizedBox(width: 14),
            const Icon(Icons.schedule_rounded, size: 16, color: Color(0xFF75748A)),
            const SizedBox(width: 6),
            Text(task.time, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF75748A))),
            const SizedBox(width: 14),
            const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF75748A)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                task.location,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF75748A)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          const Icon(Icons.inbox_rounded, size: 40, color: Color(0xFF75748A)),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12.5,
              color: Color(0xFF75748A),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
      decoration: BoxDecoration(
        color: badge.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badge.icon, size: 14, color: badge.fg),
          const SizedBox(width: 4),
          Text(
            badge.label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: badge.fg,
              fontWeight: FontWeight.w800,
            ),
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


