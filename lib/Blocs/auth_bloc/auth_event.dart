import 'package:equatable/equatable.dart';

import '../../Models/auth_model.dart';

abstract class AuthenticationEvent extends Equatable {
  @override
  List<Object?> get props => [];
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
  final List<SelectableItem> desiredService;

  RegisterTaskerRequested({
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.password,
    this.address,
    this.desiredService = const [],
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
    required this.userId,//Testing@123
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

