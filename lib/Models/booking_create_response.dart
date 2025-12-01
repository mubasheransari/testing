// booking_create_response.dart

class BookingCreateResponse {
  final bool isSuccess;
  final String message;
  final BookingResult? result;
  final dynamic errors;

  BookingCreateResponse({
    required this.isSuccess,
    required this.message,
    this.result,
    this.errors,
  });

  factory BookingCreateResponse.fromJson(Map<String, dynamic> json) {
    return BookingCreateResponse(
      isSuccess: json['isSuccess'] as bool,
      message: json['message'] as String,
      result: json['result'] != null
          ? BookingResult.fromJson(json['result'] as Map<String, dynamic>)
          : null,
      errors: json['errors'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isSuccess': isSuccess,
      'message': message,
      'result': result?.toJson(),
      'errors': errors,
    };
  }
}

class BookingResult {
  final String id;
  final String userId;
  final int subCategoryId;
  final int taskerLevelId;
  final DateTime bookingDate;
  final int bookingStatusId;
  final String scheduledStartTime;
  final String scheduledEndTime;
  final String? actualStartTime;
  final String? actualEndTime;
  final double estimatedCost;
  final double actualCost;
  final String? assignedTaskerId;
  final String? cancellationReason;
  final bool isCancelled;
  final String? cancelledBy;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isDeleted;
  final String address;
  final String? location;
  final List<dynamic> offers; // if you know offer structure, replace with a proper model

  BookingResult({
    required this.id,
    required this.userId,
    required this.subCategoryId,
    required this.taskerLevelId,
    required this.bookingDate,
    required this.bookingStatusId,
    required this.scheduledStartTime,
    required this.scheduledEndTime,
    this.actualStartTime,
    this.actualEndTime,
    required this.estimatedCost,
    required this.actualCost,
    this.assignedTaskerId,
    this.cancellationReason,
    required this.isCancelled,
    this.cancelledBy,
    this.cancelledAt,
    required this.createdAt,
    this.updatedAt,
    required this.isDeleted,
    required this.address,
    this.location,
    required this.offers,
  });

  factory BookingResult.fromJson(Map<String, dynamic> json) {
    return BookingResult(
      id: json['id'] as String,
      userId: json['userId'] as String,
      subCategoryId: json['subCategoryId'] as int,
      taskerLevelId: json['taskerLevelId'] as int,
      bookingDate: DateTime.parse(json['bookingDate'] as String),
      bookingStatusId: json['bookingStatusId'] as int,
      scheduledStartTime: json['scheduledStartTime'] as String,
      scheduledEndTime: json['scheduledEndTime'] as String,
      actualStartTime: json['actualStartTime'] as String?,
      actualEndTime: json['actualEndTime'] as String?,
      estimatedCost: (json['estimatedCost'] as num).toDouble(),
      actualCost: (json['actualCost'] as num).toDouble(),
      assignedTaskerId: json['assignedTaskerId'] as String?,
      cancellationReason: json['cancellationReason'] as String?,
      isCancelled: json['isCancelled'] as bool,
      cancelledBy: json['cancelledBy'] as String?,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      isDeleted: json['isDeleted'] as bool,
      address: json['address'] as String,
      location: json['location'] as String?,
      offers: (json['offers'] as List<dynamic>? ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'subCategoryId': subCategoryId,
      'taskerLevelId': taskerLevelId,
      'bookingDate': bookingDate.toIso8601String(),
      'bookingStatusId': bookingStatusId,
      'scheduledStartTime': scheduledStartTime,
      'scheduledEndTime': scheduledEndTime,
      'actualStartTime': actualStartTime,
      'actualEndTime': actualEndTime,
      'estimatedCost': estimatedCost,
      'actualCost': actualCost,
      'assignedTaskerId': assignedTaskerId,
      'cancellationReason': cancellationReason,
      'isCancelled': isCancelled,
      'cancelledBy': cancelledBy,
      'cancelledAt': cancelledAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isDeleted': isDeleted,
      'address': address,
      'location': location,
      'offers': offers,
    };
  }
}
