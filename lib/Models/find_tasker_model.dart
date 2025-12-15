class BookingFindResponse {
  final bool isSuccess;
  final String? message;
  final List<BookingFindTasker> result;
  final List<ApiFieldError>? errors;

  const BookingFindResponse({
    required this.isSuccess,
    this.message,
    required this.result,
    this.errors,
  });

  factory BookingFindResponse.fromJson(Map<String, dynamic> json) {
    return BookingFindResponse(
      isSuccess: json['isSuccess'] == true,
      message: json['message']?.toString(),
      result: (json['result'] as List? ?? [])
          .map((e) => BookingFindTasker.fromJson(e as Map<String, dynamic>))
          .toList(),
      errors: json['errors'] == null
          ? null
          : (json['errors'] as List)
              .map((e) => ApiFieldError.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'isSuccess': isSuccess,
        'message': message,
        'result': result.map((e) => e.toJson()).toList(),
        'errors': errors?.map((e) => e.toJson()).toList(),
      };
}

class BookingFindTasker {
  final String userId;
  final double distanceInKM;
  final double ratings;
  final String taskerName;
  final double estimatedBaseCost;
  final List<String> taskerServices;
  final String taskerId;

  const BookingFindTasker({
    required this.userId,
    required this.distanceInKM,
    required this.ratings,
    required this.taskerName,
    required this.estimatedBaseCost,
    required this.taskerServices,
    required this.taskerId,
  });

  factory BookingFindTasker.fromJson(Map<String, dynamic> json) {
    return BookingFindTasker(
      userId: (json['userId'] ?? '').toString(),
      distanceInKM: _toDouble(json['distanceInKM']),
      ratings: _toDouble(json['ratings']),
      taskerName: (json['taskerName'] ?? '').toString(),
      estimatedBaseCost: _toDouble(json['estimatedBaseCost']),
      taskerServices: (json['taskerServices'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      taskerId: (json['taskerId'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'distanceInKM': distanceInKM,
        'ratings': ratings,
        'taskerName': taskerName,
        'estimatedBaseCost': estimatedBaseCost,
        'taskerServices': taskerServices,
        'taskerId': taskerId,
      };
}

class ApiFieldError {
  final String? field;
  final String? error;

  const ApiFieldError({this.field, this.error});

  factory ApiFieldError.fromJson(Map<String, dynamic> json) {
    return ApiFieldError(
      field: json['field']?.toString(),
      error: json['error']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'field': field,
        'error': error,
      };
}

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}
