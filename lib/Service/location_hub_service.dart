// lib/services/location_hub_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:signalr_core/signalr_core.dart';
import 'package:taskoon/Models/location_update.dart';
 


class LocationHubService {
  final String hubUrl;
  late HubConnection _connection;

  // Stream of AddressLocation instead of LocationUpdate
  final _controller = StreamController<AddressLocation>.broadcast();

  Stream<AddressLocation> get locationStream => _controller.stream;

  bool get isConnected => _connection.state == HubConnectionState.connected;

  LocationHubService({required this.hubUrl}) {
    _connection = HubConnectionBuilder()
        .withUrl(hubUrl)
        .build();

    // This must match your backend: Clients.All.SendAsync("LocationUpdated", obj)
    _connection.on('LocationUpdated', _onLocationUpdated);
  }

  void _onLocationUpdated(List<Object?>? args) {
    if (args == null || args.isEmpty) return;

    final raw = args.first;

    try {
      Map<String, dynamic> data;

      if (raw is String) {
        // e.g. JSON string payload
        data = jsonDecode(raw) as Map<String, dynamic>;
      } else if (raw is Map) {
        // already deserialized
        data = Map<String, dynamic>.from(raw as Map);
      } else {
        return;
      }

      final loc = AddressLocation.fromJson(data);
      _controller.add(loc);
    } catch (e) {
      // ignore malformed messages
    }
  }

  Future<void> start() async {
    await _connection.start();
  }

  Future<void> stop() async {
    await _connection.stop();
  }

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }
}


// class LocationUpdate {
//   final String userId;
//   final double latitude;
//   final double longitude;

//   LocationUpdate({
//     required this.userId,
//     required this.latitude,
//     required this.longitude,
//   });

//   factory LocationUpdate.fromJson(Map<String, dynamic> json) {
//     return LocationUpdate(
//       userId: json['userId']?.toString() ?? '',
//       latitude: (json['latitude'] as num).toDouble(),
//       longitude: (json['longitude'] as num).toDouble(),
//     );
//   }
// }

// class LocationHubService {
//   final String hubUrl;
//   late HubConnection _connection;

//   final _controller = StreamController<LocationUpdate>.broadcast();

//   Stream<LocationUpdate> get locationStream => _controller.stream;

//   // ✅ use `connected` (lowercase) – Dart enum, not C# style
//   bool get isConnected => _connection.state == HubConnectionState.connected;

//   LocationHubService({required this.hubUrl}) {
//     _connection = HubConnectionBuilder()
//         .withUrl(hubUrl)
//         .build();

//     _connection.on('LocationUpdated', _onLocationUpdated);
//   }

//   void _onLocationUpdated(List<Object?>? args) {
//     if (args == null || args.isEmpty) return;

//     final raw = args.first;
//     try {
//       Map<String, dynamic> data;

//       if (raw is String) {
//         data = jsonDecode(raw) as Map<String, dynamic>;
//       } else if (raw is Map<String, dynamic>) {
//         data = Map<String, dynamic>.from(raw);
//       } else {
//         return;
//       }

//       final update = LocationUpdate.fromJson(data);
//       _controller.add(update);
//     } catch (_) {
//       // ignore malformed messages
//     }
//   }

//   // ✅ wrap nullable Future in our own non-nullable Future<void>
//   Future<void> start() async {
//     await _connection.start();
//   }

//   Future<void> stop() async {
//     await _connection.stop();
//   }

//   Future<void> dispose() async {
//     await stop();
//     await _controller.close();
//   }
// }
