import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_state.dart';
import 'package:taskoon/Models/selection_summary_model.dart';
import 'package:taskoon/Models/training_videos_model.dart';
import '../../Models/auth_model.dart';
import '../../Models/services_ui_model.dart';
import '../../Repository/auth_repository.dart';
import 'auth_event.dart';

class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  final AuthRepository repo;
  var storage = GetStorage();

  AuthenticationBloc(this.repo) : super(const AuthenticationState()) {
    on<GetUserStatusRequested>(_onGetUserStatusRequested);
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
      (e, emit) => emit(state.copyWith(servicesError: null)),
    );

    on<LoadServiceDocumentsRequested>(_onLoadServiceDocuments);
    on<CreatePaymentSessionRequested>(_onCreatePaymentSession);
    on<SubmitCertificateBytesRequested>(_onSubmitCertificateBytes);
    on<LoadUserDetailsRequested>(_onLoadUserDetails);
    on<OnboardUserRequested>(_onOnboardUserRequested);
    on<LoadTrainingVideosRequested>(_onLoadTrainingVideosRequested);

    on<UpdateChooseServicesSummaryRequested>((event, emit) {
      final certs =
          event.certificationsSelected ?? state.certificationsSelectedCount;

      final summary = SelectionSummary(
        certificationsSelected: certs,
        servicesSelected: event.servicesSelected,
        totalEligibleServices: event.totalEligibleServices,
      );

      emit(state.copyWith(chooseServicesSummary: summary));
    });
  }

  Future<void> _onLoadTrainingVideosRequested(
    LoadTrainingVideosRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(
      state.copyWith(
        trainingVideosStatus: TrainingVideosStatus.loading,
        clearTrainingVideosError: true,
      ),
    );

    final res = await repo.fetchTrainingVideos();

    if (res.isSuccess) {
      final list = res.data ?? const <TrainingVideo>[]; // <-- use .data
      emit(
        state.copyWith(
          trainingVideosStatus: TrainingVideosStatus.success,
          trainingVideos: list,
        ),
      );
    } else {
      emit(
        state.copyWith(
          trainingVideosStatus: TrainingVideosStatus.failure,
          trainingVideosError:
              res.failure?.message ?? 'Failed to load training videos',
        ),
      );
    }
  }

  Future<void> _onOnboardUserRequested(
    OnboardUserRequested e,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(
      state.copyWith(
        onboardingStatus: OnboardingStatus.submitting,
        clearOnboardingError: true,
      ),
    );

    final res = await repo.onboardUser(
      userId: e.userId,
      servicesId: e.servicesId, // will be []
      profilePicture: e.profilePicture,
      docCertification: e.docCertification, // will be null => omitted
      docInsurance: e.docInsurance,
      docAddressProof: e.docAddressProof,
      docIdVerification: e.docIdVerification,
    );

    // Unwrap your Result<T> (pick the branch that matches your Result)
    if ((res as dynamic).isSuccess == true) {
      emit(state.copyWith(onboardingStatus: OnboardingStatus.success));
    } else {
      final failure = (res as dynamic).failure;
      emit(
        state.copyWith(
          onboardingStatus: OnboardingStatus.failure,
          onboardingError: failure?.message ?? 'Onboarding failed',
        ),
      );
    }

    // If your Result has when()/fold(), use this instead:
    /*
  res.when(
    ok: (_) => emit(state.copyWith(onboardingStatus: OnboardingStatus.success)),
    err: (f) => emit(state.copyWith(
      onboardingStatus: OnboardingStatus.failure,
      onboardingError: f.message,
    )),
  );
  */
  }

  Future<void> _onLoadUserDetails(
    LoadUserDetailsRequested e,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(
      state.copyWith(
        userDetailsStatus: UserDetailsStatus.loading,
        userDetailsError: null,
        clearUserDetails: true,
      ),
    );

    final r = await repo.fetchUserDetails(userId: e.userId);
    print('USER DETAILS $r');
    print('USER DETAILS $r');
    print('USER DETAILS $r');

    if (r.isSuccess) {
      emit(
        state.copyWith(
          userDetailsStatus: UserDetailsStatus.success,
          userDetails: r.data!,
          userDetailsError: null,
        ),
      );
    } else {
      emit(
        state.copyWith(
          userDetailsStatus: UserDetailsStatus.failure,
          userDetailsError: r.failure!.message,
        ),
      );
    }
  }

  Future<void> _onSubmitCertificateBytes(
    SubmitCertificateBytesRequested e,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(
      state.copyWith(
        certificateSubmitStatus: CertificateSubmitStatus.uploading,
        certificateSubmitError: null,
      ),
    );

    final r = await repo.submitCertificate(
      userId: e.userId,
      serviceId: e.serviceId,
      documentId: e.documentId,
      bytes: e.bytes,
      fileName: e.fileName,
      mimeType: e.mimeType,
    );

    if (r.isSuccess) {
      emit(
        state.copyWith(
          certificateSubmitStatus: CertificateSubmitStatus.success,
          certificateSubmitError: null,
        ),
      );
    } else {
      emit(
        state.copyWith(
          certificateSubmitStatus: CertificateSubmitStatus.failure,
          certificateSubmitError:
              r.failure?.message ?? 'Certificate submit failed',
        ),
      );
    }
  }

  Future<void> _onCreatePaymentSession(
    CreatePaymentSessionRequested e,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(
      state.copyWith(
        paymentStatus: PaymentStatus.loading,
        paymentError: null,
        paymentSessionUrl: null,
      ),
    );

    final r = await repo.createPaymentSession(
      userId: e.userId,
      amount: e.amount,
      paymentMethod: e.paymentMethod,
    );

    if (r.isSuccess) {
      emit(
        state.copyWith(
          paymentStatus: PaymentStatus.urlReady,
          paymentSessionUrl: r.data,
          paymentError: null,
        ),
      );
    } else {
      emit(
        state.copyWith(
          paymentStatus: PaymentStatus.failure,
          paymentError:
              r.failure?.message ?? 'Failed to create checkout session',
          paymentSessionUrl: null,
        ),
      );
    }
  }

  Future<void> _onLoadServiceDocuments(
    LoadServiceDocumentsRequested e,
    Emitter<AuthenticationState> emit,
  ) async {
    // 1) set loading
    emit(
      state.copyWith(
        documentsStatus: DocumentsStatus.loading,
        documentsError: null,
      ),
    );

    // 2) call repo
    final r = await repo.fetchServiceDocuments();

    // 3) handle failure
    if (!r.isSuccess) {
      emit(
        state.copyWith(
          documentsStatus: DocumentsStatus.failure,
          documentsError: r.failure?.message ?? 'Failed to load documents',
        ),
      );
      return;
    }

    // 4) success (API returns a flat List<ServiceDocument>)
    final docs = r.data!;

    // Optional: dedupe exact duplicates (by serviceId+documentId)
    // final seen = <String>{};
    // final unique = <ServiceDocument>[];
    // for (final d in docs) {
    //   final k = '${d.serviceId}:${d.documentId}';
    //   if (seen.add(k)) unique.add(d);
    // }

    emit(
      state.copyWith(
        documentsStatus: DocumentsStatus.success,
        documents: docs, // or: unique
        documentsError: null,
      ),
    );
  }

  //   Future<void> _onLoadServiceDocuments(
  //   LoadServiceDocumentsRequested e,
  //   Emitter<AuthenticationState> emit,
  // ) async {
  //   emit(state.copyWith(
  //     documentsStatus: DocumentsStatus.loading,
  //     documentsError: null,
  //   ));

  //   final r = await repo.fetchServiceDocuments(); // your GET
  //   if (!r.isSuccess) {
  //     emit(state.copyWith(
  //       documentsStatus: DocumentsStatus.failure,
  //       documentsError: r.failure?.message ?? 'Failed to load documents',
  //     ));
  //     return;
  //   }

  //   // Flatten List<ServiceDocumentResponse> -> List<ServiceDocument>
  //   final out = <ServiceDocument>[];
  //   for (final resp in r.data!) {
  //     out.addAll(resp.result);
  //   }

  //   emit(state.copyWith(
  //     documentsStatus: DocumentsStatus.success,
  //     documents: out,
  //     documentsError: null,
  //   ));
  // }

  // handlers
  Future<void> _onLoadServices(
    LoadServicesRequested e,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(
      state.copyWith(
        servicesStatus: ServicesStatus.loading,
        servicesError: null,
      ),
    );

    final r = await repo.fetchServices(); // <— from AuthRepository
    if (!r.isSuccess) {
      emit(
        state.copyWith(
          servicesStatus: ServicesStatus.failure,
          servicesError: r.failure?.message ?? 'Failed to load services',
        ),
      );
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
          services: [opt],
        );
      } else {
        map[dto.certificationId] = g.copyWith(services: [...g.services, opt]);
      }
    }

    // sort for stable UI
    final groups = map.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final sorted = groups
        .map(
          (g) => g.copyWith(
            services: (List<ServiceOption>.from(g.services)
              ..sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              )),
          ),
        )
        .toList();

    emit(
      state.copyWith(
        servicesStatus: ServicesStatus.success,
        serviceGroups: sorted,
        servicesError: null,
      ),
    );
  }

  void _onToggleCertification(
    ToggleCertification e,
    Emitter<AuthenticationState> emit,
  ) {
    final updated = state.serviceGroups.map((g) {
      if (g.id != e.certificationId) return g;
      final svc = g.services
          .map((s) => s.copyWith(isSelected: e.selectAll))
          .toList();
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
    emit(
      state.copyWith(
        changePasswordStatus: ChangePasswordStatus.loading,
        error: null,
      ),
    );

    final result = await repo.changePassword(
      password: event.password,
      userId: event.userId,
    );

    if (result.isSuccess) {
      emit(
        state.copyWith(
          changePasswordStatus: ChangePasswordStatus.success,
          response: result.data,
          error: null,
        ),
      );
    } else {
      emit(
        state.copyWith(
          changePasswordStatus: ChangePasswordStatus.failure,
          error: result.failure?.message ?? 'User not found!',
        ),
      );
    }
  }

  forgotPasswordRequest(
    ForgotPasswordRequest event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(
      state.copyWith(
        forgotPasswordStatus: ForgotPasswordStatus.loading,
        error: null,
      ),
    );

    final result = await repo.forgotPassword(email: event.email);

    if (result.isSuccess) {
      emit(
        state.copyWith(
          forgotPasswordStatus: ForgotPasswordStatus.success,
          response: result.data,
          error: null,
        ),
      );
    } else {
      emit(
        state.copyWith(
          forgotPasswordStatus: ForgotPasswordStatus.failure,
          error: result.failure?.message ?? 'User not found!',
        ),
      );
    }
  }

  _onVerifyOtpRequestedPhone(
    VerifyOtpRequestedPhone event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, error: null));

    final result = await repo.verifyOtpThroughPhone(
      userId: event.userId,
      phone: event.phone,
      code: event.code,
    );

    if (result.isSuccess) {
      emit(
        state.copyWith(
          status: AuthStatus.success,
          response: result.data,
          error: null,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          error: result.failure?.message ?? 'OTP verification failed',
        ),
      );
    }
  }

  Future<void> _onVerifyOtpRequested(
    VerifyOtpRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, error: null));

    final result = await repo.verifyOtpThroughEmail(
      userId: event.userId,
      email: event.email,
      code: event.code,
    );

    if (result.isSuccess) {
      // HTTP-level success. Inspect the payload. //Testing@1234
      final RegistrationResponse? res = result.data;

      if (res?.isSuccess == true) {
        emit(
          state.copyWith(
            status: AuthStatus.success,
            response: res,
            error: null,
          ),
        );
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

        emit(state.copyWith(status: AuthStatus.failure, error: msg));
      }
    } else {
      // Transport / exception layer.
      final msg = result.failure?.message?.trim().isNotEmpty == true
          ? result.failure!.message!.trim()
          : 'Unable to verify OTP. Please try again.';
      // ignore: avoid_print
      print('OTP verification error: $msg');

      emit(state.copyWith(status: AuthStatus.failure, error: msg));
    }
  }

  // Helper (optional, place inside your bloc file)
  String _extractApiMessage(
    RegistrationResponse? res, {
    String fallback = 'OTP failed',
  }) {
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
    SendOtpThroughEmail event,
    Emitter<AuthenticationState> emit,
  ) async {
    final result = await repo.sendOtpThroughEmail(
      userId: event.userId,
      email: event.email, //Testing@1234
    );

    if (result.isSuccess) {
      final RegistrationResponse? res = result.data;
      print("RESPONSE ${result.data}");
      print("RESPONSE ${result.data}");
      print("RESPONSE ${result.data}");

      if (res?.isSuccess == true) {
        emit(state.copyWith(response: res, error: null));
      } else {
        final msg = _extractApiMessage(res, fallback: 'OTP failed');
        emit(state.copyWith(error: msg));
      }
    } else {
      final msg = (result.failure?.message?.trim().isNotEmpty ?? false)
          ? result.failure!.message!.trim()
          : 'Unable to send OTP. Please try again.';
      print('Send OTP error: $msg');
      emit(state.copyWith(error: msg));
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
        .sendOtpThroughPhone(userId: event.userId, phoneNumber: event.phone)
        .then((result) {
          if (result.isSuccess) {
            emit(state.copyWith(response: result.data));
          } else {
            emit(
              state.copyWith(error: result.failure?.message ?? 'OTP failed'),
            );
          }
        });
  }

  Future<void> _onRegisterUser(
    RegisterUserRequested e,
    Emitter<AuthenticationState> emit,
  ) async {
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
      emit(
        state.copyWith(status: AuthStatus.failure, error: r.failure!.message),
      );
    }
  }

  Future<void> _onRegisterCompany(
    //Testing@123
    RegisterCompanyRequested e,
    Emitter<AuthenticationState> emit,
  ) async {
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
      emit(
        state.copyWith(status: AuthStatus.failure, error: r.failure!.message),
      );
    }
  }

  Future<void> _onRegisterTasker(
    RegisterTaskerRequested e,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final r = await repo.registerTasker(
      fullName: e.fullName,
      phoneNumber: e.phoneNumber,
      emailAddress: e.email,
      password: e.password,
      address: e.address,
      abn: e.abn,
      taskerLevelId: 1, //new Testing@123
    );
    if (r.isSuccess) {
      emit(state.copyWith(status: AuthStatus.success, response: r.data));
    } else {
      emit(
        state.copyWith(status: AuthStatus.failure, error: r.failure!.message),
      );
    }
  }

  login(SignInRequested event, emit) async {
    emit(state.copyWith(status: AuthStatus.loading, error: null));

    final res = await repo.signIn(email: event.email, password: event.password);

    if (res.isSuccess && res.data != null) {
      debugPrint('LOGIN OK => ${res.data!.result?.user?.email}');
      emit(
        state.copyWith(
          status: AuthStatus.success,
          loginResponse: res.data, // 🔥 stored in state
          error: null,
        ),
      );

      storage.write("isActive", res.data!.result!.user!.isActive.toString());
      storage.write(
        "isOnboardingRequired",
        res.data!.result!.user!.requiresOnboarding.toString(),
      );
    } else {
      debugPrint('LOGIN FAIL => ${res.failure}');
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          error: res.failure?.message ?? 'Login failed',
        ),
      );
    }
    // emit(state.copyWith(status: AuthStatus.loading, error: null));

    // final res = await repo.signIn(email: event.email, password: event.password);

    // if (res.isSuccess) {
    //   emit(state.copyWith(
    //     status: AuthStatus.success,
    //     loginResponse: res.data,
    //   ));
    // } else {
    //   emit(state.copyWith(
    //     status: AuthStatus.failure,
    //     error: res.failure?.message ?? 'Login failed',
    //   ));
    // }
  }

  Future<void> _onGetUserStatusRequested(
    GetUserStatusRequested e,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(
      state.copyWith(getUserStatusEnum: GetUserStatusEnum.loading, error: null),
    );

    final r = await repo.getUserStatus(
      userId: e.userId,
      email: e.email,
      phone: e.phone,
      isActive: true,
    );

    if (r.isSuccess) {
      emit(
        state.copyWith(
          getUserStatusEnum: GetUserStatusEnum.success,
          response: r.data, // RegistrationResponse
          error: null,
        ),
      );
    } else {
      emit(
        state.copyWith(
          getUserStatusEnum: GetUserStatusEnum.failure,
          error: r.failure?.message ?? 'Failed to get user status',
        ),
      );
    }
  }
}
