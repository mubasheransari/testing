// network_probe.dart
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

class NetworkProbe {
  static final List<Uri> _defaults = [
    Uri.parse('https://www.gstatic.com/generate_204'),
    Uri.parse('https://clients3.google.com/generate_204'),
    Uri.parse('https://1.1.1.1'),
  ];

  static Future<bool> isOnline({
    Duration timeout = const Duration(seconds: 2),
    Uri? extraEndpoint,          // e.g., your API /health
    String dnsHost = 'google.com',
  }) async {
    final checks = <Future<bool>>[
      _dns(dnsHost, timeout),
      for (final u in {..._defaults, if (extraEndpoint != null) extraEndpoint})
        _httpHead(u, timeout),
    ];

    // fast path: any success finishes early
    try {
      final first = await Future.any([
        for (final f in checks) f,
        Future.delayed(timeout * 2, () => false),
      ]);
      if (first) return true;
    } catch (_) {}

    // slow path: consider all results
    final results = await Future.wait(checks, eagerError: false);
    return results.any((b) => b);
  }

  static Future<bool> _dns(String host, Duration timeout) async {
    try {
      final res = await InternetAddress.lookup(host).timeout(timeout);
      return res.isNotEmpty && res.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _httpHead(Uri url, Duration timeout) async {
    try {
      final res = await http.head(url).timeout(timeout);
      return res.statusCode >= 200 && res.statusCode < 400;
    } catch (_) {
      return false;
    }
  }
}
