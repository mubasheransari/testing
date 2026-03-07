class TaskerCalendarResponse {
  final bool isSuccess;
  final String? message;
  final List<TaskerCalendarItem> result;
  final List<String>? errors;

  const TaskerCalendarResponse({
    required this.isSuccess,
    required this.result,
    this.message,
    this.errors,
  });

  factory TaskerCalendarResponse.fromJson(Map<String, dynamic> json) {
    return TaskerCalendarResponse(
      isSuccess: json['isSuccess'] == true,
      message: json['message']?.toString(),
      result: json['result'] is List
          ? (json['result'] as List)
              .whereType<Map>()
              .map((e) => TaskerCalendarItem.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ))
              .toList()
          : const [],
      errors: json['errors'] == null
          ? null
          : (json['errors'] is List
              ? (json['errors'] as List).map((e) => e.toString()).toList()
              : [json['errors'].toString()]),
    );
  }
}

class TaskerCalendarItemResponse {
  final bool isSuccess;
  final String? message;
  final TaskerCalendarItem? result;
  final List<String>? errors;

  const TaskerCalendarItemResponse({
    required this.isSuccess,
    this.message,
    this.result,
    this.errors,
  });

  factory TaskerCalendarItemResponse.fromJson(Map<String, dynamic> json) {
    return TaskerCalendarItemResponse(
      isSuccess: json['isSuccess'] == true,
      message: json['message']?.toString(),
      result: json['result'] is Map<String, dynamic>
          ? TaskerCalendarItem.fromJson(json['result'] as Map<String, dynamic>)
          : null,
      errors: json['errors'] == null
          ? null
          : (json['errors'] is List
              ? (json['errors'] as List).map((e) => e.toString()).toList()
              : [json['errors'].toString()]),
    );
  }
}

class TaskerCalendarActionResponse {
  final bool isSuccess;
  final String? message;
  final dynamic result;
  final List<String>? errors;

  const TaskerCalendarActionResponse({
    required this.isSuccess,
    this.message,
    this.result,
    this.errors,
  });

  factory TaskerCalendarActionResponse.fromJson(Map<String, dynamic> json) {
    return TaskerCalendarActionResponse(
      isSuccess: json['isSuccess'] == true,
      message: json['message']?.toString(),
      result: json['result'],
      errors: json['errors'] == null
          ? null
          : (json['errors'] is List
              ? (json['errors'] as List).map((e) => e.toString()).toList()
              : [json['errors'].toString()]),
    );
  }
}

class TaskerCalendarItem {
  final String id;
  final String taskerUserId;
  final String startTime;
  final String endTime;
  final bool isBlocked;

  const TaskerCalendarItem({
    required this.id,
    required this.taskerUserId,
    required this.startTime,
    required this.endTime,
    required this.isBlocked,
  });

  factory TaskerCalendarItem.fromJson(Map<String, dynamic> json) {
    return TaskerCalendarItem(
      id: (json['id'] ?? '').toString(),
      taskerUserId: (json['taskerUserId'] ?? '').toString(),
      startTime: (json['startTime'] ?? '').toString(),
      endTime: (json['endTime'] ?? '').toString(),
      isBlocked: json['isBlocked'] == true,
    );
  }
}

class TaskerCalendarRequest {
  final String taskerUserId;
  final String startTime;
  final String endTime;
  final bool isBlocked;

  const TaskerCalendarRequest({
    required this.taskerUserId,
    required this.startTime,
    required this.endTime,
    required this.isBlocked,
  });

  Map<String, dynamic> toJson() {
    return {
      'taskerUserId': taskerUserId,
      'startTime': startTime,
      'endTime': endTime,
      'isBlocked': isBlocked,
    };
  }
}

class TaskerCalendarUpdateRequest {
  final String id;
  final String taskerUserId;
  final String startTime;
  final String endTime;
  final bool isBlocked;

  const TaskerCalendarUpdateRequest({
    required this.id,
    required this.taskerUserId,
    required this.startTime,
    required this.endTime,
    required this.isBlocked,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskerUserId': taskerUserId,
      'startTime': startTime,
      'endTime': endTime,
      'isBlocked': isBlocked,
    };
  }
}