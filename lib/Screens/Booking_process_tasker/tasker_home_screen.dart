import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_bloc.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_bloc.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_event.dart';
import 'dart:convert';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:taskoon/Repository/auth_repository.dart';


const Color kPrimary = Color(0xFF5C2E91);
const Color kTextDark = Color(0xFF3E1E69);
const Color kMuted = Color(0xFF75748A);
const Color kBg = Color(0xFFF8F7FB);

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

  // ✅ FIX: supports 4.5 (double)
  final String? bookingService;
  final String? userName;
  final double? bookingDuration;
  final DateTime? bookingTime;
  final double? distanceKm;
  final String? location;

  // existing
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

      // data can be a map or json string
      dynamic dataAny = map['data'];
      if (dataAny is String) {
        try {
          dataAny = jsonDecode(dataAny);
        } catch (_) {}
      }

      Map<String, dynamic>? data;
      if (dataAny is Map) data = Map<String, dynamic>.from(dataAny);

      // bookingDetailId
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

      // ✅ FIX: duration as double to support 4.5
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

/// ===============================================================
/// ✅ SIGNALR SERVICE (Stable + single-start lock + logs)
/// ===============================================================
class TaskerDispatchHubService {
  HubConnection? _conn;
  String? _baseUrl;
  String? _userId;

  Completer<void>? _startCompleter;
  bool _handlersAttached = false;

  final _notifCtrl = StreamController<dynamic>.broadcast();
  Stream<dynamic> get notifications => _notifCtrl.stream;

  bool get isConnected => _conn != null && _conn!.state == HubConnectionState.Connected;
  HubConnectionState? get state => _conn?.state;

  void logStatus([String tag = "STATUS"]) {
    debugPrint(
      "🟣 HUB($tag): connected=$isConnected state=${_conn?.state} baseUrl=${_baseUrl ?? '-'} userId=${(_userId?.isNotEmpty == true) ? _userId : '-'}",
    );
  }

  void configure({required String baseUrl, required String userId}) {
    final changed = (_baseUrl != baseUrl) || (_userId != userId);
    _baseUrl = baseUrl;
    _userId = userId;

    logStatus("CONFIG");

    if (changed) {
      debugPrint("🧩 HUB(SVC): config changed -> rebuilding");
      _handlersAttached = false;
      _disposeConnectionOnly();
    }
  }

  Future<void> ensureConnected() async {
    if (_baseUrl == null || _userId == null || _userId!.isEmpty) {
      throw Exception("HUB(SVC): configure(baseUrl,userId) first");
    }

    logStatus("ENSURE_ENTER");

    if (isConnected) {
      logStatus("ENSURE_ALREADY_CONNECTED");
      return;
    }

    if (_startCompleter != null) {
      logStatus("ENSURE_WAIT_EXISTING_START");
      await _startCompleter!.future;
      logStatus("ENSURE_AFTER_WAIT");
      return;
    }

    _startCompleter = Completer<void>();
    try {
      await _startInternal();
    } finally {
      _startCompleter?.complete();
      _startCompleter = null;
      logStatus("ENSURE_EXIT");
    }
  }

  Future<void> _startInternal() async {
    final baseUrl = _baseUrl!;
    final userId = _userId!;
    final url = "$baseUrl/hubs/dispatch?userId=$userId";

    try {
      _conn ??= HubConnectionBuilder()
          .withUrl(
            url,
            options: HttpConnectionOptions(
              transport: HttpTransportType.LongPolling,
            ),
          )
          .withAutomaticReconnect()
          .build();

      _wireLifecycle(_conn!);

      if (!_handlersAttached) {
        _registerHandlers(_conn!);
        _handlersAttached = true;
        debugPrint("🧩 HUB(SVC): handlers attached");
      }

      debugPrint("🔌 HUB(SVC): start... url=$url state(before)=${_conn!.state}");

      if (_conn!.state != HubConnectionState.Disconnected) {
        try {
          debugPrint("🧩 HUB(SVC): not Disconnected -> stopping first...");
          await _conn!.stop();
          debugPrint("🧩 HUB(SVC): stop done.");
        } catch (e) {
          debugPrint("⚠️ HUB(SVC): stop failed (ignored) => $e");
        }
      }

      await _conn!.start();

      debugPrint("✅ HUB(SVC): start done. state(after)=${_conn!.state}");

      if (_conn!.state != HubConnectionState.Connected) {
        throw Exception("HUB(SVC): start finished but state=${_conn!.state}");
      }

      debugPrint("✅ HUB(SVC): CONNECTED ✅ (LongPolling)");
      logStatus("CONNECTED_FINAL");
    } catch (e) {
      debugPrint("❌ HUB(SVC): start failed => $e");
      logStatus("START_FAIL");
      _handlersAttached = false;
      _disposeConnectionOnly();
      rethrow;
    }
  }

  void _wireLifecycle(HubConnection c) {
    c.onclose(({error}) {
      debugPrint("🛑 HUB(SVC): onClose error=$error state=${c.state}");
      logStatus("ONCLOSE");
    });

    c.onreconnecting(({error}) {
      debugPrint("🔄 HUB(SVC): onReconnecting error=$error state=${c.state}");
      logStatus("RECONNECTING");
    });

    c.onreconnected(({connectionId}) {
      debugPrint("✅ HUB(SVC): onReconnected id=$connectionId state=${c.state}");
      logStatus("RECONNECTED");
    });
  }

  void _registerHandlers(HubConnection c) {
    c.off("ReceiveBookingOffer");
    c.off("ReceiveNotification");

    debugPrint("🧩 HUB(SVC): registering handlers: ReceiveBookingOffer, ReceiveNotification");

    c.on("ReceiveBookingOffer", (args) {
      final payload = _normalizeArgs(args);
      if (payload == null) return;
      debugPrint("📩 HUB(SVC): ReceiveBookingOffer => $payload");
      _notifCtrl.add(payload);
    });

    c.on("ReceiveNotification", (args) {
      final payload = _normalizeArgs(args);
      if (payload == null) return;
      debugPrint("📩 HUB(SVC): ReceiveNotification => $payload");
      _notifCtrl.add(payload);
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
    logStatus("DISPOSE_CONN_ONLY_BEGIN");
    try {
      _conn?.stop();
    } catch (e) {
      debugPrint("⚠️ HUB(SVC): stop() failed in disposeConnectionOnly => $e");
    }
    _conn = null;
    logStatus("DISPOSE_CONN_ONLY_END");
  }

  Future<void> dispose() async {
    logStatus("DISPOSE_BEGIN");
    _disposeConnectionOnly();
    await _notifCtrl.close();
    debugPrint("🧩 HUB(SVC): stream closed");
    logStatus("DISPOSE_END");
  }
}

/// ===============================================================
/// ✅ SCREEN (UI SAME, POPUP UPDATED TO SHOW FULL OFFER DETAILS)
/// ===============================================================
class TaskerHomeRedesign extends StatefulWidget {
  const TaskerHomeRedesign({super.key});

  @override
  State<TaskerHomeRedesign> createState() => _TaskerHomeRedesignState();
}

class _TaskerHomeRedesignState extends State<TaskerHomeRedesign> with WidgetsBindingObserver {
  static const String _baseUrl = ApiConfig.baseUrl;

  final box = GetStorage();

  String? userId;
  String name = "";

  bool available = false;
  String period = 'Week';
  static const String _kAvailabilityKey = 'tasker_available';
  bool _restored = false;

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

  String _selectedChip = 'All';
  final List<String> _chipLabels = const ['All', 'Upcoming', 'Current'];

  Duration _nextBackoff() {
    final secs = [2, 4, 8, 16, 30, 30, 30];
    final idx = (_attempt - 1).clamp(0, secs.length - 1);
    return Duration(seconds: secs[idx]);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      userId = (box.read('userId'))?.toString();
      name = (box.read("name"))?.toString() ?? "";

      final saved = box.read(_kAvailabilityKey) == true;
      setState(() {
        available = saved;
        _restored = true;
      });

      debugPrint("🟣 TaskerHome init: userId=$userId name=$name restored available=$saved");

      await _trySetupSignalR(reason: "init");
      _attachHubListener();
      _startHubWatchdog();

      if (saved) _startLocationUpdates();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.resumed) {
      debugPrint("🔁 TaskerHome resumed -> FORCE hub ensureConnected");
      _ensureHubConnectedNow(reason: "resumed");
    }
  }

  Future<void> _trySetupSignalR({required String reason}) async {
    userId ??= (box.read('userId'))?.toString();

    if (userId == null || userId!.trim().isEmpty) {
      debugPrint("⏳ TASKER HUB: userId not ready yet (reason=$reason)");
      return;
    }

    if (!_hubConfigured) {
      debugPrint("🧩 TASKER HUB: configure baseUrl=$_baseUrl userId=$userId");
      _hub.configure(baseUrl: _baseUrl, userId: userId!.trim());
      _hubConfigured = true;
      _hub.logStatus("SCREEN_CONFIG_DONE");
    }

    await _ensureHubConnectedNow(reason: reason);
  }

  Future<bool> _ensureHubConnectedNow({required String reason}) async {
    if (!_hubConfigured) {
      await _trySetupSignalR(reason: "ensureNow($reason)");
    }

    if (!_hubConfigured) {
      debugPrint("❌ TASKER HUB: still not configured (userId missing?) reason=$reason");
      return false;
    }

    if (_hub.isConnected) return true;
    if (_hubEnsuring) return false;

    _hubEnsuring = true;
    try {
      debugPrint("🔌 TASKER HUB: ensureConnected NOW... reason=$reason state=${_hub.state}");
      await _hub.ensureConnected();
      debugPrint("✅ TASKER HUB: connected=${_hub.isConnected} state=${_hub.state}");
      if (_hub.isConnected) _attempt = 0;
      return _hub.isConnected;
    } catch (e, st) {
      debugPrint("❌ TASKER HUB: ensureConnected exception => $e");
      debugPrint("$st");
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
        await _trySetupSignalR(reason: "watchdog-config");
        return;
      }

      if (_hub.isConnected) return;
      if (_hubEnsuring) return;

      _attempt++;
      final wait = _nextBackoff();

      debugPrint("🛡️ TASKER HUB WATCHDOG: disconnected -> retry attempt=$_attempt in ${wait.inSeconds}s");

      await Future.delayed(wait);
      if (!mounted) return;

      await _ensureHubConnectedNow(reason: "watchdog");
    });
  }

  void _attachHubListener() {
    _hubSub?.cancel();

    debugPrint("🧩 TASKER HUB: attaching notifications listener...");

    _hubSub = _hub.notifications.listen(
      (payload) {
        if (!mounted) return;

        debugPrint("📩 TASKER HUB payload => $payload");

        if (!available) {
          debugPrint("⚠️ TASKER HUB: offer received but available=false (no popup)");
          return;
        }

        final offer = TaskerBookingOffer.tryParse(payload);
        if (offer == null) {
          debugPrint("❌ TASKER HUB: offer parse FAILED (popup not shown)");
          return;
        }

        debugPrint("✅ TASKER HUB: offer parsed bookingDetailId=${offer.bookingDetailId}");
        _showBookingPopup(offer);
      },
      onError: (e) => debugPrint("❌ TASKER HUB stream error => $e"),
      onDone: () => debugPrint("⚠️ TASKER HUB stream closed"),
    );
  }

  Future<void> _onAvailabilityToggle(bool value) async {
    debugPrint("🟡 Availability toggle => $value");
    await box.write(_kAvailabilityKey, value);

    setState(() => available = value);

    userId ??= (box.read('userId'))?.toString();
    if (userId != null) userId = userId!.trim();

    if (!value) {
      debugPrint("🔴 TASKER OFFLINE: stop location updates");
      _stopLocationUpdates();

      if (userId != null && userId!.isNotEmpty) {
        context.read<UserBookingBloc>().add(ChangeAvailabilityStatus(userId: userId.toString()));
        debugPrint("✅ EVENT: ChangeAvailabilityStatus dispatched (offline)");
      }
      return;
    }

    await _ensureHubConnectedNow(reason: "availability-on");

    if (userId != null && userId!.isNotEmpty) {
      context.read<UserBookingBloc>().add(ChangeAvailabilityStatus(userId: userId.toString()));
      debugPrint("✅ EVENT: ChangeAvailabilityStatus dispatched (online)");
    }

    debugPrint("🟢 TASKER ONLINE: start location updates (every 5s)");
    _startLocationUpdates();
  }

  Future<void> _dispatchLocationUpdateToApi() async {
    if (!mounted) return;

    if (!available) {
      debugPrint("⚠️ LOCATION: skipped (available=false)");
      return;
    }

    userId ??= (box.read('userId'))?.toString();
    userId = userId?.trim();

    if (userId == null || userId!.isEmpty) {
      debugPrint("❌ LOCATION: userId missing (cannot send)");
      return;
    }

    final ok = await _ensureHubConnectedNow(reason: "location-tick");
    if (!ok) {
      debugPrint("⚠️ LOCATION: skipped (SignalR not connected yet)");
      return;
    }

    const double lat = 67.00;
    const double lng = 70.00;

    debugPrint("📍 LOCATION: sending => userId=$userId lat=$lat lng=$lng");

    context.read<UserBookingBloc>().add(
          UpdateUserLocationRequested(
            userId: userId.toString(),
            latitude: lat,
            longitude: lng,
          ),
        );

    debugPrint("✅ EVENT: UpdateUserLocationRequested dispatched");
  }

  void _startLocationUpdates() {
    if (!_restored) return;
    if (!available) return;

    if (_locationTimer?.isActive == true) {
      debugPrint("⏱️ LOCATION TIMER: already running");
      return;
    }

    debugPrint("⏱️ LOCATION TIMER: start interval=${_locationInterval.inSeconds}s");

    _dispatchLocationUpdateToApi();

    _locationTimer = Timer.periodic(_locationInterval, (_) async {
      if (!mounted) return;

      if (!available) {
        debugPrint("🛑 LOCATION TIMER: detected available=false -> stopping");
        _stopLocationUpdates();
        return;
      }

      debugPrint("⏱️ LOCATION TIMER TICK");
      await _dispatchLocationUpdateToApi();
    });
  }

  void _stopLocationUpdates() {
    debugPrint("🛑 LOCATION TIMER: stop");
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  // ✅ POPUP UPDATED: shows full offer map (dynamic)
  void _showBookingPopup(TaskerBookingOffer offer) {
    if (!mounted) return;

    if (_dialogOpen) {
      debugPrint("⚠️ POPUP: already open, skipping booking=${offer.bookingDetailId}");
      return;
    }

    if (_lastPopupBookingDetailId == offer.bookingDetailId) {
      debugPrint("⚠️ POPUP: same booking received again, skipping booking=${offer.bookingDetailId}");
      return;
    }

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

            // ✅ NEW: show offer map table dynamically
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
                    debugPrint("⏳ POPUP: auto-timeout booking=${offer.bookingDetailId}");
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

                              // ✅ NEW: show all SignalR offer data here
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
                                        debugPrint("🟠 POPUP: Decline pressed booking=${offer.bookingDetailId}");
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
                                        debugPrint("🟢 POPUP: Accept pressed booking=${offer.bookingDetailId} userId=$userId");
                                        context.read<UserBookingBloc>().add(
                                              AcceptBooking(
                                                userId: userId.toString(),
                                                bookingDetailId: offer.bookingDetailId,
                                              ),
                                            );
                                        debugPrint("✅ EVENT: AcceptBooking dispatched");
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
        debugPrint("❌ POPUP: showDialog exception => $e");
      } finally {
        _dialogOpen = false;
        _lastPopupBookingDetailId = null;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopLocationUpdates();
    _hubWatchdog?.cancel();
    _hubSub?.cancel();
    _hub.dispose();
    super.dispose();
  }

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
/// ✅ UI WIDGETS (unchanged from your code)
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 18,
                color: kPrimary,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Earnings',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.5,
                  color: Color(0xFF75748A),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(.08),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: kPrimary.withOpacity(.16)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.trending_up_rounded, size: 16, color: kPrimary),
                  SizedBox(width: 5),
                  Text(
                    'Live',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: kPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  "\$${amount.toString()}",
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 30,
                    color: Color(0xFF3E1E69),
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'per ${period.toLowerCase()}',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: Color(0xFF75748A),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: const [
            Expanded(
              child: _MiniLineStat(
                label: 'Completed',
                value: '12',
                icon: Icons.check_circle_outline_rounded,
                fg: Color(0xFF1E8E66),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _MiniLineStat(
                label: 'Pending',
                value: '3',
                icon: Icons.hourglass_bottom_rounded,
                fg: Color(0xFFEE8A41),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: kPrimary.withOpacity(0.15)),
            ),
            child: Wrap(
              spacing: 6,
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
        ),
      ],
    );
  }
}

class _MiniLineStat extends StatelessWidget {
  const _MiniLineStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.fg,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: fg.withOpacity(.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fg.withOpacity(.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: fg.withOpacity(.95),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? kPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: selected ? Colors.white : kPrimary,
          ),
        ),
      ),
    );
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








/*

//new updation
final GlobalKey<NavigatorState> appNavKey = GlobalKey<NavigatorState>();




const Color kPrimary = Color(0xFF5C2E91);
const Color kTextDark = Color(0xFF3E1E69);
const Color kMuted = Color(0xFF75748A);
const Color kBg = Color(0xFFF8F7FB);

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

  // ✅ new fields
  final String? bookingService;
  final String? userName;
  final int? bookingDuration;
  final DateTime? bookingTime;
  final double? distanceKm;
  final String? location;

  // existing
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
      "Duration": bookingDuration == null ? "" : "${bookingDuration} hr",
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

      // data can be a map or json string
      dynamic dataAny = map['data'];
      if (dataAny is String) {
        try {
          dataAny = jsonDecode(dataAny);
        } catch (_) {}
      }

      Map<String, dynamic>? data;
      if (dataAny is Map) data = Map<String, dynamic>.from(dataAny);

      // bookingDetailId
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

      // ✅ new fields parsing
      final bookingService = (data?['bookingService'] ?? data?['BookingService'])?.toString();
      final userName = (data?['userName'] ?? data?['UserName'])?.toString();

      final bookingDuration = _toInt(data?['bookingDuration'] ?? data?['BookingDuration']);
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

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static DateTime? _toDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }
}

/// ===============================================================
/// ✅ SIGNALR SERVICE (Stable + single-start lock + logs)
/// ===============================================================
class TaskerDispatchHubService {
  HubConnection? _conn;
  String? _baseUrl;
  String? _userId;

  Completer<void>? _startCompleter;
  bool _handlersAttached = false;

  final _notifCtrl = StreamController<dynamic>.broadcast();
  Stream<dynamic> get notifications => _notifCtrl.stream;

  bool get isConnected => _conn != null && _conn!.state == HubConnectionState.Connected;
  HubConnectionState? get state => _conn?.state;

  void logStatus([String tag = "STATUS"]) {
    debugPrint(
      "🟣 HUB($tag): connected=$isConnected state=${_conn?.state} baseUrl=${_baseUrl ?? '-'} userId=${(_userId?.isNotEmpty == true) ? _userId : '-'}",
    );
  }

  void configure({required String baseUrl, required String userId}) {
    final changed = (_baseUrl != baseUrl) || (_userId != userId);
    _baseUrl = baseUrl;
    _userId = userId;

    logStatus("CONFIG");

    if (changed) {
      debugPrint("🧩 HUB(SVC): config changed -> rebuilding");
      _handlersAttached = false;
      _disposeConnectionOnly();
    }
  }

  Future<void> ensureConnected() async {
    if (_baseUrl == null || _userId == null || _userId!.isEmpty) {
      throw Exception("HUB(SVC): configure(baseUrl,userId) first");
    }

    logStatus("ENSURE_ENTER");

    if (isConnected) {
      logStatus("ENSURE_ALREADY_CONNECTED");
      return;
    }

    // ✅ If already starting, wait (prevents parallel starts)
    if (_startCompleter != null) {
      logStatus("ENSURE_WAIT_EXISTING_START");
      await _startCompleter!.future;
      logStatus("ENSURE_AFTER_WAIT");
      return;
    }

    _startCompleter = Completer<void>();
    try {
      await _startInternal();
    } finally {
      _startCompleter?.complete();
      _startCompleter = null;
      logStatus("ENSURE_EXIT");
    }
  }

  Future<void> _startInternal() async {
    final baseUrl = _baseUrl!;
    final userId = _userId!;
    final url = "$baseUrl/hubs/dispatch?userId=$userId";

    try {
      _conn ??= HubConnectionBuilder()
          .withUrl(
            url,
            options: HttpConnectionOptions(
              // ✅ Mobile stable
              transport: HttpTransportType.LongPolling,
              // accessTokenFactory: () async => "token",
            ),
          )
          .withAutomaticReconnect()
          .build();

      _wireLifecycle(_conn!);

      if (!_handlersAttached) {
        _registerHandlers(_conn!);
        _handlersAttached = true;
        debugPrint("🧩 HUB(SVC): handlers attached");
      }

      debugPrint("🔌 HUB(SVC): start... url=$url state(before)=${_conn!.state}");

      // reset if in weird state
      if (_conn!.state != HubConnectionState.Disconnected) {
        try {
          debugPrint("🧩 HUB(SVC): not Disconnected -> stopping first...");
          await _conn!.stop();
          debugPrint("🧩 HUB(SVC): stop done.");
        } catch (e) {
          debugPrint("⚠️ HUB(SVC): stop failed (ignored) => $e");
        }
      }

      await _conn!.start();

      debugPrint("✅ HUB(SVC): start done. state(after)=${_conn!.state}");

      if (_conn!.state != HubConnectionState.Connected) {
        throw Exception("HUB(SVC): start finished but state=${_conn!.state}");
      }

      debugPrint("✅ HUB(SVC): CONNECTED ✅ (LongPolling)");
      logStatus("CONNECTED_FINAL");
    } catch (e) {
      debugPrint("❌ HUB(SVC): start failed => $e");
      logStatus("START_FAIL");
      _handlersAttached = false;
      _disposeConnectionOnly();
      rethrow;
    }
  }

  void _wireLifecycle(HubConnection c) {
    c.onclose(({error}) {
      debugPrint("🛑 HUB(SVC): onClose error=$error state=${c.state}");
      logStatus("ONCLOSE");
    });

    c.onreconnecting(({error}) {
      debugPrint("🔄 HUB(SVC): onReconnecting error=$error state=${c.state}");
      logStatus("RECONNECTING");
    });

    c.onreconnected(({connectionId}) {
      debugPrint("✅ HUB(SVC): onReconnected id=$connectionId state=${c.state}");
      logStatus("RECONNECTED");
    });
  }

  void _registerHandlers(HubConnection c) {
    c.off("ReceiveBookingOffer");
    c.off("ReceiveNotification");

    debugPrint("🧩 HUB(SVC): registering handlers: ReceiveBookingOffer, ReceiveNotification");

    c.on("ReceiveBookingOffer", (args) {
      final payload = _normalizeArgs(args);
      if (payload == null) return;
      debugPrint("📩 HUB(SVC): ReceiveBookingOffer => $payload");
      _notifCtrl.add(payload);
    });

    c.on("ReceiveNotification", (args) {
      final payload = _normalizeArgs(args);
      if (payload == null) return;
      debugPrint("📩 HUB(SVC): ReceiveNotification => $payload");
      _notifCtrl.add(payload);
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
    logStatus("DISPOSE_CONN_ONLY_BEGIN");
    try {
      _conn?.stop();
    } catch (e) {
      debugPrint("⚠️ HUB(SVC): stop() failed in disposeConnectionOnly => $e");
    }
    _conn = null;
    logStatus("DISPOSE_CONN_ONLY_END");
  }

  Future<void> dispose() async {
    logStatus("DISPOSE_BEGIN");
    _disposeConnectionOnly();
    await _notifCtrl.close();
    debugPrint("🧩 HUB(SVC): stream closed");
    logStatus("DISPOSE_END");
  }
}

/// ===============================================================
/// ✅ SCREEN (UI SAME, LOGIC UPDATED)
/// ===============================================================
class TaskerHomeRedesign extends StatefulWidget {
  const TaskerHomeRedesign({super.key});

  @override
  State<TaskerHomeRedesign> createState() => _TaskerHomeRedesignState();
}

class _TaskerHomeRedesignState extends State<TaskerHomeRedesign> with WidgetsBindingObserver {
  static const String _baseUrl =ApiConfig.baseUrl; //"https://api.taskoon.com";

  final box = GetStorage();

  // ✅ from storage
  String? userId;
  String name = "";

  bool available = false;
  String period = 'Week';
  static const String _kAvailabilityKey = 'tasker_available';
  bool _restored = false;

  // ✅ hub
  final TaskerDispatchHubService _hub = TaskerDispatchHubService();
  StreamSubscription? _hubSub;

  // ✅ watchdog
  Timer? _hubWatchdog;
  bool _hubConfigured = false;
  bool _hubEnsuring = false;
  int _attempt = 0;

  // ✅ periodic location updates
  Timer? _locationTimer;
  static const Duration _locationInterval = Duration(seconds: 5); // ✅ EXACT 5 seconds

  // popup guards
  bool _dialogOpen = false;
  String? _lastPopupBookingDetailId;

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

  String _selectedChip = 'All';
  final List<String> _chipLabels = const ['All', 'Upcoming', 'Current'];

  // Adaptive backoff: 2s,4s,8s,16s,30s...
  Duration _nextBackoff() {
    final secs = [2, 4, 8, 16, 30, 30, 30];
    final idx = (_attempt - 1).clamp(0, secs.length - 1);
    return Duration(seconds: secs[idx]);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // ✅ Read stored user info (safe)
      userId = (box.read('userId'))?.toString();
      name = (box.read("name"))?.toString() ?? "";

      final saved = box.read(_kAvailabilityKey) == true;
      setState(() {
        available = saved;
        _restored = true;
      });

      debugPrint("🟣 TaskerHome init: userId=$userId name=$name restored available=$saved");

      // ✅ Configure & connect hub (retry until userId ready)
      await _trySetupSignalR(reason: "init");

      // ✅ attach listener once
      _attachHubListener();

      // ✅ watchdog to keep connected forever
      _startHubWatchdog();

      // ✅ if online => start location timer (will ensure hub before each tick)
      if (saved) _startLocationUpdates();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.resumed) {
      debugPrint("🔁 TaskerHome resumed -> FORCE hub ensureConnected");
      _ensureHubConnectedNow(reason: "resumed");
    }
  }

  Future<void> _trySetupSignalR({required String reason}) async {
    // userId may come late
    userId ??= (box.read('userId'))?.toString();

    if (userId == null || userId!.trim().isEmpty) {
      debugPrint("⏳ TASKER HUB: userId not ready yet (reason=$reason)");
      return;
    }

    if (!_hubConfigured) {
      debugPrint("🧩 TASKER HUB: configure baseUrl=$_baseUrl userId=$userId");
      _hub.configure(baseUrl: _baseUrl, userId: userId!.trim());
      _hubConfigured = true;
      _hub.logStatus("SCREEN_CONFIG_DONE");
    }

    await _ensureHubConnectedNow(reason: reason);
  }

  /// ✅ HARD GUARANTEE CONNECT (used everywhere)
  Future<bool> _ensureHubConnectedNow({required String reason}) async {
    // keep trying to configure if userId comes late
    if (!_hubConfigured) {
      await _trySetupSignalR(reason: "ensureNow($reason)");
    }

    if (!_hubConfigured) {
      debugPrint("❌ TASKER HUB: still not configured (userId missing?) reason=$reason");
      return false;
    }

    if (_hub.isConnected) return true;
    if (_hubEnsuring) return false;

    _hubEnsuring = true;
    try {
      debugPrint("🔌 TASKER HUB: ensureConnected NOW... reason=$reason state=${_hub.state}");
      await _hub.ensureConnected();
      debugPrint("✅ TASKER HUB: connected=${_hub.isConnected} state=${_hub.state}");
      if (_hub.isConnected) _attempt = 0;
      return _hub.isConnected;
    } catch (e, st) {
      debugPrint("❌ TASKER HUB: ensureConnected exception => $e");
      debugPrint("$st");
      return false;
    } finally {
      _hubEnsuring = false;
    }
  }

  /// ✅ WATCHDOG: keeps the hub connected forever
  void _startHubWatchdog() {
    _hubWatchdog?.cancel();

    _hubWatchdog = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted) return;

      // userId may come late: keep trying to configure
      if (!_hubConfigured) {
        await _trySetupSignalR(reason: "watchdog-config");
        return;
      }

      // already connected
      if (_hub.isConnected) return;

      // don't overlap attempts
      if (_hubEnsuring) return;

      _attempt++;
      final wait = _nextBackoff();

      debugPrint("🛡️ TASKER HUB WATCHDOG: disconnected -> retry attempt=$_attempt in ${wait.inSeconds}s");

      await Future.delayed(wait);
      if (!mounted) return;

      await _ensureHubConnectedNow(reason: "watchdog");
    });
  }

  void _attachHubListener() {
    _hubSub?.cancel();

    debugPrint("🧩 TASKER HUB: attaching notifications listener...");

    _hubSub = _hub.notifications.listen(
      (payload) {
        if (!mounted) return;

        debugPrint("📩 TASKER HUB payload => $payload");

        // Popup only when online
        if (!available) {
          debugPrint("⚠️ TASKER HUB: offer received but available=false (no popup)");
          return;
        }

        final offer = TaskerBookingOffer.tryParse(payload);
        if (offer == null) {
          debugPrint("❌ TASKER HUB: offer parse FAILED (popup not shown)");
          return;
        }

        debugPrint("✅ TASKER HUB: offer parsed bookingDetailId=${offer.bookingDetailId}");
        _showBookingPopup(offer);
      },
      onError: (e) => debugPrint("❌ TASKER HUB stream error => $e"),
      onDone: () => debugPrint("⚠️ TASKER HUB stream closed"),
    );
  }

  Future<void> _onAvailabilityToggle(bool value) async {
    debugPrint("🟡 Availability toggle => $value");
    await box.write(_kAvailabilityKey, value);

    setState(() => available = value);

    // ✅ always refresh stored userId (in case it changes)
    userId ??= (box.read('userId'))?.toString();
    if (userId != null) userId = userId!.trim();

    if (!value) {
      debugPrint("🔴 TASKER OFFLINE: stop location updates");
      _stopLocationUpdates();

      // optional: if backend needs availability update
      if (userId != null && userId!.isNotEmpty) {
        context.read<UserBookingBloc>().add(ChangeAvailabilityStatus(userId: userId.toString()));
        debugPrint("✅ EVENT: ChangeAvailabilityStatus dispatched (offline)");
      }
      return;
    }

    // ✅ ONLINE: ensure hub now
    await _ensureHubConnectedNow(reason: "availability-on");

    // optional: availability update
    if (userId != null && userId!.isNotEmpty) {
      context.read<UserBookingBloc>().add(ChangeAvailabilityStatus(userId: userId.toString()));
      debugPrint("✅ EVENT: ChangeAvailabilityStatus dispatched (online)");
    }

    debugPrint("🟢 TASKER ONLINE: start location updates (every 5s)");
    _startLocationUpdates();
  }

  /// ✅ UPDATED: location tick is ASYNC and guarantees SignalR is connected
  Future<void> _dispatchLocationUpdateToApi() async {
    if (!mounted) return;

    if (!available) {
      debugPrint("⚠️ LOCATION: skipped (available=false)");
      return;
    }

    userId ??= (box.read('userId'))?.toString();
    userId = userId?.trim();

    if (userId == null || userId!.isEmpty) {
      debugPrint("❌ LOCATION: userId missing (cannot send)");
      return;
    }

    // ✅ Ensure hub is connected BEFORE sending
    final ok = await _ensureHubConnectedNow(reason: "location-tick");
    if (!ok) {
      debugPrint("⚠️ LOCATION: skipped (SignalR not connected yet)");
      return;
    }

    // TODO: replace with GPS later
    const double lat = 67.00;
    const double lng = 70.00;

    debugPrint("📍 LOCATION: sending => userId=$userId lat=$lat lng=$lng");

    context.read<UserBookingBloc>().add(
          UpdateUserLocationRequested(
            userId: userId.toString(),
            latitude: lat,
            longitude: lng,
          ),
        );

    debugPrint("✅ EVENT: UpdateUserLocationRequested dispatched");
  }

  /// ✅ EXACT 5 seconds tick when ONLINE
  void _startLocationUpdates() {
    if (!_restored) return;
    if (!available) return;

    if (_locationTimer?.isActive == true) {
      debugPrint("⏱️ LOCATION TIMER: already running");
      return;
    }

    debugPrint("⏱️ LOCATION TIMER: start interval=${_locationInterval.inSeconds}s");

    // fire instantly
    _dispatchLocationUpdateToApi();

    _locationTimer = Timer.periodic(_locationInterval, (_) async {
      if (!mounted) return;

      if (!available) {
        debugPrint("🛑 LOCATION TIMER: detected available=false -> stopping");
        _stopLocationUpdates();
        return;
      }

      debugPrint("⏱️ LOCATION TIMER TICK");
      await _dispatchLocationUpdateToApi();
    });
  }

  void _stopLocationUpdates() {
    debugPrint("🛑 LOCATION TIMER: stop");
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  void _showBookingPopup(TaskerBookingOffer offer) {
    if (!mounted) return;

    if (_dialogOpen) {
      debugPrint("⚠️ POPUP: already open, skipping booking=${offer.bookingDetailId}");
      return;
    }

    if (_lastPopupBookingDetailId == offer.bookingDetailId) {
      debugPrint("⚠️ POPUP: same booking received again, skipping booking=${offer.bookingDetailId}");
      return;
    }

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

            return StatefulBuilder(
              builder: (context, setState) {
                timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
                  if (closed) return;

                  if (secondsLeft <= 1) {
                    debugPrint("⏳ POPUP: auto-timeout booking=${offer.bookingDetailId}");
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
                                    value: offer.bookingDuration == null ? "-" : "${offer.bookingDuration} hr",
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
                                      debugPrint("🟠 POPUP: Decline pressed booking=${offer.bookingDetailId}");
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
                                      debugPrint("🟢 POPUP: Accept pressed booking=${offer.bookingDetailId} userId=$userId");
                                      context.read<UserBookingBloc>().add(
                                            AcceptBooking(
                                              userId: userId.toString(),
                                              bookingDetailId: offer.bookingDetailId,
                                            ),
                                          );
                                      debugPrint("✅ EVENT: AcceptBooking dispatched");
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
                );
              },
            );
          },
        );
      } catch (e) {
        debugPrint("❌ POPUP: showDialog exception => $e");
      } finally {
        _dialogOpen = false;
        _lastPopupBookingDetailId = null;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopLocationUpdates();
    _hubWatchdog?.cancel();
    _hubSub?.cancel();
    _hub.dispose();
    super.dispose();
  }

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
                            available
                                ? 'You’re online — offers can arrive anytime.'
                                : 'You’re offline — go available to receive offers.',
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
                text: available
                    ? 'You are online. New offers can arrive anytime.'
                    : 'You are offline. Turn on availability to receive offers.',
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
/// ✅ UI WIDGETS (unchanged from your code)
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 18,
                color: kPrimary,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Earnings',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.5,
                  color: Color(0xFF75748A),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(.08),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: kPrimary.withOpacity(.16)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.trending_up_rounded, size: 16, color: kPrimary),
                  SizedBox(width: 5),
                  Text(
                    'Live',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: kPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  "\$${amount.toString()}",
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 30,
                    color: Color(0xFF3E1E69),
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'per ${period.toLowerCase()}',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: Color(0xFF75748A),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: const [
            Expanded(
              child: _MiniLineStat(
                label: 'Completed',
                value: '12',
                icon: Icons.check_circle_outline_rounded,
                fg: Color(0xFF1E8E66),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _MiniLineStat(
                label: 'Pending',
                value: '3',
                icon: Icons.hourglass_bottom_rounded,
                fg: Color(0xFFEE8A41),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: kPrimary.withOpacity(0.15)),
            ),
            child: Wrap(
              spacing: 6,
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
        ),
      ],
    );
  }
}

class _MiniLineStat extends StatelessWidget {
  const _MiniLineStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.fg,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: fg.withOpacity(.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fg.withOpacity(.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: fg.withOpacity(.95),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? kPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: selected ? Colors.white : kPrimary,
          ),
        ),
      ),
    );
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




*/
























































/*

  final box = GetStorage();
      var userId=     box.read('userId');
                var name = box.read("name");


   const Color kPrimary = Color(0xFF5C2E91);
   const Color kTextDark = Color(0xFF3E1E69);
   const Color kMuted = Color(0xFF75748A);
   const Color kBg = Color(0xFFF8F7FB);

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

  // ✅ new fields
  final String? bookingService;
  final String? userName;
  final int? bookingDuration; 
  final DateTime? bookingTime;
  final double? distanceKm;
  final String? location;

  // existing
  final String message;
  final String? type;
  final String? date; 

  TaskerBookingOffer({
    required this.bookingDetailId,
    required this.lat,
    required this.lng,
    required this.estimatedCost,

    // new
    this.bookingService,
    this.userName,
    this.bookingDuration,
    this.bookingTime,
    this.distanceKm,
    this.location,

    // existing
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
      "Distance": distanceKm == null
          ? ""
          : "${distanceKm!.toStringAsFixed(2)} km",
      "Location": location ?? "",
      "Estimated Cost": estimatedCost == 0
          ? ""
          : "\$${estimatedCost.toStringAsFixed(2)}",
      "Duration": bookingDuration == null ? "" : "${bookingDuration} hr",

      // booking date/time separately (from bookingTime)
      "Booking Date": fmtDate(bookingTime),
      "Booking Time": fmtTime(bookingTime),

      // top-level date (if you also want it)
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

      // data can be a map or json string
      dynamic dataAny = map['data'];
      if (dataAny is String) {
        try {
          dataAny = jsonDecode(dataAny);
        } catch (_) {}
      }

      Map<String, dynamic>? data;
      if (dataAny is Map) data = Map<String, dynamic>.from(dataAny);

      // bookingDetailId (support multiple casings / old placements)
      final bookingDetailId =
          (data?['bookingDetailId'] ??
                  data?['BookingDetailId'] ??
                  map['bookingDetailId'] ??
                  map['BookingDetailId'])
              ?.toString();

      if (bookingDetailId == null || bookingDetailId.isEmpty) {
        debugPrint("❌ tryParse: bookingDetailId missing. keys=${map.keys}");
        return null;
      }

      final lat = _toDouble(
        data?['lat'] ?? data?['Lat'] ?? map['lat'] ?? map['Lat'] ?? 0,
      );
      final lng = _toDouble(
        data?['lng'] ?? data?['Lng'] ?? map['lng'] ?? map['Lng'] ?? 0,
      );

      final estimatedCost = _toDouble(
        data?['estimatedCost'] ??
            data?['EstimatedCost'] ??
            map['estimatedCost'] ??
            map['EstimatedCost'] ??
            0,
      );

      // ✅ new fields parsing
      final bookingService =
          (data?['bookingService'] ?? data?['BookingService'])?.toString();
      final userName = (data?['userName'] ?? data?['UserName'])?.toString();

      final bookingDuration = _toInt(
        data?['bookingDuration'] ?? data?['BookingDuration'],
      );

      final bookingTime = _toDateTime(
        data?['bookingTime'] ?? data?['BookingTime'],
      );

      final distanceKm = _toDoubleOrNull(
        data?['distanceKm'] ?? data?['DistanceKm'],
      );

      final location = (data?['location'] ?? data?['Location'])?.toString();

      return TaskerBookingOffer(
        bookingDetailId: bookingDetailId,
        lat: lat,
        lng: lng,
        estimatedCost: estimatedCost,

        // new
        bookingService: bookingService,
        userName: userName,
        bookingDuration: bookingDuration,
        bookingTime: bookingTime,
        distanceKm: distanceKm,
        location: location,

        // existing
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

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static DateTime? _toDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    final s = v.toString();
    return DateTime.tryParse(s);
  }
}
class TaskerDispatchHubService {
  HubConnection? _conn;

  String? _baseUrl;
  String? _userId;

  Completer<void>? _startCompleter;
  bool _handlersAttached = false;

  final _notifCtrl = StreamController<dynamic>.broadcast();
  Stream<dynamic> get notifications => _notifCtrl.stream;

  bool get isConnected =>
      _conn != null && _conn!.state == HubConnectionState.Connected;

  HubConnectionState? get state => _conn?.state;

  // ✅ ADDED: logs only (no functional change)
  void logStatus([String tag = "STATUS"]) {
    debugPrint(
      "🟣 HUB($tag): connected=$isConnected state=${_conn?.state} "
      "baseUrl=${_baseUrl ?? '-'} userId=${(_userId?.isNotEmpty == true) ? _userId : '-'}",
    );
  }

  void configure({required String baseUrl, required String userId}) {
    final changed = (_baseUrl != baseUrl) || (_userId != userId);
    _baseUrl = baseUrl;
    _userId = userId;

    // ✅ ADDED: log only
    logStatus("CONFIG");

    if (changed) {
      debugPrint("🧩 HUB(SVC): config changed -> rebuilding");
      _handlersAttached = false;
      _disposeConnectionOnly();
    }
  }

  Future<void> ensureConnected() async {
    if (_baseUrl == null || _userId == null || _userId!.isEmpty) {
      throw Exception("HUB(SVC): configure(baseUrl,userId) first");
    }

    // ✅ ADDED: log only
    logStatus("ENSURE_ENTER");

    if (isConnected) {
      // ✅ ADDED: log only
      logStatus("ENSURE_ALREADY_CONNECTED");
      return;
    }

    // If already starting, wait
    if (_startCompleter != null) {
      // ✅ ADDED: log only
      logStatus("ENSURE_WAIT_EXISTING_START");
      await _startCompleter!.future;
      // ✅ ADDED: log only
      logStatus("ENSURE_AFTER_WAIT");
      return;
    }

    _startCompleter = Completer<void>();
    try {
      await _startInternal();
    } finally {
      _startCompleter?.complete();
      _startCompleter = null;

      // ✅ ADDED: log only
      logStatus("ENSURE_EXIT");
    }
  }

  Future<void> _startInternal() async {
    final baseUrl = _baseUrl!;
    final userId = _userId!;
    final url = "$baseUrl/hubs/dispatch?userId=$userId";

    try {
      if (_conn == null) {
        debugPrint("🧩 HUB(SVC): building connection...");
      }

      _conn ??= HubConnectionBuilder()
          .withUrl(
            url,
            options: HttpConnectionOptions(
              // ✅ same as your code (NO change)
              transport: HttpTransportType.LongPolling,
              // accessTokenFactory: () async => "token",
            ),
          )
          .withAutomaticReconnect()
          .build();

      _wireLifecycle(_conn!);

      if (!_handlersAttached) {
        _registerHandlers(_conn!);
        _handlersAttached = true;

        // ✅ ADDED: log only
        debugPrint("🧩 HUB(SVC): handlers attached");
      }

      debugPrint(
        "🔌 HUB(SVC): start... url=$url state(before)=${_conn!.state}",
      );

      // ✅ ADDED: log only
      logStatus("START_BEFORE_STOP_CHECK");

      // Reset if in weird state
      if (_conn!.state != HubConnectionState.Disconnected) {
        try {
          debugPrint("🧩 HUB(SVC): not Disconnected -> stopping first...");
          await _conn!.stop();
          debugPrint("🧩 HUB(SVC): stop done.");
        } catch (e) {
          debugPrint("⚠️ HUB(SVC): stop failed (ignored) => $e");
        }
      }

      // ✅ ADDED: log only
      logStatus("START_BEFORE_START");

      await _conn!.start();

      debugPrint("✅ HUB(SVC): start done. state(after)=${_conn!.state}");

      // ✅ ADDED: log only
      logStatus("START_AFTER_START");

      if (_conn!.state != HubConnectionState.Connected) {
        // ✅ ADDED: log only
        logStatus("START_BAD_STATE");
        throw Exception("HUB(SVC): start finished but state=${_conn!.state}");
      }

      // ✅ ADDED: log only
      debugPrint("✅ HUB(SVC): CONNECTED ✅ (LongPolling)");
      logStatus("CONNECTED_FINAL");
    } catch (e) {
      // ✅ ADDED: log only
      debugPrint("❌ HUB(SVC): start failed => $e");
      logStatus("START_FAIL");

      _handlersAttached = false;
      _disposeConnectionOnly();
      rethrow;
    }
  }

  void _wireLifecycle(HubConnection c) {
    // NOTE: your original had onclose / onreconnecting / onreconnected
    // ✅ only logs added here

    c.onclose(({error}) {
      debugPrint("🛑 HUB(SVC): onClose error=$error state=${c.state}");
      logStatus("ONCLOSE");
    });

    c.onreconnecting(({error}) {
      debugPrint("🔄 HUB(SVC): onReconnecting error=$error state=${c.state}");
      logStatus("RECONNECTING");
    });

    c.onreconnected(({connectionId}) {
      debugPrint("✅ HUB(SVC): onReconnected id=$connectionId state=${c.state}");
      logStatus("RECONNECTED");
    });
  }

  void _registerHandlers(HubConnection c) {
    // Prevent duplicate
    c.off("ReceiveBookingOffer");
    c.off("ReceiveNotification");

    // ✅ ADDED: log only
    debugPrint("🧩 HUB(SVC): registering handlers: ReceiveBookingOffer, ReceiveNotification");

    c.on("ReceiveBookingOffer", (args) {
      final payload = _normalizeArgs(args);
      if (payload == null) return;
      debugPrint("📩 HUB(SVC): ReceiveBookingOffer => $payload");
      _notifCtrl.add(payload);
    });

    c.on("ReceiveNotification", (args) {
      final payload = _normalizeArgs(args);
      if (payload == null) return;
      debugPrint("📩 HUB(SVC): ReceiveNotification => $payload");
      _notifCtrl.add(payload);
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
    // ✅ ADDED: log only
    logStatus("DISPOSE_CONN_ONLY_BEGIN");

    try {
      _conn?.stop();
    } catch (e) {
      debugPrint("⚠️ HUB(SVC): stop() failed in disposeConnectionOnly => $e");
    }
    _conn = null;

    // ✅ ADDED: log only
    logStatus("DISPOSE_CONN_ONLY_END");
  }

  Future<void> dispose() async {
    // ✅ ADDED: log only
    logStatus("DISPOSE_BEGIN");

    _disposeConnectionOnly();
    await _notifCtrl.close();

    // ✅ ADDED: log only
    debugPrint("🧩 HUB(SVC): stream closed");
    logStatus("DISPOSE_END");
  }
}

/*
class TaskerDispatchHubService {
  HubConnection? _conn;

  String? _baseUrl;
  String? _userId;

  Completer<void>? _startCompleter;
  bool _handlersAttached = false;

  final _notifCtrl = StreamController<dynamic>.broadcast();
  Stream<dynamic> get notifications => _notifCtrl.stream;

  bool get isConnected =>
      _conn != null && _conn!.state == HubConnectionState.Connected;

  HubConnectionState? get state => _conn?.state;

  void configure({required String baseUrl, required String userId}) {
    final changed = (_baseUrl != baseUrl) || (_userId != userId);
    _baseUrl = baseUrl;
    _userId = userId;

    if (changed) {
      debugPrint("🧩 HUB(SVC): config changed -> rebuilding");
      _handlersAttached = false;
      _disposeConnectionOnly();
    }
  }

  Future<void> ensureConnected() async {
    if (_baseUrl == null || _userId == null || _userId!.isEmpty) {
      throw Exception("HUB(SVC): configure(baseUrl,userId) first");
    }

    if (isConnected) return;

    // If already starting, wait
    if (_startCompleter != null) {
      await _startCompleter!.future;
      return;
    }

    _startCompleter = Completer<void>();
    try {
      await _startInternal();
    } finally {
      _startCompleter?.complete();
      _startCompleter = null;
    }
  }

  Future<void> _startInternal() async {
    final baseUrl = _baseUrl!;
    final userId = _userId!;
    final url = "$baseUrl/hubs/dispatch?userId=$userId";

    try {
      _conn ??= HubConnectionBuilder()
          .withUrl(
            url,
            options: HttpConnectionOptions(
              // ✅ Mobile stable
              transport: HttpTransportType.LongPolling,
              // If your server needs headers/token, add here
              // accessTokenFactory: () async => "token",
            ),
          )
          .withAutomaticReconnect()
          .build();

      _wireLifecycle(_conn!);

      if (!_handlersAttached) {
        _registerHandlers(_conn!);
        _handlersAttached = true;
      }

      debugPrint(
        "🔌 HUB(SVC): start... url=$url state(before)=${_conn!.state}",
      );

      // Reset if in weird state
      if (_conn!.state != HubConnectionState.Disconnected) {
        try {
          await _conn!.stop();
        } catch (_) {}
      }

      await _conn!.start();

      debugPrint("✅ HUB(SVC): start done. state(after)=${_conn!.state}");

      if (_conn!.state != HubConnectionState.Connected) {
        throw Exception("HUB(SVC): start finished but state=${_conn!.state}");
      }
    } catch (e) {
      debugPrint("❌ HUB(SVC): start failed => $e");
      _handlersAttached = false;
      _disposeConnectionOnly();
      rethrow;
    }
  }

  void _wireLifecycle(HubConnection c) {
    c.onclose(({error}) {
      debugPrint("🛑 HUB(SVC): onClose error=$error state=${c.state}");
    });

    c.onreconnecting(({error}) {
      debugPrint("🔄 HUB(SVC): onReconnecting error=$error state=${c.state}");
    });

    c.onreconnected(({connectionId}) {
      debugPrint("✅ HUB(SVC): onReconnected id=$connectionId state=${c.state}");
    });
  }

  void _registerHandlers(HubConnection c) {
    // Prevent duplicate
    c.off("ReceiveBookingOffer");
    c.off("ReceiveNotification");

    c.on("ReceiveBookingOffer", (args) {
      final payload = _normalizeArgs(args);
      if (payload == null) return;
      debugPrint("📩 HUB(SVC): ReceiveBookingOffer => $payload");
      _notifCtrl.add(payload);
    });

    c.on("ReceiveNotification", (args) {
      final payload = _normalizeArgs(args);
      if (payload == null) return;
      debugPrint("📩 HUB(SVC): ReceiveNotification => $payload");
      _notifCtrl.add(payload);
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
}*/

/// ===============================================================
/// ✅ SCREEN (OLD UI kept, SignalR separate)
/// ===============================================================
class TaskerHomeRedesign extends StatefulWidget {
  const TaskerHomeRedesign({super.key});

  @override
  State<TaskerHomeRedesign> createState() => _TaskerHomeRedesignState();
}

class _TaskerHomeRedesignState extends State<TaskerHomeRedesign>
    with WidgetsBindingObserver {
  // theme tokens
  // static const Color kPrimary = Color(0xFF5C2E91);
  // static const Color kTextDark = Color(0xFF3E1E69);
  // static const Color kMuted = Color(0xFF75748A);
  // static const Color kBg = Color(0xFFF8F7FB);

  static const String _baseUrl =
      "https://api.taskoon.com"; //"http://192.3.3.187:85";

  bool available = false;
  String period = 'Week';
  final box = GetStorage();
  static const String _kAvailabilityKey = 'tasker_available';
  bool _restored = false;

  // ✅ separate hub
  final TaskerDispatchHubService _hub = TaskerDispatchHubService();
  StreamSubscription? _hubSub;

  // ✅ watchdog
  Timer? _hubWatchdog;
  bool _hubConfigured = false;
  bool _hubEnsuring = false;
  int _attempt = 0;

  // Adaptive backoff: 2s,4s,8s,16s,30s...
  Duration _nextBackoff() {
    final secs = [2, 4, 8, 16, 30, 30, 30];
    final idx = (_attempt - 1).clamp(0, secs.length - 1);
    return Duration(seconds: secs[idx]);
  }

  // ✅ periodic location updates
  Timer? _locationTimer;
  static const Duration _locationInterval = Duration(seconds: 5);

  // popup guards
  bool _dialogOpen = false;
  String? _lastPopupBookingDetailId;

  // mock data (UI unchanged)
  final _avatarUrl =
      'https://images.unsplash.com/photo-1607746882042-944635dfe10e?q=80&w=256&auto=format&fit=crop';
 // final _title = '${context.read()}';

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

  String _selectedChip = 'All';
  final List<String> _chipLabels = const ['All', 'Upcoming', 'Current'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final saved = box.read(_kAvailabilityKey) == true;
      setState(() {
        available = saved;
        _restored = true;
      });

      debugPrint("🟣 TaskerHome init: restored available=$saved");

      // ✅ Configure & connect hub (retry until userId ready)
      await _trySetupSignalR(reason: "init");

      // ✅ attach listener once (kept)
      _attachHubListener();

      // ✅ watchdog to keep connected forever
      _startHubWatchdog();

      if (saved) _startLocationUpdates();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint("🔁 TaskerHome resumed -> ensure hub connected");
      _safeEnsureHubConnected(reason: "resumed");
    }
  }

  Future<void> _trySetupSignalR({required String reason}) async {


    if (userId == null || userId.isEmpty) {
      debugPrint("⏳ TASKER HUB: userId not ready yet (reason=$reason)");
      return;
    }

    if (!_hubConfigured) {
        debugPrint("🧩 TASKER HUB: configure baseUrl=$_baseUrl userId=$userId");
  _hub.configure(baseUrl: _baseUrl, userId: userId);
  _hubConfigured = true;

  // ✅ ADDED: log only
  _hub.logStatus("SCREEN_CONFIG_DONE");
    }

    await _safeEnsureHubConnected(reason: reason);
  }

  Future<void> _safeEnsureHubConnected({required String reason}) async {
    if (!_hubConfigured) {
      await _trySetupSignalR(reason: "ensure($reason)");
      return;
    }

    if (_hubEnsuring) return;
    if (_hub.isConnected) return;

    _hubEnsuring = true;
    try {
      debugPrint(
        "🔌 TASKER HUB: ensureConnected... reason=$reason isConnected(before)=${_hub.isConnected} state=${_hub.state}",
      );

      await _hub.ensureConnected();

// ✅ ADDED: log only
_hub.logStatus("SCREEN_ENSURE_DONE");

      // await _hub.ensureConnected();

      debugPrint(
        "✅ TASKER HUB: ensureConnected done. isConnected=${_hub.isConnected} state=${_hub.state}",
      );

      if (_hub.isConnected) _attempt = 0;
    } catch (e) {
      debugPrint("❌ TASKER HUB: ensureConnected failed => $e");
    } finally {
      _hubEnsuring = false;
    }
  }

  void _startHubWatchdog() {
  _hubWatchdog?.cancel();

  _hubWatchdog = Timer.periodic(const Duration(seconds: 3), (_) async {
    if (!mounted) return;

    // userId may come late: keep trying to configure
    if (!_hubConfigured) {
      await _trySetupSignalR(reason: "watchdog-config");
      return;
    }

    // already connected
    if (_hub.isConnected) return;

    // don't overlap attempts
    if (_hubEnsuring) return;

    _attempt++;
    final wait = _nextBackoff();

    debugPrint("🛡️ TASKER HUB WATCHDOG: disconnected -> retry attempt=$_attempt in ${wait.inSeconds}s");

    // wait the backoff then try once
    await Future.delayed(wait);
    if (!mounted) return;

    await _ensureHubConnectedNow(reason: "watchdog");
  });
}




/*  void _startHubWatchdog() {
    _hubWatchdog?.cancel();

    // Lightweight tick that schedules reconnect attempts with backoff.
    _hubWatchdog = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted) return;

      // userId might come late — keep trying
      if (!_hubConfigured) {
        await _trySetupSignalR(reason: "watchdog-config");
        return;
      }

      if (_hub.isConnected) return;
      if (_hubEnsuring) return;

      _attempt++;
      final wait = _nextBackoff();

      debugPrint(
        "🛡️ TASKER HUB WATCHDOG: disconnected -> reconnecting attempt=$_attempt in ${wait.inSeconds}s",
      );

      // Delay per backoff before attempting (so you don't spam the server)
      await Future.delayed(wait);
      if (!mounted) return;

      await _safeEnsureHubConnected(reason: "watchdog");
    });
  }*/

  void _attachHubListener() {
    _hubSub?.cancel();

    debugPrint("🧩 TASKER HUB: attaching notifications listener...");

    _hubSub = _hub.notifications.listen(
      (payload) {
        if (!mounted) return;

        debugPrint("📩 TASKER HUB payload => $payload");

        // Popup only when online (same as before)
        if (!available) {
          debugPrint(
            "⚠️ TASKER HUB: offer received but available=false (no popup)",
          );
          return;
        }

        final offer = TaskerBookingOffer.tryParse(payload);
        if (offer == null) {
          debugPrint("❌ TASKER HUB: offer parse FAILED (popup not shown)");
          return;
        }

        debugPrint(
          "✅ TASKER HUB: offer parsed bookingDetailId=${offer.bookingDetailId}",
        );
        _showBookingPopup(offer);
      },
      onError: (e) => debugPrint("❌ TASKER HUB stream error => $e"),
      onDone: () => debugPrint("⚠️ TASKER HUB stream closed"),
    );
  }

  Future<void> _onAvailabilityToggle(bool value) async {
  debugPrint("🟡 Availability toggle => $value");
  await box.write(_kAvailabilityKey, value);

  setState(() => available = value);

  if (!value) {
    debugPrint("🔴 TASKER OFFLINE: stop location updates");
    _stopLocationUpdates();

    // ✅ Call once when going offline (optional if your backend needs it)
    if (userId != null) {
      context.read<UserBookingBloc>().add(
        ChangeAvailabilityStatus(userId: userId),
      );
      debugPrint("✅ EVENT: ChangeAvailabilityStatus dispatched (offline)");
    }
    return;
  }

  // ✅ Ensure hub immediately too
  await _safeEnsureHubConnected(reason: "availability-on");

  // ✅ Call once when going online (optional if your backend needs it)
  if (userId != null) {
    context.read<UserBookingBloc>().add(
      ChangeAvailabilityStatus(userId: userId),
    );
    debugPrint("✅ EVENT: ChangeAvailabilityStatus dispatched (online)");
  }

  debugPrint("🟢 TASKER ONLINE: start location updates (every 5s)");
  _startLocationUpdates();
}


 /* Future<void> _onAvailabilityToggle(bool value) async {
    debugPrint("🟡 Availability toggle => $value");
    await box.write(_kAvailabilityKey, value);

    if (!value) {
      setState(() => available = false);
      debugPrint("🔴 TASKER OFFLINE: stop location updates");
      _stopLocationUpdates();
      return;
    }

    setState(() => available = true);

    // Ensure hub immediately too
    await _safeEnsureHubConnected(reason: "availability-on");

    debugPrint("🟢 TASKER ONLINE: start location updates (every 5s)");
    _startLocationUpdates();
  }*/

  void _dispatchLocationUpdateToApi() {
  if (!mounted) return;

  if (!available) {
    debugPrint("⚠️ LOCATION: skipped (available=false)");
    return;
  }

  if (userId == null || userId.toString().isEmpty) {
    debugPrint("❌ LOCATION: user id missing (cannot send)");
    return;
  }

  // TODO: replace with GPS values later
  const double lat = 67.00;
  const double lng = 70.00;

  debugPrint("📍 LOCATION: sending => userId=$userId lat=$lat lng=$lng");

  context.read<UserBookingBloc>().add(
    UpdateUserLocationRequested(
      userId: userId,
      latitude: lat,
      longitude: lng,
    ),
  );

  debugPrint("✅ EVENT: UpdateUserLocationRequested dispatched");
}



 /* void _dispatchLocationUpdateToApi() {
    if (!mounted) return;

    if (!available) {
      debugPrint("⚠️ LOCATION: skipped (available=false)");
      return;
    }

 

    if (userId == null) {
      debugPrint("❌ LOCATION: user id missing (cannot send)");
      return;
    }



    // TODO replace with GPS later
    const double lat = 67.00;
    const double lng = 70.00;

    debugPrint("📍 LOCATION: sending => userId=$userId lat=$lat lng=$lng");

    context.read<UserBookingBloc>().add(
      UpdateUserLocationRequested(
        userId: userId,
        latitude: lat,
        longitude: lng,
      ),
    );
    debugPrint("✅ EVENT: UpdateUserLocationRequested dispatched");

    context.read<UserBookingBloc>().add(
      ChangeAvailabilityStatus(userId: userId),
    );
    debugPrint("✅ EVENT: ChangeAvailabilityStatus dispatched");
  }*/

void _startLocationUpdates() {
  if (!_restored) return;
  if (!available) return;

  // ✅ prevent duplicate timers
  if (_locationTimer?.isActive == true) {
    debugPrint("⏱️ LOCATION TIMER: already running");
    return;
  }

  debugPrint("⏱️ LOCATION TIMER: start interval=${_locationInterval.inSeconds}s");

  // fire instantly
  _dispatchLocationUpdateToApi();

  _locationTimer = Timer.periodic(_locationInterval, (_) {
    if (!mounted) return;

    // ✅ if user toggled OFF while timer is running, stop immediately
    if (!available) {
      debugPrint("🛑 LOCATION TIMER: detected available=false -> stopping");
      _stopLocationUpdates();
      return;
    }

    debugPrint("⏱️ LOCATION TIMER TICK");
    _dispatchLocationUpdateToApi();
  });
}
void _stopLocationUpdates() {
  debugPrint("🛑 LOCATION TIMER: stop");
  _locationTimer?.cancel();
  _locationTimer = null;
}
Future<bool> _ensureHubConnectedNow({required String reason}) async {
  // keep trying to configure if userId comes late
  if (!_hubConfigured) {
    await _trySetupSignalR(reason: "ensureNow($reason)");
  }

  if (!_hubConfigured) {
    debugPrint("❌ TASKER HUB: still not configured (userId missing?) reason=$reason");
    return false;
  }

  if (_hub.isConnected) return true;
  if (_hubEnsuring) return false;

  _hubEnsuring = true;
  try {
    debugPrint("🔌 TASKER HUB: ensureConnected NOW... reason=$reason state=${_hub.state}");
    await _hub.ensureConnected();
    debugPrint("✅ TASKER HUB: connected=${_hub.isConnected} state=${_hub.state}");
    if (_hub.isConnected) _attempt = 0;
    return _hub.isConnected;
  } catch (e, st) {
    debugPrint("❌ TASKER HUB: ensureConnected exception => $e");
    debugPrint("$st");
    return false;
  } finally {
    _hubEnsuring = false;
  }
}






  // void _stopLocationUpdates() {
  //   debugPrint("🛑 LOCATION TIMER: stop");
  //   _locationTimer?.cancel();
  //   _locationTimer = null;
  // }

  

  void _showBookingPopup(TaskerBookingOffer offer) {
    if (!mounted) return;

    if (_dialogOpen) {
      debugPrint(
        "⚠️ POPUP: already open, skipping booking=${offer.bookingDetailId}",
      );
      return;
    }

    if (_lastPopupBookingDetailId == offer.bookingDetailId) {
      debugPrint(
        "⚠️ POPUP: same booking received again, skipping booking=${offer.bookingDetailId}",
      );
      return;
    }

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

            String mmss(int s) =>
                '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
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
                    debugPrint(
                      "⏳ POPUP: auto-timeout booking=${offer.bookingDetailId}",
                    );
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
                                const Icon(
                                  Icons.close_rounded,
                                  color: Colors.transparent,
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Progress
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

                            // Message (full)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: kPrimary.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: kPrimary.withOpacity(0.12),
                                ),
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

                            infoTile(
                              icon: Icons.home_repair_service_rounded,
                              label: "Service",
                              value: offer.bookingService ?? "-",
                            ),
                            const SizedBox(height: 10),
                            infoTile(
                              icon: Icons.attach_money_rounded,
                              label: "Estimated Cost",
                              value:
                                  "\$${offer.estimatedCost.toStringAsFixed(2)}",
                            ),

                            const SizedBox(height: 10),

                            // Booking Date + Booking Time (separate)
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
                                    value: offer.distanceKm == null
                                        ? "-"
                                        : "${offer.distanceKm!.toStringAsFixed(2)} km",
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: infoTile(
                                    icon: Icons.timelapse_rounded,
                                    label: "Duration",
                                    value: offer.bookingDuration == null
                                        ? "-"
                                        : "${offer.bookingDuration} hr",
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Location (full width)
                            infoTile(
                              icon: Icons.location_on_rounded,
                              label: "Location",
                              value: offer.location ?? "-",
                            ),

                            const SizedBox(height: 14),

                            // Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      debugPrint(
                                        "🟠 POPUP: Decline pressed booking=${offer.bookingDetailId}",
                                      );
                                      closeDialog();
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: kPrimary,
                                      side: BorderSide(
                                        color: kPrimary.withOpacity(0.35),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
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
                                
                                     

                                      debugPrint(
                                        "🟢 POPUP: Accept pressed booking=${offer.bookingDetailId} userId=$userId",
                                      );

                                      context.read<UserBookingBloc>().add(
                                        AcceptBooking(
                                          userId: userId,
                                          bookingDetailId:
                                              offer.bookingDetailId,
                                        ),
                                      );

                                      debugPrint(
                                        "✅ EVENT: AcceptBooking dispatched",
                                      );
                                      closeDialog();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kPrimary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
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
      } catch (e) {
        debugPrint("❌ POPUP: showDialog exception => $e");
      } finally {
        _dialogOpen = false;
        _lastPopupBookingDetailId = null;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopLocationUpdates();
    _hubWatchdog?.cancel();
    _hubSub?.cancel();
    _hub.dispose();
    super.dispose();
  }

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
        ),//Testing@123
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
            // ✅ Modern hero card (UI only)
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
                          available
                              ? 'You’re online — offers can arrive anytime.'
                              : 'You’re offline — go available to receive offers.',
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
              icon: available
                  ? Icons.wifi_tethering_rounded
                  : Icons.wifi_off_rounded,
              text: available
                  ? 'You are online. New offers can arrive anytime.'
                  : 'You are offline. Turn on availability to receive offers.',
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
                    _selectedChip == 'All'
                        ? 'Recent activity'
                        : '$_selectedChip tasks',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14.5,
                      color: kTextDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (filteredTasks.isEmpty)
                    const _EmptyState(
                      text: 'No tasks yet. Turn on availability to get offers.',
                    )
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
          // const Text(
          //   'Tasker',
          //   style: TextStyle(
          //     fontFamily: 'Poppins',
          //     fontSize: 12,
          //     color: Color(0xFF75748A),
          //     fontWeight: FontWeight.w700,
          //   ),
          // ),
          // const SizedBox(height: 10),

          Row(
            children: [
              _AvatarRing(url: 'https://images.unsplash.com/photo-1607746882042-944635dfe10e?q=80&w=256&auto=format&fit=crop'),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
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
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ✅ More compact & responsive row (no overflow)
          const Row(
            children: [
              // Expanded(
              //   child: _MiniInfoChip(
              //     icon: Icons.star_rounded,
              //     label: 'Rating',
              //     value: '4.9',
              //     bg: Color(0xFFFFF4E8),
              //     fg: Color(0xFFEE8A41),
              //   ),
              // ),

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

          const SizedBox(height: 10),

          // const _VerificationRow(
          //   items: [
          //     VerificationItem(
          //       label: 'ID Verified',
          //       icon: Icons.badge_outlined,
          //       bg: Color(0xFFEFF8F4),
          //       fg: Color(0xFF1E8E66),
          //     ),
          //     VerificationItem(
          //       label: 'Police Verified',
          //       icon: Icons.verified_user_outlined,
          //       bg: Color(0xFFF3EEFF),
          //       fg: Color(0xFF5C2E91),
          //     ),
              
          //   ],
          // ),
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

class _MiniInfoChip extends StatelessWidget {
  const _MiniInfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.bg,
    required this.fg,
    this.fullWidth = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color bg;
  final Color fg;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: fg.withOpacity(.16)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: fg.withOpacity(.92),
              ),
            ),
          ),
          const SizedBox(width: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: fg,
              ),
            ),
          ),
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
                border: Border.all(
                  color: sel ? kPrimary : kPrimary.withOpacity(.22),
                ),
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
        // 2 columns on small screens, 3 columns on larger
        final cols = c.maxWidth >= 520 ? 3 : 2;
        final gap = 10.0;
        final itemW = (c.maxWidth - (gap * (cols - 1))) / cols;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: itemW,
              child: _KpiTile(
                icon: Icons.star_rate_rounded,
                title: rating.toStringAsFixed(1),
                sub: '$reviews reviews',
              ),
            ),
            SizedBox(
              width: itemW,
              child: _KpiTile(
                icon: Icons.bolt_rounded,
                title: '$acceptance%',
                sub: 'acceptance',
              ),
            ),
            SizedBox(
              width: itemW,
              child: _KpiTile(
                icon: Icons.check_circle_rounded,
                title: '$completion%',
                sub: 'completion',
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

/// Your _EarningsCard stays same functionality.
/// Only UI tweaks inside to avoid overflow & look modern.
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 18,
                color: kPrimary,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Earnings',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.5,
                  color: Color(0xFF75748A),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(.08),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: kPrimary.withOpacity(.16)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.trending_up_rounded, size: 16, color: kPrimary),
                  SizedBox(width: 5),
                  Text(
                    'Live',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: kPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Amount
        Row(
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  "\$${amount.toString()}",
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 30,
                    color: Color(0xFF3E1E69),
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        Text(
          'per ${period.toLowerCase()}',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: Color(0xFF75748A),
            fontWeight: FontWeight.w600,
          ),
        ),

   const SizedBox(height: 12),

Row(
  children: const [
    Expanded(
      child: _MiniLineStat(
        label: 'Completed',
        value: '12',
        icon: Icons.check_circle_outline_rounded,
        fg: Color(0xFF1E8E66),
      ),
    ),
    SizedBox(width: 10),
    Expanded(
      child: _MiniLineStat(
        label: 'Pending',
        value: '3',
        icon: Icons.hourglass_bottom_rounded,
        fg: Color(0xFFEE8A41),
      ),
    ),
  ],
),


        const SizedBox(height: 12),

        // Period pills (overflow-safe)
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: kPrimary.withOpacity(0.15)),
            ),
            child: Wrap(
              spacing: 6,
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
        ),
      ],
    );
  }
}

class _MiniLineStat extends StatelessWidget {
  const _MiniLineStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.fg,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: fg.withOpacity(.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fg.withOpacity(.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
          Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: fg.withOpacity(.95),
              ),
            ),
          
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? kPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: selected ? Colors.white : kPrimary,
          ),
        ),
      ),
    );
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
}*/