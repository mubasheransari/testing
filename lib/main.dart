import 'package:flutter/material.dart';
import 'package:taskoon/routes.dart';
import 'package:taskoon/theme.dart';

import 'Service/internet_connectivity_banner.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Taskoon',
      theme: AppTheme.light,
      initialRoute: Routes.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
      scaffoldMessengerKey: scaffoldMessengerKey,
      builder: (context, child) =>
          ConnectivityBannerHost(child: child ?? const SizedBox()),
      // home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your App')),
      body: const Center(child: Text('Screen content')),
    );
  }
}
