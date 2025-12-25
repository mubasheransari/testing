import 'dart:async';
import 'dart:convert';

import 'package:signalr_netcore/signalr_client.dart';

/// ===============================================================
/// ✅ ALWAYS CONNECTED DISPATCH HUB (Singleton, signalr_netcore)
/// ===============================================================
class DispatchHubSingleton {
  DispatchHubSingleton._();
  static final DispatchHubSingleton instance = DispatchHubSingleton._();

  HubConnection? _conn;

  String? _baseUrl;
  String? _userId;

  bool _starting = false;
  bool _disposed = false;

  Timer? _watchdog;

  // Broadcast streams so MANY screens can listen without creating hub again
  final _notificationCtrl = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get notifications => _notificationCtrl.stream;

  final _rawCtrl = StreamController<dynamic>.broadcast();
  Stream<dynamic> get rawNotifications => _rawCtrl.stream;

  HubConnectionState? get state => _conn?.state;
  bool get isConnected => _conn?.state == HubConnectionState.Connected;

  String get hubUrl {
    final clean = (_baseUrl ?? '').endsWith('/')
        ? (_baseUrl!).substring(0, _baseUrl!.length - 1)
        : (_baseUrl ?? '');
    return "$clean/hubs/dispatch?userId=${_userId ?? ''}";
  }

  /// Call once after login/userDetails loaded
  void configure({
    required String baseUrl,
    required String userId,
  }) {
    final changed = (_baseUrl != baseUrl) || (_userId != userId);
    _baseUrl = baseUrl;
    _userId = userId;

    // If user changes, reset connection so next ensureConnected connects fresh
    if (changed) {
      _hardReset();
    }
  }

  /// Safe to call multiple times. It will NOT create multiple connections.
  Future<void> ensureConnected() async {
    if (_disposed) return;
    if (_baseUrl == null || _userId == null) return;

    // Start watchdog once (keeps trying if disconnected)
    _watchdog ??= Timer.periodic(const Duration(seconds: 4), (_) async {
      if (_disposed) return;

      final st = _conn?.state;
      if (st != HubConnectionState.Connected &&
          st != HubConnectionState.Connecting &&
          st != HubConnectionState.Reconnecting) {
        await _startInternal();
      }
    });

    // Immediate connect attempt
    await _startInternal();
  }

  /// Call this on app resume
  Future<void> onAppResumed() async {
    await ensureConnected();
  }

  /// Call on logout
  Future<void> disconnect() async {
    _watchdog?.cancel();
    _watchdog = null;

    final c = _conn;
    _conn = null;

    try {
      if (c != null) await c.stop();
    } catch (_) {}

    _baseUrl = null;
    _userId = null;
  }

  /// Only call when app is closing permanently
  void dispose() {
    _disposed = true;
    _watchdog?.cancel();
    _watchdog = null;

    try {
      _notificationCtrl.close();
      _rawCtrl.close();
    } catch (_) {}
  }

  // -------------------- Internals --------------------

  void _hardReset() {
    final c = _conn;
    _conn = null;
    if (c != null) {
      // ignore: discarded_futures
      c.stop();
    }
  }

  HubConnection _buildConnection({
    required HttpTransportType transport,
  }) {
    final options = HttpConnectionOptions(
      transport: transport,
      // You can add headers/accessTokenFactory here if needed later:
      // headers: {"Authorization": "Bearer ..."},
      // accessTokenFactory: () async => token,
    );

    final hub = HubConnectionBuilder()
        .withUrl(hubUrl, options: options)
        // ✅ null at end = keep retrying forever
        .withAutomaticReconnect(
          retryDelays: [2000, 5000, 10000, 20000],
        )
        .build();

    // timeouts / keepalive (supported by HubConnection)
    hub.serverTimeoutInMilliseconds = 30000;
    hub.keepAliveIntervalInMilliseconds = 10000;

    _wireHandlers(hub);
    return hub;
  }

  void _wireHandlers(HubConnection hub) {
    // IMPORTANT: avoid double-wiring if same instance reused
    // (we rebuild hub on reset; so safe)

    void handle(dynamic payload) {
      _rawCtrl.add(payload);

      final normalized = _normalize(payload);
      if (normalized != null) _notificationCtrl.add(normalized);
    }

    hub.on("receivenotification", (args) {
      final payload = (args != null && args.isNotEmpty) ? args[0] : args;
      handle(payload);
    });

    hub.on("ReceiveNotification", (args) {
      final payload = (args != null && args.isNotEmpty) ? args[0] : args;
      handle(payload);
    });

    hub.onclose(({error}) {
      // auto-reconnect + watchdog will handle reconnection
    });

    hub.onreconnecting(({error}) {
      // optional: debugPrint("🔁 reconnecting: $error");
    });

    hub.onreconnected(({connectionId}) {
      // optional: debugPrint("✅ reconnected: $connectionId");
    });
  }

  Map<String, dynamic>? _normalize(dynamic payload) {
    try {
      dynamic obj = payload;

      if (obj is List && obj.isNotEmpty) obj = obj[0];
      if (obj is String) obj = jsonDecode(obj);

      if (obj is Map) return Map<String, dynamic>.from(obj);
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _startInternal() async {
    if (_starting) return;
    if (_baseUrl == null || _userId == null) return;

    // already connected/connecting/reconnecting
    final st = _conn?.state;
    if (st == HubConnectionState.Connected ||
        st == HubConnectionState.Connecting ||
        st == HubConnectionState.Reconnecting) {
      return;
    }

    _starting = true;
    try {
      _conn ??= _buildConnection(transport: HttpTransportType.WebSockets);

      try {
        await _conn!.start();
        return;
      } catch (_) {
        // ✅ Fallback to LongPolling if websocket fails
        try {
          await _conn!.stop();
        } catch (_) {}

        _conn = _buildConnection(transport: HttpTransportType.LongPolling);
        await _conn!.start();
      }
    } catch (_) {
      // ignore; watchdog keeps trying
    } finally {
      _starting = false;
    }
  }
}
