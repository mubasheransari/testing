import 'package:equatable/equatable.dart';
import 'package:taskoon/Models/auth_model.dart';
import 'package:taskoon/Models/booking_create_response.dart';
import 'package:taskoon/Models/booking_find_response.dart';
import 'package:taskoon/Models/payment_intent_response.dart';

import 'package:equatable/equatable.dart';
import 'package:taskoon/Models/auth_model.dart';
import 'package:taskoon/Models/booking_create_response.dart';
import 'package:taskoon/Models/booking_find_response.dart';
import 'package:taskoon/Models/payment_intent_response.dart';
import 'package:taskoon/Models/sos/start_sos_response.dart';



enum StartSosStatus { initial, submitting, success, failure }
enum UpdateSosLocationStatus { initial, submitting, success, failure }
enum CreatePaymentIntentStatus { initial, submitting, success, failure }

enum UserBookingCreateStatus { initial, submitting, success, failure }
enum UserBookingCancelStatus { initial, submitting, success, failure }
enum UserLocationUpdateStatus { initial, updating, success, failure }
enum FindingTaskerStatus { initial, updating, success, failure }
enum ChangeAvailabilityStatusEnum { initial, updating, success, failure }
enum AcceptBookingEnum { initial, updating, success, failure }

class UserBookingState extends Equatable {
  // =========================
  // ✅ SOS (NEW)
  // =========================
  final StartSosStatus startSosStatus;
  final StartSosResult? startSosResult;
  final String? startSosError;

  final UpdateSosLocationStatus updateSosLocationStatus;
  final String? updateSosLocationError;

  // (optional legacy if you still use RegistrationResponse elsewhere)
  final RegistrationResponse? startSosResponse;
  final RegistrationResponse? updateSosLocationResponse;

  // =========================
  // ✅ Payment Intent
  // =========================
  final CreatePaymentIntentStatus createPaymentIntentStatus;
  final PaymentIntentResponse? paymentIntentResponse;
  final String? paymentIntentError;

  // =========================
  // ✅ Booking
  // =========================
  final BookingCreateResponse? bookingCreateResponse;

  final BookingFindResponse? bookingFindResponse;
  final String? findingTaskerError;

  final UserBookingCreateStatus createStatus;
  final UserBookingCancelStatus userBookingCancelStatus;
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
  final RegistrationResponse? acceptBookingResponse;
  final String? acceptBookingMessage;

  const UserBookingState({
    // SOS
    this.startSosStatus = StartSosStatus.initial,
    this.startSosResult,
    this.startSosError,
    this.updateSosLocationStatus = UpdateSosLocationStatus.initial,
    this.updateSosLocationError,
    this.startSosResponse,
    this.updateSosLocationResponse,

    // payment
    this.createPaymentIntentStatus = CreatePaymentIntentStatus.initial,
    this.paymentIntentResponse,
    this.paymentIntentError,

    // booking create
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
    // =========================
    // ✅ SOS
    // =========================
    StartSosStatus? startSosStatus,
    StartSosResult? startSosResult,
    String? startSosError,
    bool clearStartSosResult = false,
    bool clearStartSosError = false,

    UpdateSosLocationStatus? updateSosLocationStatus,
    String? updateSosLocationError,
    bool clearUpdateSosLocationError = false,

    // optional legacy RegistrationResponse
    RegistrationResponse? startSosResponse,
    bool clearStartSosResponse = false,

    RegistrationResponse? updateSosLocationResponse,
    bool clearUpdateSosLocationResponse = false,

    // =========================
    // ✅ Payment Intent
    // =========================
    CreatePaymentIntentStatus? createPaymentIntentStatus,
    PaymentIntentResponse? paymentIntentResponse,
    String? paymentIntentError,
    bool clearPaymentIntentResponse = false,
    bool clearPaymentIntentError = false,

    // =========================
    // ✅ Booking statuses
    // =========================
    AcceptBookingEnum? acceptBookingEnum,
    ChangeAvailabilityStatusEnum? changeAvailabilityStatusEnum,
    FindingTaskerStatus? findingTaskerStatus,
    UserBookingCreateStatus? createStatus,
    UserBookingCancelStatus? userBookingCancelStatus,

    // booking create response
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
      // =========================
      // ✅ SOS
      // =========================
      startSosStatus: startSosStatus ?? this.startSosStatus,
      startSosResult:
          clearStartSosResult ? null : (startSosResult ?? this.startSosResult),
      startSosError: clearStartSosError ? null : (startSosError ?? this.startSosError),

      updateSosLocationStatus:
          updateSosLocationStatus ?? this.updateSosLocationStatus,
      updateSosLocationError: clearUpdateSosLocationError
          ? null
          : (updateSosLocationError ?? this.updateSosLocationError),

      startSosResponse: clearStartSosResponse
          ? null
          : (startSosResponse ?? this.startSosResponse),

      updateSosLocationResponse: clearUpdateSosLocationResponse
          ? null
          : (updateSosLocationResponse ?? this.updateSosLocationResponse),

      // =========================
      // ✅ Payment intent
      // =========================
      createPaymentIntentStatus:
          createPaymentIntentStatus ?? this.createPaymentIntentStatus,

      paymentIntentResponse: clearPaymentIntentResponse
          ? null
          : (paymentIntentResponse ?? this.paymentIntentResponse),

      paymentIntentError: clearPaymentIntentError
          ? null
          : (paymentIntentError ?? this.paymentIntentError),

      // =========================
      // ✅ Other statuses
      // =========================
      acceptBookingEnum: acceptBookingEnum ?? this.acceptBookingEnum,
      changeAvailabilityStatusEnum:
          changeAvailabilityStatusEnum ?? this.changeAvailabilityStatusEnum,
      findingTaskerStatus: findingTaskerStatus ?? this.findingTaskerStatus,
      createStatus: createStatus ?? this.createStatus,
      userBookingCancelStatus:
          userBookingCancelStatus ?? this.userBookingCancelStatus,

      // booking create response
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

      // create booking API
      createResponse:
          clearCreateResponse ? null : (createResponse ?? this.createResponse),
      createError: clearCreateError ? null : (createError ?? this.createError),

      // location
      locationStatus: locationStatus ?? this.locationStatus,
      lastLatitude: lastLatitude ?? this.lastLatitude,
      lastLongitude: lastLongitude ?? this.lastLongitude,
      locationError:
          clearLocationError ? null : (locationError ?? this.locationError),

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
        // payment
        createPaymentIntentStatus,
        paymentIntentResponse,
        paymentIntentError,

        // ✅ SOS
        startSosStatus,
        startSosResult,
        startSosError,
        updateSosLocationStatus,
        updateSosLocationError,
        startSosResponse,
        updateSosLocationResponse,

        // cancel
        userBookingCancelStatus,

        // create booking
        bookingCreateResponse,

        // find tasker
        bookingFindResponse,
        findingTaskerError,
        findingTaskerStatus,

        // accept booking
        acceptBookingEnum,
        acceptBookingError,
        acceptBookingResponse,
        acceptBookingMessage,

        // availability
        changeAvailabilityStatusEnum,
        changeAvailabilityError,

        // create booking API
        createStatus,
        createResponse,
        createError,

        // location
        locationStatus,
        lastLatitude,
        lastLongitude,
        locationError,
      ];
}