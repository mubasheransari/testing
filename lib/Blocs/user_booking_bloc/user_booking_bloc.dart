import 'package:bloc/bloc.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_event.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_state.dart';
import 'package:taskoon/Repository/auth_repository.dart';


class UserBookingBloc extends Bloc<UserBookingEvent, UserBookingState> {
  final AuthRepository repo;

  UserBookingBloc(this.repo) : super( UserBookingState()) {
    on<CreateUserBookingRequested>(_onCreateUserBookingRequested);
    on<UpdateUserLocationRequested>(_onUpdateUserLocationRequested);
    on<FindingTaskerRequested>(findingTaskerRequested);
    on<ChangeAvailabilityStatus>(_changeAvailabilityStatus);
  }


Future<void> findingTaskerRequested(
  FindingTaskerRequested e,
  Emitter<UserBookingState> emit,
)async{

emit(state.copyWith(findingTaskerStatus:  FindingTaskerStatus.initial));
 final r = await repo.findBooking(bookingDetailId: e.bookingId);
   if (r.isSuccess) {
    emit(state.copyWith(findingTaskerStatus:  FindingTaskerStatus.success));
   }
   else{
    emit(state.copyWith(findingTaskerStatus:  FindingTaskerStatus.failure));
   }
}

Future<void> _onCreateUserBookingRequested(
  CreateUserBookingRequested e,
  Emitter<UserBookingState> emit,
) async {
  print('📥 [Bloc] CreateUserBookingRequested: '
      'userId=${e.userId}, subCategoryId=${e.subCategoryId}, '
      'bookingDate=${e.bookingDate.toIso8601String()}, '
      'start=${e.startTime}, end=${e.endTime}, '
      'address=${e.address}, taskerLevelId=${e.taskerLevelId}, '
      'currency=${e.currency}, paymentType=${e.paymentType}, '
      'serviceType=${e.serviceType}, paymentMethod=${e.paymentMethod}');

  emit(state.copyWith(
    createStatus: UserBookingCreateStatus.submitting,
    clearCreateError: true,
    clearCreateResponse: true,
  ));

  // ⬇️ Now returns Result<BookingCreateResponse>
  final r = await repo.createBooking(
    userId: e.userId,
    subCategoryId:1032, //e.subCategoryId, 123
    bookingDate: e.bookingDate,
    startTime: e.startTime,
    endTime: e.endTime,
    address: e.address,
    taskerLevelId:1 //e.taskerLevelId,
    // currency: e.currency,
    // paymentType: e.paymentType,
    // serviceType: e.serviceType,
    // paymentMethod: e.paymentMethod,
  );

  if (r.isSuccess) {
    print('✅ [Bloc] createBooking SUCCESS');

    // r.data is BookingCreateResponse?
    final bookingResp = r.data; // BookingCreateResponse?

    emit(state.copyWith(
      createStatus: UserBookingCreateStatus.success,
   bookingCreateResponse: bookingResp, // change field type to BookingCreateResponse?
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

//   Future<void> _onCreateUserBookingRequested(
//   CreateUserBookingRequested e,
//   Emitter<UserBookingState> emit,
// ) async {
//   // 🔍 Debug log
//   print('📥 [Bloc] CreateUserBookingRequested: '
//       'userId=${e.userId}, subCategoryId=${e.subCategoryId}, '
//       'bookingDate=${e.bookingDate.toIso8601String()}, '
//       'start=${e.startTime}, end=${e.endTime}, '
//       'address=${e.address}, taskerLevelId=${e.taskerLevelId}, '
//       'currency=${e.currency}, paymentType=${e.paymentType}, '
//       'serviceType=${e.serviceType}, paymentMethod=${e.paymentMethod}');

//   emit(state.copyWith(
//     createStatus: UserBookingCreateStatus.submitting,
//     clearCreateError: true,
//     clearCreateResponse: true,
//   ));

//   final r = await repo.createBooking(
//     userId: e.userId,
//     subCategoryId: e.subCategoryId,
//     bookingDate: e.bookingDate,
//     startTime: e.startTime,
//     endTime: e.endTime,
//     address: e.address,
//     taskerLevelId: e.taskerLevelId,
//     // currency: e.currency,
//     // paymentType: e.paymentType,
//     // serviceType: e.serviceType,
//     // paymentMethod: e.paymentMethod,
//   );

//   if (r.isSuccess) {
//     print('✅ [Bloc] createBooking SUCCESS');

//     emit(state.copyWith(
//       createStatus: UserBookingCreateStatus.success,
//       createResponse: r.data,
//       clearCreateError: true,
//     ));
//   } else {
//     print('❌ [Bloc] createBooking FAILURE: ${r.failure?.message}');

//     emit(state.copyWith(
//       createStatus: UserBookingCreateStatus.failure,
//       createError: r.failure?.message ?? 'Failed to create booking',
//       clearCreateResponse: true,
//     ));
//   }
// }


  // ---------- /api/Booking/Create ----------
  // Future<void> _onCreateUserBookingRequested(
  //   CreateUserBookingRequested e,
  //   Emitter<UserBookingState> emit,
  // ) async {
  //   emit(state.copyWith(
  //     createStatus: UserBookingCreateStatus.submitting,
  //     clearCreateError: true,
  //     clearCreateResponse: true,
  //   ));

  //   final r = await repo.createBooking(
  //     userId: e.userId,
  //     subCategoryId: e.subCategoryId,
  //     bookingDate: e.bookingDate,
  //     startTime: e.startTime,
  //     endTime: e.endTime,
  //     address: e.address,
  //     taskerLevelId: e.taskerLevelId,
  //   );

  //   if (r.isSuccess) {
  //     emit(state.copyWith(
  //       createStatus: UserBookingCreateStatus.success,
  //       createResponse: r.data,
  //       clearCreateError: true,
  //     ));
  //   } else {
  //     emit(state.copyWith(
  //       createStatus: UserBookingCreateStatus.failure,
  //       createError: r.failure?.message ?? 'Failed to create booking',
  //       clearCreateResponse: true,
  //     ));
  //   }
  // }

Future<void> _onUpdateUserLocationRequested(
  UpdateUserLocationRequested e,
  Emitter<UserBookingState> emit,
) async {
  // print('📥 [Bloc] UpdateUserLocationRequested received: '
  //       'userId=${e.userId}, lat=${e.latitude}, lng=${e.longitude}');
  //         print('📥 [Bloc] UpdateUserLocationRequested received: '
  //       'userId=${e.userId}, lat=${e.latitude}, lng=${e.longitude}');
  //         print('📥 [Bloc] UpdateUserLocationRequested received: '
  //       'userId=${e.userId}, lat=${e.latitude}, lng=${e.longitude}');
  //         print('📥 [Bloc] UpdateUserLocationRequested received: '
  //       'userId=${e.userId}, lat=${e.latitude}, lng=${e.longitude}');
  //         print('📥 [Bloc] UpdateUserLocationRequested received: '
  //       'userId=${e.userId}, lat=${e.latitude}, lng=${e.longitude}');

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
    // print('✅ [Bloc] updateUserLocation SUCCESS');
    //  print('✅ [Bloc] updateUserLocation SUCCESS');
    //      print('✅ [Bloc] updateUserLocation SUCCESS');
    //  print('✅ [Bloc] updateUserLocation SUCCESS');
    //      print('✅ [Bloc] updateUserLocation SUCCESS');
    //  print('✅ [Bloc] updateUserLocation SUCCESS');
    //      print('✅ [Bloc] updateUserLocation SUCCESS');
    //  print('✅ [Bloc] updateUserLocation SUCCESS');
    //      print('✅ [Bloc] updateUserLocation SUCCESS');
    //  print('✅ [Bloc] updateUserLocation SUCCESS');

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

Future<void> _changeAvailabilityStatus(
  ChangeAvailabilityStatus e,
  Emitter<UserBookingState> emit,
) async {


  emit(state.copyWith(
    changeAvailabilityStatusEnum: ChangeAvailabilityStatusEnum.initial,
   // clearLocationError: true,
  ));

  final r = await repo.changeAvailbilityStatusTasker(
    userId: e.userId
  );

  if (r.isSuccess) {
    print('✅ [Bloc] _changeAvailabilityStatus SUCCESS');
    print('✅ [Bloc] _changeAvailabilityStatus SUCCESS');
      print('✅ [Bloc] _changeAvailabilityStatus SUCCESS');
    print('✅ [Bloc] _changeAvailabilityStatus SUCCESS');

    emit(state.copyWith(
      changeAvailabilityStatusEnum: ChangeAvailabilityStatusEnum.success,
     // clearLocationError: true,
    ));
  } else {
    print('❌ [Bloc] _changeAvailabilityStatus FAILURE: ${r.failure?.message}');
    print('❌ [Bloc] _changeAvailabilityStatus FAILURE: ${r.failure?.message}');
    print('❌ [Bloc] _changeAvailabilityStatus FAILURE: ${r.failure?.message}');
        print('❌ [Bloc] _changeAvailabilityStatus FAILURE: ${r.failure?.message}');

    
    emit(state.copyWith(
    changeAvailabilityStatusEnum: ChangeAvailabilityStatusEnum.failure,
      changeAvailabilityError: r.failure?.message ?? 'Failed to update user location',
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
