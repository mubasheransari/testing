import 'package:equatable/equatable.dart';
import 'package:taskoon/Models/auth_model.dart';
import 'package:taskoon/Models/booking_create_response.dart';
import 'package:taskoon/Models/booking_find_response.dart';
import 'package:taskoon/Models/dashboard/tasker_dashboard.dart';
import 'package:taskoon/Models/dashboard/tasker_earnings_chart_model.dart';
import 'package:taskoon/Models/dashboard/tasker_earnings_stats_model.dart';
import 'package:taskoon/Models/payment_intent_response.dart';
import 'package:taskoon/Models/sos/start_sos_response.dart';
import 'package:equatable/equatable.dart';


enum TaskerEarningsStatsStatus { initial, loading, success, failure }

// ✅ NEW: Earnings Chart status
enum TaskerEarningsChartStatus { initial, loading, success, failure }

enum TaskerDashboardStatus { initial, loading, success, failure }

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
  // ✅ Dashboard
  final TaskerDashboardStatus taskerDashboardStatus;
  final TaskerDashboardResponse? taskerDashboardResponse;
  final String? taskerDashboardError;

  // ✅ Earnings Stats
  final TaskerEarningsStatsStatus taskerEarningsStatsStatus;
  final TaskerEarningsStatsResponse? taskerEarningsStatsResponse;
  final String? taskerEarningsStatsError;

  // ✅ NEW: Earnings Chart
  final TaskerEarningsChartStatus taskerEarningsChartStatus;
  final TaskerEarningsChartResponse? taskerEarningsChartResponse;
  final String? taskerEarningsChartError;

  // ✅ SOS
  final StartSosStatus startSosStatus;
  final StartSosResult? startSosResult;
  final String? startSosError;

  final UpdateSosLocationStatus updateSosLocationStatus;
  final String? updateSosLocationError;

  final RegistrationResponse? startSosResponse;
  final RegistrationResponse? updateSosLocationResponse;

  // ✅ payment
  final CreatePaymentIntentStatus createPaymentIntentStatus;
  final PaymentIntentResponse? paymentIntentResponse;
  final String? paymentIntentError;

  // booking create
  final BookingCreateResponse? bookingCreateResponse;

  // find tasker
  final BookingFindResponse? bookingFindResponse;
  final String? findingTaskerError;

  // statuses
  final UserBookingCreateStatus createStatus;
  final UserBookingCancelStatus userBookingCancelStatus;
  final UserLocationUpdateStatus locationStatus;
  final FindingTaskerStatus findingTaskerStatus;
  final ChangeAvailabilityStatusEnum changeAvailabilityStatusEnum;
  final AcceptBookingEnum acceptBookingEnum;

  // create booking API
  final RegistrationResponse? createResponse;
  final String? createError;

  // location
  final double? lastLatitude;
  final double? lastLongitude;
  final String? locationError;

  // availability
  final String? changeAvailabilityError;

  // accept booking
  final String? acceptBookingError;
  final RegistrationResponse? acceptBookingResponse;
  final String? acceptBookingMessage;

  const UserBookingState({
    // ✅ dashboard
    this.taskerDashboardStatus = TaskerDashboardStatus.initial,
    this.taskerDashboardResponse,
    this.taskerDashboardError,

    // ✅ earnings stats
    this.taskerEarningsStatsStatus = TaskerEarningsStatsStatus.initial,
    this.taskerEarningsStatsResponse,
    this.taskerEarningsStatsError,

    // ✅ NEW: earnings chart
    this.taskerEarningsChartStatus = TaskerEarningsChartStatus.initial,
    this.taskerEarningsChartResponse,
    this.taskerEarningsChartError,

    // ✅ SOS
    this.startSosStatus = StartSosStatus.initial,
    this.startSosResult,
    this.startSosError,
    this.updateSosLocationStatus = UpdateSosLocationStatus.initial,
    this.updateSosLocationError,
    this.startSosResponse,
    this.updateSosLocationResponse,

    // ✅ payment
    this.createPaymentIntentStatus = CreatePaymentIntentStatus.initial,
    this.paymentIntentResponse,
    this.paymentIntentError,

    // booking create response
    this.bookingCreateResponse,

    // find tasker
    this.bookingFindResponse,
    this.findingTaskerError,

    // statuses
    this.createStatus = UserBookingCreateStatus.initial,
    this.userBookingCancelStatus = UserBookingCancelStatus.initial,
    this.locationStatus = UserLocationUpdateStatus.initial,
    this.findingTaskerStatus = FindingTaskerStatus.initial,
    this.changeAvailabilityStatusEnum = ChangeAvailabilityStatusEnum.initial,
    this.acceptBookingEnum = AcceptBookingEnum.initial,

    // create booking API
    this.createResponse,
    this.createError,

    // location
    this.lastLatitude,
    this.lastLongitude,
    this.locationError,

    // availability
    this.changeAvailabilityError,

    // accept booking
    this.acceptBookingError,
    this.acceptBookingResponse,
    this.acceptBookingMessage,
  });

  UserBookingState copyWith({
    // ✅ dashboard
    TaskerDashboardStatus? taskerDashboardStatus,
    TaskerDashboardResponse? taskerDashboardResponse,
    String? taskerDashboardError,
    bool clearTaskerDashboardResponse = false,
    bool clearTaskerDashboardError = false,

    // ✅ earnings stats
    TaskerEarningsStatsStatus? taskerEarningsStatsStatus,
    TaskerEarningsStatsResponse? taskerEarningsStatsResponse,
    String? taskerEarningsStatsError,
    bool clearTaskerEarningsStatsResponse = false,
    bool clearTaskerEarningsStatsError = false,

    // ✅ NEW: earnings chart
    TaskerEarningsChartStatus? taskerEarningsChartStatus,
    TaskerEarningsChartResponse? taskerEarningsChartResponse,
    String? taskerEarningsChartError,
    bool clearTaskerEarningsChartResponse = false,
    bool clearTaskerEarningsChartError = false,

    // ✅ SOS
    StartSosStatus? startSosStatus,
    StartSosResult? startSosResult,
    String? startSosError,
    bool clearStartSosResult = false,
    bool clearStartSosError = false,

    UpdateSosLocationStatus? updateSosLocationStatus,
    String? updateSosLocationError,
    bool clearUpdateSosLocationError = false,

    RegistrationResponse? startSosResponse,
    bool clearStartSosResponse = false,

    RegistrationResponse? updateSosLocationResponse,
    bool clearUpdateSosLocationResponse = false,

    // ✅ payment
    CreatePaymentIntentStatus? createPaymentIntentStatus,
    PaymentIntentResponse? paymentIntentResponse,
    String? paymentIntentError,
    bool clearPaymentIntentResponse = false,
    bool clearPaymentIntentError = false,

    // ✅ statuses
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
      // ✅ dashboard
      taskerDashboardStatus: taskerDashboardStatus ?? this.taskerDashboardStatus,
      taskerDashboardResponse: clearTaskerDashboardResponse
          ? null
          : (taskerDashboardResponse ?? this.taskerDashboardResponse),
      taskerDashboardError: clearTaskerDashboardError
          ? null
          : (taskerDashboardError ?? this.taskerDashboardError),

      // ✅ earnings stats
      taskerEarningsStatsStatus:
          taskerEarningsStatsStatus ?? this.taskerEarningsStatsStatus,
      taskerEarningsStatsResponse: clearTaskerEarningsStatsResponse
          ? null
          : (taskerEarningsStatsResponse ?? this.taskerEarningsStatsResponse),
      taskerEarningsStatsError: clearTaskerEarningsStatsError
          ? null
          : (taskerEarningsStatsError ?? this.taskerEarningsStatsError),

      // ✅ NEW: earnings chart
      taskerEarningsChartStatus:
          taskerEarningsChartStatus ?? this.taskerEarningsChartStatus,
      taskerEarningsChartResponse: clearTaskerEarningsChartResponse
          ? null
          : (taskerEarningsChartResponse ?? this.taskerEarningsChartResponse),
      taskerEarningsChartError: clearTaskerEarningsChartError
          ? null
          : (taskerEarningsChartError ?? this.taskerEarningsChartError),

      // ✅ SOS
      startSosStatus: startSosStatus ?? this.startSosStatus,
      startSosResult:
          clearStartSosResult ? null : (startSosResult ?? this.startSosResult),
      startSosError:
          clearStartSosError ? null : (startSosError ?? this.startSosError),

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

      // ✅ payment
      createPaymentIntentStatus:
          createPaymentIntentStatus ?? this.createPaymentIntentStatus,
      paymentIntentResponse: clearPaymentIntentResponse
          ? null
          : (paymentIntentResponse ?? this.paymentIntentResponse),
      paymentIntentError: clearPaymentIntentError
          ? null
          : (paymentIntentError ?? this.paymentIntentError),

      // ✅ statuses
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
        // dashboard
        taskerDashboardStatus,
        taskerDashboardResponse,
        taskerDashboardError,

        // earnings stats
        taskerEarningsStatsStatus,
        taskerEarningsStatsResponse,
        taskerEarningsStatsError,

        // ✅ NEW earnings chart
        taskerEarningsChartStatus,
        taskerEarningsChartResponse,
        taskerEarningsChartError,

        // payment
        createPaymentIntentStatus,
        paymentIntentResponse,
        paymentIntentError,

        // SOS
        startSosStatus,
        startSosResult,
        startSosError,
        updateSosLocationStatus,
        updateSosLocationError,
        startSosResponse,
        updateSosLocationResponse,

        // cancel
        userBookingCancelStatus,

        // booking create response
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
// enum TaskerEarningsStatsStatus { initial, loading, success, failure }

// enum TaskerDashboardStatus { initial, loading, success, failure }

// enum StartSosStatus { initial, submitting, success, failure }
// enum UpdateSosLocationStatus { initial, submitting, success, failure }
// enum CreatePaymentIntentStatus { initial, submitting, success, failure }

// enum UserBookingCreateStatus { initial, submitting, success, failure }
// enum UserBookingCancelStatus { initial, submitting, success, failure }
// enum UserLocationUpdateStatus { initial, updating, success, failure }
// enum FindingTaskerStatus { initial, updating, success, failure }
// enum ChangeAvailabilityStatusEnum { initial, updating, success, failure }
// enum AcceptBookingEnum { initial, updating, success, failure }

// class UserBookingState extends Equatable {
//   // ✅ Dashboard
//   final TaskerDashboardStatus taskerDashboardStatus;
//   final TaskerDashboardResponse? taskerDashboardResponse;
//   final String? taskerDashboardError;
//   final TaskerEarningsStatsStatus taskerEarningsStatsStatus;
//   final TaskerEarningsStatsResponse? taskerEarningsStatsResponse;
//   final String? taskerEarningsStatsError;

//   // ✅ SOS
//   final StartSosStatus startSosStatus;
//   final StartSosResult? startSosResult;
//   final String? startSosError;

//   final UpdateSosLocationStatus updateSosLocationStatus;
//   final String? updateSosLocationError;

//   final RegistrationResponse? startSosResponse;
//   final RegistrationResponse? updateSosLocationResponse;

//   // ✅ payment
//   final CreatePaymentIntentStatus createPaymentIntentStatus;
//   final PaymentIntentResponse? paymentIntentResponse;
//   final String? paymentIntentError;

//   // booking create
//   final BookingCreateResponse? bookingCreateResponse;

//   // find tasker
//   final BookingFindResponse? bookingFindResponse;
//   final String? findingTaskerError;

//   // statuses
//   final UserBookingCreateStatus createStatus;
//   final UserBookingCancelStatus userBookingCancelStatus;
//   final UserLocationUpdateStatus locationStatus;
//   final FindingTaskerStatus findingTaskerStatus;
//   final ChangeAvailabilityStatusEnum changeAvailabilityStatusEnum;
//   final AcceptBookingEnum acceptBookingEnum;

//   // create booking API
//   final RegistrationResponse? createResponse;
//   final String? createError;

//   // location
//   final double? lastLatitude;
//   final double? lastLongitude;
//   final String? locationError;

//   // availability
//   final String? changeAvailabilityError;

//   // accept booking
//   final String? acceptBookingError;
//   final RegistrationResponse? acceptBookingResponse;
//   final String? acceptBookingMessage;

//   const UserBookingState({
//     // ✅ dashboard
//     this.taskerDashboardStatus = TaskerDashboardStatus.initial,
//     this.taskerDashboardResponse,
//     this.taskerDashboardError,
//       this.taskerEarningsStatsStatus = TaskerEarningsStatsStatus.initial,
//   this.taskerEarningsStatsResponse,
//   this.taskerEarningsStatsError,

//     // ✅ SOS
//     this.startSosStatus = StartSosStatus.initial,
//     this.startSosResult,
//     this.startSosError,
//     this.updateSosLocationStatus = UpdateSosLocationStatus.initial,
//     this.updateSosLocationError,
//     this.startSosResponse,
//     this.updateSosLocationResponse,

//     // ✅ payment
//     this.createPaymentIntentStatus = CreatePaymentIntentStatus.initial,
//     this.paymentIntentResponse,
//     this.paymentIntentError,

//     // booking create response
//     this.bookingCreateResponse,

//     // find tasker
//     this.bookingFindResponse,
//     this.findingTaskerError,

//     // statuses
//     this.createStatus = UserBookingCreateStatus.initial,
//     this.userBookingCancelStatus = UserBookingCancelStatus.initial,
//     this.locationStatus = UserLocationUpdateStatus.initial,
//     this.findingTaskerStatus = FindingTaskerStatus.initial,
//     this.changeAvailabilityStatusEnum = ChangeAvailabilityStatusEnum.initial,
//     this.acceptBookingEnum = AcceptBookingEnum.initial,

//     // create booking API
//     this.createResponse,
//     this.createError,

//     // location
//     this.lastLatitude,
//     this.lastLongitude,
//     this.locationError,

//     // availability
//     this.changeAvailabilityError,

//     // accept booking
//     this.acceptBookingError,
//     this.acceptBookingResponse,
//     this.acceptBookingMessage,
//   });

//   UserBookingState copyWith({
//     // ✅ dashboard
//     TaskerDashboardStatus? taskerDashboardStatus,
//     TaskerDashboardResponse? taskerDashboardResponse,
//     String? taskerDashboardError,
//     bool clearTaskerDashboardResponse = false,
//     bool clearTaskerDashboardError = false,
//       TaskerEarningsStatsStatus? taskerEarningsStatsStatus,
//   TaskerEarningsStatsResponse? taskerEarningsStatsResponse,
//   String? taskerEarningsStatsError,
//   bool clearTaskerEarningsStatsResponse = false,
//   bool clearTaskerEarningsStatsError = false,

//     // ✅ SOS
//     StartSosStatus? startSosStatus,
//     StartSosResult? startSosResult,
//     String? startSosError,
//     bool clearStartSosResult = false,
//     bool clearStartSosError = false,

//     UpdateSosLocationStatus? updateSosLocationStatus,
//     String? updateSosLocationError,
//     bool clearUpdateSosLocationError = false,

//     RegistrationResponse? startSosResponse,
//     bool clearStartSosResponse = false,

//     RegistrationResponse? updateSosLocationResponse,
//     bool clearUpdateSosLocationResponse = false,

//     // ✅ payment
//     CreatePaymentIntentStatus? createPaymentIntentStatus,
//     PaymentIntentResponse? paymentIntentResponse,
//     String? paymentIntentError,
//     bool clearPaymentIntentResponse = false,
//     bool clearPaymentIntentError = false,

//     // ✅ statuses
//     AcceptBookingEnum? acceptBookingEnum,
//     ChangeAvailabilityStatusEnum? changeAvailabilityStatusEnum,
//     FindingTaskerStatus? findingTaskerStatus,
//     UserBookingCreateStatus? createStatus,
//     UserBookingCancelStatus? userBookingCancelStatus,

//     // booking create response
//     BookingCreateResponse? bookingCreateResponse,
//     bool clearBookingCreateResponse = false,

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
//       // ✅ dashboard
//       taskerDashboardStatus: taskerDashboardStatus ?? this.taskerDashboardStatus,
//       taskerDashboardResponse: clearTaskerDashboardResponse
//           ? null
//           : (taskerDashboardResponse ?? this.taskerDashboardResponse),
//       taskerDashboardError: clearTaskerDashboardError
//           ? null
//           : (taskerDashboardError ?? this.taskerDashboardError),

//       // ✅ SOS
//       startSosStatus: startSosStatus ?? this.startSosStatus,
//       startSosResult: clearStartSosResult ? null : (startSosResult ?? this.startSosResult),
//       startSosError: clearStartSosError ? null : (startSosError ?? this.startSosError),

//       updateSosLocationStatus: updateSosLocationStatus ?? this.updateSosLocationStatus,
//       updateSosLocationError: clearUpdateSosLocationError
//           ? null
//           : (updateSosLocationError ?? this.updateSosLocationError),

//       startSosResponse: clearStartSosResponse ? null : (startSosResponse ?? this.startSosResponse),
//       updateSosLocationResponse:
//           clearUpdateSosLocationResponse ? null : (updateSosLocationResponse ?? this.updateSosLocationResponse),

//       // ✅ payment
//       createPaymentIntentStatus: createPaymentIntentStatus ?? this.createPaymentIntentStatus,
//       paymentIntentResponse: clearPaymentIntentResponse
//           ? null
//           : (paymentIntentResponse ?? this.paymentIntentResponse),
//       paymentIntentError: clearPaymentIntentError ? null : (paymentIntentError ?? this.paymentIntentError),

//       // ✅ statuses
//       acceptBookingEnum: acceptBookingEnum ?? this.acceptBookingEnum,
//       changeAvailabilityStatusEnum: changeAvailabilityStatusEnum ?? this.changeAvailabilityStatusEnum,
//       findingTaskerStatus: findingTaskerStatus ?? this.findingTaskerStatus,
//       createStatus: createStatus ?? this.createStatus,
//       userBookingCancelStatus: userBookingCancelStatus ?? this.userBookingCancelStatus,

//       // booking create response
//       bookingCreateResponse: clearBookingCreateResponse ? null : (bookingCreateResponse ?? this.bookingCreateResponse),

//       // find tasker
//       bookingFindResponse: clearBookingFindResponse ? null : (bookingFindResponse ?? this.bookingFindResponse),
//       findingTaskerError: clearFindingTaskerError ? null : (findingTaskerError ?? this.findingTaskerError),

//       // create booking API
//       createResponse: clearCreateResponse ? null : (createResponse ?? this.createResponse),
//       createError: clearCreateError ? null : (createError ?? this.createError),

//       // location
//       locationStatus: locationStatus ?? this.locationStatus,
//       lastLatitude: lastLatitude ?? this.lastLatitude,
//       lastLongitude: lastLongitude ?? this.lastLongitude,
//       locationError: clearLocationError ? null : (locationError ?? this.locationError),

//       // accept booking
//       acceptBookingError: clearAcceptBookingError ? null : (acceptBookingError ?? this.acceptBookingError),
//       acceptBookingResponse:
//           clearAcceptBookingResponse ? null : (acceptBookingResponse ?? this.acceptBookingResponse),
//       acceptBookingMessage:
//           clearAcceptBookingMessage ? null : (acceptBookingMessage ?? this.acceptBookingMessage),

//       // availability
//       changeAvailabilityError: changeAvailabilityError ?? this.changeAvailabilityError,
//     );
//   }

//   @override
//   List<Object?> get props => [
//         // dashboard
//         taskerDashboardStatus,
//         taskerDashboardResponse,
//         taskerDashboardError,
//           taskerEarningsStatsStatus,
//   taskerEarningsStatsResponse,
//   taskerEarningsStatsError,

//         // payment
//         createPaymentIntentStatus,
//         paymentIntentResponse,
//         paymentIntentError,

//         // SOS
//         startSosStatus,
//         startSosResult,
//         startSosError,
//         updateSosLocationStatus,
//         updateSosLocationError,
//         startSosResponse,
//         updateSosLocationResponse,

//         // cancel
//         userBookingCancelStatus,

//         // booking create response
//         bookingCreateResponse,

//         // find tasker
//         bookingFindResponse,
//         findingTaskerError,
//         findingTaskerStatus,

//         // accept booking
//         acceptBookingEnum,
//         acceptBookingError,
//         acceptBookingResponse,
//         acceptBookingMessage,

//         // availability
//         changeAvailabilityStatusEnum,
//         changeAvailabilityError,

//         // create booking API
//         createStatus,
//         createResponse,
//         createError,

//         // location
//         locationStatus,
//         lastLatitude,
//         lastLongitude,
//         locationError,
//       ];
// }
