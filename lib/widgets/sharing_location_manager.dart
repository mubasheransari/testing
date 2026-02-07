import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:taskoon/widgets/share_location_dialog.dart';

const String kShareLocationActiveKey = "share_location_active";

class SharingDialogManager {
  SharingDialogManager._();
  static final SharingDialogManager I = SharingDialogManager._();

  final GetStorage _box = GetStorage();

  bool _dialogOpen = false;

  bool get isActive => _box.read(kShareLocationActiveKey) == true;

  Future<void> setActive(bool v) async => _box.write(kShareLocationActiveKey, v);

  Future<void> showIfActive(
    BuildContext context, {
    required String emergencyNumber,
    required String locationText,
    required VoidCallback onCall,
    required VoidCallback onStopSharing,
  }) async {
    if (!isActive) return;
    if (_dialogOpen) return;

    _dialogOpen = true;
    try {
      await showSharingLocationDialog(
        context,
        emergencyNumber: emergencyNumber,
        locationText: locationText,
        barrierDismissible: false,
        onCall: onCall,
        onStopSharing: () async {
          await setActive(false); // ✅ persist OFF
          onStopSharing();
        },
      );
    } finally {
      _dialogOpen = false;
    }
  }
}
