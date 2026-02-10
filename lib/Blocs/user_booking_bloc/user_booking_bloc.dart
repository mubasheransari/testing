import 'package:bloc/bloc.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_event.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_state.dart';
import 'package:taskoon/Repository/auth_repository.dart';

class UserBookingBloc extends Bloc<UserBookingEvent, UserBookingState> {
  final AuthRepository repo;

  UserBookingBloc(this.repo) : super(UserBookingState()) {
    on<CreateUserBookingRequested>(_onCreateUserBookingRequested);
    on<UpdateUserLocationRequested>(_onUpdateUserLocationRequested);
    on<FindingTaskerRequested>(findingTaskerRequested);
    on<ChangeAvailabilityStatus>(_changeAvailabilityStatus);
    on<AcceptBooking>(_acceptBooking);
    on<CancelBooking>(_onCancelUserBookingRequested);
        on<StartSosRequested>(_startSosRequested);
    on<UpdateSosLocationRequested>(_updateSosLocationRequested);

  }
Future<void> _startSosRequested(
  StartSosRequested e,
  Emitter<UserBookingState> emit,
) async {
  emit(
    state.copyWith(
      startSosStatus: StartSosStatus.submitting,
      clearStartSosError: true,
      clearStartSosResponse: true,
    ),
  );

  final r = await repo.startSos(
    taskerUserId: e.taskerUserId,
    bookingDetailId: e.bookingDetailId,
    latitude: e.latitude,
    longitude: e.longitude,
  );

  if (r.isSuccess) {
    emit(
      state.copyWith(
        startSosStatus: StartSosStatus.success,
        startSosResponse: r.data,
        clearStartSosError: true,
      ),
    );
  } else {
    emit(
      state.copyWith(
        startSosStatus: StartSosStatus.failure,
        startSosError: r.failure?.message ?? 'Failed to start SOS',
        clearStartSosResponse: true,
      ),
    );
  }
}

Future<void> _updateSosLocationRequested(
  UpdateSosLocationRequested e,
  Emitter<UserBookingState> emit,
) async {
  emit(
    state.copyWith(
      updateSosLocationStatus: UpdateSosLocationStatus.submitting,
      clearUpdateSosLocationError: true,
      clearUpdateSosLocationResponse: true,
    ),
  );

  final r = await repo.updateSosLocation(
    sosId: e.sosId,
    latitude: e.latitude,
    longitude: e.longitude,
  );

  if (r.isSuccess) {
    emit(
      state.copyWith(
        updateSosLocationStatus: UpdateSosLocationStatus.success,
        updateSosLocationResponse: r.data,
        clearUpdateSosLocationError: true,
      ),
    );
  } else {
    emit(
      state.copyWith(
        updateSosLocationStatus: UpdateSosLocationStatus.failure,
        updateSosLocationError: r.failure?.message ?? 'Failed to update SOS location',
        clearUpdateSosLocationResponse: true,
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
    emit(state.copyWith(
      createStatus: UserBookingCreateStatus.failure,
      createError: "Invalid start/end time format: $ex",
      clearCreateResponse: true,
    ));
    return;
  }

  if (!startDt.isBefore(endDt)) {
    emit(state.copyWith(
      createStatus: UserBookingCreateStatus.failure,
      createError: "Start time must be earlier than end time.",
      clearCreateResponse: true,
    ));
    return;
  }

  // log
  print('📥 [Bloc] CreateUserBookingRequested: '
      'userId=${e.userId}, subCategoryId=${e.subCategoryId}, '
      'bookingTypeId=${e.bookingTypeId}, bookingDate=${e.bookingDate.toIso8601String()}, '
      'endDate=${e.endDate?.toIso8601String()}, start=${e.startTime}, end=${e.endTime}, '
      'address=${e.address}, taskerLevelId=${e.taskerLevelId}, '
      'recurrencePatternId=${e.recurrencePatternId}, customDays=${e.customDays}, '
      'lat=${e.latitude}, lng=${e.longitude}');

  emit(state.copyWith(
    createStatus: UserBookingCreateStatus.submitting,
    clearCreateError: true,
    clearCreateResponse: true,
  ));

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
    emit(state.copyWith(
      createStatus: UserBookingCreateStatus.success,
      bookingCreateResponse: r.data,
      clearCreateError: true,
    ));
  } else {
    emit(state.copyWith(
      createStatus: UserBookingCreateStatus.failure,
      createError: r.failure?.message ?? 'Failed to create booking',
      clearCreateResponse: true,
    ));
  }
}


  Future<void> _onCancelUserBookingRequested(
    CancelBooking e,
    Emitter<UserBookingState> emit,
  ) async {
    emit(
      state.copyWith(
        userBookingCancelStatus: UserBookingCancelStatus.submitting
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
          userBookingCancelStatus: UserBookingCancelStatus.failure
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

          // ✅ store full response + message
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
