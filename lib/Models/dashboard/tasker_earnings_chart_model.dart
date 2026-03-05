class TaskerEarningsChartResponse {
  final bool isSuccess;
  final String? message;
  final TaskerEarningsChartResult? result;
  final List<String>? errors;

  TaskerEarningsChartResponse({
    required this.isSuccess,
    this.message,
    this.result,
    this.errors,
  });

  factory TaskerEarningsChartResponse.fromJson(Map<String, dynamic> json) {
    return TaskerEarningsChartResponse(
      isSuccess: json['isSuccess'] == true,
      message: json['message']?.toString(),
      result: json['result'] is Map<String, dynamic>
          ? TaskerEarningsChartResult.fromJson(json['result'] as Map<String, dynamic>)
          : null,
      errors: (json['errors'] is List)
          ? (json['errors'] as List).map((e) => e.toString()).toList()
          : null,
    );
  }
}

class TaskerEarningsChartResult {
  final List<TaskerEarningsChartPoint> chartData;

  TaskerEarningsChartResult({required this.chartData});

  factory TaskerEarningsChartResult.fromJson(Map<String, dynamic> json) {
    final raw = json['chartData'];
    final list = (raw is List)
        ? raw
            .whereType<Map>()
            .map((e) => TaskerEarningsChartPoint.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <TaskerEarningsChartPoint>[];

    return TaskerEarningsChartResult(chartData: list);
  }
}

class TaskerEarningsChartPoint {
  final String label;
  final double amount;

  TaskerEarningsChartPoint({required this.label, required this.amount});

  factory TaskerEarningsChartPoint.fromJson(Map<String, dynamic> json) {
    return TaskerEarningsChartPoint(
      label: (json['label'] ?? '').toString(),
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0.0,
    );
  }
}