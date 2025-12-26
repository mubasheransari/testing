// class AddBookingRequestModel {
//   final String userId;
//   final int subCategoryId;
//   final int bookingTypeId;

//   final DateTime bookingDate;
//   final DateTime startTime;
//   final DateTime endTime;

//   final String address;
//   final int taskerLevelId;

//   final DateTime? endDate;
//   final int? recurrencePatternId;
//   final String? customDays;

//   final double latitude;
//   final double longitude;

//   AddBookingRequestModel({
//     required this.userId,
//     required this.subCategoryId,
//     required this.bookingTypeId,
//     required this.bookingDate,
//     required this.startTime,
//     required this.endTime,
//     required this.address,
//     required this.taskerLevelId,
//     this.endDate,
//     this.recurrencePatternId,
//     this.customDays,
//     required this.latitude,
//     required this.longitude,
//   });

//   Map<String, dynamic> toJson() => {
//         "userId": userId,
//         "subCategoryId": subCategoryId,
//         "bookingTypeId": bookingTypeId,

//         // ✅ IMPORTANT: send ISO strings
//         "bookingDate": bookingDate.toUtc().toIso8601String(),
//         "startTime": startTime.toUtc().toIso8601String(),
//         "endTime": endTime.toUtc().toIso8601String(),

//         "address": address,
//         "taskerLevelId": taskerLevelId,

//         // optional
//         "endDate": endDate?.toUtc().toIso8601String(),
//         "recurrencePatternId": recurrencePatternId,
//         "customDays": customDays,

//         "latitude": latitude,
//         "longitude": longitude,
//       };
// }
class AddBookingRequestModel {
  final String userId;
  final int subCategoryId;
  final int bookingTypeId;
  final DateTime bookingDate;
  final DateTime startTime;
  final DateTime endTime;
  final String address;
  final int taskerLevelId;

  final DateTime? endDate;
  final int? recurrencePatternId;
  final String? customDays;

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

  Map<String, dynamic> toJson() => {
        "userId": userId,
        "subCategoryId": subCategoryId,
        "bookingTypeId": bookingTypeId,
        "bookingDate": bookingDate.toUtc().toIso8601String(),
        "startTime": startTime.toUtc().toIso8601String(),
        "endTime": endTime.toUtc().toIso8601String(),
        "address": address,
        "taskerLevelId": taskerLevelId,
        "endDate": endDate?.toUtc().toIso8601String(),
        "recurrencePatternId": recurrencePatternId,
        "customDays": customDays,
        "latitude": latitude,
        "longitude": longitude,
      };
}
