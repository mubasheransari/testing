import 'package:equatable/equatable.dart';
import 'package:taskoon/Models/service_document_model.dart';
import 'package:taskoon/Models/user_details_model.dart';
import '../../Models/auth_model.dart';
import '../../Models/login_responnse.dart';
import '../../Models/services_ui_model.dart';

enum UserDetailsStatus { initial, loading, success, failure }

enum AuthStatus { initial, loading, success, failure }

enum ForgotPasswordStatus { initial, loading, success, failure }

enum ChangePasswordStatus { initial, loading, success, failure }

enum ServicesStatus { initial, loading, success, failure }

enum DocumentsStatus { initial, loading, success, failure }

enum PaymentStatus { initial, loading, urlReady, failure }

enum CertificateSubmitStatus { initial, uploading, success, failure }

class AuthenticationState extends Equatable {
  final UserDetailsStatus userDetailsStatus;
  final UserDetails? userDetails;
  final String? userDetailsError;
  final CertificateSubmitStatus certificateSubmitStatus;
  final String? certificateSubmitError;
  final PaymentStatus paymentStatus;     // +ADD
  final String? paymentSessionUrl;       // +ADD
  final String? paymentError;            // +ADD
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
       this.userDetailsStatus = UserDetailsStatus.initial,
    this.userDetails,
    this.userDetailsError,
          this.certificateSubmitStatus = CertificateSubmitStatus.initial,
    this.certificateSubmitError,
          this.paymentStatus = PaymentStatus.initial, // +ADD
    this.paymentSessionUrl,                     // +ADD
    this.paymentError,                          // +ADD

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
     UserDetailsStatus? userDetailsStatus,
    UserDetails? userDetails,
    bool clearUserDetailsError = false,
    bool clearUserDetails = false,
    String? userDetailsError,
        CertificateSubmitStatus? certificateSubmitStatus,
    String? certificateSubmitError,
      PaymentStatus? paymentStatus,     // +ADD
    String? paymentSessionUrl,        // +ADD
    String? paymentError,             // +ADD
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
      userDetailsStatus: userDetailsStatus ?? this.userDetailsStatus,
      userDetails: userDetails ?? this.userDetails,
      userDetailsError: clearUserDetailsError ? null : (userDetailsError ?? this.userDetailsError),
            certificateSubmitStatus: certificateSubmitStatus ?? this.certificateSubmitStatus,
        certificateSubmitError: certificateSubmitError,
           paymentStatus: paymentStatus ?? this.paymentStatus,
        paymentSessionUrl: paymentSessionUrl ?? this.paymentSessionUrl,
        paymentError: paymentError,
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
            userDetailsStatus,
        userDetails,
        userDetailsError,
            certificateSubmitStatus,
    certificateSubmitError,
        paymentStatus, paymentSessionUrl, paymentError,
            documentsStatus,
    documents,
    documentsError,servicesStatus,
        serviceGroups,
        servicesError,
        totalSelectedServices,status,changePasswordStatus, forgotPasswordStatus, response, error, loginResponse];
}
