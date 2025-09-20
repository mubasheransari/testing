// connectivity_banner_host.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'network_probe.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class ConnectivityBannerHost extends StatefulWidget {
  const ConnectivityBannerHost({
    super.key,
    required this.child,
    this.extraProbe, // e.g., Uri.parse('https://staging-api.taskoon.com/health')
  });

  final Widget child;
  final Uri? extraProbe;

  @override
  State<ConnectivityBannerHost> createState() => _ConnectivityBannerHostState();
}

enum _NetState { online, offline }

class _ConnectivityBannerHostState extends State<ConnectivityBannerHost> {
  StreamSubscription? _sub;
  Timer? _debounce;
  Timer? _offlinePoller;
  Timer? _autoHideTimer;
  _NetState _state = _NetState.online;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _verifyAndRender());

    _sub = Connectivity()
        .onConnectivityChanged
        .listen((_) {
          // Debounce rapid OS events
          _debounce?.cancel();
          _debounce = Timer(const Duration(milliseconds: 400), _verifyAndRender);
        });
  }

  Future<void> _verifyAndRender() async {
    final online = await NetworkProbe.isOnline(extraEndpoint: widget.extraProbe);

    if (!online) {
      _showOffline();
      _startOfflinePolling(); // keep probing until we’re back
      return;
    }

    // Online. If we were offline, show restored then hide.
    if (_state == _NetState.offline) {
      _state = _NetState.online;
      _stopOfflinePolling();

      // Double-check shortly after, networks can be “warm-up” flaky.
      Future.delayed(const Duration(milliseconds: 600), () async {
        final confirm = await NetworkProbe.isOnline(extraEndpoint: widget.extraProbe);
        if (!mounted) return;
        if (confirm) {
          _showRestored();
        } else {
          // If confirm failed, go back to offline banner and polling
          _showOffline();
          _startOfflinePolling();
        }
      });
    } else {
      // already online, ensure no stale banners
      _clearBanners();
    }
  }

  void _startOfflinePolling() {
    _offlinePoller?.cancel();
    _offlinePoller = Timer.periodic(const Duration(seconds: 1), (_) async {
      final ok = await NetworkProbe.isOnline(extraEndpoint: widget.extraProbe);
      if (ok) _verifyAndRender();
    });
  }

  void _stopOfflinePolling() {
    _offlinePoller?.cancel();
    _offlinePoller = null;
  }

  void _showOffline() {
    _state = _NetState.offline;
    _autoHideTimer?.cancel();
    final m = scaffoldMessengerKey.currentState ?? ScaffoldMessenger.of(context);
    m.clearMaterialBanners();
    m.showMaterialBanner(
      MaterialBanner(
        backgroundColor: Colors.red.shade600,
        contentTextStyle: const TextStyle(color: Colors.white),
        leading: const Icon(Icons.wifi_off, color: Colors.white),
        content: const Text('No internet connection'),
        actions: const [SizedBox.shrink()],
      ),
    );
  }

  void _showRestored() {
    final m = scaffoldMessengerKey.currentState ?? ScaffoldMessenger.of(context);
    m.clearMaterialBanners();
    m.showMaterialBanner(
      MaterialBanner(
        backgroundColor: Colors.green.shade600,
        contentTextStyle: const TextStyle(color: Colors.white),
        leading: const Icon(Icons.wifi, color: Colors.white),
        content: const Text('Internet connection restored'),
        actions: const [SizedBox.shrink()],
      ),
    );
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(seconds: 3), () {
      scaffoldMessengerKey.currentState?.clearMaterialBanners();
    });
  }

  void _clearBanners() {
    _autoHideTimer?.cancel();
    final m = scaffoldMessengerKey.currentState ?? ScaffoldMessenger.of(context);
    m.clearMaterialBanners();
  }

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    _offlinePoller?.cancel();
    _debounce?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}



// // connectivity_banner_host.dart
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'network_utils.dart';

// // Put this in a globals file if you prefer
// final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
//     GlobalKey<ScaffoldMessengerState>();

// class ConnectivityBannerHost extends StatefulWidget {
//   const ConnectivityBannerHost({super.key, required this.child});
//   final Widget child;

//   @override
//   State<ConnectivityBannerHost> createState() => _ConnectivityBannerHostState();
// }

// class _ConnectivityBannerHostState extends State<ConnectivityBannerHost> {
//   StreamSubscription? _sub;
//   Timer? _debounce;
//   bool _wasOffline = false;
//   Timer? _autoHideTimer;

//   @override
//   void initState() {
//     super.initState();
//     // Run once after first frame to ensure messenger is ready
//     WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndShow());

//     _sub = Connectivity()
//         .onConnectivityChanged
//         .listen((_) {
//           // Debounce rapid events
//           _debounce?.cancel();
//           _debounce = Timer(const Duration(milliseconds: 450), _checkAndShow);
//         });
//   }

//   Future<void> _checkAndShow() async {
//     final online = await NetworkUtils.hasInternet();

//     final messenger = scaffoldMessengerKey.currentState ??
//         ScaffoldMessenger.of(context);

//     if (!online) {
//       _wasOffline = true;
//       _autoHideTimer?.cancel();
//       messenger.clearMaterialBanners();
//       messenger.showMaterialBanner(
//         MaterialBanner(
//           backgroundColor: Colors.red.shade600,
//           contentTextStyle: const TextStyle(color: Colors.white),
//           leading: const Icon(Icons.wifi_off, color: Colors.white),
//           content: const Text('No internet connection'),
//           actions: const [SizedBox.shrink()],
//         ),
//       );
//       return;
//     }

//     // Online
//     if (_wasOffline) {
//       _wasOffline = false;
//       messenger.clearMaterialBanners();
//       messenger.showMaterialBanner(
//         MaterialBanner(
//           backgroundColor: Colors.green.shade600,
//           contentTextStyle: const TextStyle(color: Colors.white),
//           leading: const Icon(Icons.wifi, color: Colors.white),
//           content: const Text('Internet connection restored'),
//           actions: const [SizedBox.shrink()],
//         ),
//       );
//       _autoHideTimer?.cancel();
//       _autoHideTimer = Timer(const Duration(seconds: 3), () {
//         scaffoldMessengerKey.currentState?.clearMaterialBanners();
//       });
//     } else {
//       // Already online and no prior offline: ensure clear
//       messenger.clearMaterialBanners();
//     }
//   }

//   @override
//   void dispose() {
//     _autoHideTimer?.cancel();
//     _debounce?.cancel();
//     _sub?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) => widget.child;
// }
