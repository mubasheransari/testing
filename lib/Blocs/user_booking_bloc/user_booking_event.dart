import 'package:equatable/equatable.dart';

/// Base class for all user-booking related events
abstract class UserBookingEvent extends Equatable {
  const UserBookingEvent();

  @override
  List<Object?> get props => [];
}

/// POST /api/Booking/Create
class CreateUserBookingRequested extends UserBookingEvent {
  final String userId;
  final int subCategoryId;
  final DateTime bookingDate; // will be sent as ISO-8601 from bloc/repo
  final String startTime;
  final String endTime;
  final String address;
  final int taskerLevelId;

  const CreateUserBookingRequested({
    required this.userId,
    required this.subCategoryId,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.address,
    required this.taskerLevelId,
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