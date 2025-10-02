import 'package:flutter/material.dart';
import 'package:taskoon/Screens/Splash_Slider/splash_screen.dart';
import 'package:taskoon/screens/Tasker_Onboarding/consent.dart';
import 'package:taskoon/screens/Tasker_Onboarding/document_upload.dart';
import 'package:taskoon/screens/Tasker_Onboarding/personal_info.dart';
import 'package:taskoon/screens/Tasker_Onboarding/review_submit.dart';
import 'package:taskoon/screens/Tasker_Onboarding/selfie_verification.dart';
import 'package:taskoon/screens/Tasker_Onboarding/success.dart';
import 'package:taskoon/screens/Tasker_Onboarding/welcome.dart';
import 'Screens/Authentication/landing_screen.dart';
import 'Screens/Splash_Slider/slider_screen.dart';
import 'Screens/Tasker_Onboarding/cerifications_screen.dart';

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
}

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
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
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }
}
