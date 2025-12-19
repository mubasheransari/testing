import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_bloc.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_bloc.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_event.dart';
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

  /// ================== popup (same design, clean theme) ==================
  void _showBookingPopup(TaskerBookingOffer offer) {
    if (!mounted) return;
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
  barrierColor: Colors.black.withOpacity(0.55),
  builder: (ctx) {
    const kGold = Color(0xFFF4C847);

    String mmss(int totalSeconds) {
      final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
      final s = (totalSeconds % 60).toString().padLeft(2, '0');
      return '$m:$s';
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

    // ✅ IMPORTANT: these must be OUTSIDE StatefulBuilder (persist across rebuilds)
    const int totalSeconds = 60;
    int secondsLeft = totalSeconds;
    Timer? t;
    bool started = false;

    void closeDialog() {
      t?.cancel();
      t = null;
      if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
    }

    return StatefulBuilder(
      builder: (context, setState) {
        // ✅ start timer only once
        if (!started) {
          started = true;
          t = Timer.periodic(const Duration(seconds: 1), (_) {
            if (!Navigator.of(ctx).mounted) {
              t?.cancel();
              return;
            }

            if (secondsLeft <= 1) {
              closeDialog();
              return;
            }

            setState(() => secondsLeft--);
          });
        }

        // ✅ compute INSIDE builder so it updates every rebuild
        final timeText = mmss(secondsLeft);

        // ✅ progress 1.0 -> 0.0
        final progress = (secondsLeft / totalSeconds).clamp(0.0, 1.0);

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
                        const Icon(Icons.close_rounded, color: Colors.transparent),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // ✅ countdown bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: kPrimary.withOpacity(0.10),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          secondsLeft <= 10
                              ? Colors.redAccent
                              : (secondsLeft <= 25 ? kGold : kPrimary),
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
                        border: Border.all(color: kPrimary.withOpacity(0.12)),
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
                            value: "\$${offer.estimatedCost.toStringAsFixed(0)}",
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: infoTile(
                            icon: Icons.timer_outlined,
                            label: "Time Left",
                            value: timeText,
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

                    // ✅ THIS TEXT WILL NOW UPDATE EVERY SECOND
                    // Row(
                    //   children: [
                    //     Container(
                    //       width: 10,
                    //       height: 10,
                    //       decoration: const BoxDecoration(
                    //         color: kGold,
                    //         shape: BoxShape.circle,
                    //       ),
                    //     ),
                    //     const SizedBox(width: 8),
                    //     Expanded(
                    //       child: Text(
                    //         "Please respond within $timeText minute.",
                    //         style: const TextStyle(
                    //           fontFamily: 'Poppins',
                    //           fontSize: 12.5,
                    //           color: kMuted,
                    //           fontWeight: FontWeight.w600,
                    //         ),
                    //       ),
                    //     ),
                    //   ],
                    // ),

                   // const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: closeDialog,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kPrimary,
                              side: BorderSide(color: kPrimary.withOpacity(0.35)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
                                      bookingDetailId: offer.bookingDetailId,
                                    ),
                                  );
                                  Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
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


      // await showDialog(
      //   context: context,
      //   barrierDismissible: false,
      //   barrierColor: Colors.black.withOpacity(0.55),
      //   builder: (ctx) {
      //     const kGold = Color(0xFFF4C847);

      //     String mmss(int totalSeconds) {
      //       final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
      //       final s = (totalSeconds % 60).toString().padLeft(2, '0');
      //       return '$m:$s';
      //     }

      //     Widget infoTile({
      //       required IconData icon,
      //       required String label,
      //       required String value,
      //     }) {
      //       return Container(
      //         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      //         decoration: BoxDecoration(
      //           color: kPrimary.withOpacity(0.06),
      //           borderRadius: BorderRadius.circular(14),
      //           border: Border.all(color: kPrimary.withOpacity(0.15)),
      //         ),
      //         child: Row(
      //           children: [
      //             Container(
      //               width: 34,
      //               height: 34,
      //               decoration: BoxDecoration(
      //                 color: kPrimary.withOpacity(0.12),
      //                 borderRadius: BorderRadius.circular(12),
      //               ),
      //               child: Icon(icon, color: kPrimary, size: 18),
      //             ),
      //             const SizedBox(width: 10),
      //             Expanded(
      //               child: Column(
      //                 crossAxisAlignment: CrossAxisAlignment.start,
      //                 children: [
      //                   Text(
      //                     label,
      //                     style: const TextStyle(
      //                       fontFamily: 'Poppins',
      //                       fontSize: 11.5,
      //                       color: kMuted,
      //                       fontWeight: FontWeight.w500,
      //                     ),
      //                   ),
      //                   const SizedBox(height: 2),
      //                   Text(
      //                     value,
      //                     maxLines: 2,
      //                     overflow: TextOverflow.ellipsis,
      //                     style: const TextStyle(
      //                       fontFamily: 'Poppins',
      //                       fontSize: 13.5,
      //                       color: kTextDark,
      //                       fontWeight: FontWeight.w700,
      //                     ),
      //                   ),
      //                 ],
      //               ),
      //             ),
      //           ],
      //         ),
      //       );
      //     }

      //     return StatefulBuilder(
      //       builder: (context, setState) {
      //         int secondsLeft = 60;
      //         Timer? t;

      //         WidgetsBinding.instance.addPostFrameCallback((_) {
      //           if (t != null) return;
      //           t = Timer.periodic(const Duration(seconds: 1), (_) {
      //             if (!Navigator.of(ctx).mounted) {
      //               t?.cancel();
      //               return;
      //             }
      //             if (secondsLeft <= 1) {
      //               t?.cancel();
      //               if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
      //               return;
      //             }
      //             setState(() => secondsLeft--);
      //           });
      //         });

      //         void closeDialog() {
      //           t?.cancel();
      //           if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
      //         }

      //         final timeText = mmss(secondsLeft);

      //         return WillPopScope(
      //           onWillPop: () async => false,
      //           child: Center(
      //             child: Material(
      //               color: Colors.transparent,
      //               child: Container(
      //                 width: MediaQuery.of(ctx).size.width * 0.88,
      //                 constraints: const BoxConstraints(maxWidth: 420),
      //                 padding: const EdgeInsets.all(16),
      //                 decoration: BoxDecoration(
      //                   color: Colors.white,
      //                   borderRadius: BorderRadius.circular(22),
      //                   boxShadow: [
      //                     BoxShadow(
      //                       color: Colors.black.withOpacity(0.12),
      //                       blurRadius: 24,
      //                       offset: const Offset(0, 14),
      //                     ),
      //                   ],
      //                 ),
      //                 child: Column(
      //                   mainAxisSize: MainAxisSize.min,
      //                   children: [
      //                     Row(
      //                       children: [
      //                         Container(
      //                           width: 42,
      //                           height: 42,
      //                           decoration: BoxDecoration(
      //                             color: kGold.withOpacity(0.25),
      //                             borderRadius: BorderRadius.circular(14),
      //                           ),
      //                           child: const Icon(
      //                             Icons.notifications_active_rounded,
      //                             color: kPrimary,
      //                             size: 24,
      //                           ),
      //                         ),
      //                         const SizedBox(width: 12),
      //                         const Expanded(
      //                           child: Text(
      //                             "New Booking Offer",
      //                             style: TextStyle(
      //                               fontFamily: 'Poppins',
      //                               fontSize: 16,
      //                               color: kTextDark,
      //                               fontWeight: FontWeight.w800,
      //                             ),
      //                           ),
      //                         ),
      //                         const Icon(Icons.close_rounded, color: Colors.transparent),
      //                       ],
      //                     ),
      //                     const SizedBox(height: 10),

      //                     Container(
      //                       width: double.infinity,
      //                       padding: const EdgeInsets.all(12),
      //                       decoration: BoxDecoration(
      //                         color: kPrimary.withOpacity(0.06),
      //                         borderRadius: BorderRadius.circular(16),
      //                         border: Border.all(color: kPrimary.withOpacity(0.12)),
      //                       ),
      //                       child: Text(
      //                         offer.message,
      //                         style: const TextStyle(
      //                           fontFamily: 'Poppins',
      //                           fontSize: 13,
      //                           color: kTextDark,
      //                           fontWeight: FontWeight.w600,
      //                           height: 1.35,
      //                         ),
      //                       ),
      //                     ),

      //                     const SizedBox(height: 12),

      //                     Row(
      //                       children: [
      //                         Expanded(
      //                           child: infoTile(
      //                             icon: Icons.attach_money_rounded,
      //                             label: "Estimated",
      //                             value: "\$${offer.estimatedCost.toStringAsFixed(0)}",
      //                           ),
      //                         ),
      //                         const SizedBox(width: 10),
      //                         Expanded(
      //                           child: infoTile(
      //                             icon: Icons.timer_outlined,
      //                             label: "Time Left",
      //                             value: timeText,
      //                           ),
      //                         ),
      //                       ],
      //                     ),

      //                     const SizedBox(height: 10),

      //                     Row(
      //                       children: [
      //                         Expanded(
      //                           child: infoTile(
      //                             icon: Icons.my_location_outlined,
      //                             label: "Latitude",
      //                             value: offer.lat.toStringAsFixed(4),
      //                           ),
      //                         ),
      //                         const SizedBox(width: 10),
      //                         Expanded(
      //                           child: infoTile(
      //                             icon: Icons.my_location_outlined,
      //                             label: "Longitude",
      //                             value: offer.lng.toStringAsFixed(4),
      //                           ),
      //                         ),
      //                       ],
      //                     ),

      //                     const SizedBox(height: 14),

      //                     Row(
      //                       children: [
      //                         Container(
      //                           width: 10,
      //                           height: 10,
      //                           decoration: const BoxDecoration(
      //                             color: kGold,
      //                             shape: BoxShape.circle,
      //                           ),
      //                         ),
      //                         const SizedBox(width: 8),
      //                         Expanded(
      //                           child: Text(
      //                             "Please respond within $timeText",
      //                             style: const TextStyle(
      //                               fontFamily: 'Poppins',
      //                               fontSize: 12.5,
      //                               color: kMuted,
      //                               fontWeight: FontWeight.w600,
      //                             ),
      //                           ),
      //                         ),
      //                       ],
      //                     ),

      //                     const SizedBox(height: 16),

      //                     Row(
      //                       children: [
      //                         Expanded(
      //                           child: OutlinedButton(
      //                             onPressed: closeDialog,
      //                             style: OutlinedButton.styleFrom(
      //                               foregroundColor: kPrimary,
      //                               side: BorderSide(color: kPrimary.withOpacity(0.35)),
      //                               padding: const EdgeInsets.symmetric(vertical: 12),
      //                               shape: RoundedRectangleBorder(
      //                                 borderRadius: BorderRadius.circular(14),
      //                               ),
      //                             ),
      //                             child: const Text(
      //                               "Decline",
      //                               style: TextStyle(
      //                                 fontFamily: 'Poppins',
      //                                 fontWeight: FontWeight.w700,
      //                               ),
      //                             ),
      //                           ),
      //                         ),
      //                         const SizedBox(width: 12),
      //                         Expanded(
      //                           child: ElevatedButton(
      //                             onPressed: () {
      //                               // ✅ keep your accept logic (same event you already use)
      //                               context.read<UserBookingBloc>().add(
      //                                     AcceptBooking(
      //                                       userId: context
      //                                           .read<AuthenticationBloc>()
      //                                           .state
      //                                           .userDetails!
      //                                           .userId
      //                                           .toString(),
      //                                       bookingDetailId: offer.bookingDetailId,
      //                                     ),
      //                                   );
      //                             },
      //                             style: ElevatedButton.styleFrom(
      //                               backgroundColor: kPrimary,
      //                               foregroundColor: Colors.white,
      //                               padding: const EdgeInsets.symmetric(vertical: 12),
      //                               shape: RoundedRectangleBorder(
      //                                 borderRadius: BorderRadius.circular(14),
      //                               ),
      //                               elevation: 0,
      //                             ),
      //                             child: const Text(
      //                               "Accept",
      //                               style: TextStyle(
      //                                 fontFamily: 'Poppins',
      //                                 fontWeight: FontWeight.w800,
      //                               ),
      //                             ),
      //                           ),
      //                         ),
      //                       ],
      //                     ),
      //                   ],
      //                 ),
      //               ),
      //             ),
      //           ),
      //         );
      //       },
      //     );
      //   },
      // );

      if (mounted) _dialogOpen = false;
    });
  }

  /// ================== availability toggle (persisted) ==================
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




/*
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
// ✅ Designed dialog with 1-minute countdown + NO booking id
// ✅ Designed dialog with 1-minute countdown + NO booking id
await showDialog(
  context: context,
  barrierDismissible: false,
  barrierColor: Colors.black.withOpacity(0.55),
  builder: (ctx) {
    const kPrimary = Color(0xFF5C2E91);
    const kTextDark = Color(0xFF3E1E69);
    const kMuted = Color(0xFF75748A);
    const kGold = Color(0xFFF4C847);

    Widget infoRow({
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

    String _mmss(int totalSeconds) {
      final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
      final s = (totalSeconds % 60).toString().padLeft(2, '0');
      return '$m:$s';
    }

    // ✅ dialog-local countdown state (no need to change your screen state)
    return StatefulBuilder(
      builder: (context, setState) {
        // Start at 60 seconds
        int secondsLeft = 60;
        Timer? t;

        // Start timer once after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (t != null) return; // already started
          t = Timer.periodic(const Duration(seconds: 1), (_) {
            if (!Navigator.of(ctx).mounted) {
              t?.cancel();
              return;
            }

            if (secondsLeft <= 1) {
              t?.cancel();
              // ✅ auto-close when time ends
              if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
              return;
            }

            setState(() => secondsLeft--);
          });
        });

        // If dialog is popped manually, cancel timer
        void closeDialog() {
          t?.cancel();
          if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
        }

        final timeText = _mmss(secondsLeft);

        return WillPopScope(
          onWillPop: () async => false, // block back
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
                    // Header
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
                        // (hidden close icon to keep layout balanced)
                        const Icon(Icons.close_rounded,
                            color: Colors.transparent),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Message card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kPrimary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kPrimary.withOpacity(0.12)),
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

                    // Details (NO booking id)
                    Row(
                      children: [
                        Expanded(
                          child: infoRow(
                            icon: Icons.attach_money_rounded,
                            label: "Estimated",
                            value:
                                "\$${offer.estimatedCost.toStringAsFixed(0)}",
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: infoRow(
                            icon: Icons.timer_outlined,
                            label: "Time Left",
                            value: timeText, // ✅ live countdown
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: infoRow(
                            icon: Icons.my_location_outlined,
                            label: "Latitude",
                            value: offer.lat.toStringAsFixed(4),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: infoRow(
                            icon: Icons.my_location_outlined,
                            label: "Longitude",
                            value: offer.lng.toStringAsFixed(4),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Footer warning
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: kGold,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Please respond within $timeText",
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12.5,
                              color: kMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              closeDialog();
                              // TODO: decline
                              // context.read<UserBookingBloc>().add(DeclineOfferRequested(offer.bookingDetailId));
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kPrimary,
                              side: BorderSide(color: kPrimary.withOpacity(0.35)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
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
                              // ✅ keep your accept logic
                              context.read<UserBookingBloc>().add(
                                    AcceptBooking(
                                      userId:
                                          "2b6bb0c3-6f05-4d04-948e-a2bbf5320f0a",
                                      bookingDetailId: offer.bookingDetailId,
                                    ),
                                  );

                              // optional: close immediately (or keep open until success)
                              // closeDialog();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
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

*/