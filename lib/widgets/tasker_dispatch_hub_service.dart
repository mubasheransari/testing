import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:taskoon/widgets/notification_service.dart';


/// ===============================
/// ✅ Offer Model
/// ===============================
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
      return "${d.year.toString().padLeft(4, '0')}-"
          "${d.month.toString().padLeft(2, '0')}-"
          "${d.day.toString().padLeft(2, '0')}";
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

      dynamic dataAny = map['data'] ?? map;
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

      final bookingDuration = _toDoubleOrNull(data?['bookingDuration'] ?? data?['BookingDuration'] ?? map['bookingDuration']);
      final bookingTime = _toDateTime(data?['bookingTime'] ?? data?['BookingTime'] ?? map['bookingTime']);
      final distanceKm = _toDoubleOrNull(data?['distanceKm'] ?? data?['DistanceKm'] ?? map['distanceKm']);
      final location = (data?['location'] ?? data?['Location'] ?? map['location'])?.toString();

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
        message: (map['message'] ?? data?['message'] ?? '').toString(),
        type: (map['type'] ?? data?['type'])?.toString(),
        date: (map['date'] ?? data?['date'])?.toString(),
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

/// ===============================
/// ✅ SignalR Service (Separate File)
/// ===============================
class TaskerDispatchHubService {
  HubConnection? _conn;
  String? _baseUrl;
  String? _userId;

  Completer<void>? _startCompleter;
  bool _handlersAttached = false;

  Timer? _watchdog;

  final _notifCtrl = StreamController<dynamic>.broadcast();
  Stream<dynamic> get notifications => _notifCtrl.stream;

  bool get isConnected {
    final s = _conn?.state;
    // package versions differ: Connected vs connected
    return s == HubConnectionState.Connected || s == HubConnectionState.Connected;
  }

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
      _disposeConnectionOnly(); // best-effort
    }
  }

  /// ✅ Call this once to keep SignalR connected while app is running
  void startWatchdog({Duration interval = const Duration(seconds: 4)}) {
    _watchdog?.cancel();
    _watchdog = Timer.periodic(interval, (_) async {
      if (_baseUrl == null || _userId == null || _userId!.isEmpty) return;
      if (isConnected) return;
      if (_startCompleter != null) return;

      debugPrint("🛡️ HUB(WATCHDOG): disconnected -> ensureConnected()");
      try {
        await ensureConnected();
      } catch (e) {
        debugPrint("⚠️ HUB(WATCHDOG): ensureConnected failed => $e");
      }
    });
  }

  Future<void> ensureConnected() async {
    if (_baseUrl == null || _userId == null || _userId!.isEmpty) {
      throw Exception("HUB(SVC): configure(baseUrl,userId) first");
    }

    if (isConnected) return;

    if (_startCompleter != null) {
      await _startCompleter!.future;
      return;
    }

    _startCompleter = Completer<void>();
    try {
      await _startInternal();
      _startCompleter?.complete();
    } catch (e) {
      if (!(_startCompleter?.isCompleted ?? true)) {
        _startCompleter?.completeError(e);
      }
      rethrow;
    } finally {
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
              transport: HttpTransportType.LongPolling,
              // later you can switch to websockets if server supports:
              // transport: HttpTransportType.WebSockets,
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

      // Always stop cleanly before restart
      if (_conn!.state != HubConnectionState.Disconnected &&
          _conn!.state != HubConnectionState.Disconnected) {
        try {
          await _conn!.stop();
        } catch (_) {}
      }

      await _conn!.start();

      debugPrint("✅ HUB(SVC): start done. state(after)=${_conn!.state}");

      if (!isConnected) {
        throw Exception("HUB(SVC): start finished but state=${_conn!.state}");
      }

      debugPrint("✅ HUB(SVC): CONNECTED ✅");
    } catch (e) {
      debugPrint("❌ HUB(SVC): start failed => $e");
      _handlersAttached = false;
      await _disposeConnectionOnlyAsync();
      rethrow;
    }
  }

  void _wireLifecycle(HubConnection c) {
    // ✅ Correct callback types for signalr_netcore
    c.onclose(({Exception? error}) {
      debugPrint("🛑 HUB(SVC): onClose error=$error state=${c.state}");
    });

    c.onreconnecting(({Exception? error}) {
      debugPrint("🔄 HUB(SVC): onReconnecting error=$error state=${c.state}");
    });

    c.onreconnected(({String? connectionId}) {
      debugPrint("✅ HUB(SVC): onReconnected id=$connectionId state=${c.state}");
    });
  }

  void _registerHandlers(HubConnection c) {
    c.off("ReceiveBookingOffer");
    c.off("ReceiveNotification");

    debugPrint("🧩 HUB(SVC): registering handlers: ReceiveBookingOffer, ReceiveNotification");

    c.on("ReceiveBookingOffer", (args) async {
      final payload = _normalizeArgs(args);
      if (payload == null) return;

      debugPrint("📩 HUB(SVC): ReceiveBookingOffer => $payload");
      _notifCtrl.add(payload);

      // ✅ Foreground system notification (local)
      try {
  await NotificationService.I.show(
  title: "New booking offer",
  body: (payload is Map && payload['message'] != null)
      ? payload['message'].toString()
      : "A new booking offer is available.",
);

      } catch (e) {
        debugPrint("⚠️ HUB(SVC): local notif failed => $e");
      }
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

    // sometimes server sends [ {..} ]
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
      _conn?.stop(); // best-effort (non-awaited)
    } catch (_) {}
    _conn = null;
  }

  Future<void> _disposeConnectionOnlyAsync() async {
    try {
      if (_conn != null) {
        await _conn!.stop();
      }
    } catch (_) {}
    _conn = null;
  }

  Future<void> dispose() async {
    _watchdog?.cancel();
    _watchdog = null;

    await _disposeConnectionOnlyAsync();
    await _notifCtrl.close();
  }
}
