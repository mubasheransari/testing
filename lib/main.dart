import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_event.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_bloc.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_event.dart';
import 'package:taskoon/Realtime/app_lifecycle_watcher.dart';
import 'package:taskoon/Routes/routes.dart';
import 'package:taskoon/theme.dart';
import 'package:taskoon/widgets/notification_service.dart';
import 'package:taskoon/widgets/realtime/signalr_service.dart';
import 'Blocs/auth_bloc/auth_bloc.dart';
import 'Repository/auth_repository.dart';
import 'Service/internet_connectivity_banner.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await NotificationService.I.init();

  // If "data-only" push, show local notification yourself:
  await NotificationService.I.show(
    title: "New booking offer",
    body: "A new booking offer is available.",
  );
}

/// ✅ Safe token fetch: never crash app startup
Future<void> _initFcmSafely() async {
  try {
    // Android 13+ needs runtime permission; safe to call on all platforms
    await FirebaseMessaging.instance.requestPermission();

    // Don't let getToken hang forever
    final token = await FirebaseMessaging.instance
        .getToken()
        .timeout(const Duration(seconds: 8));

    debugPrint("✅ FCM TOKEN: $token");

    // Token can refresh later (or be issued later if initial fetch failed)
    FirebaseMessaging.instance.onTokenRefresh.listen((t) {
      debugPrint("🔁 FCM token refreshed: $t");
    });
  } catch (e, st) {
    // Common: SERVICE_NOT_AVAILABLE / no Play Services / network blocked
    debugPrint("⚠️ FCM getToken failed (non-fatal): $e");
    debugPrint("$st");
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();
  await Firebase.initializeApp();

  // ✅ Register background handler AFTER Firebase init
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // ✅ Init local notifications
  await NotificationService.I.init();

  // ✅ IMPORTANT: don't crash the app if FCM is unavailable
  // Run it without blocking startup (optional)
  unawaited(_initFcmSafely());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepo = AuthRepositoryHttp(
      baseUrl: ApiConfig.baseUrl,
      endpoint: ApiConfig.signupEndpoint,
      timeout: const Duration(seconds: 20),
    );

    return RepositoryProvider.value(
      value: authRepo,
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthenticationBloc>(
            create: (_) {
              final bloc = AuthenticationBloc(authRepo)
                ..add(LoadServiceDocumentsRequested())
                ..add(LoadServicesRequested())
                ..add(LoadTrainingVideosRequested());

              final box = GetStorage();
              final savedUserId = box.read<String>('userId');
              if (savedUserId != null && savedUserId.isNotEmpty) {
                bloc.add(LoadUserDetailsRequested(savedUserId));
              }
              return bloc;
            },
          ),
          BlocProvider<UserBookingBloc>(
            create: (_) => UserBookingBloc(authRepo),
          ),
        ],
        child: const _RealtimeBootstrap(
          child: AppLifecycleWatcher(
            child: _TaskoonMaterialApp(),
          ),
        ),
      ),
    );
  }
}

/// ✅ This ensures SignalR connect runs ONCE (not on every rebuild)
class _RealtimeBootstrap extends StatefulWidget {
  const _RealtimeBootstrap({required this.child});
  final Widget child;

  @override
  State<_RealtimeBootstrap> createState() => _RealtimeBootstrapState();
}

class _RealtimeBootstrapState extends State<_RealtimeBootstrap> {
  bool _started = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final box = GetStorage();
final userId = box.read('userId')?.toString().trim();
final role = box.read('role')?.toString().trim();

if (userId != null && userId.isNotEmpty) {
  try {
    await SignalRService.I.connect(
      baseUrl: ApiConfig.baseUrl,
      userId: userId,
    );
  } catch (e) {
    debugPrint("❌ SignalR connect failed: $e");
  }

  // ✅ NEW: fetch tasker dashboard on app start if Tasker
  if (role == "Tasker") {
    context.read<UserBookingBloc>().add(
          FetchTaskerDashboardRequested(userId: userId),
        );
  }
} else {
  debugPrint("ℹ️ SignalR not started (userId missing)");
}
  /*    if (!mounted) return;
      if (_started) return;
      _started = true;

      final box = GetStorage();
      final userId = box.read('userId')?.toString().trim();

      if (userId != null && userId.isNotEmpty) {
        try {
          await SignalRService.I.connect(
            baseUrl: ApiConfig.baseUrl,
            userId: userId,
          );
        } catch (e) {
          debugPrint("❌ SignalR connect failed: $e");
        }
      } else {
        debugPrint("ℹ️ SignalR not started (userId missing)");
      }*/
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _TaskoonMaterialApp extends StatelessWidget {
  const _TaskoonMaterialApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Taskoon',
      navigatorKey: GlobalNav.key,
      theme: AppTheme.light,
      initialRoute: Routes.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
      scaffoldMessengerKey: scaffoldMessengerKey,
      builder: (context, child) =>
          ConnectivityBannerHost(child: child ?? const SizedBox()),
    );
  }
}
