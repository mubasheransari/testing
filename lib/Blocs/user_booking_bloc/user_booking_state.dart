import 'package:equatable/equatable.dart';
import 'package:taskoon/Models/auth_model.dart';
import 'package:taskoon/Models/booking_create_response.dart';
import 'package:taskoon/Models/booking_find_response.dart'; // ✅ add





enum UserBookingCreateStatus { initial, submitting, success, failure }
enum UserBookingCancelStatus { initial, submitting, success, failure }
enum UserLocationUpdateStatus { initial, updating, success, failure }
enum FindingTaskerStatus { initial, updating, success, failure }
enum ChangeAvailabilityStatusEnum { initial, updating, success, failure }
enum AcceptBookingEnum { initial, updating, success, failure }

// ignore: must_be_immutable
class UserBookingState extends Equatable {
  // ✅ NEW CREATE BOOKING RESPONSE (API returns result as LIST)
  final BookingCreateResponse? bookingCreateResponse;

  // ----- find tasker -----
  final BookingFindResponse? bookingFindResponse;
  final String? findingTaskerError;

  // ----- statuses -----
  final UserBookingCreateStatus createStatus;
  final UserBookingCancelStatus userBookingCancelStatus;
  final ChangeAvailabilityStatusEnum changeAvailabilityStatusEnum;
  final FindingTaskerStatus findingTaskerStatus;
  final AcceptBookingEnum acceptBookingEnum;

  // ----- create booking API response (your existing generic response if used elsewhere) -----
  final RegistrationResponse? createResponse;
  final String? createError;

  // ----- location update -----
  final UserLocationUpdateStatus locationStatus;
  final double? lastLatitude;
  final double? lastLongitude;
  final String? locationError;

  // ----- change availability -----
  final String? changeAvailabilityError;

  // ----- accept booking -----
  final String? acceptBookingError;

  // ✅ Accept booking success payload/message
  final RegistrationResponse? acceptBookingResponse;
  final String? acceptBookingMessage;

  const UserBookingState({
    this.bookingCreateResponse,

    // find tasker
    this.bookingFindResponse,
    this.findingTaskerError,

    // statuses
    this.acceptBookingEnum = AcceptBookingEnum.initial,
    this.changeAvailabilityStatusEnum = ChangeAvailabilityStatusEnum.initial,
    this.createStatus = UserBookingCreateStatus.initial,
    this.findingTaskerStatus = FindingTaskerStatus.initial,
    this.userBookingCancelStatus = UserBookingCancelStatus.initial,

    // create booking API
    this.createResponse,
    this.createError,

    // location
    this.locationStatus = UserLocationUpdateStatus.initial,
    this.lastLatitude,
    this.lastLongitude,
    this.locationError,

    // accept booking
    this.acceptBookingError,
    this.acceptBookingResponse,
    this.acceptBookingMessage,

    // availability
    this.changeAvailabilityError,
  });

  UserBookingState copyWith({
    // statuses
    AcceptBookingEnum? acceptBookingEnum,
    ChangeAvailabilityStatusEnum? changeAvailabilityStatusEnum,
    FindingTaskerStatus? findingTaskerStatus,
    UserBookingCreateStatus? createStatus,
    UserBookingCancelStatus? userBookingCancelStatus,

    // ✅ create booking response (NEW)
    BookingCreateResponse? bookingCreateResponse,
    bool clearBookingCreateResponse = false,

    // find tasker
    BookingFindResponse? bookingFindResponse,
    String? findingTaskerError,
    bool clearBookingFindResponse = false,
    bool clearFindingTaskerError = false,

    // create booking API
    RegistrationResponse? createResponse,
    String? createError,
    bool clearCreateResponse = false,
    bool clearCreateError = false,

    // location
    UserLocationUpdateStatus? locationStatus,
    double? lastLatitude,
    double? lastLongitude,
    String? locationError,
    bool clearLocationError = false,

    // accept booking
    String? acceptBookingError,
    RegistrationResponse? acceptBookingResponse,
    String? acceptBookingMessage,
    bool clearAcceptBookingError = false,
    bool clearAcceptBookingResponse = false,
    bool clearAcceptBookingMessage = false,

    // availability
    String? changeAvailabilityError,
  }) {
    return UserBookingState(
      // statuses
      acceptBookingEnum: acceptBookingEnum ?? this.acceptBookingEnum,
      changeAvailabilityStatusEnum:
          changeAvailabilityStatusEnum ?? this.changeAvailabilityStatusEnum,
      findingTaskerStatus: findingTaskerStatus ?? this.findingTaskerStatus,
      createStatus: createStatus ?? this.createStatus,
      userBookingCancelStatus:
          userBookingCancelStatus ?? this.userBookingCancelStatus,

      // ✅ create booking response
      bookingCreateResponse: clearBookingCreateResponse
          ? null
          : (bookingCreateResponse ?? this.bookingCreateResponse),

      // find tasker
      bookingFindResponse: clearBookingFindResponse
          ? null
          : (bookingFindResponse ?? this.bookingFindResponse),
      findingTaskerError: clearFindingTaskerError
          ? null
          : (findingTaskerError ?? this.findingTaskerError),

      // create booking API (existing)
      createResponse: clearCreateResponse
          ? null
          : (createResponse ?? this.createResponse),
      createError: clearCreateError ? null : (createError ?? this.createError),

      // location
      locationStatus: locationStatus ?? this.locationStatus,
      lastLatitude: lastLatitude ?? this.lastLatitude,
      lastLongitude: lastLongitude ?? this.lastLongitude,
      locationError: clearLocationError
          ? null
          : (locationError ?? this.locationError),

      // accept booking
      acceptBookingError: clearAcceptBookingError
          ? null
          : (acceptBookingError ?? this.acceptBookingError),

      acceptBookingResponse: clearAcceptBookingResponse
          ? null
          : (acceptBookingResponse ?? this.acceptBookingResponse),

      acceptBookingMessage: clearAcceptBookingMessage
          ? null
          : (acceptBookingMessage ?? this.acceptBookingMessage),

      // availability
      changeAvailabilityError:
          changeAvailabilityError ?? this.changeAvailabilityError,
    );
  }

  @override
  List<Object?> get props => [
        // cancel
        userBookingCancelStatus,

        // ✅ create booking (NEW)
        bookingCreateResponse,

        // find tasker
        bookingFindResponse,
        findingTaskerError,

        // accept booking
        acceptBookingEnum,
        acceptBookingError,
        acceptBookingResponse,
        acceptBookingMessage,

        // availability
        changeAvailabilityStatusEnum,
        changeAvailabilityError,

        // create booking API (existing)
        createStatus,
        createResponse,
        createError,

        // location
        locationStatus,
        lastLatitude,
        lastLongitude,
        locationError,

        // other
        findingTaskerStatus,
      ];
}


// enum UserBookingCreateStatus { initial, submitting, success, failure }

// enum UserBookingCancelStatus { initial, submitting, success, failure }

// enum UserLocationUpdateStatus { initial, updating, success, failure }

// enum FindingTaskerStatus { initial, updating, success, failure }

// enum ChangeAvailabilityStatusEnum { initial, updating, success, failure }

// enum AcceptBookingEnum { initial, updating, success, failure }

// // ignore: must_be_immutable
// class UserBookingState extends Equatable {
//   final BookingCreateResponse? bookingCreateResponse;

//   // ----- find tasker -----
//   final BookingFindResponse? bookingFindResponse;
//   final String? findingTaskerError;

//   // ----- statuses -----
//   final UserBookingCreateStatus createStatus;
//   UserBookingCancelStatus userBookingCancelStatus;
//   final ChangeAvailabilityStatusEnum changeAvailabilityStatusEnum;
//   final FindingTaskerStatus findingTaskerStatus;
//   final AcceptBookingEnum acceptBookingEnum;

//   // ----- create booking API response -----
//   final RegistrationResponse? createResponse;
//   final String? createError;

//   // ----- location update -----
//   final UserLocationUpdateStatus locationStatus;
//   final double? lastLatitude;
//   final double? lastLongitude;
//   final String? locationError;

//   // ----- change availability -----
//   final String? changeAvailabilityError;

//   // ----- accept booking -----
//   final String? acceptBookingError;

//   // ✅ NEW (Accept Booking success payload/message)
//   final RegistrationResponse? acceptBookingResponse;
//   final String? acceptBookingMessage;

//   UserBookingState({
//     this.bookingCreateResponse,

//     // find tasker
//     this.bookingFindResponse,
//     this.findingTaskerError,

//     // statuses
//     this.acceptBookingEnum = AcceptBookingEnum.initial,
//     this.changeAvailabilityStatusEnum = ChangeAvailabilityStatusEnum.initial,
//     this.createStatus = UserBookingCreateStatus.initial,
//     this.findingTaskerStatus = FindingTaskerStatus.initial,

//     // create booking API
//     this.createResponse,
//     this.createError,
//     this.userBookingCancelStatus = UserBookingCancelStatus.initial,

//     // location
//     this.locationStatus = UserLocationUpdateStatus.initial,
//     this.lastLatitude,
//     this.lastLongitude,
//     this.locationError,

//     // accept booking
//     this.acceptBookingError,
//     this.acceptBookingResponse,
//     this.acceptBookingMessage,

//     // availability
//     this.changeAvailabilityError,
//   });

//   UserBookingState copyWith({
//     // statuses
//     AcceptBookingEnum? acceptBookingEnum,
//     ChangeAvailabilityStatusEnum? changeAvailabilityStatusEnum,
//     FindingTaskerStatus? findingTaskerStatus,
//     UserBookingCreateStatus? createStatus,
//     UserBookingCancelStatus? userBookingCancelStatus,

//     // local models
//     BookingCreateResponse? bookingCreateResponse,

//     // find tasker
//     BookingFindResponse? bookingFindResponse,
//     String? findingTaskerError,
//     bool clearBookingFindResponse = false,
//     bool clearFindingTaskerError = false,

//     // create booking API
//     RegistrationResponse? createResponse,
//     String? createError,
//     bool clearCreateResponse = false,
//     bool clearCreateError = false,

//     // location
//     UserLocationUpdateStatus? locationStatus,
//     double? lastLatitude,
//     double? lastLongitude,
//     String? locationError,
//     bool clearLocationError = false,

//     // accept booking
//     String? acceptBookingError,
//     RegistrationResponse? acceptBookingResponse,
//     String? acceptBookingMessage,
//     bool clearAcceptBookingError = false,
//     bool clearAcceptBookingResponse = false,
//     bool clearAcceptBookingMessage = false,

//     // availability
//     String? changeAvailabilityError,
//   }) {
//     return UserBookingState(
//       userBookingCancelStatus:
//           userBookingCancelStatus ?? this.userBookingCancelStatus,
//       // statuses
//       acceptBookingEnum: acceptBookingEnum ?? this.acceptBookingEnum,
//       changeAvailabilityStatusEnum:
//           changeAvailabilityStatusEnum ?? this.changeAvailabilityStatusEnum,
//       findingTaskerStatus: findingTaskerStatus ?? this.findingTaskerStatus,
//       createStatus: createStatus ?? this.createStatus,

//       // local models
//       bookingCreateResponse:
//           bookingCreateResponse ?? this.bookingCreateResponse,

//       // find tasker
//       bookingFindResponse: clearBookingFindResponse
//           ? null
//           : (bookingFindResponse ?? this.bookingFindResponse),
//       findingTaskerError: clearFindingTaskerError
//           ? null
//           : (findingTaskerError ?? this.findingTaskerError),

//       // create booking API
//       createResponse: clearCreateResponse
//           ? null
//           : (createResponse ?? this.createResponse),
//       createError: clearCreateError ? null : (createError ?? this.createError),

//       // location
//       locationStatus: locationStatus ?? this.locationStatus,
//       lastLatitude: lastLatitude ?? this.lastLatitude,
//       lastLongitude: lastLongitude ?? this.lastLongitude,
//       locationError: clearLocationError
//           ? null
//           : (locationError ?? this.locationError),

//       // accept booking
//       acceptBookingError: clearAcceptBookingError
//           ? null
//           : (acceptBookingError ?? this.acceptBookingError),

//       acceptBookingResponse: clearAcceptBookingResponse
//           ? null
//           : (acceptBookingResponse ?? this.acceptBookingResponse),

//       acceptBookingMessage: clearAcceptBookingMessage
//           ? null
//           : (acceptBookingMessage ?? this.acceptBookingMessage),

//       // availability
//       changeAvailabilityError:
//           changeAvailabilityError ?? this.changeAvailabilityError,
//     );
//   }

//   @override
//   List<Object?> get props => [
//     userBookingCancelStatus,
//     bookingCreateResponse,

//     // find tasker
//     bookingFindResponse,
//     findingTaskerError,

//     // accept booking
//     acceptBookingEnum,
//     acceptBookingError,
//     acceptBookingResponse,
//     acceptBookingMessage,

//     // availability
//     changeAvailabilityStatusEnum,
//     changeAvailabilityError,

//     // create booking
//     createStatus,
//     createResponse,
//     createError,

//     // location
//     locationStatus,
//     lastLatitude,
//     lastLongitude,
//     locationError,

//     // other
//     findingTaskerStatus,
//   ];
// }
