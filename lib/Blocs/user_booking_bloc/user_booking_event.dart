import 'package:equatable/equatable.dart';


abstract class UserBookingEvent extends Equatable {
  const UserBookingEvent();

  @override
  List<Object?> get props => [];
}


class CreateUserBookingRequested extends UserBookingEvent {
  // ----- required -----
  final String userId;
  final int subCategoryId;
  final int bookingTypeId; // 1=ASAP, 2=Future, 3=Recurrence, 4=MultiDays
  final DateTime bookingDate;

  /// FULL ISO DateTime strings expected by backend
  final String startTime; // e.g. 2025-12-26T15:00:00.000Z
  final String endTime;   // e.g. 2025-12-26T18:55:00.000Z

  final String address;
  final int taskerLevelId;

  // ----- optional -----
  final DateTime? endDate;            // recurrence / multi-days
  final int? recurrencePatternId;     // daily / weekly / monthly / custom
  final String? customDays;            // "Monday,Tuesday"

  final double latitude;
  final double longitude;

  const CreateUserBookingRequested({
    required this.userId,
    required this.subCategoryId,
    required this.bookingTypeId,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.address,
    required this.taskerLevelId,
    this.endDate,
    this.recurrencePatternId,
    this.customDays,
    this.latitude = 0.0,
    this.longitude = 0.0,
  });

  @override
  List<Object?> get props => [
        userId,
        subCategoryId,
        bookingTypeId,
        bookingDate,
        startTime,
        endTime,
        address,
        taskerLevelId,
        endDate,
        recurrencePatternId,
        customDays,
        latitude,
        longitude,
      ];
}


class UpdateUserLocationRequested extends UserBookingEvent {
  final String userId;
  final double latitude;
  final double longitude;

  const UpdateUserLocationRequested({
    required this.userId,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [userId, latitude, longitude];
}

class FindingTaskerRequested extends UserBookingEvent {
  final String bookingId;

  const FindingTaskerRequested({
    required this.bookingId,
  });

  @override
  List<Object?> get props => [bookingId];
}

class ChangeAvailabilityStatus extends UserBookingEvent {
  final String userId;

  const ChangeAvailabilityStatus({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class AcceptBooking extends UserBookingEvent {
  final String userId;
  final String bookingDetailId;

  const AcceptBooking({
    required this.userId,
    required this.bookingDetailId,
  });

  @override
  List<Object?> get props => [userId, bookingDetailId];
}

class CancelBooking extends UserBookingEvent {
  final String userId;
  final String bookingDetailId;
  final String reason;

  const CancelBooking({
    required this.userId,
    required this.bookingDetailId,
    required this.reason,
  });

  @override
  List<Object?> get props => [userId, bookingDetailId, reason];
}


// abstract class UserBookingEvent extends Equatable {
//   const UserBookingEvent();

//   @override
//   List<Object?> get props => [];
// }


// // class CreateUserBookingRequested extends UserBookingEvent {
// //   final String userId;
// //   final int subCategoryId;
// //   final DateTime bookingDate;
// //   final String startTime;
// //   final String endTime;
// //   final String address;
// //   final int taskerLevelId;

// //   // new fields
// //   final String currency;
// //   final int paymentType;
// //   final int serviceType;
// //   final int paymentMethod;

// //   CreateUserBookingRequested({
// //     required this.userId,
// //     required this.subCategoryId,
// //     required this.bookingDate,
// //     required this.startTime,
// //     required this.endTime,
// //     required this.address,
// //     required this.taskerLevelId,
// //     this.currency = 'AUD',
// //     this.paymentType = 1,
// //     this.serviceType = 1,
// //     this.paymentMethod = 1,
// //   });

// //   @override
// //   List<Object?> get props => [
// //         userId,
// //         subCategoryId,
// //         bookingDate,
// //         startTime,
// //         endTime,
// //         address,
// //         taskerLevelId,
// //         currency,
// //         paymentType,
// //         serviceType,
// //         paymentMethod,
// //       ];
// // }

// /// POST /api/Booking/Create
// // class CreateUserBookingRequested extends UserBookingEvent {
// //   final String userId;
// //   final int subCategoryId;
// //   final DateTime bookingDate; // will be sent as ISO-8601 from bloc/repo
// //   final String startTime;
// //   final String endTime;
// //   final String address;
// //   final int taskerLevelId;

// //   const CreateUserBookingRequested({
// //     required this.userId,
// //     required this.subCategoryId,
// //     required this.bookingDate,
// //     required this.startTime,
// //     required this.endTime,
// //     required this.address,
// //     required this.taskerLevelId,
// //   });

// //   @override
// //   List<Object?> get props => [
// //         userId,
// //         subCategoryId,
// //         bookingDate,
// //         startTime,
// //         endTime,
// //         address,
// //         taskerLevelId,
// //       ];
// // }
// class UpdateUserLocationRequested extends UserBookingEvent {
//   final String userId;
//   final double latitude;
//   final double longitude;

//   const UpdateUserLocationRequested({
//     required this.userId,
//     required this.latitude,
//     required this.longitude,
//   });

//   @override
//   List<Object?> get props => [userId, latitude, longitude];
// }

// class FindingTaskerRequested extends UserBookingEvent {
//   final String bookingId;


//   const FindingTaskerRequested({
//     required this.bookingId,
//   });

//   @override
//   List<Object?> get props => [bookingId];
// }

// class ChangeAvailabilityStatus extends UserBookingEvent {
//   final String userId;

//   const ChangeAvailabilityStatus({
//     required this.userId
//   });

//   @override
//   List<Object?> get props => [userId];
// }

// class AcceptBooking extends UserBookingEvent {
//   final String userId;
//   final String bookingDetailId;

//   const AcceptBooking({
//     required this.userId,
//     required this.bookingDetailId
//   });

//   @override
//   List<Object?> get props => [userId,bookingDetailId];
// }

// class CancelBooking extends UserBookingEvent {
//   final String userId;
//   final String bookingDetailId;
//   final String reason;

//   const CancelBooking({
//     required this.userId,
//     required this.bookingDetailId,
//     required this.reason
//   });

//   @override
//   List<Object?> get props => [userId,bookingDetailId,reason];
// }