import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_bloc.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_event.dart';
import 'package:taskoon/widgets/share_location_dialog.dart';



const String kShareLocationActiveKey = "share_location_active";


class SharingDialogManager {
  SharingDialogManager._();
  static final SharingDialogManager I = SharingDialogManager._();

  final GetStorage _box = GetStorage();
  bool _dialogOpen = false;

  bool get isActive => _box.read(kShareLocationActiveKey) == true;

  Future<void> setActive(bool v) async => _box.write(kShareLocationActiveKey, v);

  /// ✅ Show dialog only if persisted flag is ON
  Future<void> showIfActive(
    BuildContext context, {
    required String emergencyNumber,
    required String locationText,

    required String bookingDetailId,
    required String taskerUserId,
    required double initialLat,
    required double initialLng,

    required VoidCallback onCall,
  }) async {
    if (!isActive) return;
    if (_dialogOpen) return;

    _dialogOpen = true;
    try {
      final bookingBloc = context.read<UserBookingBloc>();

      await showSharingLocationDialog(
        context,
        bookingBloc: bookingBloc,
        emergencyNumber: emergencyNumber,
        locationText: locationText,

        bookingDetailId: bookingDetailId,
        taskerUserId: taskerUserId,
        initialLat: initialLat,
        initialLng: initialLng,

        onCall: onCall,

        // ✅ stop handled here => also persist flag OFF
        onStopSharing: () async {
          await setActive(false);
          bookingBloc.add(StopSosRequested());
        },

        barrierDismissible: false,
      );
    } finally {
      _dialogOpen = false;
    }
  }

  /// ✅ Open dialog immediately and persist ON
  Future<void> openAndSetActive(
    BuildContext context, {
    required String emergencyNumber,
    required String locationText,

    required String bookingDetailId,
    required String taskerUserId,
    required double initialLat,
    required double initialLng,

    required VoidCallback onCall,
  }) async {
    await setActive(true);
    await showIfActive(
      context,
      emergencyNumber: emergencyNumber,
      locationText: locationText,
      bookingDetailId: bookingDetailId,
      taskerUserId: taskerUserId,
      initialLat: initialLat,
      initialLng: initialLng,
      onCall: onCall,
    );
  }
}