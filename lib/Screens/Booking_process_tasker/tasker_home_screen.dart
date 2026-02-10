import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_bloc.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_event.dart';
import 'dart:convert';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:taskoon/Repository/auth_repository.dart';
import 'package:taskoon/widgets/realtime/signalr_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

const Color kPrimary = Color(0xFF5C2E91);
const Color kTextDark = Color(0xFF3E1E69);
const Color kMuted = Color(0xFF75748A);
const Color kBg = Color(0xFFF8F7FB);

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

enum PopupCloseReason { autoTimeout, declined, accepted }

class TaskerBookingOffer {
  final String bookingDetailId;
  final double lat;
  final double lng;
  final double estimatedCost;

  final String? bookingService;
  final String? userName;
  final double? bookingDuration;
  final DateTime? bookingTime;
  final double? distanceKm;
  final String? location;

  final String message;
  final String? type;
  final String? date;

  TaskerBookingOffer({
    required this.bookingDetailId,
    required this.lat,
    required this.lng,
    required this.estimatedCost,
    this.bookingService,
    this.userName,
    this.bookingDuration,
    this.bookingTime,
    this.distanceKm,
    this.location,
    required this.message,
    this.type,
    this.date,
  });

  Map<String, String> toDisplayMap() {
    String fmtDate(DateTime? dt) {
      if (dt == null) return "";
      final d = dt.toLocal();
      return "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
    }

    String fmtTime(DateTime? dt) {
      if (dt == null) return "";
      final t = dt.toLocal();
      return "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
    }

    final map = <String, String>{
      "Service": bookingService ?? "",
      "User Name": userName ?? "",
      "Distance": distanceKm == null ? "" : "${distanceKm!.toStringAsFixed(2)} km",
      "Location": location ?? "",
      "Estimated Cost": estimatedCost == 0 ? "" : "\$${estimatedCost.toStringAsFixed(2)}",
      "Duration": bookingDuration == null ? "" : "${bookingDuration!.toStringAsFixed(1)} hr",
      "Booking Date": fmtDate(bookingTime),
      "Booking Time": fmtTime(bookingTime),
      "Notification Date": (date ?? "").isEmpty ? "" : date!,
      "Type": type ?? "",
      "Message": message,
    };

    map.removeWhere((k, v) => v.trim().isEmpty);
    return map;
  }

  static TaskerBookingOffer? tryParse(dynamic payload) {
    try {
      dynamic obj = payload;

      // SignalR sometimes sends [ {..} ]
      if (obj is List && obj.isNotEmpty) obj = obj.first;

      // Server can send json string
      if (obj is String) obj = jsonDecode(obj);

      if (obj is! Map) {
        debugPrint("❌ tryParse: payload is not Map => ${obj.runtimeType}");
        return null;
      }

      final map = Map<String, dynamic>.from(obj);

      dynamic dataAny = map['data'];
      if (dataAny is String) {
        try {
          dataAny = jsonDecode(dataAny);
        } catch (_) {}
      }

      Map<String, dynamic>? data;
      if (dataAny is Map) data = Map<String, dynamic>.from(dataAny);

      final bookingDetailId =
          (data?['bookingDetailId'] ?? data?['BookingDetailId'] ?? map['bookingDetailId'] ?? map['BookingDetailId'])
              ?.toString();

      if (bookingDetailId == null || bookingDetailId.isEmpty) {
        debugPrint("❌ tryParse: bookingDetailId missing. keys=${map.keys}");
        return null;
      }

      final lat = _toDouble(data?['lat'] ?? data?['Lat'] ?? map['lat'] ?? map['Lat'] ?? 0);
      final lng = _toDouble(data?['lng'] ?? data?['Lng'] ?? map['lng'] ?? map['Lng'] ?? 0);

      final estimatedCost = _toDouble(
        data?['estimatedCost'] ?? data?['EstimatedCost'] ?? map['estimatedCost'] ?? map['EstimatedCost'] ?? 0,
      );

      final bookingService = (data?['bookingService'] ?? data?['BookingService'])?.toString();
      final userName = (data?['userName'] ?? data?['UserName'])?.toString();

      final bookingDuration =
          _toDoubleOrNull(data?['bookingDuration'] ?? data?['BookingDuration'] ?? map['bookingDuration']);

      final bookingTime = _toDateTime(data?['bookingTime'] ?? data?['BookingTime']);
      final distanceKm = _toDoubleOrNull(data?['distanceKm'] ?? data?['DistanceKm']);
      final location = (data?['location'] ?? data?['Location'])?.toString();

      return TaskerBookingOffer(
        bookingDetailId: bookingDetailId,
        lat: lat,
        lng: lng,
        estimatedCost: estimatedCost,
        bookingService: bookingService,
        userName: userName,
        bookingDuration: bookingDuration,
        bookingTime: bookingTime,
        distanceKm: distanceKm,
        location: location,
        message: (map['message'] ?? '').toString(),
        type: map['type']?.toString(),
        date: map['date']?.toString(),
      );
    } catch (e) {
      debugPrint("❌ tryParse exception => $e");
      return null;
    }
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static double? _toDoubleOrNull(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static DateTime? _toDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }
}

class TaskerDispatchHubService {
  HubConnection? _conn;

  String? _baseUrl;
  String? _userId;

  // OPTIONAL: if your hub requires auth token, set it here
  Future<String?> Function()? _tokenProvider;

  Completer<void>? _startCompleter;
  bool _handlersAttached = false;

  final _notifCtrl = StreamController<dynamic>.broadcast();
  Stream<dynamic> get notifications => _notifCtrl.stream;

  bool get isConnected => _conn != null && _conn!.state == HubConnectionState.Connected;
  HubConnectionState? get state => _conn?.state;

  void configure({
    required String baseUrl,
    required String userId,
    Future<String?> Function()? tokenProvider, // ✅ optional
  }) {
    final changed = (_baseUrl != baseUrl) || (_userId != userId);

    _baseUrl = baseUrl.trim();
    _userId = userId.trim();
    _tokenProvider = tokenProvider;

    if (changed) {
      _handlersAttached = false;
      _disposeConnectionOnly();
    }
  }

  Future<void> ensureConnected({Duration timeout = const Duration(seconds: 10)}) async {
    if (_baseUrl == null || _userId == null || _userId!.isEmpty) {
      throw Exception("HUB: configure(baseUrl,userId) first");
    }

    if (isConnected) return;

    if (_startCompleter != null) {
      await _startCompleter!.future;
      return;
    }

    _startCompleter = Completer<void>();
    try {
      await _startInternal(timeout: timeout);
    } finally {
      if (!(_startCompleter?.isCompleted ?? true)) _startCompleter?.complete();
      _startCompleter = null;
    }
  }

  Future<void> stop() async {
    try {
      await _conn?.stop();
    } catch (_) {}
  }

  Future<void> _startInternal({required Duration timeout}) async {
    final base = _baseUrl!;
    final fixedBase = (base.startsWith('http://') || base.startsWith('https://')) ? base : 'https://$base';

    // your hub url
    final url = "$fixedBase/hubs/dispatch?userId=${Uri.encodeComponent(_userId!)}";

    // ✅ IMPORTANT:
    // If websocket upgrade is blocked by proxy, FORCE LongPolling.
    // This will stop "not upgraded to websocket" completely.
    final options = HttpConnectionOptions(
      transport: HttpTransportType.LongPolling,
accessTokenFactory: () async {
  final t = await _tokenProvider?.call();
  return (t ?? '').trim(); // never null
},

    );

    try {
      // always create fresh connection for clean retry after failures
      _disposeConnectionOnly();
_conn = HubConnectionBuilder()
    .withUrl(url, options: options)
    .withAutomaticReconnect()
    .build();


      _wireLifecycle(_conn!);

      if (!_handlersAttached) {
        _registerHandlers(_conn!);
        _handlersAttached = true;
      }

      await _conn!.start()!.timeout(timeout);

      if (_conn!.state != HubConnectionState.Connected) {
        throw Exception("HUB: start finished but state=${_conn!.state}");
      }

      debugPrint("✅ HUB CONNECTED (LongPolling)");
    } catch (e) {
      debugPrint("❌ HUB start failed => $e");
      _handlersAttached = false;
      _disposeConnectionOnly();
      rethrow;
    }
  }

  void _wireLifecycle(HubConnection c) {
    c.onclose(({error}) {
      debugPrint("🛑 HUB onClose error=$error state=${c.state}");
    });

    c.onreconnecting(({error}) {
      debugPrint("🔄 HUB onReconnecting error=$error state=${c.state}");
    });

    c.onreconnected(({connectionId}) {
      debugPrint("✅ HUB onReconnected id=$connectionId state=${c.state}");
    });
  }

  void _registerHandlers(HubConnection c) {
    c.off("ReceiveBookingOffer");
    c.off("ReceiveNotification");

    c.on("ReceiveBookingOffer", (args) {
      final payload = _normalizeArgs(args);
      if (payload != null) _notifCtrl.add(payload);
    });

    c.on("ReceiveNotification", (args) {
      final payload = _normalizeArgs(args);
      if (payload != null) _notifCtrl.add(payload);
    });
  }

  dynamic _normalizeArgs(List<Object?>? args) {
    if (args == null || args.isEmpty) return null;
    dynamic first = args.first;

    if (first is List && first.isNotEmpty) first = first.first;

    if (first is String) {
      try {
        first = jsonDecode(first);
      } catch (_) {}
    }
    return first;
  }

  void _disposeConnectionOnly() {
    try {
      _conn?.stop();
    } catch (_) {}
    _conn = null;
  }

  Future<void> dispose() async {
    _disposeConnectionOnly();
    await _notifCtrl.close();
  }
}

class TaskerHomeRedesign extends StatefulWidget {
  const TaskerHomeRedesign({super.key});

  @override
  State<TaskerHomeRedesign> createState() => _TaskerHomeRedesignState();
}

class _TaskerHomeRedesignState extends State<TaskerHomeRedesign> with WidgetsBindingObserver {
  static const String _baseUrl = ApiConfig.baseUrl; // ✅ keep yours

  final box = GetStorage();

  String? userId;
  String name = "";

  bool available = false;
  String period = 'Week';
  static const String _kAvailabilityKey = 'tasker_available';
  bool _restored = false;

  // ✅ Connectivity
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _netSub;

  // ✅ SignalR hub
  final TaskerDispatchHubService _hub = TaskerDispatchHubService();
  StreamSubscription? _hubSub;

  Timer? _hubWatchdog;
  bool _hubConfigured = false;
  bool _hubEnsuring = false;
  int _attempt = 0;

  Timer? _locationTimer;
  static const Duration _locationInterval = Duration(seconds: 5);

  bool _dialogOpen = false;
  String? _lastPopupBookingDetailId;

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

  String _selectedChip = 'All';
  final List<String> _chipLabels = const ['All', 'Upcoming', 'Current'];

  StreamSubscription? _sub;

  Duration _nextBackoff() {
    final secs = [2, 4, 8, 16, 30, 30, 30];
    final idx = (_attempt - 1).clamp(0, secs.length - 1);
    return Duration(seconds: secs[idx]);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _startConnectivityWatcher();

    // Existing stream listener (keep)
    _sub = SignalRService.I.stream.listen((payload) {
      final offer = TaskerBookingOffer.tryParse(payload);
      if (offer != null && available) {
        _showBookingPopup(offer);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      userId = (box.read('userId'))?.toString();
      name = (box.read("name"))?.toString() ?? "";

      final saved = box.read(_kAvailabilityKey) == true;
      setState(() {
        available = saved;
        _restored = true;
      });

      debugPrint("🟣 Home init userId=$userId name=$name available=$saved online=$_isOnline");

      await _trySetupSignalR(reason: "init");
      _attachHubListener();
      _startHubWatchdog();

      if (saved) _startLocationUpdates();
    });
  }

  void _startConnectivityWatcher() {
    _netSub?.cancel();

    _netSub = Connectivity().onConnectivityChanged.listen((results) async {
      final online = results.any((r) => r != ConnectivityResult.none);

      if (!mounted) return;
      if (_isOnline == online) return;

      setState(() => _isOnline = online);

      debugPrint("🌐 connectivity => online=$_isOnline results=$results");

      if (!_isOnline) {
        // Stop location updates when offline (prevents spam)
        _stopLocationUpdates();
        return;
      }

      // Back online -> connect immediately
      await _ensureHubConnectedNow(reason: "net-back-online");

      if (available) {
        _startLocationUpdates();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      debugPrint("🟠 lifecycle=$state -> stop timers");
      _stopLocationUpdates();

      // Optional: stopping hub avoids internal reconnect churn
      // (OS can kill anyway)
      _hub.stop();
    }

    if (state == AppLifecycleState.resumed) {
      debugPrint("🟢 resumed -> ensure hub connected");
      if (available) _startLocationUpdates();
      _ensureHubConnectedNow(reason: "resumed");
    }
  }

  Future<void> _trySetupSignalR({required String reason}) async {
    userId ??= (box.read('userId'))?.toString();
    userId = userId?.trim();

    if (userId == null || userId!.isEmpty) {
      debugPrint("⏳ HUB: userId not ready yet reason=$reason");
      return;
    }

    if (!_hubConfigured) {
      _hub.configure(baseUrl: _baseUrl, userId: userId!);
      _hubConfigured = true;
      debugPrint("🧩 HUB configured baseUrl=$_baseUrl userId=$userId");
    }

    await _ensureHubConnectedNow(reason: reason);
  }

  Future<bool> _ensureHubConnectedNow({required String reason}) async {
    if (!_hubConfigured) return false;

    if (!_isOnline) {
      debugPrint("⛔ HUB ensureConnected skipped (offline) reason=$reason");
      return false;
    }

    if (_hub.isConnected) return true;
    if (_hubEnsuring) return false;

    _hubEnsuring = true;
    try {
      debugPrint("🔌 HUB ensureConnected reason=$reason state=${_hub.state}");
      await _hub.ensureConnected(timeout: const Duration(seconds: 10));
      if (_hub.isConnected) _attempt = 0;
      return _hub.isConnected;
    } catch (e) {
      debugPrint("❌ HUB ensureConnected failed reason=$reason => $e");
      return false;
    } finally {
      _hubEnsuring = false;
    }
  }

  void _startHubWatchdog() {
    _hubWatchdog?.cancel();

    _hubWatchdog = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted) return;

      if (!_hubConfigured) {
        if (_isOnline) {
          await _trySetupSignalR(reason: "watchdog-config");
        }
        return;
      }

      if (!_isOnline) return; // ✅ don't retry when offline
      if (_hub.isConnected) return;
      if (_hubEnsuring) return;

      _attempt++;
      final wait = _nextBackoff();

      debugPrint("🛡️ HUB watchdog disconnected -> attempt=$_attempt retry in ${wait.inSeconds}s");

      await Future.delayed(wait);
      if (!mounted || !_isOnline) return;

      await _ensureHubConnectedNow(reason: "watchdog");
    });
  }

  void _attachHubListener() {
    _hubSub?.cancel();

    _hubSub = _hub.notifications.listen(
      (payload) {
        if (!mounted) return;

        debugPrint("📩 HUB payload => $payload");

        if (!available) {
          debugPrint("⚠️ offer received but available=false (no popup)");
          return;
        }

        final offer = TaskerBookingOffer.tryParse(payload);
        if (offer == null) {
          debugPrint("❌ offer parse failed");
          return;
        }

        _showBookingPopup(offer);
      },
      onError: (e) => debugPrint("❌ HUB stream error => $e"),
      onDone: () => debugPrint("⚠️ HUB stream closed"),
    );
  }

  Future<void> _onAvailabilityToggle(bool value) async {
    await box.write(_kAvailabilityKey, value);
    setState(() => available = value);

    userId ??= (box.read('userId'))?.toString();
    userId = userId?.trim();

    if (!value) {
      _stopLocationUpdates();

      if (userId != null && userId!.isNotEmpty) {
        context.read<UserBookingBloc>().add(ChangeAvailabilityStatus(userId: userId.toString()));
      }
      return;
    }

    await _trySetupSignalR(reason: "availability-on");

    if (userId != null && userId!.isNotEmpty) {
      context.read<UserBookingBloc>().add(ChangeAvailabilityStatus(userId: userId.toString()));
    }

    _startLocationUpdates();
  }

  Future<void> _dispatchLocationUpdateToApi() async {
    if (!mounted) return;
    if (!available) return;
    if (!_isOnline) return;

    userId ??= (box.read('userId'))?.toString();
    userId = userId?.trim();
    if (userId == null || userId!.isEmpty) return;

    // ✅ Ensure hub connected (keeps realtime stable)
    await _ensureHubConnectedNow(reason: "location-tick");

    const double lat = 67.00;
    const double lng = 70.00;

    context.read<UserBookingBloc>().add(
          UpdateUserLocationRequested(
            userId: userId.toString(),
            latitude: lat,
            longitude: lng,
          ),
        );
  }

  void _startLocationUpdates() {
    if (!_restored) return;
    if (!available) return;
    if (!_isOnline) return;

    if (_locationTimer?.isActive == true) return;

    _dispatchLocationUpdateToApi();
    _locationTimer = Timer.periodic(_locationInterval, (_) async {
      if (!mounted) return;
      if (!available || !_isOnline) {
        _stopLocationUpdates();
        return;
      }
      await _dispatchLocationUpdateToApi();
    });
  }

  void _stopLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  /// ===============================================================
  /// ✅ POPUP (same UI + full offer details) - unchanged
  /// ===============================================================
  void _showBookingPopup(TaskerBookingOffer offer) {
    if (!mounted) return;

    if (_dialogOpen) return;
    if (_lastPopupBookingDetailId == offer.bookingDetailId) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (_dialogOpen) return;

      _dialogOpen = true;
      _lastPopupBookingDetailId = offer.bookingDetailId;

      try {
        await showDialog(
          context: context,
          useRootNavigator: true,
          barrierDismissible: false,
          barrierColor: Colors.black.withOpacity(0.55),
          builder: (ctx) {
            const kGold = Color(0xFFF4C847);
            const int totalSeconds = 60;

            int secondsLeft = totalSeconds;
            Timer? timer;
            bool closed = false;

            String fmtDate(DateTime? dt) {
              if (dt == null) return "-";
              final d = dt.toLocal();
              return "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
            }

            String fmtTime(DateTime? dt) {
              if (dt == null) return "-";
              final t = dt.toLocal();
              return "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
            }

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

            Widget offerTable(TaskerBookingOffer offer) {
              final entries = offer.toDisplayMap().entries.toList();

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kPrimary.withOpacity(0.12)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Offer Details",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: kTextDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text(
                                e.key,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: kMuted,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e.value,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: kTextDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              );
            }

            return StatefulBuilder(
              builder: (context, setState) {
                timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
                  if (closed) return;

                  if (secondsLeft <= 1) {
                    closeDialog();
                    return;
                  }

                  setState(() => secondsLeft--);
                });

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
                        child: SingleChildScrollView(
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
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 8,
                                  backgroundColor: kPrimary.withOpacity(0.10),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    secondsLeft <= 10 ? Colors.redAccent : (secondsLeft <= 25 ? kGold : kPrimary),
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
                              offerTable(offer),
                              const SizedBox(height: 12),
                              infoTile(
                                icon: Icons.home_repair_service_rounded,
                                label: "Service",
                                value: offer.bookingService ?? "-",
                              ),
                              const SizedBox(height: 10),
                              infoTile(
                                icon: Icons.attach_money_rounded,
                                label: "Estimated Cost",
                                value: "\$${offer.estimatedCost.toStringAsFixed(2)}",
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: infoTile(
                                      icon: Icons.event_rounded,
                                      label: "Booking Date",
                                      value: fmtDate(offer.bookingTime),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: infoTile(
                                      icon: Icons.schedule_rounded,
                                      label: "Booking Time",
                                      value: fmtTime(offer.bookingTime),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: infoTile(
                                      icon: Icons.route_rounded,
                                      label: "Distance",
                                      value: offer.distanceKm == null ? "-" : "${offer.distanceKm!.toStringAsFixed(2)} km",
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: infoTile(
                                      icon: Icons.timelapse_rounded,
                                      label: "Duration",
                                      value: offer.bookingDuration == null ? "-" : "${offer.bookingDuration!.toStringAsFixed(1)} hr",
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              infoTile(
                                icon: Icons.location_on_rounded,
                                label: "Location",
                                value: offer.location ?? "-",
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        closeDialog();
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: kPrimary,
                                        side: BorderSide(color: kPrimary.withOpacity(0.35)),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      ),
                                      child: const Text(
                                        "Decline",
                                        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        context.read<UserBookingBloc>().add(
                                              AcceptBooking(
                                                userId: userId.toString(),
                                                bookingDetailId: offer.bookingDetailId,
                                              ),
                                            );
                                        closeDialog();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: kPrimary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        elevation: 0,
                                      ),
                                      child: const Text(
                                        "Accept",
                                        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800),
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
                  ),
                );
              },
            );
          },
        );
      } catch (e) {
        debugPrint("❌ dialog exception => $e");
      } finally {
        _dialogOpen = false;
        _lastPopupBookingDetailId = null;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _netSub?.cancel();
    _netSub = null;

    _stopLocationUpdates();
    _hubWatchdog?.cancel();
    _hubSub?.cancel();
    _sub?.cancel();

    _hub.dispose();
    super.dispose();
  }

  /// ===============================================================
  /// ✅ BUILD UI (YOUR SAME UI - unchanged)
  /// ===============================================================
  @override
  Widget build(BuildContext context) {
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
        title: const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello,',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: kTextDark,
                ),
              ),
              SizedBox(height: 2),
              Text(
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
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(.06),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: kPrimary.withOpacity(.14)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Available',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: kPrimary,
                      fontWeight: FontWeight.w800,
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
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      kPrimary.withOpacity(.16),
                      kPrimary.withOpacity(.07),
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
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF3E1E69),
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            available ? 'You’re online — offers can arrive anytime.' : 'You’re offline — go available to receive offers.',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12.5,
                              height: 1.25,
                              color: Color(0xFF75748A),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _StatusPill(available: available),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _InfoCard(
                icon: available ? Icons.wifi_tethering_rounded : Icons.wifi_off_rounded,
                text: available ? 'You are online. New offers can arrive anytime.' : 'You are offline. Turn on availability to receive offers.',
                available: available,
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, c) {
                  final twoCols = c.maxWidth >= 720;
                  if (twoCols) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _TaskerProfileCard(name: name)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _WhiteCard(
                            padding: const EdgeInsets.all(14),
                            child: _EarningsCard(
                              period: period,
                              amount: earnings,
                              onChange: (p) => setState(() => period = p),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      _TaskerProfileCard(name: name),
                      const SizedBox(height: 12),
                      _WhiteCard(
                        padding: const EdgeInsets.all(14),
                        child: _EarningsCard(
                          period: period,
                          amount: earnings,
                          onChange: (p) => setState(() => period = p),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              _WhiteCard(
                child: _KpiRow(
                  rating: rating,
                  reviews: reviews,
                  acceptance: acceptanceRate,
                  completion: completionRate,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Your jobs',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: kTextDark,
                  fontWeight: FontWeight.w900,
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
                        fontWeight: FontWeight.w900,
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
                              Divider(
                                height: 18,
                                color: Colors.grey.withOpacity(0.18),
                              ),
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
/// ✅ UI WIDGETS (UNCHANGED)
/// ===============================================================
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.available});
  final bool available;

  @override
  Widget build(BuildContext context) {
    final fg = available ? const Color(0xFF1E8E66) : const Color(0xFFEE8A41);
    final bg = available ? const Color(0xFFEFF8F4) : const Color(0xFFFFF4E8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            available ? Icons.wifi_tethering_rounded : Icons.wifi_off_rounded,
            size: 16,
            color: fg,
          ),
          const SizedBox(width: 6),
          Text(
            available ? 'Online' : 'Offline',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskerProfileCard extends StatelessWidget {
  const _TaskerProfileCard({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              _AvatarRing(
                url: 'https://images.unsplash.com/photo-1607746882042-944635dfe10e?q=80&w=256&auto=format&fit=crop',
              ),
              SizedBox(width: 12),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w900,
              color: Color(0xFF3E1E69),
              fontSize: 16.5,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 14),
          const _VerificationRow(
            items: [
              VerificationItem(
                label: 'ID Verified',
                icon: Icons.badge_outlined,
                bg: Color(0xFFEFF8F4),
                fg: Color(0xFF1E8E66),
              ),
              VerificationItem(
                label: 'Police Verified',
                icon: Icons.verified_user_outlined,
                bg: Color(0xFFF3EEFF),
                fg: Color(0xFF5C2E91),
              ),
            ],
          ),
        ],
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.text,
    required this.available,
  });

  final IconData icon;
  final String text;
  final bool available;

  @override
  Widget build(BuildContext context) {
    final fg = available ? const Color(0xFF1E8E66) : kPrimary;
    final bg = available ? const Color(0xFFEFF8F4) : kPrimary.withOpacity(.06);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: fg.withOpacity(.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12.5,
                color: fg.withOpacity(.95),
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: fg.withOpacity(.9)),
        ],
      ),
    );
  }
}

class _AvatarRing extends StatelessWidget {
  const _AvatarRing({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [kPrimary.withOpacity(.75), kPrimary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.white,
        child: CircleAvatar(
          radius: 22,
          backgroundImage: NetworkImage(url),
        ),
      ),
    );
  }
}

class VerificationItem {
  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;

  const VerificationItem({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
  });
}

class _VerificationRow extends StatelessWidget {
  const _VerificationRow({required this.items});
  final List<VerificationItem> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((v) => _VerificationPill(item: v)).toList(),
    );
  }
}

class _VerificationPill extends StatelessWidget {
  const _VerificationPill({required this.item});
  final VerificationItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: item.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: item.fg.withOpacity(.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, size: 16, color: item.fg),
          const SizedBox(width: 7),
          Text(
            item.label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11.8,
              fontWeight: FontWeight.w900,
              color: item.fg,
            ),
          ),
        ],
      ),
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final label = labels[i];
          final sel = label == selected;

          return InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => onTap(label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: sel ? kPrimary : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: sel ? kPrimary : kPrimary.withOpacity(.22)),
                boxShadow: sel
                    ? [
                        BoxShadow(
                          color: kPrimary.withOpacity(.18),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        )
                      ]
                    : null,
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: sel ? Colors.white : kPrimary,
                  fontWeight: FontWeight.w800,
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
        final cols = c.maxWidth >= 520 ? 3 : 2;
        final gap = 10.0;
        final itemW = (c.maxWidth - (gap * (cols - 1))) / cols;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: itemW,
              child: const _KpiTile(
                icon: Icons.star_rate_rounded,
                title: "4.9",
                sub: "124 reviews",
              ),
            ),
            SizedBox(
              width: itemW,
              child: _KpiTile(
                icon: Icons.bolt_rounded,
                title: "$acceptance%",
                sub: "acceptance",
              ),
            ),
            SizedBox(
              width: itemW,
              child: _KpiTile(
                icon: Icons.check_circle_rounded,
                title: "$completion%",
                sub: "completion",
              ),
            ),
          ],
        );
      },
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({required this.icon, required this.title, required this.sub});

  final IconData icon;
  final String title;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kPrimary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kPrimary.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: Color(0xFF3E1E69),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11.5,
                    color: Color(0xFF75748A),
                    fontWeight: FontWeight.w600,
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

class _EarningsCard extends StatelessWidget {
  const _EarningsCard({
    required this.period,
    required this.amount,
    required this.onChange,
  });

  final String period;
  final int amount;
  final ValueChanged<String> onChange;

  @override
  Widget build(BuildContext context) {
    // ✅ Keep same as yours (you already have it)
    return const SizedBox.shrink();
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task});
  final _Task task;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w900,
              fontSize: 14.5,
              color: Color(0xFF3E1E69),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _Meta(icon: Icons.calendar_month_rounded, text: task.date),
              _Meta(icon: Icons.schedule_rounded, text: task.time),
              _Meta(icon: Icons.location_on_outlined, text: task.location),
            ],
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF75748A)),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 180),
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Color(0xFF75748A),
              fontWeight: FontWeight.w600,
            ),
          ),
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
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: kPrimary.withOpacity(.14)),
            ),
            child: const Icon(Icons.inbox_rounded, size: 28, color: kPrimary),
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12.5,
              color: Color(0xFF75748A),
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}


// const Color kPrimary = Color(0xFF5C2E91);
// const Color kTextDark = Color(0xFF3E1E69);
// const Color kMuted = Color(0xFF75748A);
// const Color kBg = Color(0xFFF8F7FB);



// class _Task {
//   final String title;
//   final String date;
//   final String time;
//   final String location;

//   const _Task({
//     required this.title,
//     required this.date,
//     required this.time,
//     required this.location,
//   });
// }

// enum PopupCloseReason { autoTimeout, declined, accepted }


// class TaskerBookingOffer {
//   final String bookingDetailId;
//   final double lat;
//   final double lng;
//   final double estimatedCost;

//   final String? bookingService;
//   final String? userName;
//   final double? bookingDuration;
//   final DateTime? bookingTime;
//   final double? distanceKm;
//   final String? location;

//   final String message;
//   final String? type;
//   final String? date;

//   TaskerBookingOffer({
//     required this.bookingDetailId,
//     required this.lat,
//     required this.lng,
//     required this.estimatedCost,
//     this.bookingService,
//     this.userName,
//     this.bookingDuration,
//     this.bookingTime,
//     this.distanceKm,
//     this.location,
//     required this.message,
//     this.type,
//     this.date,
//   });

//   Map<String, String> toDisplayMap() {
//     String fmtDate(DateTime? dt) {
//       if (dt == null) return "";
//       final d = dt.toLocal();
//       return "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
//     }

//     String fmtTime(DateTime? dt) {
//       if (dt == null) return "";
//       final t = dt.toLocal();
//       return "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
//     }

//     final map = <String, String>{
//       "Service": bookingService ?? "",
//       "User Name": userName ?? "",
//       "Distance": distanceKm == null ? "" : "${distanceKm!.toStringAsFixed(2)} km",
//       "Location": location ?? "",
//       "Estimated Cost": estimatedCost == 0 ? "" : "\$${estimatedCost.toStringAsFixed(2)}",
//       "Duration": bookingDuration == null ? "" : "${bookingDuration!.toStringAsFixed(1)} hr",
//       "Booking Date": fmtDate(bookingTime),
//       "Booking Time": fmtTime(bookingTime),
//       "Notification Date": (date ?? "").isEmpty ? "" : date!,
//       "Type": type ?? "",
//       "Message": message,
//     };

//     map.removeWhere((k, v) => v.trim().isEmpty);
//     return map;
//   }

//   static TaskerBookingOffer? tryParse(dynamic payload) {
//     try {
//       dynamic obj = payload;

//       // SignalR sometimes sends [ {..} ]
//       if (obj is List && obj.isNotEmpty) obj = obj.first;

//       // Server can send json string
//       if (obj is String) obj = jsonDecode(obj);

//       if (obj is! Map) {
//         debugPrint("❌ tryParse: payload is not Map => ${obj.runtimeType}");
//         return null;
//       }

//       final map = Map<String, dynamic>.from(obj);

//       dynamic dataAny = map['data'];
//       if (dataAny is String) {
//         try {
//           dataAny = jsonDecode(dataAny);
//         } catch (_) {}
//       }

//       Map<String, dynamic>? data;
//       if (dataAny is Map) data = Map<String, dynamic>.from(dataAny);

//       final bookingDetailId =
//           (data?['bookingDetailId'] ?? data?['BookingDetailId'] ?? map['bookingDetailId'] ?? map['BookingDetailId'])
//               ?.toString();

//       if (bookingDetailId == null || bookingDetailId.isEmpty) {
//         debugPrint("❌ tryParse: bookingDetailId missing. keys=${map.keys}");
//         return null;
//       }

//       final lat = _toDouble(data?['lat'] ?? data?['Lat'] ?? map['lat'] ?? map['Lat'] ?? 0);
//       final lng = _toDouble(data?['lng'] ?? data?['Lng'] ?? map['lng'] ?? map['Lng'] ?? 0);

//       final estimatedCost = _toDouble(
//         data?['estimatedCost'] ?? data?['EstimatedCost'] ?? map['estimatedCost'] ?? map['EstimatedCost'] ?? 0,
//       );

//       final bookingService = (data?['bookingService'] ?? data?['BookingService'])?.toString();
//       final userName = (data?['userName'] ?? data?['UserName'])?.toString();

//       final bookingDuration =
//           _toDoubleOrNull(data?['bookingDuration'] ?? data?['BookingDuration'] ?? map['bookingDuration']);

//       final bookingTime = _toDateTime(data?['bookingTime'] ?? data?['BookingTime']);
//       final distanceKm = _toDoubleOrNull(data?['distanceKm'] ?? data?['DistanceKm']);
//       final location = (data?['location'] ?? data?['Location'])?.toString();

//       return TaskerBookingOffer(
//         bookingDetailId: bookingDetailId,
//         lat: lat,
//         lng: lng,
//         estimatedCost: estimatedCost,
//         bookingService: bookingService,
//         userName: userName,
//         bookingDuration: bookingDuration,
//         bookingTime: bookingTime,
//         distanceKm: distanceKm,
//         location: location,
//         message: (map['message'] ?? '').toString(),
//         type: map['type']?.toString(),
//         date: map['date']?.toString(),
//       );
//     } catch (e) {
//       debugPrint("❌ tryParse exception => $e");
//       return null;
//     }
//   }

//   static double _toDouble(dynamic v) {
//     if (v == null) return 0;
//     if (v is num) return v.toDouble();
//     return double.tryParse(v.toString()) ?? 0;
//   }

//   static double? _toDoubleOrNull(dynamic v) {
//     if (v == null) return null;
//     if (v is num) return v.toDouble();
//     return double.tryParse(v.toString());
//   }

//   static DateTime? _toDateTime(dynamic v) {
//     if (v == null) return null;
//     if (v is DateTime) return v;
//     return DateTime.tryParse(v.toString());
//   }
// }

// /// ===============================================================
// /// ✅ SIGNALR SERVICE (keep here or move to separate file)
// /// ===============================================================
// class TaskerDispatchHubService {
//   HubConnection? _conn;
//   String? _baseUrl;
//   String? _userId;

//   Completer<void>? _startCompleter;
//   bool _handlersAttached = false;

//   final _notifCtrl = StreamController<dynamic>.broadcast();
//   Stream<dynamic> get notifications => _notifCtrl.stream;

//   bool get isConnected => _conn != null && _conn!.state == HubConnectionState.Connected;
//   HubConnectionState? get state => _conn?.state;

//   void configure({required String baseUrl, required String userId}) {
//     final changed = (_baseUrl != baseUrl) || (_userId != userId);
//     _baseUrl = baseUrl;
//     _userId = userId;

//     if (changed) {
//       _handlersAttached = false;
//       _disposeConnectionOnly();
//     }
//   }

//   Future<void> ensureConnected() async {
//     if (_baseUrl == null || _userId == null || _userId!.isEmpty) {
//       throw Exception("HUB: configure(baseUrl,userId) first");
//     }

//     if (isConnected) return;

//     if (_startCompleter != null) {
//       await _startCompleter!.future;
//       return;
//     }

//     _startCompleter = Completer<void>();
//     try {
//       await _startInternal();
//     } finally {
//       _startCompleter?.complete();
//       _startCompleter = null;
//     }
//   }

//   Future<void> _startInternal() async {
//     final url = "${_baseUrl!}/hubs/dispatch?userId=${_userId!}";

//     try {
//       _conn ??= HubConnectionBuilder()
//           .withUrl(
//             url,
//             options: HttpConnectionOptions(
//               transport: HttpTransportType.LongPolling,
//             ),
//           )
//           .withAutomaticReconnect()
//           .build();

//       _wireLifecycle(_conn!);

//       if (!_handlersAttached) {
//         _registerHandlers(_conn!);
//         _handlersAttached = true;
//       }

//       if (_conn!.state != HubConnectionState.Disconnected) {
//         try {
//           await _conn!.stop();
//         } catch (_) {}
//       }

//       await _conn!.start();

//       if (_conn!.state != HubConnectionState.Connected) {
//         throw Exception("HUB: start finished but state=${_conn!.state}");
//       }

//       debugPrint("✅ HUB CONNECTED");
//     } catch (e) {
//       debugPrint("❌ HUB start failed => $e");
//       _handlersAttached = false;
//       _disposeConnectionOnly();
//       rethrow;
//     }
//   }

//   void _wireLifecycle(HubConnection c) {
//     c.onclose(({error}) {
//       debugPrint("🛑 HUB onClose error=$error state=${c.state}");
//     });

//     c.onreconnecting(({error}) {
//       debugPrint("🔄 HUB onReconnecting error=$error state=${c.state}");
//     });

//     c.onreconnected(({connectionId}) {
//       debugPrint("✅ HUB onReconnected id=$connectionId state=${c.state}");
//     });
//   }

//   void _registerHandlers(HubConnection c) {
//     c.off("ReceiveBookingOffer");
//     c.off("ReceiveNotification");

//     c.on("ReceiveBookingOffer", (args) {
//       final payload = _normalizeArgs(args);
//       if (payload == null) return;
//       _notifCtrl.add(payload);
//     });

//     c.on("ReceiveNotification", (args) {
//       final payload = _normalizeArgs(args);
//       if (payload == null) return;
//       _notifCtrl.add(payload);
//     });
//   }

//   dynamic _normalizeArgs(List<Object?>? args) {
//     if (args == null || args.isEmpty) return null;
//     dynamic first = args.first;

//     if (first is List && first.isNotEmpty) first = first.first;

//     if (first is String) {
//       try {
//         first = jsonDecode(first);
//       } catch (_) {}
//     }
//     return first;
//   }

//   void _disposeConnectionOnly() {
//     try {
//       _conn?.stop();
//     } catch (_) {}
//     _conn = null;
//   }

//   Future<void> dispose() async {
//     _disposeConnectionOnly();
//     await _notifCtrl.close();
//   }
// }

// /// ===============================================================
// /// ✅ HOME SCREEN (UI SAME + SIGNALR THROUGHOUT APP)
// /// ===============================================================
// class TaskerHomeRedesign extends StatefulWidget {
//   const TaskerHomeRedesign({super.key});

//   @override
//   State<TaskerHomeRedesign> createState() => _TaskerHomeRedesignState();
// }

// class _TaskerHomeRedesignState extends State<TaskerHomeRedesign> with WidgetsBindingObserver {
//   static const String _baseUrl = ApiConfig.baseUrl; // ✅ keep yours

//   final box = GetStorage();

//   String? userId;
//   String name = "";

//   bool available = false;
//   String period = 'Week';
//   static const String _kAvailabilityKey = 'tasker_available';
//   bool _restored = false;

//   // ✅ SignalR
//   final TaskerDispatchHubService _hub = TaskerDispatchHubService();
//   StreamSubscription? _hubSub;

//   Timer? _hubWatchdog;
//   bool _hubConfigured = false;
//   bool _hubEnsuring = false;
//   int _attempt = 0;

//   Timer? _locationTimer;
//   static const Duration _locationInterval = Duration(seconds: 5);

//   bool _dialogOpen = false;
//   String? _lastPopupBookingDetailId;

//   double rating = 4.9;
//   int reviews = 124;
//   int acceptanceRate = 91;
//   int completionRate = 98;
//   int weeklyEarning = 820;
//   int monthlyEarning = 3280;

//   final List<_Task> upcoming = const [
//     _Task(title: 'Furniture assembly', date: 'Apr 24', time: '10:30', location: 'East Perth'),
//   ];

//   final List<_Task> current = const [
//     _Task(title: 'TV wall mount', date: 'Apr 24', time: '09:00', location: 'Perth CBD'),
//   ];

//   String _selectedChip = 'All';
//   final List<String> _chipLabels = const ['All', 'Upcoming', 'Current'];

//   Duration _nextBackoff() {
//     final secs = [2, 4, 8, 16, 30, 30, 30];
//     final idx = (_attempt - 1).clamp(0, secs.length - 1);
//     return Duration(seconds: secs[idx]);
//   }
//   StreamSubscription? _sub;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);

//       _sub = SignalRService.I.stream.listen((payload) {
//     final offer = TaskerBookingOffer.tryParse(payload);
//     if (offer != null && available) {
//       _showBookingPopup(offer);
//     }
//   });

//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       if (!mounted) return;

//       userId = (box.read('userId'))?.toString();
//       name = (box.read("name"))?.toString() ?? "";

//       final saved = box.read(_kAvailabilityKey) == true;
//       setState(() {
//         available = saved;
//         _restored = true;
//       });

//       debugPrint("🟣 Home init userId=$userId name=$name available=$saved");

//       await _trySetupSignalR(reason: "init");
//       _attachHubListener();
//       _startHubWatchdog();

//       if (saved) _startLocationUpdates();
//     });


//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (!mounted) return;

//     if (state == AppLifecycleState.resumed) {
//       debugPrint("🔁 resumed -> ensure hub connected");
//       _ensureHubConnectedNow(reason: "resumed");
//     }
//   }

//   Future<void> _trySetupSignalR({required String reason}) async {
//     userId ??= (box.read('userId'))?.toString();
//     userId = userId?.trim();

//     if (userId == null || userId!.isEmpty) {
//       debugPrint("⏳ HUB: userId not ready yet reason=$reason");
//       return;
//     }

//     if (!_hubConfigured) {
//       _hub.configure(baseUrl: _baseUrl, userId: userId!);
//       _hubConfigured = true;
//       debugPrint("🧩 HUB configured baseUrl=$_baseUrl userId=$userId");
//     }

//     await _ensureHubConnectedNow(reason: reason);
//   }

//   Future<bool> _ensureHubConnectedNow({required String reason}) async {
//     if (!_hubConfigured) return false;
//     if (_hub.isConnected) return true;
//     if (_hubEnsuring) return false;

//     _hubEnsuring = true;
//     try {
//       debugPrint("🔌 HUB ensureConnected reason=$reason state=${_hub.state}");
//       await _hub.ensureConnected();
//       if (_hub.isConnected) _attempt = 0;
//       return _hub.isConnected;
//     } catch (e) {
//       debugPrint("❌ HUB ensureConnected failed reason=$reason => $e");
//       return false;
//     } finally {
//       _hubEnsuring = false;
//     }
//   }

//   void _startHubWatchdog() {
//     _hubWatchdog?.cancel();

//     _hubWatchdog = Timer.periodic(const Duration(seconds: 3), (_) async {
//       if (!mounted) return;

//       if (!_hubConfigured) {
//         await _trySetupSignalR(reason: "watchdog-config");
//         return;
//       }

//       if (_hub.isConnected) return;
//       if (_hubEnsuring) return;

//       _attempt++;
//       final wait = _nextBackoff();

//       debugPrint("🛡️ HUB watchdog disconnected -> attempt=$_attempt retry in ${wait.inSeconds}s");

//       await Future.delayed(wait);
//       if (!mounted) return;

//       await _ensureHubConnectedNow(reason: "watchdog");
//     });
//   }

//   void _attachHubListener() {
//     _hubSub?.cancel();

//     _hubSub = _hub.notifications.listen(
//       (payload) {
//         if (!mounted) return;

//         debugPrint("📩 HUB payload => $payload");

//         if (!available) {
//           debugPrint("⚠️ offer received but available=false (no popup)");
//           return;
//         }

//         final offer = TaskerBookingOffer.tryParse(payload);
//         if (offer == null) {
//           debugPrint("❌ offer parse failed");
//           return;
//         }

//         // ✅ optional: also show local notification
//         // TaskerPushNotificationService.I.showLocalFromOffer(offer);

//         _showBookingPopup(offer);
//       },
//       onError: (e) => debugPrint("❌ HUB stream error => $e"),
//       onDone: () => debugPrint("⚠️ HUB stream closed"),
//     );
//   }

//   Future<void> _onAvailabilityToggle(bool value) async {
//     await box.write(_kAvailabilityKey, value);
//     setState(() => available = value);

//     userId ??= (box.read('userId'))?.toString();
//     userId = userId?.trim();

//     if (!value) {
//       _stopLocationUpdates();

//       if (userId != null && userId!.isNotEmpty) {
//         context.read<UserBookingBloc>().add(ChangeAvailabilityStatus(userId: userId.toString()));
//       }
//       return;
//     }

//     await _trySetupSignalR(reason: "availability-on");

//     if (userId != null && userId!.isNotEmpty) {
//       context.read<UserBookingBloc>().add(ChangeAvailabilityStatus(userId: userId.toString()));
//     }

//     _startLocationUpdates();
//   }

//   Future<void> _dispatchLocationUpdateToApi() async {
//     if (!mounted) return;
//     if (!available) return;

//     userId ??= (box.read('userId'))?.toString();
//     userId = userId?.trim();
//     if (userId == null || userId!.isEmpty) return;

//     // ✅ Ensure hub connected (keeps realtime stable)
//     await _ensureHubConnectedNow(reason: "location-tick");

//     const double lat = 67.00;
//     const double lng = 70.00;

//     context.read<UserBookingBloc>().add(
//           UpdateUserLocationRequested(
//             userId: userId.toString(),
//             latitude: lat,
//             longitude: lng,
//           ),
//         );
//   }

//   void _startLocationUpdates() {
//     if (!_restored) return;
//     if (!available) return;

//     if (_locationTimer?.isActive == true) return;

//     _dispatchLocationUpdateToApi();
//     _locationTimer = Timer.periodic(_locationInterval, (_) async {
//       if (!mounted) return;
//       if (!available) {
//         _stopLocationUpdates();
//         return;
//       }
//       await _dispatchLocationUpdateToApi();
//     });
//   }

//   void _stopLocationUpdates() {
//     _locationTimer?.cancel();
//     _locationTimer = null;
//   }

//   /// ===============================================================
//   /// ✅ POPUP (same UI + full offer details)
//   /// ===============================================================
//   void _showBookingPopup(TaskerBookingOffer offer) {
//     if (!mounted) return;

//     if (_dialogOpen) return;
//     if (_lastPopupBookingDetailId == offer.bookingDetailId) return;

//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       if (!mounted) return;
//       if (_dialogOpen) return;

//       _dialogOpen = true;
//       _lastPopupBookingDetailId = offer.bookingDetailId;

//       try {
//         await showDialog(
//           context: context,
//           useRootNavigator: true,
//           barrierDismissible: false,
//           barrierColor: Colors.black.withOpacity(0.55),
//           builder: (ctx) {
//             const kGold = Color(0xFFF4C847);
//             const int totalSeconds = 60;

//             int secondsLeft = totalSeconds;
//             Timer? timer;
//             bool closed = false;

//             String fmtDate(DateTime? dt) {
//               if (dt == null) return "-";
//               final d = dt.toLocal();
//               return "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
//             }

//             String fmtTime(DateTime? dt) {
//               if (dt == null) return "-";
//               final t = dt.toLocal();
//               return "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
//             }

//             void closeDialog() {
//               if (closed) return;
//               closed = true;
//               timer?.cancel();
//               timer = null;

//               if (Navigator.of(ctx, rootNavigator: true).canPop()) {
//                 Navigator.of(ctx, rootNavigator: true).pop();
//               }
//             }

//             Widget infoTile({
//               required IconData icon,
//               required String label,
//               required String value,
//             }) {
//               return Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//                 decoration: BoxDecoration(
//                   color: kPrimary.withOpacity(0.06),
//                   borderRadius: BorderRadius.circular(14),
//                   border: Border.all(color: kPrimary.withOpacity(0.15)),
//                 ),
//                 child: Row(
//                   children: [
//                     Container(
//                       width: 34,
//                       height: 34,
//                       decoration: BoxDecoration(
//                         color: kPrimary.withOpacity(0.12),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Icon(icon, color: kPrimary, size: 18),
//                     ),
//                     const SizedBox(width: 10),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             label,
//                             style: const TextStyle(
//                               fontFamily: 'Poppins',
//                               fontSize: 11.5,
//                               color: kMuted,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                           const SizedBox(height: 2),
//                           Text(
//                             value,
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                             style: const TextStyle(
//                               fontFamily: 'Poppins',
//                               fontSize: 13.5,
//                               color: kTextDark,
//                               fontWeight: FontWeight.w700,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             }

//             Widget offerTable(TaskerBookingOffer offer) {
//               final entries = offer.toDisplayMap().entries.toList();

//               return Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(color: kPrimary.withOpacity(0.12)),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       "Offer Details",
//                       style: TextStyle(
//                         fontFamily: 'Poppins',
//                         fontSize: 13,
//                         fontWeight: FontWeight.w900,
//                         color: kTextDark,
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     ...entries.map((e) {
//                       return Padding(
//                         padding: const EdgeInsets.only(bottom: 8),
//                         child: Row(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             SizedBox(
//                               width: 120,
//                               child: Text(
//                                 e.key,
//                                 style: const TextStyle(
//                                   fontFamily: 'Poppins',
//                                   fontSize: 12,
//                                   fontWeight: FontWeight.w800,
//                                   color: kMuted,
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(width: 8),
//                             Expanded(
//                               child: Text(
//                                 e.value,
//                                 style: const TextStyle(
//                                   fontFamily: 'Poppins',
//                                   fontSize: 12.5,
//                                   fontWeight: FontWeight.w800,
//                                   color: kTextDark,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       );
//                     }).toList(),
//                   ],
//                 ),
//               );
//             }

//             return StatefulBuilder(
//               builder: (context, setState) {
//                 timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
//                   if (closed) return;

//                   if (secondsLeft <= 1) {
//                     closeDialog();
//                     return;
//                   }

//                   setState(() => secondsLeft--);
//                 });

//                 final progress = (secondsLeft / totalSeconds).clamp(0.0, 1.0);

//                 return WillPopScope(
//                   onWillPop: () async => false,
//                   child: Center(
//                     child: Material(
//                       color: Colors.transparent,
//                       child: Container(
//                         width: MediaQuery.of(ctx).size.width * 0.88,
//                         constraints: const BoxConstraints(maxWidth: 420),
//                         padding: const EdgeInsets.all(16),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(22),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.12),
//                               blurRadius: 24,
//                               offset: const Offset(0, 14),
//                             ),
//                           ],
//                         ),
//                         child: SingleChildScrollView(
//                           child: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Row(
//                                 children: [
//                                   Container(
//                                     width: 42,
//                                     height: 42,
//                                     decoration: BoxDecoration(
//                                       color: kGold.withOpacity(0.25),
//                                       borderRadius: BorderRadius.circular(14),
//                                     ),
//                                     child: const Icon(
//                                       Icons.notifications_active_rounded,
//                                       color: kPrimary,
//                                       size: 24,
//                                     ),
//                                   ),
//                                   const SizedBox(width: 12),
//                                   const Expanded(
//                                     child: Text(
//                                       "New Booking Offer",
//                                       style: TextStyle(
//                                         fontFamily: 'Poppins',
//                                         fontSize: 16,
//                                         color: kTextDark,
//                                         fontWeight: FontWeight.w800,
//                                       ),
//                                     ),
//                                   ),
//                                   const Icon(Icons.close_rounded, color: Colors.transparent),
//                                 ],
//                               ),
//                               const SizedBox(height: 10),
//                               ClipRRect(
//                                 borderRadius: BorderRadius.circular(999),
//                                 child: LinearProgressIndicator(
//                                   value: progress,
//                                   minHeight: 8,
//                                   backgroundColor: kPrimary.withOpacity(0.10),
//                                   valueColor: AlwaysStoppedAnimation<Color>(
//                                     secondsLeft <= 10 ? Colors.redAccent : (secondsLeft <= 25 ? kGold : kPrimary),
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(height: 12),
//                               Container(
//                                 width: double.infinity,
//                                 padding: const EdgeInsets.all(12),
//                                 decoration: BoxDecoration(
//                                   color: kPrimary.withOpacity(0.06),
//                                   borderRadius: BorderRadius.circular(16),
//                                   border: Border.all(color: kPrimary.withOpacity(0.12)),
//                                 ),
//                                 child: Text(
//                                   offer.message,
//                                   style: const TextStyle(
//                                     fontFamily: 'Poppins',
//                                     fontSize: 13,
//                                     color: kTextDark,
//                                     fontWeight: FontWeight.w600,
//                                     height: 1.35,
//                                   ),
//                                 ),
//                               ),

//                               const SizedBox(height: 12),
//                               offerTable(offer),

//                               const SizedBox(height: 12),
//                               infoTile(
//                                 icon: Icons.home_repair_service_rounded,
//                                 label: "Service",
//                                 value: offer.bookingService ?? "-",
//                               ),
//                               const SizedBox(height: 10),
//                               infoTile(
//                                 icon: Icons.attach_money_rounded,
//                                 label: "Estimated Cost",
//                                 value: "\$${offer.estimatedCost.toStringAsFixed(2)}",
//                               ),
//                               const SizedBox(height: 10),
//                               Row(
//                                 children: [
//                                   Expanded(
//                                     child: infoTile(
//                                       icon: Icons.event_rounded,
//                                       label: "Booking Date",
//                                       value: fmtDate(offer.bookingTime),
//                                     ),
//                                   ),
//                                   const SizedBox(width: 10),
//                                   Expanded(
//                                     child: infoTile(
//                                       icon: Icons.schedule_rounded,
//                                       label: "Booking Time",
//                                       value: fmtTime(offer.bookingTime),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 10),
//                               Row(
//                                 children: [
//                                   Expanded(
//                                     child: infoTile(
//                                       icon: Icons.route_rounded,
//                                       label: "Distance",
//                                       value: offer.distanceKm == null ? "-" : "${offer.distanceKm!.toStringAsFixed(2)} km",
//                                     ),
//                                   ),
//                                   const SizedBox(width: 10),
//                                   Expanded(
//                                     child: infoTile(
//                                       icon: Icons.timelapse_rounded,
//                                       label: "Duration",
//                                       value: offer.bookingDuration == null ? "-" : "${offer.bookingDuration!.toStringAsFixed(1)} hr",
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 10),
//                               infoTile(
//                                 icon: Icons.location_on_rounded,
//                                 label: "Location",
//                                 value: offer.location ?? "-",
//                               ),
//                               const SizedBox(height: 14),
//                               Row(
//                                 children: [
//                                   Expanded(
//                                     child: OutlinedButton(
//                                       onPressed: () {
//                                         closeDialog();
//                                       },
//                                       style: OutlinedButton.styleFrom(
//                                         foregroundColor: kPrimary,
//                                         side: BorderSide(color: kPrimary.withOpacity(0.35)),
//                                         padding: const EdgeInsets.symmetric(vertical: 12),
//                                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                                       ),
//                                       child: const Text(
//                                         "Decline",
//                                         style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
//                                       ),
//                                     ),
//                                   ),
//                                   const SizedBox(width: 12),
//                                   Expanded(
//                                     child: ElevatedButton(
//                                       onPressed: () {
//                                         context.read<UserBookingBloc>().add(
//                                               AcceptBooking(
//                                                 userId: userId.toString(),
//                                                 bookingDetailId: offer.bookingDetailId,
//                                               ),
//                                             );
//                                         closeDialog();
//                                       },
//                                       style: ElevatedButton.styleFrom(
//                                         backgroundColor: kPrimary,
//                                         foregroundColor: Colors.white,
//                                         padding: const EdgeInsets.symmetric(vertical: 12),
//                                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                                         elevation: 0,
//                                       ),
//                                       child: const Text(
//                                         "Accept",
//                                         style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800),
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             );
//           },
//         );
//       } catch (e) {
//         debugPrint("❌ dialog exception => $e");
//       } finally {
//         _dialogOpen = false;
//         _lastPopupBookingDetailId = null;
//       }
//     });
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _stopLocationUpdates();
//     _hubWatchdog?.cancel();
//     _hubSub?.cancel();
//     _hub.dispose();
//     super.dispose();
//   }

//   /// ===============================================================
//   /// ✅ BUILD UI (YOUR SAME UI - keep as is)
//   /// ===============================================================
//   @override
//   Widget build(BuildContext context) {
//     final earnings = period == 'Week' ? weeklyEarning : monthlyEarning;

//     final filteredTasks = _selectedChip == 'Upcoming'
//         ? upcoming
//         : _selectedChip == 'Current'
//             ? current
//             : [...current, ...upcoming];

//     return Scaffold(
//       backgroundColor: kBg,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         surfaceTintColor: Colors.transparent,
//         elevation: 0,
//         centerTitle: false,
//         titleSpacing: 16,
//         title: const Padding(
//           padding: EdgeInsets.only(top: 6),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Hello,',
//                 style: TextStyle(
//                   fontFamily: 'Poppins',
//                   fontSize: 16,
//                   fontWeight: FontWeight.w800,
//                   color: kTextDark,
//                 ),
//               ),
//               SizedBox(height: 2),
//               Text(
//                 'Ready for new gigs?',
//                 style: TextStyle(
//                   fontFamily: 'Poppins',
//                   fontSize: 12,
//                   color: kMuted,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 12),
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//               decoration: BoxDecoration(
//                 color: kPrimary.withOpacity(.06),
//                 borderRadius: BorderRadius.circular(999),
//                 border: Border.all(color: kPrimary.withOpacity(.14)),
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Text(
//                     'Available',
//                     style: TextStyle(
//                       fontFamily: 'Poppins',
//                       fontSize: 12,
//                       color: kPrimary,
//                       fontWeight: FontWeight.w800,
//                     ),
//                   ),
//                   const SizedBox(width: 6),
//                   Switch.adaptive(
//                     value: available,
//                     onChanged: _onAvailabilityToggle,
//                     activeColor: kPrimary,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//       body: SafeArea(
//         top: false,
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(24),
//                   gradient: LinearGradient(
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                     colors: [
//                       kPrimary.withOpacity(.16),
//                       kPrimary.withOpacity(.07),
//                       Colors.white,
//                     ],
//                   ),
//                   border: Border.all(color: kPrimary.withOpacity(.12)),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(.06),
//                       blurRadius: 22,
//                       offset: const Offset(0, 12),
//                     ),
//                   ],
//                 ),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             name,
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                             style: const TextStyle(
//                               fontFamily: 'Poppins',
//                               fontWeight: FontWeight.w900,
//                               color: Color(0xFF3E1E69),
//                               fontSize: 18,
//                             ),
//                           ),
//                           const SizedBox(height: 6),
//                           Text(
//                             available ? 'You’re online — offers can arrive anytime.' : 'You’re offline — go available to receive offers.',
//                             style: const TextStyle(
//                               fontFamily: 'Poppins',
//                               fontSize: 12.5,
//                               height: 1.25,
//                               color: Color(0xFF75748A),
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     _StatusPill(available: available),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 14),
//               _InfoCard(
//                 icon: available ? Icons.wifi_tethering_rounded : Icons.wifi_off_rounded,
//                 text: available ? 'You are online. New offers can arrive anytime.' : 'You are offline. Turn on availability to receive offers.',
//                 available: available,
//               ),
//               const SizedBox(height: 14),
//               LayoutBuilder(
//                 builder: (context, c) {
//                   final twoCols = c.maxWidth >= 720;
//                   if (twoCols) {
//                     return Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Expanded(child: _TaskerProfileCard(name: name)),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: _WhiteCard(
//                             padding: const EdgeInsets.all(14),
//                             child: _EarningsCard(
//                               period: period,
//                               amount: earnings,
//                               onChange: (p) => setState(() => period = p),
//                             ),
//                           ),
//                         ),
//                       ],
//                     );
//                   }
//                   return Column(
//                     children: [
//                       _TaskerProfileCard(name: name),
//                       const SizedBox(height: 12),
//                       _WhiteCard(
//                         padding: const EdgeInsets.all(14),
//                         child: _EarningsCard(
//                           period: period,
//                           amount: earnings,
//                           onChange: (p) => setState(() => period = p),
//                         ),
//                       ),
//                     ],
//                   );
//                 },
//               ),
//               const SizedBox(height: 12),
//               _WhiteCard(
//                 child: _KpiRow(
//                   rating: rating,
//                   reviews: reviews,
//                   acceptance: acceptanceRate,
//                   completion: completionRate,
//                 ),
//               ),
//               const SizedBox(height: 18),
//               const Text(
//                 'Your jobs',
//                 style: TextStyle(
//                   fontFamily: 'Poppins',
//                   fontSize: 16,
//                   color: kTextDark,
//                   fontWeight: FontWeight.w900,
//                 ),
//               ),
//               const SizedBox(height: 10),
//               _ChipsRow(
//                 labels: _chipLabels,
//                 selected: _selectedChip,
//                 onTap: (v) => setState(() => _selectedChip = v),
//               ),
//               const SizedBox(height: 14),
//               _WhiteCard(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       _selectedChip == 'All' ? 'Recent activity' : '$_selectedChip tasks',
//                       style: const TextStyle(
//                         fontFamily: 'Poppins',
//                         fontSize: 14.5,
//                         color: kTextDark,
//                         fontWeight: FontWeight.w900,
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     if (filteredTasks.isEmpty)
//                       const _EmptyState(text: 'No tasks yet. Turn on availability to get offers.')
//                     else
//                       Column(
//                         children: [
//                           for (int i = 0; i < filteredTasks.length; i++) ...[
//                             _TaskTile(task: filteredTasks[i]),
//                             if (i != filteredTasks.length - 1)
//                               Divider(
//                                 height: 18,
//                                 color: Colors.grey.withOpacity(0.18),
//                               ),
//                           ],
//                         ],
//                       ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// /// ===============================================================
// /// ✅ UI WIDGETS (UNCHANGED)
// /// ===============================================================
// class _StatusPill extends StatelessWidget {
//   const _StatusPill({required this.available});
//   final bool available;

//   @override
//   Widget build(BuildContext context) {
//     final fg = available ? const Color(0xFF1E8E66) : const Color(0xFFEE8A41);
//     final bg = available ? const Color(0xFFEFF8F4) : const Color(0xFFFFF4E8);

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: BoxDecoration(
//         color: bg,
//         borderRadius: BorderRadius.circular(999),
//         border: Border.all(color: fg.withOpacity(.18)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             available ? Icons.wifi_tethering_rounded : Icons.wifi_off_rounded,
//             size: 16,
//             color: fg,
//           ),
//           const SizedBox(width: 6),
//           Text(
//             available ? 'Online' : 'Offline',
//             style: TextStyle(
//               fontFamily: 'Poppins',
//               fontSize: 12,
//               fontWeight: FontWeight.w900,
//               color: fg,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _TaskerProfileCard extends StatelessWidget {
//   const _TaskerProfileCard({required this.name});
//   final String name;

//   @override
//   Widget build(BuildContext context) {
//     return _WhiteCard(
//       padding: const EdgeInsets.all(14),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: const [
//               _AvatarRing(
//                 url: 'https://images.unsplash.com/photo-1607746882042-944635dfe10e?q=80&w=256&auto=format&fit=crop',
//               ),
//               SizedBox(width: 12),
//             ],
//           ),
//           const SizedBox(height: 10),
//           Text(
//             name,
//             maxLines: 2,
//             overflow: TextOverflow.ellipsis,
//             style: const TextStyle(
//               fontFamily: 'Poppins',
//               fontWeight: FontWeight.w900,
//               color: Color(0xFF3E1E69),
//               fontSize: 16.5,
//               height: 1.15,
//             ),
//           ),
//           const SizedBox(height: 14),
//           const _VerificationRow(
//             items: [
//               VerificationItem(
//                 label: 'ID Verified',
//                 icon: Icons.badge_outlined,
//                 bg: Color(0xFFEFF8F4),
//                 fg: Color(0xFF1E8E66),
//               ),
//               VerificationItem(
//                 label: 'Police Verified',
//                 icon: Icons.verified_user_outlined,
//                 bg: Color(0xFFF3EEFF),
//                 fg: Color(0xFF5C2E91),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _WhiteCard extends StatelessWidget {
//   const _WhiteCard({required this.child, this.padding = const EdgeInsets.all(14)});
//   final Widget child;
//   final EdgeInsets padding;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: padding,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: kPrimary.withOpacity(.08)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(.05),
//             blurRadius: 18,
//             offset: const Offset(0, 12),
//           ),
//         ],
//       ),
//       child: child,
//     );
//   }
// }

// class _InfoCard extends StatelessWidget {
//   const _InfoCard({
//     required this.icon,
//     required this.text,
//     required this.available,
//   });

//   final IconData icon;
//   final String text;
//   final bool available;

//   @override
//   Widget build(BuildContext context) {
//     final fg = available ? const Color(0xFF1E8E66) : kPrimary;
//     final bg = available ? const Color(0xFFEFF8F4) : kPrimary.withOpacity(.06);

//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(18),
//         border: Border.all(color: fg.withOpacity(.12)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(.04),
//             blurRadius: 16,
//             offset: const Offset(0, 10),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             height: 42,
//             width: 42,
//             decoration: BoxDecoration(
//               color: bg,
//               borderRadius: BorderRadius.circular(14),
//             ),
//             child: Icon(icon, color: fg),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               text,
//               style: TextStyle(
//                 fontFamily: 'Poppins',
//                 fontSize: 12.5,
//                 color: fg.withOpacity(.95),
//                 fontWeight: FontWeight.w600,
//                 height: 1.25,
//               ),
//             ),
//           ),
//           Icon(Icons.chevron_right_rounded, color: fg.withOpacity(.9)),
//         ],
//       ),
//     );
//   }
// }

// class _AvatarRing extends StatelessWidget {
//   const _AvatarRing({required this.url});
//   final String url;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(2),
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         gradient: LinearGradient(
//           colors: [kPrimary.withOpacity(.75), kPrimary],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//       ),
//       child: CircleAvatar(
//         radius: 24,
//         backgroundColor: Colors.white,
//         child: CircleAvatar(
//           radius: 22,
//           backgroundImage: NetworkImage(url),
//         ),
//       ),
//     );
//   }
// }

// class VerificationItem {
//   final String label;
//   final IconData icon;
//   final Color bg;
//   final Color fg;

//   const VerificationItem({
//     required this.label,
//     required this.icon,
//     required this.bg,
//     required this.fg,
//   });
// }

// class _VerificationRow extends StatelessWidget {
//   const _VerificationRow({required this.items});
//   final List<VerificationItem> items;

//   @override
//   Widget build(BuildContext context) {
//     return Wrap(
//       spacing: 10,
//       runSpacing: 10,
//       children: items.map((v) => _VerificationPill(item: v)).toList(),
//     );
//   }
// }

// class _VerificationPill extends StatelessWidget {
//   const _VerificationPill({required this.item});
//   final VerificationItem item;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
//       decoration: BoxDecoration(
//         color: item.bg,
//         borderRadius: BorderRadius.circular(999),
//         border: Border.all(color: item.fg.withOpacity(.14)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(item.icon, size: 16, color: item.fg),
//           const SizedBox(width: 7),
//           Text(
//             item.label,
//             style: TextStyle(
//               fontFamily: 'Poppins',
//               fontSize: 11.8,
//               fontWeight: FontWeight.w900,
//               color: item.fg,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _ChipsRow extends StatelessWidget {
//   const _ChipsRow({
//     required this.labels,
//     required this.selected,
//     required this.onTap,
//   });

//   final List<String> labels;
//   final String selected;
//   final ValueChanged<String> onTap;

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 38,
//       child: ListView.separated(
//         scrollDirection: Axis.horizontal,
//         itemCount: labels.length,
//         separatorBuilder: (_, __) => const SizedBox(width: 10),
//         itemBuilder: (_, i) {
//           final label = labels[i];
//           final sel = label == selected;

//           return InkWell(
//             borderRadius: BorderRadius.circular(999),
//             onTap: () => onTap(label),
//             child: AnimatedContainer(
//               duration: const Duration(milliseconds: 180),
//               padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
//               decoration: BoxDecoration(
//                 color: sel ? kPrimary : Colors.white,
//                 borderRadius: BorderRadius.circular(999),
//                 border: Border.all(color: sel ? kPrimary : kPrimary.withOpacity(.22)),
//                 boxShadow: sel
//                     ? [
//                         BoxShadow(
//                           color: kPrimary.withOpacity(.18),
//                           blurRadius: 14,
//                           offset: const Offset(0, 8),
//                         )
//                       ]
//                     : null,
//               ),
//               child: Text(
//                 label,
//                 style: TextStyle(
//                   fontFamily: 'Poppins',
//                   color: sel ? Colors.white : kPrimary,
//                   fontWeight: FontWeight.w800,
//                   fontSize: 12.5,
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// class _KpiRow extends StatelessWidget {
//   const _KpiRow({
//     required this.rating,
//     required this.reviews,
//     required this.acceptance,
//     required this.completion,
//   });

//   final double rating;
//   final int reviews;
//   final int acceptance;
//   final int completion;

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, c) {
//         final cols = c.maxWidth >= 520 ? 3 : 2;
//         final gap = 10.0;
//         final itemW = (c.maxWidth - (gap * (cols - 1))) / cols;

//         return Wrap(
//           spacing: gap,
//           runSpacing: gap,
//           children: [
//             SizedBox(
//               width: itemW,
//               child: const _KpiTile(
//                 icon: Icons.star_rate_rounded,
//                 title: "4.9",
//                 sub: "124 reviews",
//               ),
//             ),
//             SizedBox(
//               width: itemW,
//               child: _KpiTile(
//                 icon: Icons.bolt_rounded,
//                 title: "$acceptance%",
//                 sub: "acceptance",
//               ),
//             ),
//             SizedBox(
//               width: itemW,
//               child: _KpiTile(
//                 icon: Icons.check_circle_rounded,
//                 title: "$completion%",
//                 sub: "completion",
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }

// class _KpiTile extends StatelessWidget {
//   const _KpiTile({required this.icon, required this.title, required this.sub});

//   final IconData icon;
//   final String title;
//   final String sub;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: kPrimary.withOpacity(0.06),
//         borderRadius: BorderRadius.circular(18),
//         border: Border.all(color: kPrimary.withOpacity(0.12)),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 38,
//             height: 38,
//             decoration: BoxDecoration(
//               color: kPrimary.withOpacity(0.12),
//               borderRadius: BorderRadius.circular(14),
//             ),
//             child: Icon(icon, color: kPrimary, size: 20),
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                     fontFamily: 'Poppins',
//                     fontWeight: FontWeight.w900,
//                     fontSize: 15,
//                     color: Color(0xFF3E1E69),
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   sub,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                     fontFamily: 'Poppins',
//                     fontSize: 11.5,
//                     color: Color(0xFF75748A),
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _EarningsCard extends StatelessWidget {
//   const _EarningsCard({
//     required this.period,
//     required this.amount,
//     required this.onChange,
//   });

//   final String period;
//   final int amount;
//   final ValueChanged<String> onChange;

//   @override
//   Widget build(BuildContext context) {
//     // ✅ Keep same as yours (you already have it)
//     return const SizedBox.shrink();
//   }
// }

// class _TaskTile extends StatelessWidget {
//   const _TaskTile({required this.task});
//   final _Task task;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             task.title,
//             style: const TextStyle(
//               fontFamily: 'Poppins',
//               fontWeight: FontWeight.w900,
//               fontSize: 14.5,
//               color: Color(0xFF3E1E69),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Wrap(
//             spacing: 12,
//             runSpacing: 8,
//             children: [
//               _Meta(icon: Icons.calendar_month_rounded, text: task.date),
//               _Meta(icon: Icons.schedule_rounded, text: task.time),
//               _Meta(icon: Icons.location_on_outlined, text: task.location),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _Meta extends StatelessWidget {
//   const _Meta({required this.icon, required this.text});
//   final IconData icon;
//   final String text;

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(icon, size: 16, color: const Color(0xFF75748A)),
//         const SizedBox(width: 6),
//         ConstrainedBox(
//           constraints: const BoxConstraints(maxWidth: 180),
//           child: Text(
//             text,
//             overflow: TextOverflow.ellipsis,
//             style: const TextStyle(
//               fontFamily: 'Poppins',
//               fontSize: 12,
//               color: Color(0xFF75748A),
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _EmptyState extends StatelessWidget {
//   const _EmptyState({required this.text});
//   final String text;

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 18),
//       child: Column(
//         children: [
//           Container(
//             width: 54,
//             height: 54,
//             decoration: BoxDecoration(
//               color: kPrimary.withOpacity(.08),
//               borderRadius: BorderRadius.circular(18),
//               border: Border.all(color: kPrimary.withOpacity(.14)),
//             ),
//             child: const Icon(Icons.inbox_rounded, size: 28, color: kPrimary),
//           ),
//           const SizedBox(height: 10),
//           Text(
//             text,
//             style: const TextStyle(
//               fontFamily: 'Poppins',
//               fontSize: 12.5,
//               color: Color(0xFF75748A),
//               fontWeight: FontWeight.w700,
//               height: 1.25,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }
// }

