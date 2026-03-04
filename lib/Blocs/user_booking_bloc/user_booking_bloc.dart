import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_event.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_state.dart';
import 'package:taskoon/Repository/auth_repository.dart';

class UserBookingBloc extends Bloc<UserBookingEvent, UserBookingState> {
  final AuthRepository repo;
  Timer? _sosLocationTimer;
  String? _activeSosId;

  UserBookingBloc(this.repo) : super(const UserBookingState()) {
    //dashboard
      on<FetchTaskerDashboardRequested>(_onFetchTaskerDashboard);
    on<ClearTaskerDashboardStatus>(_onClearTaskerDashboardStatus);
    on<StartSosRequested>(_startSosRequested);
    on<UpdateSosLocationRequested>(_updateSosLocationRequested);
    on<CreatePaymentIntentRequested>(_createPaymentIntentRequested);
    on<CreateUserBookingRequested>(_onCreateUserBookingRequested);
    on<UpdateUserLocationRequested>(_onUpdateUserLocationRequested);
    on<FindingTaskerRequested>(findingTaskerRequested);
    on<ChangeAvailabilityStatus>(_changeAvailabilityStatus);
    on<AcceptBooking>(_acceptBooking);
    on<CancelBooking>(_onCancelUserBookingRequested);
    on<StopSosRequested>(_stopSosRequested);
  }
  void _startSosTimer() {
    // ✅ cancel only timer, DO NOT null sosId here
    _sosLocationTimer?.cancel();
    _sosLocationTimer = null;

    if (_activeSosId == null) {
      print("❌ SOS TIMER NOT STARTED: _activeSosId is null");
      return;
    }

    print("✅ SOS TIMER STARTED for sosId=$_activeSosId");

    _sosLocationTimer = Timer.periodic(const Duration(seconds: 10), (t) {
      if (isClosed) {
        print("⚠️ Bloc closed -> cancelling SOS timer");
        t.cancel();
        return;
      }

      if (_activeSosId == null) {
        print("⚠️ sosId became null -> cancelling timer");
        t.cancel();
        return;
      }

      print("⏱️ SOS TIMER TICK -> dispatch UpdateSosLocationRequested");

      add(
        UpdateSosLocationRequested(
          sosId: _activeSosId!,
          latitude: 67.00,
          longitude: 70.00,
        ),
      );
    });
  }

  void _stopSosTimer() {
    if (_sosLocationTimer != null) {
      print("🛑 SOS TIMER STOPPED");
    }
    _sosLocationTimer?.cancel();
    _sosLocationTimer = null;
    _activeSosId = null;
  }

  Future<void> _onFetchTaskerDashboard(
    FetchTaskerDashboardRequested event,
    Emitter<UserBookingState> emit,
  ) async {
    emit(state.copyWith(
      taskerDashboardStatus: TaskerDashboardStatus.loading,
      clearTaskerDashboardError: true,
      clearTaskerDashboardResponse: true,
    ));

    final r = await repo.fetchTaskerDashboard(userId: event.userId);

    if (!r.isSuccess) {
      emit(state.copyWith(
        taskerDashboardStatus: TaskerDashboardStatus.failure,
        taskerDashboardError: r.failure?.message ?? "Failed to load dashboard",
      ));
      return;
    }

   final resp = r.data!;
    if (resp.isSuccess != true || resp.result == null) {
      final msg = (resp.errors != null && resp.errors!.isNotEmpty)
          ? resp.errors!.join(' • ')
          : (resp.message ?? "Dashboard failed");
      emit(state.copyWith(
        taskerDashboardStatus: TaskerDashboardStatus.failure,
        taskerDashboardError: msg,
        taskerDashboardResponse: resp,
      ));
      return;
    }

    emit(state.copyWith(
      taskerDashboardStatus: TaskerDashboardStatus.success,
      taskerDashboardResponse: resp,
      clearTaskerDashboardError: true,
    ));
  }

  void _onClearTaskerDashboardStatus(
    ClearTaskerDashboardStatus event,
    Emitter<UserBookingState> emit,
  ) {
    emit(state.copyWith(
      taskerDashboardStatus: TaskerDashboardStatus.initial,
      clearTaskerDashboardError: true,
    ));
  }

  Future<void> _startSosRequested(
    StartSosRequested e,
    Emitter<UserBookingState> emit,
  ) async {
    // ✅ prevent double start if already active or submitting
    if (state.startSosStatus == StartSosStatus.submitting) return;
    if (_activeSosId != null) {
      print(
        "ℹ️ SOS already active ($_activeSosId), ignoring StartSosRequested",
      );
      return;
    }

    emit(
      state.copyWith(
        startSosStatus: StartSosStatus.submitting,
        clearStartSosError: true,
        clearStartSosResult: true,
      ),
    );

    final r = await repo.startSos(
      taskerUserId: e.taskerUserId,
      bookingDetailId: e.bookingDetailId,
      latitude: e.latitude,
      longitude: e.longitude,
    );

    if (r.isSuccess == true && r.data?.result != null) {
      final sosId = r.data!.result!.sosId;
      _activeSosId = sosId;

      // ✅ start 10s loop (with fallback initial location)
      _startSosTimer();

      emit(
        state.copyWith(
          startSosStatus: StartSosStatus.success,
          startSosResult: r.data!.result,
          clearStartSosError: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          startSosStatus: StartSosStatus.failure,
          startSosError: r.failure?.message ?? 'SOS start failed',
        ),
      );
    }
  }

  Future<void> _updateSosLocationRequested(
    UpdateSosLocationRequested e,
    Emitter<UserBookingState> emit,
  ) async {
    print(
      "🚀 Calling updateSosLocation sosId=${e.sosId} lat=${e.latitude} lng=${e.longitude}",
    );

    final r = await repo.updateSosLocation(
      sosId: e.sosId,
      latitude: e.latitude,
      longitude: e.longitude,
    );

    if (r.isSuccess == true) {
      emit(
        state.copyWith(
          updateSosLocationStatus: UpdateSosLocationStatus.success,
        ),
      );
    } else {
      emit(
        state.copyWith(
          updateSosLocationStatus: UpdateSosLocationStatus.failure,
          updateSosLocationError:
              r.failure?.message ?? 'Failed to update SOS location',
        ),
      );
    }
  }

  Future<void> _stopSosRequested(
    StopSosRequested e,
    Emitter<UserBookingState> emit,
  ) async {
    _stopSosTimer();

    emit(
      state.copyWith(
        startSosStatus: StartSosStatus.initial,
        updateSosLocationStatus: UpdateSosLocationStatus.initial,
        clearStartSosResult: true,
      ),
    );
  }

  Future<void> _createPaymentIntentRequested(
    CreatePaymentIntentRequested e,
    Emitter<UserBookingState> emit,
  ) async {
    emit(
      state.copyWith(
        createPaymentIntentStatus: CreatePaymentIntentStatus.submitting,
        clearPaymentIntentError: true,
        clearPaymentIntentResponse: true,
      ),
    );

    final r = await repo.createPaymentIntent(
      bookingDetailId: e.bookingDetailId,
    );

    if (r.isSuccess) {
      emit(
        state.copyWith(
          createPaymentIntentStatus: CreatePaymentIntentStatus.success,
          paymentIntentResponse: r.data,
          clearPaymentIntentError: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          createPaymentIntentStatus: CreatePaymentIntentStatus.failure,
          paymentIntentError:
              r.failure?.message ?? 'Failed to create payment intent',
          clearPaymentIntentResponse: true,
        ),
      );
    }
  }

  Future<void> findingTaskerRequested(
    FindingTaskerRequested e,
    Emitter<UserBookingState> emit,
  ) async {
    emit(
      state.copyWith(
        findingTaskerStatus: FindingTaskerStatus.updating,
        clearFindingTaskerError: true,
        clearBookingFindResponse: true,
      ),
    );

    final r = await repo.findBooking(bookingDetailId: e.bookingId);

    if (r.isSuccess) {
      emit(
        state.copyWith(
          findingTaskerStatus: FindingTaskerStatus.success,
          bookingFindResponse: r.data,
        ),
      );
    } else {
      emit(
        state.copyWith(
          findingTaskerStatus: FindingTaskerStatus.failure,
          findingTaskerError: r.failure?.message ?? 'Find booking failed',
        ),
      );
    }
  }

  Future<void> _onCreateUserBookingRequested(
    CreateUserBookingRequested e,
    Emitter<UserBookingState> emit,
  ) async {
    DateTime _parseIsoDateTime(String v) {
      final raw = v.trim();
      if (raw.isEmpty) throw const FormatException("Empty datetime");

      final normalized = raw.contains('T') ? raw : raw.replaceFirst(' ', 'T');

      return DateTime.parse(normalized);
    }

    late final DateTime startDt;
    late final DateTime endDt;

    try {
      startDt = _parseIsoDateTime(e.startTime);
      endDt = _parseIsoDateTime(e.endTime);
    } catch (ex) {
      emit(
        state.copyWith(
          createStatus: UserBookingCreateStatus.failure,
          createError: "Invalid start/end time format: $ex",
          clearCreateResponse: true,
        ),
      );
      return;
    }

    if (!startDt.isBefore(endDt)) {
      emit(
        state.copyWith(
          createStatus: UserBookingCreateStatus.failure,
          createError: "Start time must be earlier than end time.",
          clearCreateResponse: true,
        ),
      );
      return;
    }

    // log
    print(
      '📥 [Bloc] CreateUserBookingRequested: '
      'userId=${e.userId}, subCategoryId=${e.subCategoryId}, '
      'bookingTypeId=${e.bookingTypeId}, bookingDate=${e.bookingDate.toIso8601String()}, '
      'endDate=${e.endDate?.toIso8601String()}, start=${e.startTime}, end=${e.endTime}, '
      'address=${e.address}, taskerLevelId=${e.taskerLevelId}, '
      'recurrencePatternId=${e.recurrencePatternId}, customDays=${e.customDays}, '
      'lat=${e.latitude}, lng=${e.longitude}',
    );

    emit(
      state.copyWith(
        createStatus: UserBookingCreateStatus.submitting,
        clearCreateError: true,
        clearCreateResponse: true,
      ),
    );

    final r = await repo.createBooking(
      userId: e.userId,
      subCategoryId: e.subCategoryId,
      bookingTypeId: e.bookingTypeId,
      bookingDate: e.bookingDate,
      endDate: e.endDate,
      startTime: startDt,
      endTime: endDt,
      address: e.address,
      taskerLevelId: e.taskerLevelId,
      recurrencePatternId: e.recurrencePatternId,
      customDays: e.customDays,
      latitude: e.latitude,
      longitude: e.longitude,
    );

    if (r.isSuccess) {
      emit(
        state.copyWith(
          createStatus: UserBookingCreateStatus.success,
          bookingCreateResponse: r.data,
          clearCreateError: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          createStatus: UserBookingCreateStatus.failure,
          createError: r.failure?.message ?? 'Failed to create booking',
          clearCreateResponse: true,
        ),
      );
    }
  }

  Future<void> _onCancelUserBookingRequested(
    CancelBooking e,
    Emitter<UserBookingState> emit,
  ) async {
    emit(
      state.copyWith(
        userBookingCancelStatus: UserBookingCancelStatus.submitting,
      ),
    );

    final r = await repo.cancelBookingPut(
      userId: e.userId,
      bookingDetailId: e.bookingDetailId,
      reason: e.reason,
    );

    if (r.isSuccess) {
      print('✅ [Bloc] createBooking SUCCESS');

      // r.data is BookingCreateResponse?
      final bookingResp = r.data; // BookingCreateResponse?

      emit(
        state.copyWith(
          userBookingCancelStatus: UserBookingCancelStatus.success,
        ),
      );
    } else {
      emit(
        state.copyWith(
          userBookingCancelStatus: UserBookingCancelStatus.failure,
        ),
      );
    }
  }

  Future<void> _onUpdateUserLocationRequested(
    UpdateUserLocationRequested e,
    Emitter<UserBookingState> emit,
  ) async {
    emit(
      state.copyWith(
        locationStatus: UserLocationUpdateStatus.updating,
        clearLocationError: true,
      ),
    );

    final r = await repo.updateUserLocation(
      userId: e.userId,
      latitude: e.latitude,
      longitude: e.longitude,
    );

    if (r.isSuccess) {
      emit(
        state.copyWith(
          locationStatus: UserLocationUpdateStatus.success,
          lastLatitude: e.latitude,
          lastLongitude: e.longitude,
          clearLocationError: true,
        ),
      );
    } else {
      print('❌ [Bloc] updateUserLocation FAILURE: ${r.failure?.message}');
      print('❌ [Bloc] updateUserLocation FAILURE: ${r.failure?.message}');

      emit(
        state.copyWith(
          locationStatus: UserLocationUpdateStatus.failure,
          locationError: r.failure?.message ?? 'Failed to update user location',
        ),
      );
    }
  }

  Future<void> _changeAvailabilityStatus(
    ChangeAvailabilityStatus e,
    Emitter<UserBookingState> emit,
  ) async {
    emit(
      state.copyWith(
        changeAvailabilityStatusEnum: ChangeAvailabilityStatusEnum.initial,
      ),
    );

    final r = await repo.changeAvailbilityStatusTasker(userId: e.userId);

    if (r.isSuccess) {
      emit(
        state.copyWith(
          changeAvailabilityStatusEnum: ChangeAvailabilityStatusEnum.success,
          // clearLocationError: true,
        ),
      );
    } else {
      print(
        '❌ [Bloc] _changeAvailabilityStatus FAILURE: ${r.failure?.message}',
      );
      print(
        '❌ [Bloc] _changeAvailabilityStatus FAILURE: ${r.failure?.message}',
      );
      print(
        '❌ [Bloc] _changeAvailabilityStatus FAILURE: ${r.failure?.message}',
      );
      print(
        '❌ [Bloc] _changeAvailabilityStatus FAILURE: ${r.failure?.message}',
      );

      emit(
        state.copyWith(
          changeAvailabilityStatusEnum: ChangeAvailabilityStatusEnum.failure,
          changeAvailabilityError:
              r.failure?.message ?? 'Failed to update user location',
        ),
      );
    }
  }

  Future<void> _acceptBooking(
    AcceptBooking e,
    Emitter<UserBookingState> emit,
  ) async {
    emit(
      state.copyWith(
        acceptBookingEnum: AcceptBookingEnum.updating,

        // clear old accept state
        clearAcceptBookingError: true,
        clearAcceptBookingResponse: true,
        clearAcceptBookingMessage: true,

        // keep your existing behavior
        clearLocationError: true,
      ),
    );

    final r = await repo.acceptBooking(
      userId: e.userId,
      bookingId: e.bookingDetailId,
    );

    if (r.isSuccess == true) {
      print("BOOKING ACCEPT ${state.acceptBookingEnum}");
      print("BOOKING ACCEPT ${state.acceptBookingEnum}");
      print("BOOKING ACCEPT ${state.acceptBookingEnum}");
      print("BOOKING ACCEPT ${state.acceptBookingEnum}");

      emit(
        state.copyWith(
          acceptBookingEnum: AcceptBookingEnum.success,
          acceptBookingResponse: r.data,
          acceptBookingMessage: r.data?.message ?? '',

          clearLocationError: true,
        ),
      );
      print("BOOKING ACCEPT ${state.acceptBookingEnum}");
      print("BOOKING ACCEPT ${state.acceptBookingEnum}");
      print("BOOKING ACCEPT ${state.acceptBookingEnum}");
      print("BOOKING ACCEPT ${state.acceptBookingEnum}");
    } else {
      print('❌ [Bloc] _acceptBooking FAILURE: ${r.failure?.message}');

      emit(
        state.copyWith(
          acceptBookingEnum: AcceptBookingEnum.failure,
          acceptBookingError: r.failure?.message ?? 'Failed to accept booking',
        ),
      );
    }
  }
}
