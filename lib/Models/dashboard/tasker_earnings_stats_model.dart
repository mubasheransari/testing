class TaskerEarningsStatsResponse {
  final bool? isSuccess;
  final String? message;
  final TaskerEarningsStatsResult? result;
  final List<String>? errors;

  TaskerEarningsStatsResponse({
    this.isSuccess,
    this.message,
    this.result,
    this.errors,
  });

  factory TaskerEarningsStatsResponse.fromJson(Map<String, dynamic> json) {
    return TaskerEarningsStatsResponse(
      isSuccess: json['isSuccess'] == true,
      message: json['message']?.toString(),
      result: json['result'] == null
          ? null
          : TaskerEarningsStatsResult.fromJson(
              Map<String, dynamic>.from(json['result']),
            ),
      errors: (json['errors'] is List)
          ? (json['errors'] as List).map((e) => e.toString()).toList()
          : null,
    );
  }
}

class TaskerEarningsStatsResult {
  final double earnings;
  final int tasksCompleted;
  final String onlineTime; // e.g. "0h 0m"
  final double rating;

  TaskerEarningsStatsResult({
    required this.earnings,
    required this.tasksCompleted,
    required this.onlineTime,
    required this.rating,
  });

  factory TaskerEarningsStatsResult.fromJson(Map<String, dynamic> json) {
    return TaskerEarningsStatsResult(
      earnings: (json['earnings'] is num) ? (json['earnings'] as num).toDouble() : 0,
      tasksCompleted: (json['tasksCompleted'] is num) ? (json['tasksCompleted'] as num).toInt() : 0,
      onlineTime: (json['onlineTime'] ?? '0h 0m').toString(),
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : 0,
    );
  }
}