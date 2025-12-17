// lib/Models/user_details.dart

class UserDetails {
  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final String? profilePictureUrl;
  final DateTime? createdDate;
  final bool isActive;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final bool isPaymentVerified;
  final String userRole;
  final String? street;
  final String? city;
  final String? zipCode;
  final String? state;
  final String? country;
  final double? latitude;
  final double? longitude;

  const UserDetails({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    this.profilePictureUrl,
    this.createdDate,
    required this.isActive,
    required this.isEmailVerified,
    required this.isPhoneVerified,
    required this.isPaymentVerified,
    required this.userRole,
    this.street,
    this.city,
    this.zipCode,
    this.state,
    this.country,
    this.latitude,
    this.longitude,
  });

  /// Dart's DateTime.parse supports up to 6 fractional digits.
  /// Your API sometimes returns 7 (e.g., "2025-10-15T10:05:24.3389352").
  /// This helper truncates to 6 so parsing never fails.
  static DateTime? _parseIso8601Relaxed(String? s) {
    if (s == null || s.isEmpty) return null;
    final i = s.indexOf('.');
    if (i > 0) {
      final z = s.indexOf('Z', i);
      final end = z > 0 ? z : s.length;
      final frac = s.substring(i + 1, end);
      if (frac.length > 6) {
        final truncated = s.replaceFirst(frac, frac.substring(0, 6));
        return DateTime.tryParse(truncated);
      }
    }
    return DateTime.tryParse(s);
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static bool _b(dynamic v) => v == true;

  factory UserDetails.fromJson(Map<String, dynamic> j) {
    return UserDetails(
      userId: (j['userId'] ?? '').toString(),
      fullName: (j['fullName'] ?? '').toString(),
      email: (j['email'] ?? '').toString(),
      phone: (j['phone'] ?? '').toString(),
      profilePictureUrl: j['profilePictureUrl']?.toString(),
      createdDate: _parseIso8601Relaxed(j['createdDate']?.toString()),

      isActive: _b(j['isActive']),
      isEmailVerified: _b(j['isEmailVerified']),
      isPhoneVerified: _b(j['isPhoneVerified']),
      isPaymentVerified: _b(j['isPaymentVerified']),

      userRole: (j['userRole'] ?? '').toString(),
      street: j['street']?.toString(),
      city: j['city']?.toString(),
      zipCode: j['zipCode']?.toString(),
      state: j['state']?.toString(),
      country: j['country']?.toString(),
      latitude: _toDouble(j['latitude']),
      longitude: _toDouble(j['longitude']),
    );
  }
}
