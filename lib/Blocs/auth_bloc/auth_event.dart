import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:taskoon/Models/named_bytes.dart';

import '../../Models/auth_model.dart';

abstract class AuthenticationEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SubmitCertificateBytesRequested extends AuthenticationEvent {
  final String userId;
  final int serviceId;
  final int documentId;
  final Uint8List bytes;
  final String? fileName;
  final String? mimeType;

  SubmitCertificateBytesRequested({
    required this.userId,
    required this.serviceId,
    required this.documentId,
    required this.bytes,
    this.fileName,
    this.mimeType,
  });

  @override
  List<Object?> get props => [userId, serviceId, documentId, bytes, fileName, mimeType];
}


class RegisterUserRequested extends AuthenticationEvent {
  final String fullName, phoneNumber, email, password;
  final List<SelectableItem> desiredService,
      companyCategory,
      companySubCategory;
  final String? abn;

  RegisterUserRequested({
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.password,
    this.desiredService = const [],
    this.companyCategory = const [],
    this.companySubCategory = const [],
    this.abn,
  });
}

class RegisterCompanyRequested extends AuthenticationEvent {
  final String fullName, phoneNumber, email, password;
  final List<SelectableItem> desiredService,
      companyCategory,
      companySubCategory;
  final String? abn, representativeName, representativeNumber;

  RegisterCompanyRequested({
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.password,
    this.desiredService = const [],
    this.companyCategory = const [],
    this.companySubCategory = const [],
    this.abn,
    this.representativeName,
    this.representativeNumber,
  });
}

class RegisterTaskerRequested extends AuthenticationEvent {
  final String fullName, phoneNumber, email, password;
  final String? address;

  RegisterTaskerRequested({
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.password,
    this.address,
  });
}

class SignInRequested extends AuthenticationEvent {
  final String email;
  final String password;

  SignInRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class SendOtpThroughEmail extends AuthenticationEvent {
  final String userId;
  final String email;

  SendOtpThroughEmail({
    required this.userId,
    required this.email,
  });

  @override
  List<Object?> get props => [userId, email];
}

class SendOtpThroughPhone extends AuthenticationEvent {
  final String userId;
  final String phone;

  SendOtpThroughPhone({
    required this.userId, //Testing@123
    required this.phone,
  });

  @override
  List<Object?> get props => [userId, phone];
}

class VerifyOtpRequested extends AuthenticationEvent {
  final String userId;
  final String email;
  final String code;

  VerifyOtpRequested({
    required this.userId,
    required this.email,
    required this.code,
  });

  @override
  List<Object?> get props => [userId, email, code];
}

class VerifyOtpRequestedPhone extends AuthenticationEvent {
  final String userId;
  final String code;
  final String phone;

  VerifyOtpRequestedPhone(
      {required this.userId, required this.code, required this.phone});

  @override
  List<Object?> get props => [userId, code, phone];
}

class ForgotPasswordRequest extends AuthenticationEvent {
  final String email;

  ForgotPasswordRequest({required this.email});

  @override
  List<Object?> get props => [email];
}

class ChangePassword extends AuthenticationEvent {
  final String password;
  final String userId;
  ChangePassword({required this.password, required this.userId});

  @override
  List<Object?> get props => [password, userId];
}


class LoadServicesRequested extends AuthenticationEvent {}

class ToggleCertification extends AuthenticationEvent {
  final int certificationId;
  final bool selectAll;
  ToggleCertification({required this.certificationId, required this.selectAll});
  @override
  List<Object?> get props => [certificationId, selectAll];
}

class ToggleSingleService extends AuthenticationEvent {
  final int certificationId;
  final int serviceId;
  final bool isSelected;
  ToggleSingleService({
    required this.certificationId,
    required this.serviceId,
    required this.isSelected,
  });
  @override
  List<Object?> get props => [certificationId, serviceId, isSelected];
}

class ClearServicesError extends AuthenticationEvent {}

class LoadServiceDocumentsRequested extends AuthenticationEvent {}

class CreatePaymentSessionRequested extends AuthenticationEvent {
  final String userId;
  final num amount;
  final String paymentMethod; 

  CreatePaymentSessionRequested({
    required this.userId,
    required this.amount,
    this.paymentMethod = 'stripe',
  });

  @override
  List<Object?> get props => [userId, amount, paymentMethod];
}

class LoadUserDetailsRequested extends AuthenticationEvent {
  final String userId;
   LoadUserDetailsRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}
// authentication_event.dart
class OnboardUserRequested extends AuthenticationEvent {
  final String userId;
  final List<int> servicesId;
  final NamedBytes profilePicture;
  final NamedBytes? docCertification; // null => empty
  final NamedBytes docInsurance;
  final NamedBytes docAddressProof;
  final NamedBytes docIdVerification;

   OnboardUserRequested({
    required this.userId,
    this.servicesId = const [],
    required this.profilePicture,
    this.docCertification,
    required this.docInsurance,
    required this.docAddressProof,
    required this.docIdVerification,
  });

  @override
  List<Object?> get props => [
        userId,
        servicesId,
        profilePicture,
        docCertification,
        docInsurance,
        docAddressProof,
        docIdVerification,
      ];
}

class LoadTrainingVideosRequested extends AuthenticationEvent {
   LoadTrainingVideosRequested();
}


// class LoadUserDetailsRequested extends AuthenticationEvent {
//   final String userId;
//    LoadUserDetailsRequested(this.userId);
// }