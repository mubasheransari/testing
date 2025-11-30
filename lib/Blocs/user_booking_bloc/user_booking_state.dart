import 'package:equatable/equatable.dart';
import 'package:taskoon/Models/auth_model.dart';

// Booking create status
enum UserBookingCreateStatus { initial, submitting, success, failure }

class UserBookingState extends Equatable {
  /// Status of POST /api/Booking/Create
  final UserBookingCreateStatus createStatus;

  /// Response from backend (same type you used in repo for createBooking)
  final RegistrationResponse? createResponse;

  /// Error message for create booking
  final String? createError;

  const UserBookingState({
    this.createStatus = UserBookingCreateStatus.initial,
    this.createResponse,
    this.createError,
  });

  UserBookingState copyWith({
    UserBookingCreateStatus? createStatus,
    RegistrationResponse? createResponse,
    String? createError,
    bool clearCreateResponse = false,
    bool clearCreateError = false,
  }) {
    return UserBookingState(
      createStatus: createStatus ?? this.createStatus,
      createResponse:
          clearCreateResponse ? null : (createResponse ?? this.createResponse),
      createError:
          clearCreateError ? null : (createError ?? this.createError),
    );
  }

  @override
  List<Object?> get props => [
        createStatus,
        createResponse,
        createError,
      ];
}
