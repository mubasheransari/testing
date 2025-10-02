import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_state.dart';

import '../../Repository/auth_repository.dart';
import 'auth_event.dart';

class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  final AuthRepository repo;

  AuthenticationBloc(this.repo) : super(const AuthenticationState()) {
    on<RegisterUserRequested>(_onRegisterUser);
    on<RegisterCompanyRequested>(_onRegisterCompany);
    on<RegisterTaskerRequested>(_onRegisterTasker);
    on<SignInRequested>(login);
    on<SendOtpThroughEmail>(sendotpThroughEmail);
    on<VerifyOtpRequested>(_onVerifyOtpRequested);
    on<SendOtpThroughPhone>(sendotpThroughPhone);
    on<VerifyOtpRequestedPhone>(_onVerifyOtpRequestedPhone);
    on<ForgotPasswordRequest>(forgotPasswordRequest);
  }

  forgotPasswordRequest(
    ForgotPasswordRequest event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(state.copyWith(
      forgotPasswordStatus: ForgotPasswordStatus.loading,
      error: null,
    ));

    final result = await repo.forgotPassword(email: event.email);

    if (result.isSuccess) {
      emit(state.copyWith(
        forgotPasswordStatus: ForgotPasswordStatus.success,
        response: result.data,
        error: null,
      ));
    } else {
      emit(state.copyWith(
        forgotPasswordStatus: ForgotPasswordStatus.failure,
        error: result.failure?.message ?? 'User not found!',
      ));
    }
  }

  _onVerifyOtpRequestedPhone(
    VerifyOtpRequestedPhone event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(state.copyWith(
      status: AuthStatus.loading,
      error: null,
    ));

    final result = await repo.verifyOtpThroughPhone(
      userId: event.userId,
      phone: event.phone,
      code: event.code,
    );

    if (result.isSuccess) {
      emit(state.copyWith(
        status: AuthStatus.success,
        response: result.data,
        error: null,
      ));
    } else {
      emit(state.copyWith(
        status: AuthStatus.failure,
        error: result.failure?.message ?? 'OTP verification failed',
      ));
    }
  }

  Future<void> _onVerifyOtpRequested(
    VerifyOtpRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(state.copyWith(
      status: AuthStatus.loading,
      error: null,
    ));

    final result = await repo.verifyOtpThroughEmail(
      userId: event.userId,
      email: event.email,
      code: event.code,
    );

    if (result.isSuccess) {
      // Reuse registrationResponse slot since response shape matches
      emit(state.copyWith(
        status: AuthStatus.success,
        response: result.data,
        error: null,
      ));
    } else {
      emit(state.copyWith(
        status: AuthStatus.failure,
        error: result.failure?.message ?? 'OTP verification failed',
      ));
    }
  }

  sendotpThroughEmail(SendOtpThroughEmail event, emit) {
    //  emit(state.copyWith(status: AuthStatus.loading));

    repo
        .sendOtpThroughEmail(
      userId: event.userId,
      email: event.email,
    )
        .then((result) {
      if (result.isSuccess) {
        emit(state.copyWith(
          //   status: AuthStatus.success,
          response: result.data, // reuse registrationResponse
        ));
      } else {
        emit(state.copyWith(
          //  status: AuthStatus.failure,
          error: result.failure?.message ?? 'OTP failed',
        ));
      }
    });
  }

  sendotpThroughPhone(SendOtpThroughPhone event, emit) {
    repo
        .sendOtpThroughPhone(
      userId: event.userId,
      phoneNumber: event.phone,
    )
        .then((result) {
      if (result.isSuccess) {
        emit(state.copyWith(
          response: result.data,
        ));
      } else {
        emit(state.copyWith(
          error: result.failure?.message ?? 'OTP failed',
        ));
      }
    });
  }

  Future<void> _onRegisterUser(
      RegisterUserRequested e, Emitter<AuthenticationState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final r = await repo.registerUser(
      fullName: e.fullName,
      phoneNumber: e.phoneNumber,
      emailAddress: e.email,
      password: e.password,
      desiredService: e.desiredService,
      companyCategory: e.companyCategory,
      companySubCategory: e.companySubCategory,
      abn: e.abn,
    );
    if (r.isSuccess) {
      emit(state.copyWith(status: AuthStatus.success, response: r.data));
    } else {
      emit(state.copyWith(
          status: AuthStatus.failure, error: r.failure!.message));
    }
  }

  Future<void> _onRegisterCompany(
      RegisterCompanyRequested e, Emitter<AuthenticationState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final r = await repo.registerCompany(
      fullName: e.fullName,
      phoneNumber: e.phoneNumber,
      emailAddress: e.email,
      password: e.password,
      desiredService: e.desiredService,
      companyCategory: e.companyCategory,
      companySubCategory: e.companySubCategory,
      abn: e.abn,
      representativeName: e.representativeName,
      representativeNumber: e.representativeNumber,
    );
    if (r.isSuccess) {
      emit(state.copyWith(status: AuthStatus.success, response: r.data));
    } else {
      emit(state.copyWith(
          status: AuthStatus.failure, error: r.failure!.message));
    }
  }

  Future<void> _onRegisterTasker(
      RegisterTaskerRequested e, Emitter<AuthenticationState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final r = await repo.registerTasker(
      fullName: e.fullName,
      phoneNumber: e.phoneNumber,
      emailAddress: e.email,
      password: e.password,
      address: e.address,
      desiredService: e.desiredService,
    );
    if (r.isSuccess) {
      emit(state.copyWith(status: AuthStatus.success, response: r.data));
    } else {
      emit(state.copyWith(
          status: AuthStatus.failure, error: r.failure!.message));
    }
  }

  login(SignInRequested event, emit) async {
    emit(state.copyWith(status: AuthStatus.loading, error: null));

    final res = await repo.signIn(email: event.email, password: event.password);

    if (res.isSuccess) {
      emit(state.copyWith(
        status: AuthStatus.success,
        loginResponse: res.data,
      ));
    } else {
      emit(state.copyWith(
        status: AuthStatus.failure,
        error: res.failure?.message ?? 'Login failed',
      ));
    }
  }
}
