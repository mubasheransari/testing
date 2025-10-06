import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_state.dart';

import '../../Models/auth_model.dart';
import '../../Models/services_ui_model.dart';
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
    on<ChangePassword>(changePassword);

    on<LoadServicesRequested>(_onLoadServices);
    on<ToggleCertification>(_onToggleCertification);
    on<ToggleSingleService>(_onToggleSingleService);
    on<ClearServicesError>(
        (e, emit) => emit(state.copyWith(servicesError: null)));
  }

  // handlers
  Future<void> _onLoadServices(
    LoadServicesRequested e,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(state.copyWith(
        servicesStatus: ServicesStatus.loading, servicesError: null));

    final r = await repo.fetchServices(); // <— from AuthRepository
    if (!r.isSuccess) {
      emit(state.copyWith(
        servicesStatus: ServicesStatus.failure,
        servicesError: r.failure?.message ?? 'Failed to load services',
      ));
      return;
    }

    // group rows by certification
    final map = <int, CertificationGroup>{};
    for (final dto in r.data!) {
      final opt = ServiceOption(id: dto.serviceId, name: dto.serviceName);
      final g = map[dto.certificationId];
      if (g == null) {
        map[dto.certificationId] = CertificationGroup(
            id: dto.certificationId,
            name: dto.certificationName,
            services: [opt]);
      } else {
        map[dto.certificationId] = g.copyWith(services: [...g.services, opt]);
      }
    }

    // sort for stable UI
    final groups = map.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final sorted = groups
        .map((g) => g.copyWith(
              services: (List<ServiceOption>.from(g.services)
                ..sort((a, b) =>
                    a.name.toLowerCase().compareTo(b.name.toLowerCase()))),
            ))
        .toList();

    emit(state.copyWith(
      servicesStatus: ServicesStatus.success,
      serviceGroups: sorted,
      servicesError: null,
    ));
  }

  void _onToggleCertification(
    ToggleCertification e,
    Emitter<AuthenticationState> emit,
  ) {
    final updated = state.serviceGroups.map((g) {
      if (g.id != e.certificationId) return g;
      final svc =
          g.services.map((s) => s.copyWith(isSelected: e.selectAll)).toList();
      return g.copyWith(services: svc);
    }).toList();
    emit(state.copyWith(serviceGroups: updated));
  }

  void _onToggleSingleService(
    ToggleSingleService e,
    Emitter<AuthenticationState> emit,
  ) {
    final updated = state.serviceGroups.map((g) {
      if (g.id != e.certificationId) return g;
      final svc = g.services.map((s) {
        if (s.id == e.serviceId) return s.copyWith(isSelected: e.isSelected);
        return s;
      }).toList();
      return g.copyWith(services: svc);
    }).toList();
    emit(state.copyWith(serviceGroups: updated));
  }

  changePassword(
    ChangePassword event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(state.copyWith(
      changePasswordStatus: ChangePasswordStatus.loading,
      error: null,
    ));

    final result = await repo.changePassword(
        password: event.password, userId: event.userId);

    if (result.isSuccess) {
      emit(state.copyWith(
        changePasswordStatus: ChangePasswordStatus.success,
        response: result.data,
        error: null,
      ));
    } else {
      emit(state.copyWith(
        changePasswordStatus: ChangePasswordStatus.failure,
        error: result.failure?.message ?? 'User not found!',
      ));
    }
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
      // HTTP-level success. Inspect the payload. //Testing@1234
      final RegistrationResponse? res = result.data;

      if (res?.isSuccess == true) {
        emit(state.copyWith(
          status: AuthStatus.success,
          response: res,
          error: null,
        ));
      } else {
        // Prefer message from body; fall back to first error item; then default text.
        final msg = (res?.message?.trim().isNotEmpty ?? false)
            ? res!.message!.trim()
            : ((res?.errors.isNotEmpty ?? false)
                ? (res!.errors.first.error?.trim().isNotEmpty == true
                    ? res.errors.first.error!.trim()
                    : 'OTP verification failed')
                : 'OTP verification failed');

        // print to console
        // ignore: avoid_print
        print('OTP verification failed: $msg');

        emit(state.copyWith(
          status: AuthStatus.failure,
          error: msg,
        ));
      }
    } else {
      // Transport / exception layer.
      final msg = result.failure?.message?.trim().isNotEmpty == true
          ? result.failure!.message!.trim()
          : 'Unable to verify OTP. Please try again.';
      // ignore: avoid_print
      print('OTP verification error: $msg');

      emit(state.copyWith(
        status: AuthStatus.failure,
        error: msg,
      ));
    }
  }

  // Helper (optional, place inside your bloc file)
  String _extractApiMessage(RegistrationResponse? res,
      {String fallback = 'OTP failed'}) {
    if (res == null) return fallback;
    final msg = res.message?.trim();
    if (msg != null && msg.isNotEmpty) return msg;

    if (res.errors.isNotEmpty) {
      final e = res.errors.first;
      final err = e.error?.trim();
      if (err != null && err.isNotEmpty) return err;
      final fld = e.field?.trim();
      if (fld != null && fld.isNotEmpty) return fld;
    }
    return fallback;
  }

  sendotpThroughEmail(
      SendOtpThroughEmail event, Emitter<AuthenticationState> emit) async {
    final result = await repo.sendOtpThroughEmail(
      userId: event.userId,
      email: event.email,//Testing@1234
    );

    if (result.isSuccess) {
      final RegistrationResponse? res = result.data;
      print("RESPONSE ${result.data}");
      print("RESPONSE ${result.data}");
      print("RESPONSE ${result.data}");

      if (res?.isSuccess == true) {
        emit(state.copyWith(
          response: res,
          error: null,
        ));
      } else {
        final msg = _extractApiMessage(res, fallback: 'OTP failed');
        emit(state.copyWith(
          error: msg,
        ));
      }
    } else {
      final msg = (result.failure?.message?.trim().isNotEmpty ?? false)
          ? result.failure!.message!.trim()
          : 'Unable to send OTP. Please try again.';
      print('Send OTP error: $msg');
      emit(state.copyWith(
        error: msg,
      ));
    }
  }

  // sendotpThroughEmail(SendOtpThroughEmail event, emit) {
  //   //  emit(state.copyWith(status: AuthStatus.loading));

  //   repo
  //       .sendOtpThroughEmail(
  //     userId: event.userId,
  //     email: event.email,
  //   )
  //       .then((result) {
  //     if (result.isSuccess) {
  //       emit(state.copyWith(
  //         //   status: AuthStatus.success,
  //         response: result.data, // reuse registrationResponse
  //       ));
  //     } else {
  //       emit(state.copyWith(
  //         //  status: AuthStatus.failure,
  //         error: result.failure?.message ?? 'OTP failed',
  //       ));
  //     }
  //   });
  // }

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
