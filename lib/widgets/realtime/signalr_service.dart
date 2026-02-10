import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';

class SignalRService {
  SignalRService._();
  static final SignalRService I = SignalRService._();

  HubConnection? _connection;
  bool _connecting = false;

  final _stream = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get stream => _stream.stream;

  Future<void> connect({
    required String baseUrl,
    required String userId,
  }) async {
    if (_connection?.state == HubConnectionState.Connected) return;
    if (_connecting) return;

    _connecting = true;

    try {
      _connection = HubConnectionBuilder()
          .withUrl(
            "$baseUrl/hubs/dispatch?userId=$userId",
            options: HttpConnectionOptions(
              transport: HttpTransportType.LongPolling,
            ),
          )
          .withAutomaticReconnect()
          .build();

      _connection!.on("ReceiveBookingOffer", (args) {
        final payload = _normalize(args);
        if (payload != null) {
          debugPrint("📩 SIGNALR offer => $payload");
          _stream.add(payload);
        }
      });
_connection!.onclose(({error}) async {
  debugPrint("❌ SignalR closed: $error");
});


      await _connection!.start();
      debugPrint("✅ SignalR connected");
    } catch (e) {
      debugPrint("❌ SignalR connect failed: $e");
    } finally {
      _connecting = false;
    }
  }

  dynamic _normalize(List<Object?>? args) {
    if (args == null || args.isEmpty) return null;
    dynamic d = args.first;
    if (d is String) {
      try {
        d = jsonDecode(d);
      } catch (_) {}
    }
    if (d is Map) return Map<String, dynamic>.from(d);
    return null;
  }

  Future<void> dispose() async {
    await _connection?.stop();
    await _stream.close();
  }
}
