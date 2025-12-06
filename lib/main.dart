import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_event.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_bloc.dart';
import 'package:taskoon/Routes/routes.dart';
import 'package:taskoon/theme.dart';
import 'Blocs/auth_bloc/auth_bloc.dart';
import 'Repository/auth_repository.dart';
import 'Service/internet_connectivity_banner.dart';

// void main() => runApp(const MyApp());

main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  runApp(const MyApp());
}


final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();


// class MyApp extends StatelessWidget {//Testing@123
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final authRepo = AuthRepositoryHttp(
//       baseUrl: ApiConfig.baseUrl,
//       endpoint: ApiConfig.signupEndpoint,
//       timeout: const Duration(seconds: 20),
//     );

// return RepositoryProvider.value(
//   value: authRepo,
//   child: BlocProvider(
//     create: (_) {
//       final bloc = AuthenticationBloc(authRepo)
//         ..add(LoadServiceDocumentsRequested())
//         ..add(LoadServicesRequested())
//         ..add(LoadTrainingVideosRequested());


//       final box = GetStorage();
//       final savedUserId = box.read<String>('userId');

//       if (savedUserId != null && savedUserId.isNotEmpty) {
//         bloc.add(LoadUserDetailsRequested(savedUserId));
//       }
//       return bloc;
//     },
//         child: MaterialApp(
//           debugShowCheckedModeBanner: false,
//           title: 'Taskoon',
//           theme: AppTheme.light,
//           initialRoute:Routes.takerHomeBottomNavBarRoot,//Routes.locationSignalR,//Routes.splash,//Routes.userHomeBottomNavBarRoot, //takerHomeBottomNavBarRoot,//Routes.personalInfo, // Routes.splash,
//           onGenerateRoute: AppRouter.onGenerateRoute,
//           scaffoldMessengerKey: scaffoldMessengerKey,
//           builder: (context, child) =>
//               ConnectivityBannerHost(child: child ?? const SizedBox()),
//         ),
//       ),
//     );
//   }
// }

class MyApp extends StatelessWidget {//Testing@123
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
          /// 🔹 AuthenticationBloc (existing)
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

          /// 🔹 NEW: UserBookingBloc
          BlocProvider<UserBookingBloc>(
            create: (_) => UserBookingBloc(authRepo),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Taskoon',
          theme: AppTheme.light,//Testing@123
          initialRoute: Routes.userHomeBottomNavBarRoot,//takerHomeBottomNavBarRoot,
          // Routes.locationSignalR,//Routes.splash,//Routes.userHomeBottomNavBarRoot,
          onGenerateRoute: AppRouter.onGenerateRoute,
          scaffoldMessengerKey: scaffoldMessengerKey,
          builder: (context, child) =>
              ConnectivityBannerHost(child: child ?? const SizedBox()),
        ),
      ),
    );
  }
}



// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final authRepo = AuthRepositoryHttp(
//       baseUrl: ApiConfig.baseUrl,
//       endpoint: ApiConfig.signupEndpoint,
//       timeout: const Duration(seconds: 20),
//     );

//     return RepositoryProvider.value(
//       value: authRepo,
//       child: BlocProvider(
//         create: (_) => AuthenticationBloc(authRepo),
//         child: MaterialApp(
//           debugShowCheckedModeBanner: false,
//           title: 'Taskoon',
//           theme: AppTheme.light,
//           initialRoute:Routes.personalInfo,//Routes.splash,
//           onGenerateRoute: AppRouter.onGenerateRoute,
//           scaffoldMessengerKey: scaffoldMessengerKey,
//           builder: (context, child) =>
//               ConnectivityBannerHost(child: child ?? const SizedBox()),
//         ),
//       ),
//     );
//   }
// }


// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Taskoon',
//       theme: AppTheme.light,
//       initialRoute: Routes.splash,
//       onGenerateRoute: AppRouter.onGenerateRoute,
//       scaffoldMessengerKey: scaffoldMessengerKey,
//       builder: (context, child) =>
//           ConnectivityBannerHost(child: child ?? const SizedBox()),
//     );
//   }
// }

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your App')),//Testing@123
      body: const Center(child: Text('Screen content')),
    );
  }
}
