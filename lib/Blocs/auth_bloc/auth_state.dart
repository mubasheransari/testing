import 'package:equatable/equatable.dart';

import '../../Models/auth_model.dart';




enum AuthStatus { initial, loading, success, failure }

class AuthenticationState extends Equatable {
  final AuthStatus status;
  final RegistrationResponse? response;
  final String? error;

  const AuthenticationState({
    this.status = AuthStatus.initial,
    this.response,
    this.error,
  });

  AuthenticationState copyWith({
    AuthStatus? status,
    RegistrationResponse? response,
    String? error,
  }) =>
      AuthenticationState(
        status: status ?? this.status,
        response: response ?? this.response,
        error: error,
      );

  @override
  List<Object?> get props => [status, response, error];
}
