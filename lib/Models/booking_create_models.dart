class AddBookingRequestModel {
  final String userId;
  final int subCategoryId;
  final int bookingTypeId;

  final DateTime bookingDate;
  final DateTime startTime;
  final DateTime endTime;

  final String address;
  final int taskerLevelId;

  final DateTime? endDate; // for multi-days + recurrence
  final int? recurrencePatternId; // for recurrence
  final String? customDays; // for custom days recurrence

  final double latitude;
  final double longitude;

  AddBookingRequestModel({
    required this.userId,
    required this.subCategoryId,
    required this.bookingTypeId,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.address,
    required this.taskerLevelId,
    this.endDate,
    this.recurrencePatternId,
    this.customDays,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      "userId": userId,
      "subCategoryId": subCategoryId,
      "bookingTypeId": bookingTypeId,
      "bookingDate": bookingDate.toUtc().toIso8601String(),
      "startTime": startTime.toUtc().toIso8601String(),
      "endTime": endTime.toUtc().toIso8601String(),
      "address": address,
      "taskerLevelId": taskerLevelId,
      "latitude": latitude,
      "longitude": longitude,

      // optional
      if (endDate != null) "endDate": endDate!.toUtc().toIso8601String(),
      if (recurrencePatternId != null && recurrencePatternId != 0)
        "recurrencePatternId": recurrencePatternId,
      if (customDays != null && customDays!.trim().isNotEmpty)
        "customDays": customDays,
    };
  }
}

class BookingCreateItem {
  final String bookingId;
  final String bookigNumber;
  final String bookingDetailId;
  final String bookingDetailNumber;
  final double estimatedCost;

  BookingCreateItem({
    required this.bookingId,
    required this.bookigNumber,
    required this.bookingDetailId,
    required this.bookingDetailNumber,
    required this.estimatedCost,
  });

  factory BookingCreateItem.fromJson(Map<String, dynamic> json) {
    return BookingCreateItem(
      bookingId: (json["bookingId"] ?? "").toString(),
      bookigNumber: (json["bookigNumber"] ?? "").toString(),
      bookingDetailId: (json["bookingDetailId"] ?? "").toString(),
      bookingDetailNumber: (json["bookingDetailNumber"] ?? "").toString(),
      estimatedCost: (json["estimatedCost"] is num)
          ? (json["estimatedCost"] as num).toDouble()
          : double.tryParse((json["estimatedCost"] ?? "0").toString()) ?? 0.0,
    );
  }
}

class BookingCreateResponse {
  final String message;
  final List<BookingCreateItem> items;

  BookingCreateResponse({required this.message, required this.items});

  factory BookingCreateResponse.fromApiJson(Map<String, dynamic> json) {
    final message = (json["message"] ?? "").toString();
    final raw = json["result"];

    final items = (raw is List)
        ? raw
            .map((e) => BookingCreateItem.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList()
        : <BookingCreateItem>[];

    return BookingCreateResponse(message: message, items: items);
  }
}
