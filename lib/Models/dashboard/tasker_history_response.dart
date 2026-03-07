class TaskerHistoryResponse {
  final bool isSuccess;
  final String? message;
  final TaskerHistoryResult? result;
  final List<String>? errors;

  const TaskerHistoryResponse({
    required this.isSuccess,
    this.message,
    this.result,
    this.errors,
  });

  factory TaskerHistoryResponse.fromJson(Map<String, dynamic> json) {
    return TaskerHistoryResponse(
      isSuccess: json['isSuccess'] == true,
      message: json['message']?.toString(),
      result: json['result'] is Map<String, dynamic>
          ? TaskerHistoryResult.fromJson(json['result'] as Map<String, dynamic>)
          : null,
      errors: json['errors'] == null
          ? null
          : (json['errors'] is List
              ? (json['errors'] as List).map((e) => e.toString()).toList()
              : [json['errors'].toString()]),
    );
  }
}

class TaskerHistoryResult {
  final List<TaskerHistoryTask> tasks;

  const TaskerHistoryResult({
    required this.tasks,
  });

  factory TaskerHistoryResult.fromJson(Map<String, dynamic> json) {
    return TaskerHistoryResult(
      tasks: json['tasks'] is List
          ? (json['tasks'] as List)
              .whereType<Map>()
              .map((e) => TaskerHistoryTask.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ))
              .toList()
          : const [],
    );
  }
}

class TaskerHistoryTask {
  final String id;
  final String title;
  final String customerName;
  final String serviceName;
  final String status;
  final String dateTime;
  final double amount;
  final String address;

  const TaskerHistoryTask({
    required this.id,
    required this.title,
    required this.customerName,
    required this.serviceName,
    required this.status,
    required this.dateTime,
    required this.amount,
    required this.address,
  });

  factory TaskerHistoryTask.fromJson(Map<String, dynamic> json) {
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

    return TaskerHistoryTask(
      id: pickString(['id', 'taskId', 'bookingId', 'bookingDetailId']),
      title: pickString(
        ['title', 'taskTitle', 'jobTitle', 'name'],
        fallback: 'Task',
      ),
      customerName: pickString(
        ['customerName', 'userName', 'clientName', 'name'],
        fallback: 'Customer',
      ),
      serviceName: pickString(
        ['serviceName', 'service', 'categoryName', 'subCategoryName'],
        fallback: 'Service',
      ),
      status: pickString(
        ['status', 'taskStatus', 'bookingStatus'],
        fallback: 'Unknown',
      ),
      dateTime: pickString(
        ['dateTime', 'bookingDate', 'createdAt', 'completedAt', 'time'],
      ),
      amount: pickDouble(
        ['amount', 'earning', 'earnedAmount', 'price', 'totalAmount'],
      ),
      address: pickString(['address', 'location', 'serviceAddress']),
    );
  }
}