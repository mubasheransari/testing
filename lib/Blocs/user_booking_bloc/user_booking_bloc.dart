import 'package:bloc/bloc.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_event.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_state.dart';
import 'package:taskoon/Repository/auth_repository.dart';


class UserBookingBloc extends Bloc<UserBookingEvent, UserBookingState> {
  final AuthRepository repo;

  UserBookingBloc(this.repo) : super(const UserBookingState()) {
    on<CreateUserBookingRequested>(_onCreateUserBookingRequested);
    on<UpdateUserLocationRequested>(_onUpdateUserLocationRequested);
  }

  // ---------- /api/Booking/Create ----------
  Future<void> _onCreateUserBookingRequested(
    CreateUserBookingRequested e,
    Emitter<UserBookingState> emit,
  ) async {
    emit(state.copyWith(
      createStatus: UserBookingCreateStatus.submitting,
      clearCreateError: true,
      clearCreateResponse: true,
    ));

    final r = await repo.createBooking(
      userId: e.userId,
      subCategoryId: e.subCategoryId,
      bookingDate: e.bookingDate,
      startTime: e.startTime,
      endTime: e.endTime,
      address: e.address,
      taskerLevelId: e.taskerLevelId,
    );

    if (r.isSuccess) {
      emit(state.copyWith(
        createStatus: UserBookingCreateStatus.success,
        createResponse: r.data,
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

Future<void> _onUpdateUserLocationRequested(
  UpdateUserLocationRequested e,
  Emitter<UserBookingState> emit,
) async {
  print('📥 [Bloc] UpdateUserLocationRequested received: '
        'userId=${e.userId}, lat=${e.latitude}, lng=${e.longitude}');
          print('📥 [Bloc] UpdateUserLocationRequested received: '
        'userId=${e.userId}, lat=${e.latitude}, lng=${e.longitude}');
          print('📥 [Bloc] UpdateUserLocationRequested received: '
        'userId=${e.userId}, lat=${e.latitude}, lng=${e.longitude}');
          print('📥 [Bloc] UpdateUserLocationRequested received: '
        'userId=${e.userId}, lat=${e.latitude}, lng=${e.longitude}');
          print('📥 [Bloc] UpdateUserLocationRequested received: '
        'userId=${e.userId}, lat=${e.latitude}, lng=${e.longitude}');

  emit(state.copyWith(
    locationStatus: UserLocationUpdateStatus.updating,
    clearLocationError: true,
  ));

  final r = await repo.updateUserLocation(
    userId: e.userId,
    latitude: e.latitude,
    longitude: e.longitude,
  );

  if (r.isSuccess) {
    print('✅ [Bloc] updateUserLocation SUCCESS');
     print('✅ [Bloc] updateUserLocation SUCCESS');
         print('✅ [Bloc] updateUserLocation SUCCESS');
     print('✅ [Bloc] updateUserLocation SUCCESS');
         print('✅ [Bloc] updateUserLocation SUCCESS');
     print('✅ [Bloc] updateUserLocation SUCCESS');
         print('✅ [Bloc] updateUserLocation SUCCESS');
     print('✅ [Bloc] updateUserLocation SUCCESS');
         print('✅ [Bloc] updateUserLocation SUCCESS');
     print('✅ [Bloc] updateUserLocation SUCCESS');

    emit(state.copyWith(
      locationStatus: UserLocationUpdateStatus.success,
      lastLatitude: e.latitude,
      lastLongitude: e.longitude,
      clearLocationError: true,
    ));
  } else {
    print('❌ [Bloc] updateUserLocation FAILURE: ${r.failure?.message}');
    print('❌ [Bloc] updateUserLocation FAILURE: ${r.failure?.message}');
    print('❌ [Bloc] updateUserLocation FAILURE: ${r.failure?.message}');
    print('❌ [Bloc] updateUserLocation FAILURE: ${r.failure?.message}');
    print('❌ [Bloc] updateUserLocation FAILURE: ${r.failure?.message}');
    
    emit(state.copyWith(
      locationStatus: UserLocationUpdateStatus.failure,
      locationError: r.failure?.message ?? 'Failed to update user location',
    ));
  }
}

}


// class UserBookingBloc extends Bloc<UserBookingEvent, UserBookingState> {
//   final AuthRepository repo;

//   UserBookingBloc(this.repo) : super(const UserBookingState()) {
//     on<CreateUserBookingRequested>(_onCreateUserBookingRequested);
//   }

//   Future<void> _onCreateUserBookingRequested(
//     CreateUserBookingRequested e,
//     Emitter<UserBookingState> emit,
//   ) async {
//     // set submitting state, clear any previous error/response
//     emit(state.copyWith(
//       createStatus: UserBookingCreateStatus.submitting,
//       clearCreateError: true,
//       clearCreateResponse: true,
//     ));

//     final r = await repo.createBooking(
//       userId: e.userId,
//       subCategoryId: e.subCategoryId,
//       bookingDate: e.bookingDate,
//       startTime: e.startTime,
//       endTime: e.endTime,
//       address: e.address,
//       taskerLevelId: e.taskerLevelId,
//     );

//     if (r.isSuccess) {
//       emit(state.copyWith(
//         createStatus: UserBookingCreateStatus.success,
//         createResponse: r.data,      // RegistrationResponse from repo
//         clearCreateError: true,
//       ));
//     } else {
//       emit(state.copyWith(
//         createStatus: UserBookingCreateStatus.failure,
//         createError: r.failure?.message ?? 'Failed to create booking',
//         clearCreateResponse: true,
//       ));
//     }
//   }
// }
