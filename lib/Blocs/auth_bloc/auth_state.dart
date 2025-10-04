import 'package:equatable/equatable.dart';

import '../../Models/auth_model.dart';
import '../../Models/login_responnse.dart';

enum AuthStatus { initial, loading, success, failure }

enum ForgotPasswordStatus { initial, loading, success, failure }

enum ChangePasswordStatus { initial, loading, success, failure }

class AuthenticationState extends Equatable {
  final AuthStatus status;
  final ForgotPasswordStatus forgotPasswordStatus;
  final ChangePasswordStatus changePasswordStatus;
  final RegistrationResponse? response;
  final String? error;
  final LoginResponse? loginResponse;

  const AuthenticationState(
      {this.status = AuthStatus.initial,
      this.changePasswordStatus = ChangePasswordStatus.initial,
      this.forgotPasswordStatus = ForgotPasswordStatus.initial,
      this.response,
      this.error,
      this.loginResponse});

  AuthenticationState copyWith({
    AuthStatus? status,
    ForgotPasswordStatus? forgotPasswordStatus,
    ChangePasswordStatus? changePasswordStatus,
    RegistrationResponse? response,
    String? error,
    LoginResponse? loginResponse,
  }) =>
      AuthenticationState(
          status: status ?? this.status,
          changePasswordStatus: changePasswordStatus ?? this.changePasswordStatus,
          forgotPasswordStatus:
              forgotPasswordStatus ?? this.forgotPasswordStatus,
          response: response ?? this.response,
          error: error,
          loginResponse: loginResponse ?? this.loginResponse);

  @override
  List<Object?> get props =>
      [status,changePasswordStatus, forgotPasswordStatus, response, error, loginResponse];
}
