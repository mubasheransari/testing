import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';
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
    final conn = _connection;
    if (conn != null) {
      final s = conn.state;
      if (s == HubConnectionState.Connected ||
          s == HubConnectionState.Connecting ||
          s == HubConnectionState.Reconnecting) {
        return;
      }
    }

    if (_connecting) return;
    _connecting = true;

    try {
      await _connection?.stop();
      _connection = null;

      final url = "$baseUrl/hubs/dispatch?userId=${Uri.encodeComponent(userId)}";

      final connection = HubConnectionBuilder()
          .withUrl(
            url,
            options: HttpConnectionOptions(),
          )
          .withAutomaticReconnect()
          .build();

      _connection = connection;

      connection.on("ReceiveBookingOffer", (args) {
        final payload = _normalize(args);
        if (payload != null) {
          debugPrint("📩 SIGNALR offer => $payload");
          _stream.add(payload);
        }
      });

      connection.on("ReceiveNotification", (args) {
        final payload = _normalize(args);
        if (payload != null) {
          debugPrint("📩 SIGNALR notification => $payload");
          _stream.add(payload);
        }
      });

      connection.onclose(({error}) {
        debugPrint("❌ SignalR closed: $error");
      });

      connection.onreconnecting(({error}) {
        debugPrint("🔄 SignalR reconnecting: $error");
      });

      connection.onreconnected(({connectionId}) {
        debugPrint("✅ SignalR reconnected: $connectionId");
      });

      final startFuture = connection.start();
      if (startFuture == null) {
        throw Exception("SignalR start() returned null");
      }

      await startFuture.timeout(const Duration(seconds: 15));
      debugPrint("✅ SignalR connected");
    } catch (e) {
      debugPrint("❌ SignalR connect failed: $e");
    } finally {
      _connecting = false;
    }
  }

  Map<String, dynamic>? _normalize(List<Object?>? args) {
    if (args == null || args.isEmpty) return null;

    dynamic d = args.first;

    if (d is List && d.isNotEmpty) {
      d = d.first;
    }

    if (d is String) {
      try {
        d = jsonDecode(d);
      } catch (_) {}
    }

    if (d is Map) {
      return Map<String, dynamic>.from(d);
    }

    return null;
  }

  Future<void> disconnect() async {
    try {
      await _connection?.stop(); 
    } catch (_) {}
    _connection = null;
  }

  Future<void> dispose() async {
    await disconnect();
    await _stream.close();
  }
}
// class SignalRService {
//   SignalRService._();
//   static final SignalRService I = SignalRService._();

//   HubConnection? _connection;
//   bool _connecting = false;

//   final _stream = StreamController<Map<String, dynamic>>.broadcast();
//   Stream<Map<String, dynamic>> get stream => _stream.stream;

//   Future<void> connect({
//     required String baseUrl,
//     required String userId,
//   }) async {
//     if (_connection?.state == HubConnectionState.Connected) return;
//     if (_connecting) return;

//     _connecting = true;

//     try {
//       _connection = HubConnectionBuilder()
//           .withUrl(
//             "$baseUrl/hubs/dispatch?userId=$userId",
//             options: HttpConnectionOptions(
//               transport: HttpTransportType.LongPolling,
//             ),
//           )
//           .withAutomaticReconnect()
//           .build();

//       _connection!.on("ReceiveBookingOffer", (args) {
//         final payload = _normalize(args);
//         if (payload != null) {
//           debugPrint("📩 SIGNALR offer => $payload");
//           _stream.add(payload);
//         }
//       });
// _connection!.onclose(({error}) async {
//   debugPrint("❌ SignalR closed: $error");
// });


//       await _connection!.start();
//       debugPrint("✅ SignalR connected");
//     } catch (e) {
//       debugPrint("❌ SignalR connect failed: $e");
//     } finally {
//       _connecting = false;
//     }
//   }

//   dynamic _normalize(List<Object?>? args) {
//     if (args == null || args.isEmpty) return null;
//     dynamic d = args.first;
//     if (d is String) {
//       try {
//         d = jsonDecode(d);
//       } catch (_) {}
//     }
//     if (d is Map) return Map<String, dynamic>.from(d);
//     return null;
//   }

//   Future<void> dispose() async {
//     await _connection?.stop();
//     await _stream.close();
//   }
// }
