import 'package:flutter/widgets.dart';
import 'package:taskoon/Realtime/dispatch_hub_service.dart';

class AppLifecycleWatcher extends StatefulWidget {
  final Widget child;
  const AppLifecycleWatcher({super.key, required this.child});

  @override
  State<AppLifecycleWatcher> createState() => _AppLifecycleWatcherState();
}

class _AppLifecycleWatcherState extends State<AppLifecycleWatcher>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      DispatchHubSingleton.instance.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
