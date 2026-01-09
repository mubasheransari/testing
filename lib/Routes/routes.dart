import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_bloc.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_event.dart';
import 'package:taskoon/Screens/Authentication/login_screen.dart';
import 'package:taskoon/Screens/Booking_process_tasker/bottom_nav_root_screen.dart';
import 'package:taskoon/Screens/Booking_process_tasker/tasker_home_screen.dart';
import 'package:taskoon/Screens/Splash_Slider/splash_screen.dart';
import 'package:taskoon/Screens/User_booking/user_booking_nav_bar.dart';
import 'package:taskoon/screens/Tasker_Onboarding/consent.dart';
import 'package:taskoon/screens/Tasker_Onboarding/document_upload.dart';
import 'package:taskoon/screens/Tasker_Onboarding/personal_info.dart';
import 'package:taskoon/screens/Tasker_Onboarding/review_submit.dart';
import 'package:taskoon/screens/Tasker_Onboarding/selfie_verification.dart';
import 'package:taskoon/screens/Tasker_Onboarding/success.dart';
import '../Screens/Splash_Slider/slider_screen.dart';
import '../Screens/Tasker_Onboarding/cerifications_screen.dart';

class Routes {
  static const splash = '/splash';
  static const personalInfo = '/personal-info';
  static const documentUpload = '/document-upload';
  static const selfieVerification = '/selfie-verification';
  static const consent = '/consent';
  static const reviewSubmit = '/review-submit';
  static const success = '/success';
  static const slider = '/OnboardingCarousel';
  static const cerificationScreen = '/Certifications-screen';
  static const appShellScreen = '/app_Shell-screen';
  static const taskerHomeScreen = '/taskerhome-screen';
  static const takerHomeBottomNavBarRoot = '/tasker_home_bottom_nav_bar';
  static const userHomeBottomNavBarRoot = '/user_home_bottom_nav_bar';
  static const locationSignalR = '/LocationSignalRScreen';
  static const login = '/login_screen';
}


class GlobalNav {
  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  static NavigatorState get nav => key.currentState!;
}
class AppRouter {
  
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
        case Routes.login:
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case Routes.splash:
        return MaterialPageRoute(builder: (_) => SplashScreen());
      case Routes.slider:
        return MaterialPageRoute(builder: (_) => OnboardingScreen());
      case Routes.cerificationScreen:
        return MaterialPageRoute(builder: (_) => CertificationsScreen());
      case Routes.personalInfo:
        return MaterialPageRoute(builder: (_) => const PersonalInfo());
      case Routes.documentUpload:
        return MaterialPageRoute(builder: (_) => const DocumentUpload());
      case Routes.selfieVerification:
        return MaterialPageRoute(builder: (_) => const SelfieVerification());
      case Routes.consent:
        return MaterialPageRoute(builder: (_) => const Consent());
      case Routes.reviewSubmit:
        return MaterialPageRoute(builder: (_) => const ReviewSubmit());
      case Routes.success:
        return MaterialPageRoute(builder: (_) => const Success());
      case Routes.taskerHomeScreen:
        return MaterialPageRoute(builder: (_) =>  TaskerHomeRedesign());
      case Routes.takerHomeBottomNavBarRoot:
        return MaterialPageRoute(builder: (_) => const TaskoonApp());
      case Routes.userHomeBottomNavBarRoot:
        return MaterialPageRoute(
          builder: (context) {
            context.read<AuthenticationBloc>().add(LoadServicesRequested());
            return const UserBottomNavBar();
          },
        );

      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Route not found'))),
        );
    }
  }
}
