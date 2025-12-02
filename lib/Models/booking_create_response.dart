// booking_create_response.dart

class BookingCreateResponse {
  final bool isSuccess;
  final String message;
  final BookingCreateResult? result;
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
          ? BookingCreateResult.fromJson(json['result'] as Map<String, dynamic>)
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

class BookingCreateResult {
  final String id;
  final String userId;
  final int bookingTypeId;
  final int subCategoryId;
  final int taskerLevelId;
  final String address;
  final int bookingStatusId;
  final String? assignedTaskerId;
  final bool isCancelled;
  final String? cancelledBy;
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final String? cancelledTypeBy;
  final int? cancelledType;
  final int? cancelledTaskDuration;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isDeleted;
  final List<BookingDetail> details;

  BookingCreateResult({
    required this.id,
    required this.userId,
    required this.bookingTypeId,
    required this.subCategoryId,
    required this.taskerLevelId,
    required this.address,
    required this.bookingStatusId,
    this.assignedTaskerId,
    required this.isCancelled,
    this.cancelledBy,
    this.cancellationReason,
    this.cancelledAt,
    this.cancelledTypeBy,
    this.cancelledType,
    this.cancelledTaskDuration,
    required this.createdAt,
    this.updatedAt,
    required this.isDeleted,
    required this.details,
  });

  factory BookingCreateResult.fromJson(Map<String, dynamic> json) {
    return BookingCreateResult(
      id: json['id'] as String,
      userId: json['userId'] as String,
      bookingTypeId: json['bookingTypeId'] as int,
      subCategoryId: json['subCategoryId'] as int,
      taskerLevelId: json['taskerLevelId'] as int,
      address: json['address'] as String,
      bookingStatusId: json['bookingStatusId'] as int,
      assignedTaskerId: json['assignedTaskerId'] as String?,
      isCancelled: json['isCancelled'] as bool,
      cancelledBy: json['cancelledBy'] as String?,
      cancellationReason: json['cancellationReason'] as String?,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'] as String)
          : null,
      cancelledTypeBy: json['cancelledTypeBy'] as String?,
      cancelledType: json['cancelledType'] as int?,
      cancelledTaskDuration: json['cancelledTaskDuration'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      isDeleted: json['isDeleted'] as bool,
      details: (json['details'] as List<dynamic>? ?? [])
          .map((e) => BookingDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'bookingTypeId': bookingTypeId,
      'subCategoryId': subCategoryId,
      'taskerLevelId': taskerLevelId,
      'address': address,
      'bookingStatusId': bookingStatusId,
      'assignedTaskerId': assignedTaskerId,
      'isCancelled': isCancelled,
      'cancelledBy': cancelledBy,
      'cancellationReason': cancellationReason,
      'cancelledAt': cancelledAt?.toIso8601String(),
      'cancelledTypeBy': cancelledTypeBy,
      'cancelledType': cancelledType,
      'cancelledTaskDuration': cancelledTaskDuration,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isDeleted': isDeleted,
      'details': details.map((e) => e.toJson()).toList(),
    };
  }
}

class BookingDetail {
  final String id;
  final String bookingId;
  final DateTime bookingDate;
  final DateTime scheduledStartTime;
  final DateTime scheduledEndTime;
  final DateTime? actualStartTime;
  final DateTime? actualEndTime;
  final double estimatedCost;
  final double? actualCost;
  final int detailStatusId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isDeleted;
  final double latitude;
  final double longitude;

  BookingDetail({
    required this.id,
    required this.bookingId,
    required this.bookingDate,
    required this.scheduledStartTime,
    required this.scheduledEndTime,
    this.actualStartTime,
    this.actualEndTime,
    required this.estimatedCost,
    this.actualCost,
    required this.detailStatusId,
    required this.createdAt,
    this.updatedAt,
    required this.isDeleted,
    required this.latitude,
    required this.longitude,
  });

  factory BookingDetail.fromJson(Map<String, dynamic> json) {
    return BookingDetail(
      id: json['id'] as String,
      bookingId: json['bookingId'] as String,
      bookingDate: DateTime.parse(json['bookingDate'] as String),
      scheduledStartTime:
          DateTime.parse(json['scheduledStartTime'] as String),
      scheduledEndTime: DateTime.parse(json['scheduledEndTime'] as String),
      actualStartTime: json['actualStartTime'] != null
          ? DateTime.parse(json['actualStartTime'] as String)
          : null,
      actualEndTime: json['actualEndTime'] != null
          ? DateTime.parse(json['actualEndTime'] as String)
          : null,
      estimatedCost: (json['estimatedCost'] as num).toDouble(),
      actualCost: json['actualCost'] != null
          ? (json['actualCost'] as num).toDouble()
          : null,
      detailStatusId: json['detailStatusId'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      isDeleted: json['isDeleted'] as bool,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'bookingDate': bookingDate.toIso8601String(),
      'scheduledStartTime': scheduledStartTime.toIso8601String(),
      'scheduledEndTime': scheduledEndTime.toIso8601String(),
      'actualStartTime': actualStartTime?.toIso8601String(),
      'actualEndTime': actualEndTime?.toIso8601String(),
      'estimatedCost': estimatedCost,
      'actualCost': actualCost,
      'detailStatusId': detailStatusId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isDeleted': isDeleted,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
