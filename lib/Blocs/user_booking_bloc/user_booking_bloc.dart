import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_event.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_state.dart';
import 'package:taskoon/Repository/auth_repository.dart';

class UserBookingBloc extends Bloc<UserBookingEvent, UserBookingState> {
  final AuthRepository repo;

  UserBookingBloc(this.repo) : super(const UserBookingState()) {
    on<CreateUserBookingRequested>(_onCreateUserBookingRequested);
  }

  Future<void> _onCreateUserBookingRequested(
    CreateUserBookingRequested e,
    Emitter<UserBookingState> emit,
  ) async {
    // set submitting state, clear any previous error/response
    emit(state.copyWith(
      createStatus: UserBookingCreateStatus.submitting,
      clearCreateError: true,
      clearCreateResponse: true,
    ));

    final r = await repo.createBooking(
      userId: e.userId,
      subCategoryId: e.subCategoryId,
      bookingDate: e.bookingDate,
      startTime: e.startTime,
      endTime: e.endTime,
      address: e.address,
      taskerLevelId: e.taskerLevelId,
    );

    if (r.isSuccess) {
      emit(state.copyWith(
        createStatus: UserBookingCreateStatus.success,
        createResponse: r.data,      // RegistrationResponse from repo
        clearCreateError: true,
      ));
    } else {
      emit(state.copyWith(
        createStatus: UserBookingCreateStatus.failure,
        createError: r.failure?.message ?? 'Failed to create booking',
        clearCreateResponse: true,
      ));
    }
  }
}
