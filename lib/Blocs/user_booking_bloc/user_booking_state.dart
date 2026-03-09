import 'package:equatable/equatable.dart';
import 'package:taskoon/Models/auth_model.dart';
import 'package:taskoon/Models/booking_create_response.dart';
import 'package:taskoon/Models/booking_find_response.dart';
import 'package:taskoon/Models/calender/tasker_calendar_models.dart';
import 'package:taskoon/Models/dashboard/tasker_dashboard.dart';
import 'package:taskoon/Models/dashboard/tasker_earnings_chart_model.dart';
import 'package:taskoon/Models/dashboard/tasker_earnings_stats_model.dart';
import 'package:taskoon/Models/dashboard/tasker_earnings_tasks_response.dart'
    show TaskerEarningsTasksResponse;
import 'package:taskoon/Models/dashboard/tasker_history_response.dart';
import 'package:taskoon/Models/dispute/dispute_reason_outcomes_response.dart';
import 'package:taskoon/Models/dispute/dispute_reason_response.dart';
import 'package:taskoon/Models/payment_intent_response.dart';
import 'package:taskoon/Models/sos/start_sos_response.dart';

//Dispute
enum DisputeReasonsStatus { initial, loading, success, failure }
enum DisputeReasonOutcomesStatus { initial, loading, success, failure }

// calender
enum TaskerCalendarStatus { initial, loading, success, failure }
enum TaskerCalendarByIdStatus { initial, loading, success, failure }
enum TaskerCalendarCreateStatus { initial, submitting, success, failure }
enum TaskerCalendarUpdateStatus { initial, submitting, success, failure }
enum TaskerCalendarDeleteStatus { initial, submitting, success, failure }

enum TaskerEarningsTasksStatus { initial, loading, success, failure }
enum TaskerEarningsStatsStatus { initial, loading, success, failure }
enum TaskerEarningsChartStatus { initial, loading, success, failure }
enum TaskerDashboardStatus { initial, loading, success, failure }
enum TaskerHistoryStatus { initial, loading, success, failure }

enum StartSosStatus { initial, submitting, success, failure }
enum UpdateSosLocationStatus { initial, submitting, success, failure }
enum CreatePaymentIntentStatus { initial, submitting, success, failure }

enum UserBookingCreateStatus { initial, submitting, success, failure }
enum UserBookingCancelStatus { initial, submitting, success, failure }
enum UserLocationUpdateStatus { initial, updating, success, failure }
enum FindingTaskerStatus { initial, updating, success, failure }
enum ChangeAvailabilityStatusEnum { initial, updating, success, failure }

enum AcceptBookingStatus { initial, loading, success, failure }

class UserBookingState extends Equatable {

  //Dispute
  final DisputeReasonsStatus disputeReasonsStatus;
final DisputeReasonResponse? disputeReasonResponse;
final String? disputeReasonError;

final DisputeReasonOutcomesStatus disputeReasonOutcomesStatus;
final DisputeReasonOutcomesResponse? disputeReasonOutcomesResponse;
final String? disputeReasonOutcomesError;
  // calender
  final TaskerCalendarStatus taskerCalendarStatus;
  final TaskerCalendarResponse? taskerCalendarResponse;
  final String? taskerCalendarError;

  final TaskerCalendarByIdStatus taskerCalendarByIdStatus;
  final TaskerCalendarItemResponse? taskerCalendarByIdResponse;
  final String? taskerCalendarByIdError;

  final TaskerCalendarCreateStatus taskerCalendarCreateStatus;
  final TaskerCalendarActionResponse? taskerCalendarCreateResponse;
  final String? taskerCalendarCreateError;

  final TaskerCalendarUpdateStatus taskerCalendarUpdateStatus;
  final TaskerCalendarActionResponse? taskerCalendarUpdateResponse;
  final String? taskerCalendarUpdateError;

  final TaskerCalendarDeleteStatus taskerCalendarDeleteStatus;
  final TaskerCalendarActionResponse? taskerCalendarDeleteResponse;
  final String? taskerCalendarDeleteError;

  // Dashboard
  final TaskerHistoryStatus taskerHistoryStatus;
  final TaskerHistoryResponse? taskerHistoryResponse;
  final String? taskerHistoryError;

  final TaskerEarningsTasksStatus taskerEarningsTasksStatus;
  final TaskerEarningsTasksResponse? taskerEarningsTasksResponse;
  final String? taskerEarningsTasksError;

  final TaskerDashboardStatus taskerDashboardStatus;
  final TaskerDashboardResponse? taskerDashboardResponse;
  final String? taskerDashboardError;

  // Earnings Stats
  final TaskerEarningsStatsStatus taskerEarningsStatsStatus;
  final TaskerEarningsStatsResponse? taskerEarningsStatsResponse;
  final String? taskerEarningsStatsError;

  // Earnings Stats cache by period
  final Map<String, TaskerEarningsStatsResponse> taskerEarningsStatsByPeriod;

  // Earnings Chart
  final TaskerEarningsChartStatus taskerEarningsChartStatus;
  final TaskerEarningsChartResponse? taskerEarningsChartResponse;
  final String? taskerEarningsChartError;

  // Earnings Chart cache by period
  final Map<String, TaskerEarningsChartResponse> taskerEarningsChartByPeriod;

  // SOS
  final StartSosStatus startSosStatus;
  final StartSosResult? startSosResult;
  final String? startSosError;

  final UpdateSosLocationStatus updateSosLocationStatus;
  final String? updateSosLocationError;

  final RegistrationResponse? startSosResponse;
  final RegistrationResponse? updateSosLocationResponse;

  // Payment
  final CreatePaymentIntentStatus createPaymentIntentStatus;
  final PaymentIntentResponse? paymentIntentResponse;
  final String? paymentIntentError;

  // Booking create
  final BookingCreateResponse? bookingCreateResponse;

  // Find tasker
  final BookingFindResponse? bookingFindResponse;
  final String? findingTaskerError;

  // Statuses
  final UserBookingCreateStatus createStatus;
  final UserBookingCancelStatus userBookingCancelStatus;
  final UserLocationUpdateStatus locationStatus;
  final FindingTaskerStatus findingTaskerStatus;
  final ChangeAvailabilityStatusEnum changeAvailabilityStatusEnum;
  final AcceptBookingStatus acceptBookingStatus;

  // Create booking API
  final RegistrationResponse? createResponse;
  final String? createError;

  // Location
  final double? lastLatitude;
  final double? lastLongitude;
  final String? locationError;

  // Availability
  final String? changeAvailabilityError;

  // Accept booking
  final String? acceptBookingError;
  final RegistrationResponse? acceptBookingResponse;
  final String? acceptBookingMessage;

  const UserBookingState({

    //dispute
    this.disputeReasonsStatus = DisputeReasonsStatus.initial,
this.disputeReasonResponse,
this.disputeReasonError,
this.disputeReasonOutcomesStatus = DisputeReasonOutcomesStatus.initial,
this.disputeReasonOutcomesResponse,
this.disputeReasonOutcomesError,
    // calender
    this.taskerCalendarStatus = TaskerCalendarStatus.initial,
    this.taskerCalendarResponse,
    this.taskerCalendarError,
    this.taskerCalendarByIdStatus = TaskerCalendarByIdStatus.initial,
    this.taskerCalendarByIdResponse,
    this.taskerCalendarByIdError,
    this.taskerCalendarCreateStatus = TaskerCalendarCreateStatus.initial,
    this.taskerCalendarCreateResponse,
    this.taskerCalendarCreateError,
    this.taskerCalendarUpdateStatus = TaskerCalendarUpdateStatus.initial,
    this.taskerCalendarUpdateResponse,
    this.taskerCalendarUpdateError,
    this.taskerCalendarDeleteStatus = TaskerCalendarDeleteStatus.initial,
    this.taskerCalendarDeleteResponse,
    this.taskerCalendarDeleteError,

    // Dashboard
    this.taskerHistoryStatus = TaskerHistoryStatus.initial,
    this.taskerHistoryResponse,
    this.taskerHistoryError,
    this.taskerEarningsTasksStatus = TaskerEarningsTasksStatus.initial,
    this.taskerEarningsTasksResponse,
    this.taskerEarningsTasksError,
    this.taskerDashboardStatus = TaskerDashboardStatus.initial,
    this.taskerDashboardResponse,
    this.taskerDashboardError,

    // Earnings stats
    this.taskerEarningsStatsStatus = TaskerEarningsStatsStatus.initial,
    this.taskerEarningsStatsResponse,
    this.taskerEarningsStatsError,
    this.taskerEarningsStatsByPeriod = const {},

    // Earnings chart
    this.taskerEarningsChartStatus = TaskerEarningsChartStatus.initial,
    this.taskerEarningsChartResponse,
    this.taskerEarningsChartError,
    this.taskerEarningsChartByPeriod = const {},

    // SOS
    this.startSosStatus = StartSosStatus.initial,
    this.startSosResult,
    this.startSosError,
    this.updateSosLocationStatus = UpdateSosLocationStatus.initial,
    this.updateSosLocationError,
    this.startSosResponse,
    this.updateSosLocationResponse,

    // Payment
    this.createPaymentIntentStatus = CreatePaymentIntentStatus.initial,
    this.paymentIntentResponse,
    this.paymentIntentError,

    // Booking create
    this.bookingCreateResponse,

    // Find tasker
    this.bookingFindResponse,
    this.findingTaskerError,

    // Statuses
    this.createStatus = UserBookingCreateStatus.initial,
    this.userBookingCancelStatus = UserBookingCancelStatus.initial,
    this.locationStatus = UserLocationUpdateStatus.initial,
    this.findingTaskerStatus = FindingTaskerStatus.initial,
    this.changeAvailabilityStatusEnum = ChangeAvailabilityStatusEnum.initial,
    this.acceptBookingStatus = AcceptBookingStatus.initial,

    // Create booking API
    this.createResponse,
    this.createError,

    // Location
    this.lastLatitude,
    this.lastLongitude,
    this.locationError,

    // Availability
    this.changeAvailabilityError,

    // Accept booking
    this.acceptBookingError,
    this.acceptBookingResponse,
    this.acceptBookingMessage,
  });

  UserBookingState copyWith({
    //dispute
    DisputeReasonsStatus? disputeReasonsStatus,
DisputeReasonResponse? disputeReasonResponse,
String? disputeReasonError,
bool clearDisputeReasonResponse = false,
bool clearDisputeReasonError = false,
DisputeReasonOutcomesStatus? disputeReasonOutcomesStatus,
DisputeReasonOutcomesResponse? disputeReasonOutcomesResponse,
String? disputeReasonOutcomesError,
bool clearDisputeReasonOutcomesResponse = false,
bool clearDisputeReasonOutcomesError = false,
    // calender
    TaskerCalendarStatus? taskerCalendarStatus,
    TaskerCalendarResponse? taskerCalendarResponse,
    String? taskerCalendarError,
    bool clearTaskerCalendarResponse = false,
    bool clearTaskerCalendarError = false,

    TaskerCalendarByIdStatus? taskerCalendarByIdStatus,
    TaskerCalendarItemResponse? taskerCalendarByIdResponse,
    String? taskerCalendarByIdError,
    bool clearTaskerCalendarByIdResponse = false,
    bool clearTaskerCalendarByIdError = false,

    TaskerCalendarCreateStatus? taskerCalendarCreateStatus,
    TaskerCalendarActionResponse? taskerCalendarCreateResponse,
    String? taskerCalendarCreateError,
    bool clearTaskerCalendarCreateResponse = false,
    bool clearTaskerCalendarCreateError = false,

    TaskerCalendarUpdateStatus? taskerCalendarUpdateStatus,
    TaskerCalendarActionResponse? taskerCalendarUpdateResponse,
    String? taskerCalendarUpdateError,
    bool clearTaskerCalendarUpdateResponse = false,
    bool clearTaskerCalendarUpdateError = false,

    TaskerCalendarDeleteStatus? taskerCalendarDeleteStatus,
    TaskerCalendarActionResponse? taskerCalendarDeleteResponse,
    String? taskerCalendarDeleteError,
    bool clearTaskerCalendarDeleteResponse = false,
    bool clearTaskerCalendarDeleteError = false,

    // Dashboard
    TaskerHistoryStatus? taskerHistoryStatus,
    TaskerHistoryResponse? taskerHistoryResponse,
    String? taskerHistoryError,
    bool clearTaskerHistoryResponse = false,
    bool clearTaskerHistoryError = false,

    TaskerEarningsTasksStatus? taskerEarningsTasksStatus,
    TaskerEarningsTasksResponse? taskerEarningsTasksResponse,
    String? taskerEarningsTasksError,
    bool clearTaskerEarningsTasksResponse = false,
    bool clearTaskerEarningsTasksError = false,

    TaskerDashboardStatus? taskerDashboardStatus,
    TaskerDashboardResponse? taskerDashboardResponse,
    String? taskerDashboardError,
    bool clearTaskerDashboardResponse = false,
    bool clearTaskerDashboardError = false,

    // Earnings stats
    TaskerEarningsStatsStatus? taskerEarningsStatsStatus,
    TaskerEarningsStatsResponse? taskerEarningsStatsResponse,
    String? taskerEarningsStatsError,
    bool clearTaskerEarningsStatsResponse = false,
    bool clearTaskerEarningsStatsError = false,
    Map<String, TaskerEarningsStatsResponse>? taskerEarningsStatsByPeriod,

    // Earnings chart
    TaskerEarningsChartStatus? taskerEarningsChartStatus,
    TaskerEarningsChartResponse? taskerEarningsChartResponse,
    String? taskerEarningsChartError,
    bool clearTaskerEarningsChartResponse = false,
    bool clearTaskerEarningsChartError = false,
    Map<String, TaskerEarningsChartResponse>? taskerEarningsChartByPeriod,

    // SOS
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

    // Payment
    CreatePaymentIntentStatus? createPaymentIntentStatus,
    PaymentIntentResponse? paymentIntentResponse,
    String? paymentIntentError,
    bool clearPaymentIntentResponse = false,
    bool clearPaymentIntentError = false,

    // Statuses
    AcceptBookingStatus? acceptBookingStatus,
    ChangeAvailabilityStatusEnum? changeAvailabilityStatusEnum,
    FindingTaskerStatus? findingTaskerStatus,
    UserBookingCreateStatus? createStatus,
    UserBookingCancelStatus? userBookingCancelStatus,

    // Booking create response
    BookingCreateResponse? bookingCreateResponse,
    bool clearBookingCreateResponse = false,

    // Find tasker
    BookingFindResponse? bookingFindResponse,
    String? findingTaskerError,
    bool clearBookingFindResponse = false,
    bool clearFindingTaskerError = false,

    // Create booking API
    RegistrationResponse? createResponse,
    String? createError,
    bool clearCreateResponse = false,
    bool clearCreateError = false,

    // Location
    UserLocationUpdateStatus? locationStatus,
    double? lastLatitude,
    double? lastLongitude,
    String? locationError,
    bool clearLocationError = false,

    // Accept booking
    String? acceptBookingError,
    RegistrationResponse? acceptBookingResponse,
    String? acceptBookingMessage,
    bool clearAcceptBookingError = false,
    bool clearAcceptBookingResponse = false,
    bool clearAcceptBookingMessage = false,

    // Availability
    String? changeAvailabilityError,
  }) {
    return UserBookingState(

      //dispute
      disputeReasonsStatus: disputeReasonsStatus ?? this.disputeReasonsStatus,
disputeReasonResponse: clearDisputeReasonResponse
    ? null
    : (disputeReasonResponse ?? this.disputeReasonResponse),
disputeReasonError: clearDisputeReasonError
    ? null
    : (disputeReasonError ?? this.disputeReasonError),

    disputeReasonOutcomesStatus:
    disputeReasonOutcomesStatus ?? this.disputeReasonOutcomesStatus,
disputeReasonOutcomesResponse: clearDisputeReasonOutcomesResponse
    ? null
    : (disputeReasonOutcomesResponse ?? this.disputeReasonOutcomesResponse),
disputeReasonOutcomesError: clearDisputeReasonOutcomesError
    ? null
    : (disputeReasonOutcomesError ?? this.disputeReasonOutcomesError),
      // calender
      taskerCalendarStatus: taskerCalendarStatus ?? this.taskerCalendarStatus,
      taskerCalendarResponse: clearTaskerCalendarResponse
          ? null
          : (taskerCalendarResponse ?? this.taskerCalendarResponse),
      taskerCalendarError: clearTaskerCalendarError
          ? null
          : (taskerCalendarError ?? this.taskerCalendarError),

      taskerCalendarByIdStatus:
          taskerCalendarByIdStatus ?? this.taskerCalendarByIdStatus,
      taskerCalendarByIdResponse: clearTaskerCalendarByIdResponse
          ? null
          : (taskerCalendarByIdResponse ?? this.taskerCalendarByIdResponse),
      taskerCalendarByIdError: clearTaskerCalendarByIdError
          ? null
          : (taskerCalendarByIdError ?? this.taskerCalendarByIdError),

      taskerCalendarCreateStatus:
          taskerCalendarCreateStatus ?? this.taskerCalendarCreateStatus,
      taskerCalendarCreateResponse: clearTaskerCalendarCreateResponse
          ? null
          : (taskerCalendarCreateResponse ?? this.taskerCalendarCreateResponse),
      taskerCalendarCreateError: clearTaskerCalendarCreateError
          ? null
          : (taskerCalendarCreateError ?? this.taskerCalendarCreateError),

      taskerCalendarUpdateStatus:
          taskerCalendarUpdateStatus ?? this.taskerCalendarUpdateStatus,
      taskerCalendarUpdateResponse: clearTaskerCalendarUpdateResponse
          ? null
          : (taskerCalendarUpdateResponse ?? this.taskerCalendarUpdateResponse),
      taskerCalendarUpdateError: clearTaskerCalendarUpdateError
          ? null
          : (taskerCalendarUpdateError ?? this.taskerCalendarUpdateError),

      taskerCalendarDeleteStatus:
          taskerCalendarDeleteStatus ?? this.taskerCalendarDeleteStatus,
      taskerCalendarDeleteResponse: clearTaskerCalendarDeleteResponse
          ? null
          : (taskerCalendarDeleteResponse ?? this.taskerCalendarDeleteResponse),
      taskerCalendarDeleteError: clearTaskerCalendarDeleteError
          ? null
          : (taskerCalendarDeleteError ?? this.taskerCalendarDeleteError),

      // Dashboard
      taskerHistoryStatus: taskerHistoryStatus ?? this.taskerHistoryStatus,
      taskerHistoryResponse: clearTaskerHistoryResponse
          ? null
          : (taskerHistoryResponse ?? this.taskerHistoryResponse),
      taskerHistoryError: clearTaskerHistoryError
          ? null
          : (taskerHistoryError ?? this.taskerHistoryError),

      taskerEarningsTasksStatus:
          taskerEarningsTasksStatus ?? this.taskerEarningsTasksStatus,
      taskerEarningsTasksResponse: clearTaskerEarningsTasksResponse
          ? null
          : (taskerEarningsTasksResponse ?? this.taskerEarningsTasksResponse),
      taskerEarningsTasksError: clearTaskerEarningsTasksError
          ? null
          : (taskerEarningsTasksError ?? this.taskerEarningsTasksError),

      taskerDashboardStatus:
          taskerDashboardStatus ?? this.taskerDashboardStatus,
      taskerDashboardResponse: clearTaskerDashboardResponse
          ? null
          : (taskerDashboardResponse ?? this.taskerDashboardResponse),
      taskerDashboardError: clearTaskerDashboardError
          ? null
          : (taskerDashboardError ?? this.taskerDashboardError),

      // Earnings stats
      taskerEarningsStatsStatus:
          taskerEarningsStatsStatus ?? this.taskerEarningsStatsStatus,
      taskerEarningsStatsResponse: clearTaskerEarningsStatsResponse
          ? null
          : (taskerEarningsStatsResponse ?? this.taskerEarningsStatsResponse),
      taskerEarningsStatsError: clearTaskerEarningsStatsError
          ? null
          : (taskerEarningsStatsError ?? this.taskerEarningsStatsError),
      taskerEarningsStatsByPeriod:
          taskerEarningsStatsByPeriod ?? this.taskerEarningsStatsByPeriod,

      // Earnings chart
      taskerEarningsChartStatus:
          taskerEarningsChartStatus ?? this.taskerEarningsChartStatus,
      taskerEarningsChartResponse: clearTaskerEarningsChartResponse
          ? null
          : (taskerEarningsChartResponse ?? this.taskerEarningsChartResponse),
      taskerEarningsChartError: clearTaskerEarningsChartError
          ? null
          : (taskerEarningsChartError ?? this.taskerEarningsChartError),
      taskerEarningsChartByPeriod:
          taskerEarningsChartByPeriod ?? this.taskerEarningsChartByPeriod,

      // SOS
      startSosStatus: startSosStatus ?? this.startSosStatus,
      startSosResult: clearStartSosResult
          ? null
          : (startSosResult ?? this.startSosResult),
      startSosError: clearStartSosError
          ? null
          : (startSosError ?? this.startSosError),

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

      // Payment
      createPaymentIntentStatus:
          createPaymentIntentStatus ?? this.createPaymentIntentStatus,
      paymentIntentResponse: clearPaymentIntentResponse
          ? null
          : (paymentIntentResponse ?? this.paymentIntentResponse),
      paymentIntentError: clearPaymentIntentError
          ? null
          : (paymentIntentError ?? this.paymentIntentError),

      // Statuses
      acceptBookingStatus: acceptBookingStatus ?? this.acceptBookingStatus,
      changeAvailabilityStatusEnum:
          changeAvailabilityStatusEnum ?? this.changeAvailabilityStatusEnum,
      findingTaskerStatus: findingTaskerStatus ?? this.findingTaskerStatus,
      createStatus: createStatus ?? this.createStatus,
      userBookingCancelStatus:
          userBookingCancelStatus ?? this.userBookingCancelStatus,

      // Booking create response
      bookingCreateResponse: clearBookingCreateResponse
          ? null
          : (bookingCreateResponse ?? this.bookingCreateResponse),

      // Find tasker
      bookingFindResponse: clearBookingFindResponse
          ? null
          : (bookingFindResponse ?? this.bookingFindResponse),
      findingTaskerError: clearFindingTaskerError
          ? null
          : (findingTaskerError ?? this.findingTaskerError),

      // Create booking API
      createResponse: clearCreateResponse
          ? null
          : (createResponse ?? this.createResponse),
      createError: clearCreateError ? null : (createError ?? this.createError),

      // Location
      locationStatus: locationStatus ?? this.locationStatus,
      lastLatitude: lastLatitude ?? this.lastLatitude,
      lastLongitude: lastLongitude ?? this.lastLongitude,
      locationError: clearLocationError
          ? null
          : (locationError ?? this.locationError),

      // Accept booking
      acceptBookingError: clearAcceptBookingError
          ? null
          : (acceptBookingError ?? this.acceptBookingError),
      acceptBookingResponse: clearAcceptBookingResponse
          ? null
          : (acceptBookingResponse ?? this.acceptBookingResponse),
      acceptBookingMessage: clearAcceptBookingMessage
          ? null
          : (acceptBookingMessage ?? this.acceptBookingMessage),

      // Availability
      changeAvailabilityError:
          changeAvailabilityError ?? this.changeAvailabilityError,
    );
  }

  @override
  List<Object?> get props => [

    //dispute
    disputeReasonsStatus,
disputeReasonResponse,
disputeReasonError,
disputeReasonOutcomesStatus,
disputeReasonOutcomesResponse,
disputeReasonOutcomesError,
        // calender
        taskerCalendarStatus,
        taskerCalendarResponse,
        taskerCalendarError,
        taskerCalendarByIdStatus,
        taskerCalendarByIdResponse,
        taskerCalendarByIdError,
        taskerCalendarCreateStatus,
        taskerCalendarCreateResponse,
        taskerCalendarCreateError,
        taskerCalendarUpdateStatus,
        taskerCalendarUpdateResponse,
        taskerCalendarUpdateError,
        taskerCalendarDeleteStatus,
        taskerCalendarDeleteResponse,
        taskerCalendarDeleteError,

        // Dashboard
        taskerHistoryStatus,
        taskerHistoryResponse,
        taskerHistoryError,
        taskerEarningsTasksStatus,
        taskerEarningsTasksResponse,
        taskerEarningsTasksError,
        taskerDashboardStatus,
        taskerDashboardResponse,
        taskerDashboardError,

        // Earnings stats
        taskerEarningsStatsStatus,
        taskerEarningsStatsResponse,
        taskerEarningsStatsError,
        taskerEarningsStatsByPeriod,

        // Earnings chart
        taskerEarningsChartStatus,
        taskerEarningsChartResponse,
        taskerEarningsChartError,
        taskerEarningsChartByPeriod,

        // Payment
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

        // Cancel
        userBookingCancelStatus,

        // Booking create
        bookingCreateResponse,

        // Find tasker
        bookingFindResponse,
        findingTaskerError,
        findingTaskerStatus,

        // Accept booking
        acceptBookingStatus,
        acceptBookingError,
        acceptBookingResponse,
        acceptBookingMessage,

        // Availability
        changeAvailabilityStatusEnum,
        changeAvailabilityError,

        // Create booking API
        createStatus,
        createResponse,
        createError,

        // Location
        locationStatus,
        lastLatitude,
        lastLongitude,
        locationError,
      ];
}
