import 'package:equatable/equatable.dart';
import 'package:taskoon/Models/auth_model.dart';


import 'package:equatable/equatable.dart';

// For booking create
enum UserBookingCreateStatus { initial, submitting, success, failure }

// For address / location update
enum UserLocationUpdateStatus { initial, updating, success, failure }

class UserBookingState extends Equatable {
  // ----- booking create -----
  final UserBookingCreateStatus createStatus;
  final RegistrationResponse? createResponse;
  final String? createError;

  // ----- user location update -----
  final UserLocationUpdateStatus locationStatus;
  final double? lastLatitude;
  final double? lastLongitude;
  final String? locationError;

  const UserBookingState({
    this.createStatus = UserBookingCreateStatus.initial,
    this.createResponse,
    this.createError,
    this.locationStatus = UserLocationUpdateStatus.initial,
    this.lastLatitude,
    this.lastLongitude,
    this.locationError,
  });

  UserBookingState copyWith({
    // booking create
    UserBookingCreateStatus? createStatus,
    RegistrationResponse? createResponse,
    String? createError,
    bool clearCreateResponse = false,
    bool clearCreateError = false,

    // location update
    UserLocationUpdateStatus? locationStatus,
    double? lastLatitude,
    double? lastLongitude,
    String? locationError,
    bool clearLocationError = false,
  }) {
    return UserBookingState(
      // booking create
      createStatus: createStatus ?? this.createStatus,
      createResponse:
          clearCreateResponse ? null : (createResponse ?? this.createResponse),
      createError:
          clearCreateError ? null : (createError ?? this.createError),

      // location update
      locationStatus: locationStatus ?? this.locationStatus,
      lastLatitude: lastLatitude ?? this.lastLatitude,
      lastLongitude: lastLongitude ?? this.lastLongitude,
      locationError:
          clearLocationError ? null : (locationError ?? this.locationError),
    );
  }

  @override
  List<Object?> get props => [
        // booking create
        createStatus,
        createResponse,
        createError,
        // location update
        locationStatus,
        lastLatitude,
        lastLongitude,
        locationError,
      ];
}


// // Booking create status
// enum UserBookingCreateStatus { initial, submitting, success, failure }

// class UserBookingState extends Equatable {
//   /// Status of POST /api/Booking/Create
//   final UserBookingCreateStatus createStatus;

//   /// Response from backend (same type you used in repo for createBooking)
//   final RegistrationResponse? createResponse;

//   /// Error message for create booking
//   final String? createError;

//   const UserBookingState({
//     this.createStatus = UserBookingCreateStatus.initial,
//     this.createResponse,
//     this.createError,
//   });

//   UserBookingState copyWith({
//     UserBookingCreateStatus? createStatus,
//     RegistrationResponse? createResponse,
//     String? createError,
//     bool clearCreateResponse = false,
//     bool clearCreateError = false,
//   }) {
//     return UserBookingState(
//       createStatus: createStatus ?? this.createStatus,
//       createResponse:
//           clearCreateResponse ? null : (createResponse ?? this.createResponse),
//       createError:
//           clearCreateError ? null : (createError ?? this.createError),
//     );
//   }

//   @override
//   List<Object?> get props => [
//         createStatus,
//         createResponse,
//         createError,
//       ];
// }
