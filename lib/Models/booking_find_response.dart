// booking_find_response.dart

class BookingFindResponse {
  final bool isSuccess;
  final String message;
  final dynamic result; // replace with proper model later
  final dynamic errors;

  BookingFindResponse({
    required this.isSuccess,
    required this.message,
    this.result,
    this.errors,
  });

  factory BookingFindResponse.fromJson(Map<String, dynamic> json) {
    return BookingFindResponse(
      isSuccess: json['isSuccess'] as bool,
      message: json['message'] as String? ?? '',
      result: json['result'],
      errors: json['errors'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isSuccess': isSuccess,
      'message': message,
      'result': result,
      'errors': errors,
    };
  }
}
