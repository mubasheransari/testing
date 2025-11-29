// lib/models/location_update.dart



// lib/models/address_models.dart

class AddressLocation {
  final String userId;
  final double latitude;
  final double longitude;

  // Optional address fields from your response
  final String? street;
  final String? city;
  final String? state;
  final String? country;
  final String? zipCode;

  AddressLocation({
    required this.userId,
    required this.latitude,
    required this.longitude,
    this.street,
    this.city,
    this.state,
    this.country,
    this.zipCode,
  });

  factory AddressLocation.fromJson(Map<String, dynamic> json) {
    return AddressLocation(
      userId: json['userId']?.toString() ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      street: json['street'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      zipCode: json['zipcode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class AddressUpdateResponse {
  final bool isSuccess;
  final String message;
  final AddressLocation? result;

  AddressUpdateResponse({
    required this.isSuccess,
    required this.message,
    this.result,
  });

  factory AddressUpdateResponse.fromJson(Map<String, dynamic> json) {
    return AddressUpdateResponse(
      isSuccess: json['isSuccess'] == true,
      message: json['message']?.toString() ?? '',
      result: json['result'] != null
          ? AddressLocation.fromJson(json['result'] as Map<String, dynamic>)
          : null,
    );
  }
}

// class LocationUpdate {
//   final String userId;
//   final double latitude;
//   final double longitude;

//   // Optional extra fields (street/city/…)
//   final String? street;
//   final String? city;
//   final String? state;
//   final String? country;
//   final String? zipCode;

//   LocationUpdate({
//     required this.userId,
//     required this.latitude,
//     required this.longitude,
//     this.street,
//     this.city,
//     this.state,
//     this.country,
//     this.zipCode,
//   });

//   factory LocationUpdate.fromJson(Map<String, dynamic> json) {
//     return LocationUpdate(
//       userId: json['userId']?.toString() ?? '',
//       latitude: (json['latitude'] ?? 0).toDouble(),
//       longitude: (json['longitude'] ?? 0).toDouble(),
//       street: json['street'] as String?,
//       city: json['city'] as String?,
//       state: json['state'] as String?,
//       country: json['country'] as String?,
//       zipCode: json['zipCode'] as String?,
//     );
//   }
// }
