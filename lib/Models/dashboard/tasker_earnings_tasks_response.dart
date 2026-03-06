class TaskerEarningsTasksResponse {
  final bool isSuccess;
  final String? message;
  final TaskerEarningsTasksResult? result;
  final List<String>? errors;

  const TaskerEarningsTasksResponse({
    required this.isSuccess,
    this.message,
    this.result,
    this.errors,
  });

  factory TaskerEarningsTasksResponse.fromJson(Map<String, dynamic> json) {
    return TaskerEarningsTasksResponse(
      isSuccess: json['isSuccess'] == true,
      message: json['message']?.toString(),
      result: json['result'] is Map<String, dynamic>
          ? TaskerEarningsTasksResult.fromJson(
              json['result'] as Map<String, dynamic>,
            )
          : null,
      errors: json['errors'] == null
          ? null
          : (json['errors'] is List
              ? (json['errors'] as List).map((e) => e.toString()).toList()
              : [json['errors'].toString()]),
    );
  }
}

class TaskerEarningsTasksResult {
  final double availableForPayout;
  final int totalTasksCompleted;
  final String? lastTaskEndedAgo;
  final List<TaskerRecentTask> recentTasks;

  const TaskerEarningsTasksResult({
    required this.availableForPayout,
    required this.totalTasksCompleted,
    required this.lastTaskEndedAgo,
    required this.recentTasks,
  });

  factory TaskerEarningsTasksResult.fromJson(Map<String, dynamic> json) {
    return TaskerEarningsTasksResult(
      availableForPayout: _toDouble(json['availableForPayout']),
      totalTasksCompleted: _toInt(json['totalTasksCompleted']),
      lastTaskEndedAgo: json['lastTaskEndedAgo']?.toString(),
      recentTasks: json['recentTasks'] is List
          ? (json['recentTasks'] as List)
              .whereType<Map>()
              .map(
                (e) => TaskerRecentTask.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList()
          : const [],
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}

class TaskerRecentTask {
  final String name;
  final String service;
  final String time;
  final double amount;
  final String status;

  const TaskerRecentTask({
    required this.name,
    required this.service,
    required this.time,
    required this.amount,
    required this.status,
  });

  factory TaskerRecentTask.fromJson(Map<String, dynamic> json) {
    String pickString(List<String> keys, {String fallback = ''}) {
      for (final k in keys) {
        final v = json[k];
        if (v != null && v.toString().trim().isNotEmpty) {
          return v.toString().trim();
        }
      }
      return fallback;
    }

    double pickDouble(List<String> keys, {double fallback = 0}) {
      for (final k in keys) {
        final v = json[k];
        if (v == null) continue;
        if (v is num) return v.toDouble();
        final parsed = double.tryParse(v.toString());
        if (parsed != null) return parsed;
      }
      return fallback;
    }

    return TaskerRecentTask(
      name: pickString(
        [
          'name',
          'customerName',
          'clientName',
          'userName',
          'fullName',
          'taskName',
          'title',
        ],
        fallback: 'Customer',
      ),
      service: pickString(
        [
          'service',
          'serviceName',
          'categoryName',
          'subCategoryName',
          'taskType',
        ],
        fallback: 'Service',
      ),
      time: pickString(
        [
          'time',
          'completedAt',
          'endedAt',
          'createdAt',
          'taskTime',
          'dateTime',
        ],
        fallback: '',
      ),
      amount: pickDouble(
        [
          'amount',
          'earning',
          'earnedAmount',
          'price',
          'payout',
        ],
        fallback: 0,
      ),
      status: pickString(
        [
          'status',
          'taskStatus',
          'bookingStatus',
        ],
        fallback: 'Complete',
      ),
    );
  }
}