import 'package:equatable/equatable.dart';
import 'package:taskoon/Models/service_document_model.dart';
import '../../Models/auth_model.dart';
import '../../Models/login_responnse.dart';
import '../../Models/services_ui_model.dart';

enum AuthStatus { initial, loading, success, failure }

enum ForgotPasswordStatus { initial, loading, success, failure }

enum ChangePasswordStatus { initial, loading, success, failure }

enum ServicesStatus { initial, loading, success, failure }

enum DocumentsStatus { initial, loading, success, failure }

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

    final DocumentsStatus documentsStatus;
  final List<ServiceDocument> documents;
  final String? documentsError;


  int get totalSelectedServices =>
      serviceGroups.fold(0, (sum, g) => sum + g.selectedCount);

  const AuthenticationState(
      {

            this.documentsStatus = DocumentsStatus.initial,
    this.documents = const [],
    this.documentsError,
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
        DocumentsStatus? documentsStatus,
    List<ServiceDocument>? documents,
    String? documentsError,
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
                documentsStatus: documentsStatus ?? this.documentsStatus,
        documents: documents ?? this.documents,
        documentsError: documentsError,
         servicesStatus: servicesStatus ?? this.servicesStatus,
        serviceGroups: serviceGroups ?? this.serviceGroups,
        servicesError: servicesError,
          status: status ?? this.status,
          changePasswordStatus: changePasswordStatus ?? this.changePasswordStatus,
          forgotPasswordStatus:
              forgotPasswordStatus ?? this.forgotPasswordStatus,
          response: response ?? this.response,
          error: error,
          loginResponse: loginResponse ?? this.loginResponse);

  @override
  List<Object?> get props =>
      [    
            documentsStatus,
    documents,
    documentsError,servicesStatus,
        serviceGroups,
        servicesError,
        totalSelectedServices,status,changePasswordStatus, forgotPasswordStatus, response, error, loginResponse];
}
