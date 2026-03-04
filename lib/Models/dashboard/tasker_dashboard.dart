class TaskerDashboardResponse {
  final bool isSuccess;
  final String? message;
  final TaskerDashboardResult? result;
  final List<String>? errors;

  TaskerDashboardResponse({
    required this.isSuccess,
    this.message,
    this.result,
    this.errors,
  });

  factory TaskerDashboardResponse.fromJson(Map<String, dynamic> j) {
    return TaskerDashboardResponse(
      isSuccess: j['isSuccess'] == true,
      message: j['message']?.toString(),
      errors: (j['errors'] is List)
          ? (j['errors'] as List).map((e) => e.toString()).toList()
          : null,
      result: (j['result'] is Map<String, dynamic>)
          ? TaskerDashboardResult.fromJson(Map<String, dynamic>.from(j['result']))
          : null,
    );
  }
}

class TaskerDashboardResult {
  final double rating;
  final int reviews;
  final int acceptanceRate;
  final int completionRate;
  final int weeklyEarning;
  final int monthlyEarning;

  final List<TaskerDashboardTask> upcoming;
  final List<TaskerDashboardTask> current;

  TaskerDashboardResult({
    required this.rating,
    required this.reviews,
    required this.acceptanceRate,
    required this.completionRate,
    required this.weeklyEarning,
    required this.monthlyEarning,
    required this.upcoming,
    required this.current,
  });

  static double _d(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static int _i(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static List<TaskerDashboardTask> _tasks(dynamic v) {
    if (v is List) {
      return v
          .where((e) => e is Map)
          .map((e) => TaskerDashboardTask.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false);
    }
    return const [];
  }

  factory TaskerDashboardResult.fromJson(Map<String, dynamic> j) {
    dynamic pick(List<String> keys) {
      for (final k in keys) {
        if (j.containsKey(k) && j[k] != null) return j[k];
      }
      return null;
    }

    return TaskerDashboardResult(
      rating: _d(pick(['rating', 'avgRating', 'taskerRating'])),
      reviews: _i(pick(['reviews', 'reviewCount', 'totalReviews'])),
      acceptanceRate: _i(pick(['acceptanceRate', 'acceptRate'])),
      completionRate: _i(pick(['completionRate', 'completeRate'])),
      weeklyEarning: _i(pick(['weeklyEarning', 'weeklyEarnings', 'weekEarning'])),
      monthlyEarning: _i(pick(['monthlyEarning', 'monthlyEarnings', 'monthEarning'])),
      upcoming: _tasks(pick(['upcoming', 'upcomingTasks', 'upcomingBookings', 'upcomingJobs'])),
      current: _tasks(pick(['current', 'currentTasks', 'currentBookings', 'currentJobs'])),
    );
  }
}

class TaskerDashboardTask {
  final String title;
  final String date;
  final String time;
  final String location;

  TaskerDashboardTask({
    required this.title,
    required this.date,
    required this.time,
    required this.location,
  });

  static String _s(dynamic v) => (v ?? '').toString();

  static DateTime? _dt(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  factory TaskerDashboardTask.fromJson(Map<String, dynamic> j) {
    dynamic pick(List<String> keys) {
      for (final k in keys) {
        if (j.containsKey(k) && j[k] != null) return j[k];
      }
      return null;
    }

    final dt = _dt(pick(['bookingTime', 'bookingDateTime', 'startTime', 'dateTime']));

    String fmtDate(DateTime? d) {
      if (d == null) return _s(pick(['date', 'bookingDate']));
      final x = d.toLocal();
      return "${x.year.toString().padLeft(4, '0')}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}";
    }

    String fmtTime(DateTime? d) {
      if (d == null) return _s(pick(['time', 'bookingTimeText']));
      final x = d.toLocal();
      return "${x.hour.toString().padLeft(2, '0')}:${x.minute.toString().padLeft(2, '0')}";
    }

    final title = _s(pick(['title', 'serviceName', 'service', 'bookingService']));
    return TaskerDashboardTask(
      title: title.isEmpty ? 'Task' : title,
      date: fmtDate(dt),
      time: fmtTime(dt),
      location: _s(pick(['location', 'address', 'area'])),
    );
  }
}

// class TaskerDashboardResponse {
//   final bool isSuccess;
//   final String message;
//   final TaskerDashboardResult? result;
//   final List<ApiError> errors;

//   TaskerDashboardResponse({
//     required this.isSuccess,
//     required this.message,
//     required this.result,
//     required this.errors,
//   });

//   factory TaskerDashboardResponse.fromJson(Map<String, dynamic> json) {
//     return TaskerDashboardResponse(
//       isSuccess: json['isSuccess'] == true,
//       message: (json['message'] ?? '').toString(),
//       result: json['result'] is Map<String, dynamic>
//           ? TaskerDashboardResult.fromJson(json['result'] as Map<String, dynamic>)
//           : null,
//       errors: (json['errors'] is List)
//           ? (json['errors'] as List)
//               .map((e) => ApiError.fromJson(e as Map<String, dynamic>))
//               .toList()
//           : <ApiError>[],
//     );
//   }
// }

// class TaskerDashboardResult {
//   // Keep fields flexible because backend may change.
//   final dynamic raw;

//   TaskerDashboardResult({required this.raw});

//   factory TaskerDashboardResult.fromJson(Map<String, dynamic> json) {
//     return TaskerDashboardResult(raw: json);
//   }
// }

// class ApiError {
//   final String field;
//   final String error;

//   ApiError({required this.field, required this.error});

//   factory ApiError.fromJson(Map<String, dynamic> json) {
//     return ApiError(
//       field: (json['field'] ?? '').toString(),
//       error: (json['error'] ?? '').toString(),
//     );
//   }
// }