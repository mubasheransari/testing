import 'dart:async';
import 'package:flutter/foundation.dart';

import 'tasker_dispatch_hub_service.dart';

class HubManager {
  HubManager._();
  static final HubManager I = HubManager._();

  final TaskerDispatchHubService hub = TaskerDispatchHubService();

  // A stream of parsed offers (so UI screens don't parse again)
  final _offersCtrl = StreamController<TaskerBookingOffer>.broadcast();
  Stream<TaskerBookingOffer> get offers => _offersCtrl.stream;

  StreamSubscription? _sub;
  bool _configured = false;

  Future<void> init({required String baseUrl, required String userId}) async {
    if (userId.trim().isEmpty) return;

    hub.configure(baseUrl: baseUrl, userId: userId.trim());
    _configured = true;

    // connect once
    await hub.ensureConnected();

    // attach once (fan-out to offers stream)
    _sub ??= hub.notifications.listen((payload) {
      final offer = TaskerBookingOffer.tryParse(payload);
      if (offer != null) {
        debugPrint("✅ HubManager: offer received bookingDetailId=${offer.bookingDetailId}");
        _offersCtrl.add(offer);
      } else {
        debugPrint("⚠️ HubManager: payload received but offer parse failed");
      }
    });

    // keep alive (optional if you already have watchdog in your service)
    hub.startWatchdog();
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    await hub.dispose();
    await _offersCtrl.close();
    _configured = false;
  }

  bool get isReady => _configured;
}
