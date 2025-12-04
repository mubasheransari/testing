import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  /// Ask for permission + return 'City, CountryCode' (e.g. 'Melbourne, AU')
  static Future<String?> getReadableLocation() async {
    // 1. Check services
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null; // you can return a message instead
    }

    // 2. Permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    // 3. Get position
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );

    // 4. Reverse geocode
    final placemarks = await placemarkFromCoordinates(
      pos.latitude,
      pos.longitude,
    );

    if (placemarks.isEmpty) return null;

    final p = placemarks.first;
    final city = p.locality?.isNotEmpty == true
        ? p.locality
        : (p.subAdministrativeArea ?? '');
    final countryCode = p.isoCountryCode ?? '';

    if ((city == null || city.isEmpty) && countryCode.isEmpty) {
      return null;
    }

    return countryCode.isEmpty ? city : '$city, $countryCode';
  }
}
