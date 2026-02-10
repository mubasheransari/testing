import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'tasker_dispatch_hub_service.dart';


class TaskerOfferNotifications {
  TaskerOfferNotifications._();
  static final TaskerOfferNotifications I = TaskerOfferNotifications._();

  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  final StreamController<TaskerBookingOffer> _tapCtrl = StreamController.broadcast();
  Stream<TaskerBookingOffer> get onNotificationTapOffer => _tapCtrl.stream;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'tasker_offers',
    'Task Offers',
    description: 'Notifications for new task offers',
    importance: Importance.max,
  );

  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (resp) {
        final p = resp.payload;
        if (p == null || p.isEmpty) return;

        try {
          final obj = jsonDecode(p);
          // payload is your same signalr payload structure or offer map
          final offer = TaskerBookingOffer.tryParse(obj);
          if (offer != null) {
            debugPrint("🔔 NOTIF TAP -> offer bookingDetailId=${offer.bookingDetailId}");
            _tapCtrl.add(offer);
          }
        } catch (e) {
          debugPrint("❌ NOTIF TAP parse error => $e");
        }
      },
    );

    final android = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_channel);
  }

  Future<void> showOfferNotification({
    required TaskerBookingOffer offer,
  }) async {
    // Build a short text like your dialog
    final title = "New task request";
    final body = "${offer.bookingService ?? "Service"} • ${offer.location ?? ""}"
        "${offer.distanceKm == null ? "" : " • ${offer.distanceKm!.toStringAsFixed(1)} km"}";

    // Put FULL payload into notification payload so we can reconstruct offer on tap
    // We store as a structure that tryParse can understand
    final payloadObj = {
      "type": "ReceiveBookingOffer",
      "message": offer.message,
      "date": offer.date,
      "data": {
        "bookingDetailId": offer.bookingDetailId,
        "lat": offer.lat,
        "lng": offer.lng,
        "estimatedCost": offer.estimatedCost,
        "bookingService": offer.bookingService,
        "userName": offer.userName,
        "bookingDuration": offer.bookingDuration,
        "bookingTime": offer.bookingTime?.toIso8601String(),
        "distanceKm": offer.distanceKm,
        "location": offer.location,
      }
    };

    final payload = jsonEncode(payloadObj);

    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.max,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  Future<void> dispose() async {
    await _tapCtrl.close();
  }
}
