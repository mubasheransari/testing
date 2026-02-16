class PaymentIntentResponse {
  final bool isSuccess;
  final String? message;
  final dynamic result; // keep dynamic to avoid break if backend changes shape
  final List<dynamic>? errors;

  PaymentIntentResponse({
    required this.isSuccess,
    this.message,
    this.result,
    this.errors,
  });

  factory PaymentIntentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentIntentResponse(
      isSuccess: json['isSuccess'] == true,
      message: json['message']?.toString(),
      result: json['result'],
      errors: (json['errors'] is List) ? (json['errors'] as List) : null,
    );
  }
}
