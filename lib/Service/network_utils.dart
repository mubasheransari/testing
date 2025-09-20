// network_utils.dart
import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkUtils {
  static Future<bool> hasInternet({String host = 'google.com'}) async {
    final c = await Connectivity().checkConnectivity();
    if (c == ConnectivityResult.none) return false;
    try {
      final res = await InternetAddress.lookup(host).timeout(const Duration(seconds: 3));
      return res.isNotEmpty && res.first.rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException {
      return false;
    }
  }
}
