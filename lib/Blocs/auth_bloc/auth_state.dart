import 'package:equatable/equatable.dart';

import '../../Models/auth_model.dart';
import '../../Models/login_responnse.dart';




enum AuthStatus { initial, loading, success, failure }

class AuthenticationState extends Equatable {
  final AuthStatus status;
  final RegistrationResponse? response;
  final String? error;
  final LoginResponse? loginResponse;

  const AuthenticationState({
    this.status = AuthStatus.initial,
    this.response,
    this.error,
    this.loginResponse
  });

  AuthenticationState copyWith({
    AuthStatus? status,
    RegistrationResponse? response,
    String? error,
    LoginResponse? loginResponse,
  }) =>
      AuthenticationState(
        status: status ?? this.status,
        response: response ?? this.response,
        error: error,
        loginResponse: loginResponse ?? this.loginResponse
      );

  @override
  List<Object?> get props => [status, response, error,loginResponse];
}
