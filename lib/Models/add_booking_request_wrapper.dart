import 'add_booking_request_model.dart';

class AddBookingRequestWrapper {
  final AddBookingRequestModel request;

  AddBookingRequestWrapper({required this.request});

  Map<String, dynamic> toJson() => {
        "request": request.toJson(),
      };
}
