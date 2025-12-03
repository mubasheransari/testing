import 'package:equatable/equatable.dart';

/// Base class for all user-booking related events
abstract class UserBookingEvent extends Equatable {
  const UserBookingEvent();

  @override
  List<Object?> get props => [];
}
class CreateUserBookingRequested extends UserBookingEvent {
  final String userId;
  final int subCategoryId;
  final DateTime bookingDate;
  final String startTime;
  final String endTime;
  final String address;
  final int taskerLevelId;

  // new fields
  final String currency;
  final int paymentType;
  final int serviceType;
  final int paymentMethod;

  CreateUserBookingRequested({
    required this.userId,
    required this.subCategoryId,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.address,
    required this.taskerLevelId,
    this.currency = 'AUD',
    this.paymentType = 1,
    this.serviceType = 1,
    this.paymentMethod = 1,
  });

  @override
  List<Object?> get props => [
        userId,
        subCategoryId,
        bookingDate,
        startTime,
        endTime,
        address,
        taskerLevelId,
        currency,
        paymentType,
        serviceType,
        paymentMethod,
      ];
}

/// POST /api/Booking/Create
// class CreateUserBookingRequested extends UserBookingEvent {
//   final String userId;
//   final int subCategoryId;
//   final DateTime bookingDate; // will be sent as ISO-8601 from bloc/repo
//   final String startTime;
//   final String endTime;
//   final String address;
//   final int taskerLevelId;

//   const CreateUserBookingRequested({
//     required this.userId,
//     required this.subCategoryId,
//     required this.bookingDate,
//     required this.startTime,
//     required this.endTime,
//     required this.address,
//     required this.taskerLevelId,
//   });

//   @override
//   List<Object?> get props => [
//         userId,
//         subCategoryId,
//         bookingDate,
//         startTime,
//         endTime,
//         address,
//         taskerLevelId,
//       ];
// }
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
  final double userLatitude;
  final double userLongitude;

  const FindingTaskerRequested({
    required this.bookingId,
    required this.userLatitude,
    required this.userLongitude,
  });

  @override
  List<Object?> get props => [bookingId, userLatitude, userLongitude];
}