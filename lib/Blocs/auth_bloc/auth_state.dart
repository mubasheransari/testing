import 'package:equatable/equatable.dart';

import '../../Models/auth_model.dart';
import '../../Models/login_responnse.dart';
import '../../Models/services_ui_model.dart';

enum AuthStatus { initial, loading, success, failure }

enum ForgotPasswordStatus { initial, loading, success, failure }

enum ChangePasswordStatus { initial, loading, success, failure }

enum ServicesStatus { initial, loading, success, failure }

class AuthenticationState extends Equatable {
  final AuthStatus status;
  final ForgotPasswordStatus forgotPasswordStatus;
  final ChangePasswordStatus changePasswordStatus;
  final RegistrationResponse? response;
  final String? error;
  final LoginResponse? loginResponse;
  final ServicesStatus servicesStatus;
  final List<CertificationGroup> serviceGroups;
  final String? servicesError;


  int get totalSelectedServices =>
      serviceGroups.fold(0, (sum, g) => sum + g.selectedCount);

  const AuthenticationState(
      {
           this.servicesStatus = ServicesStatus.initial,
    this.serviceGroups = const [],
    this.servicesError,
        this.status = AuthStatus.initial,
      this.changePasswordStatus = ChangePasswordStatus.initial,
      this.forgotPasswordStatus = ForgotPasswordStatus.initial,
      this.response,
      this.error,
      this.loginResponse});

  AuthenticationState copyWith({
      ServicesStatus? servicesStatus,
    List<CertificationGroup>? serviceGroups,
    String? servicesError,
    AuthStatus? status,
    ForgotPasswordStatus? forgotPasswordStatus,
    ChangePasswordStatus? changePasswordStatus,
    RegistrationResponse? response,
    String? error,
    LoginResponse? loginResponse,
  }) =>
      AuthenticationState(
         servicesStatus: servicesStatus ?? this.servicesStatus,
        serviceGroups: serviceGroups ?? this.serviceGroups,
        servicesError: servicesError,
          status: status ?? this.status,
          changePasswordStatus: changePasswordStatus ?? this.changePasswordStatus,
          forgotPasswordStatus:
              forgotPasswordStatus ?? this.forgotPasswordStatus,//Testing@123
          response: response ?? this.response,
          error: error,
          loginResponse: loginResponse ?? this.loginResponse);

  @override
  List<Object?> get props =>
      [    servicesStatus,
        serviceGroups,
        servicesError,
        totalSelectedServices,status,changePasswordStatus, forgotPasswordStatus, response, error, loginResponse];
}
