import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_state.dart';

import '../../Repository/auth_repository.dart';
import 'auth_event.dart';



class AuthenticationBloc extends Bloc<AuthenticationEvent, AuthenticationState> {
  final AuthRepository repo;

  AuthenticationBloc(this.repo) : super(const AuthenticationState()) {
    on<RegisterUserRequested>(_onRegisterUser);
    on<RegisterCompanyRequested>(_onRegisterCompany);
    on<RegisterTaskerRequested>(_onRegisterTasker);
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
      emit(state.copyWith(status: AuthStatus.failure, error: r.failure!.message));
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
      emit(state.copyWith(status: AuthStatus.failure, error: r.failure!.message));
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
      emit(state.copyWith(status: AuthStatus.failure, error: r.failure!.message));
    }
  }
}



// class AuthenticationBloc
//     extends Bloc<AuthenticationEvent, AuthenticationState> {
//   final AuthRepository repo;

//   AuthenticationBloc(this.repo) : super(const AuthenticationState()) {
//     on<RegisterUserRequested>(_onRegisterUser);
//     on<RegisterCompanyRequested>(_onRegisterCompany);
//     on<RegisterTaskerRequested>(_onRegisterTasker);
//   }

//   Future<void> _onRegisterUser(
//       RegisterUserRequested e, Emitter<AuthenticationState> emit) async {
//     emit(state.copyWith(status: AuthStatus.loading));
//     final r = await repo.registerUser(
//       fullName: e.fullName,
//       phoneNumber: e.phoneNumber,
//       emailAddress: e.email,
//       password: e.password,
//       desiredService: e.desiredService,
//       companyCategory: e.companyCategory,
//       companySubCategory: e.companySubCategory,
//       abn: e.abn,
//     );
//     if (r.isSuccess) {
//       emit(state.copyWith(status: AuthStatus.success, response: r.data));
//     } else {
//       emit(state.copyWith(status: AuthStatus.failure, error: r.failure!.message));
//     }
//   }

//   Future<void> _onRegisterCompany(
//       RegisterCompanyRequested e, Emitter<AuthenticationState> emit) async {
//     emit(state.copyWith(status: AuthStatus.loading));
//     final r = await repo.registerCompany(
//       fullName: e.fullName,
//       phoneNumber: e.phoneNumber,
//       emailAddress: e.email,
//       password: e.password,
//       desiredService: e.desiredService,
//       companyCategory: e.companyCategory,
//       companySubCategory: e.companySubCategory,
//       abn: e.abn,
//       representativeName: e.representativeName,
//       representativeNumber: e.representativeNumber,
//     );
//     if (r.isSuccess) {
//       emit(state.copyWith(status: AuthStatus.success, response: r.data));
//     } else {
//       emit(state.copyWith(status: AuthStatus.failure, error: r.failure!.message));
//     }
//   }

//   Future<void> _onRegisterTasker(
//       RegisterTaskerRequested e, Emitter<AuthenticationState> emit) async {
//     emit(state.copyWith(status: AuthStatus.loading));
//     final r = await repo.registerTasker(
//       fullName: e.fullName,
//       phoneNumber: e.phoneNumber,
//       emailAddress: e.email,
//       password: e.password,
//       address: e.address,
//       desiredService: e.desiredService,
//     );
//     if (r.isSuccess) {
//       emit(state.copyWith(status: AuthStatus.success, response: r.data));
//     } else {
//       emit(state.copyWith(status: AuthStatus.failure, error: r.failure!.message));
//     }
//   }
// }
