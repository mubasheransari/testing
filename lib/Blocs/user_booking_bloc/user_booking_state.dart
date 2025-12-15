import 'package:equatable/equatable.dart';
import 'package:taskoon/Models/auth_model.dart';
import 'package:taskoon/Models/booking_create_response.dart';


import 'package:equatable/equatable.dart';
import 'package:taskoon/Models/auth_model.dart';
import 'package:taskoon/Models/booking_create_response.dart';
import 'package:taskoon/Models/booking_find_response.dart'; // ✅ add

enum UserBookingCreateStatus { initial, submitting, success, failure }
enum UserLocationUpdateStatus { initial, updating, success, failure }
enum FindingTaskerStatus { initial, updating, success, failure }
enum ChangeAvailabilityStatusEnum { initial, updating, success, failure }
enum AcceptBookingEnum { initial, updating, success, failure }

// ignore: must_be_immutable
class UserBookingState extends Equatable {
  BookingCreateResponse? bookingCreateResponse;

  // ✅ NEW
  final BookingFindResponse? bookingFindResponse;
  final String? findingTaskerError;

  final UserBookingCreateStatus createStatus;
  final ChangeAvailabilityStatusEnum changeAvailabilityStatusEnum;
  final FindingTaskerStatus findingTaskerStatus;
  final AcceptBookingEnum acceptBookingEnum;

  final RegistrationResponse? createResponse;
  final String? createError;

  final UserLocationUpdateStatus locationStatus;
  final double? lastLatitude;
  final double? lastLongitude;
  final String? locationError;

  final String? changeAvailabilityError;
  final String? acceptBookingError;

  UserBookingState({
    this.bookingCreateResponse,

    // ✅ NEW
    this.bookingFindResponse,
    this.findingTaskerError,

    this.acceptBookingEnum = AcceptBookingEnum.initial,
    this.changeAvailabilityStatusEnum = ChangeAvailabilityStatusEnum.initial,
    this.createStatus = UserBookingCreateStatus.initial,
    this.findingTaskerStatus = FindingTaskerStatus.initial,
    this.createResponse,
    this.createError,
    this.locationStatus = UserLocationUpdateStatus.initial,
    this.lastLatitude,
    this.lastLongitude,
    this.locationError,
    this.acceptBookingError,
    this.changeAvailabilityError,
  });

  UserBookingState copyWith({
    AcceptBookingEnum? acceptBookingEnum,
    ChangeAvailabilityStatusEnum? changeAvailabilityStatusEnum,
    FindingTaskerStatus? findingTaskerStatus,

    BookingCreateResponse? bookingCreateResponse,

    // ✅ NEW
    BookingFindResponse? bookingFindResponse,
    String? findingTaskerError,
    bool clearBookingFindResponse = false,
    bool clearFindingTaskerError = false,

    UserBookingCreateStatus? createStatus,
    RegistrationResponse? createResponse,
    String? createError,
    bool clearCreateResponse = false,
    bool clearCreateError = false,

    UserLocationUpdateStatus? locationStatus,
    double? lastLatitude,
    double? lastLongitude,
    String? locationError,
    bool clearLocationError = false,

    String? acceptBookingError,
    String? changeAvailabilityError,
  }) {
    return UserBookingState(
      acceptBookingEnum: acceptBookingEnum ?? this.acceptBookingEnum,
      changeAvailabilityError:
          changeAvailabilityError ?? this.changeAvailabilityError,
      changeAvailabilityStatusEnum:
          changeAvailabilityStatusEnum ?? this.changeAvailabilityStatusEnum,

      findingTaskerStatus: findingTaskerStatus ?? this.findingTaskerStatus,

      bookingCreateResponse: bookingCreateResponse ?? this.bookingCreateResponse,

      // ✅ NEW
      bookingFindResponse: clearBookingFindResponse
          ? null
          : (bookingFindResponse ?? this.bookingFindResponse),
      findingTaskerError: clearFindingTaskerError
          ? null
          : (findingTaskerError ?? this.findingTaskerError),

      createStatus: createStatus ?? this.createStatus,
      createResponse:
          clearCreateResponse ? null : (createResponse ?? this.createResponse),
      createError: clearCreateError ? null : (createError ?? this.createError),

      locationStatus: locationStatus ?? this.locationStatus,
      lastLatitude: lastLatitude ?? this.lastLatitude,
      lastLongitude: lastLongitude ?? this.lastLongitude,
      acceptBookingError: acceptBookingError ?? this.acceptBookingError,

      locationError:
          clearLocationError ? null : (locationError ?? this.locationError),
    );
  }

  @override
  List<Object?> get props => [
        bookingCreateResponse,

        // ✅ NEW
        bookingFindResponse,
        findingTaskerError,

        acceptBookingError,
        acceptBookingEnum,
        changeAvailabilityError,
        changeAvailabilityStatusEnum,
        findingTaskerStatus,
        createStatus,
        createResponse,
        createError,
        locationStatus,
        lastLatitude,
        lastLongitude,
        locationError,
      ];
}


// enum UserBookingCreateStatus { initial, submitting, success, failure }

// enum UserLocationUpdateStatus { initial, updating, success, failure }

// enum FindingTaskerStatus { initial, updating, success, failure }

// enum ChangeAvailabilityStatusEnum { initial, updating, success, failure }

// enum AcceptBookingEnum { initial, updating, success, failure }

// // ignore: must_be_immutable
// class UserBookingState extends Equatable {
//   BookingCreateResponse? bookingCreateResponse;
//   final UserBookingCreateStatus createStatus;
//   final ChangeAvailabilityStatusEnum changeAvailabilityStatusEnum;
//   final FindingTaskerStatus findingTaskerStatus;
//   final AcceptBookingEnum acceptBookingEnum;
//   final RegistrationResponse? createResponse;
//   final String? createError;
//   final UserLocationUpdateStatus locationStatus;
//   final double? lastLatitude;
//   final double? lastLongitude;
//   final String? locationError;
//   final String? changeAvailabilityError;
//   String? acceptBookingError;

//   UserBookingState({
//     this.bookingCreateResponse,
//     this.acceptBookingEnum = AcceptBookingEnum.initial,
//     this.changeAvailabilityStatusEnum = ChangeAvailabilityStatusEnum.initial,
//     this.createStatus = UserBookingCreateStatus.initial,
//     this.findingTaskerStatus = FindingTaskerStatus.initial,
//     this.createResponse,
//     this.createError,
//     this.locationStatus = UserLocationUpdateStatus.initial,
//     this.lastLatitude,
//     this.lastLongitude,
//     this.locationError,
//   this.acceptBookingError,
//     this.changeAvailabilityError
//   });

//   UserBookingState copyWith({
//     AcceptBookingEnum ?acceptBookingEnum,
//     ChangeAvailabilityStatusEnum? changeAvailabilityStatusEnum,
//     FindingTaskerStatus? findingTaskerStatus,
//     BookingCreateResponse? bookingCreateResponse,
//     UserBookingCreateStatus? createStatus,
//     RegistrationResponse? createResponse,
//     String? createError,
//     bool clearCreateResponse = false,
//     bool clearCreateError = false,
//     UserLocationUpdateStatus? locationStatus,
//     double? lastLatitude,
//     double? lastLongitude,
//     String? locationError,
//     String? acceptBookingError,
//     bool clearLocationError = false,
//     String ? changeAvailabilityError
//   }) {
//     return UserBookingState(
//       acceptBookingEnum: acceptBookingEnum ?? this.acceptBookingEnum,
//       changeAvailabilityError: changeAvailabilityError ?? this.changeAvailabilityError,
//       changeAvailabilityStatusEnum: changeAvailabilityStatusEnum ?? this.changeAvailabilityStatusEnum,
//       findingTaskerStatus: findingTaskerStatus ?? this.findingTaskerStatus,
//       bookingCreateResponse:
//           bookingCreateResponse ?? this.bookingCreateResponse,
//       createStatus: createStatus ?? this.createStatus,
//       createResponse: clearCreateResponse
//           ? null
//           : (createResponse ?? this.createResponse),
//       createError: clearCreateError ? null : (createError ?? this.createError),
//       locationStatus: locationStatus ?? this.locationStatus,
//       lastLatitude: lastLatitude ?? this.lastLatitude,
//       lastLongitude: lastLongitude ?? this.lastLongitude,
//       acceptBookingError: acceptBookingError ?? this.acceptBookingError,
//       locationError: clearLocationError
//           ? null
//           : (locationError ?? this.locationError),
//     );
//   }

//   @override
//   List<Object?> get props => [
//     acceptBookingError,
//     acceptBookingEnum,
//     changeAvailabilityError,
//     changeAvailabilityStatusEnum,
//     findingTaskerStatus,
//     bookingCreateResponse,
//     createStatus,
//     createResponse,
//     createError,
//     locationStatus,
//     lastLatitude,
//     lastLongitude,
//     locationError,
//   ];
// }
