class Failure {
  final String code; // keep as String (your error said code expects String)
  final String message;

  Failure({required this.code, required this.message});
}

class Result<T> {
  final T? data;
  final Failure? failure;

  const Result._(this.data, this.failure);

  bool get isSuccess => data != null && failure == null;

  static Result<T> ok<T>(T data) => Result._(data, null);

  static Result<T> fail<T>(Failure failure) => Result._(null, failure);
}
