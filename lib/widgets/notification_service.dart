import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService I = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'taskoon_offers';

  Future<void> init() async {
    // ---------- INIT ----------
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    await _plugin.initialize(
      const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      ),
    );

    // ---------- ANDROID 13 PERMISSION ----------
    final android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await android?.requestNotificationsPermission();

    // ---------- CREATE CHANNEL ----------
    const channel = AndroidNotificationChannel(
      channelId,
      'Taskoon Offers',
      description: 'New task offers and booking updates',
      importance: Importance.max, // 🔥 MUST be MAX
      playSound: true,
      enableVibration: true,
    );

    await android?.createNotificationChannel(channel);

    // ---------- iOS PERMISSION ----------
    if (Platform.isIOS) {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        sound: true,
        badge: true,
      );
    }

    // ---------- FOREGROUND FCM ----------
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('📩 FCM FOREGROUND RECEIVED');
      show(
        title: message.notification?.title ?? 'New task request',
        body: message.notification?.body ?? 'You have a new offer',
      );
    });
  }

  /// 🔔 FORCE SYSTEM NOTIFICATION
  Future<void> show({
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'Taskoon Offers',
          channelDescription: 'New task offers',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
