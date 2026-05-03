import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'models/lawyer.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/ai_chat_screen.dart';
import 'screens/booking_screen.dart';
import 'screens/case_management_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/lawyer_dashboard_screen.dart';
import 'screens/lawyer_profile_screen.dart';
import 'screens/lawyer_signup_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/search_lawyers_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/user_dashboard_screen.dart';
import 'screens/user_requests_screen.dart';
import 'screens/user_settings_screen.dart';

class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String login = '/';
  static const String forgotPassword = '/forgot-password';
  static const String signup = '/signup';
  static const String lawyerSignup = '/lawyer-signup';

  // مسارات المستخدم (العميل)
  static const String userDashboard = '/user/dashboard';
  static const String userSearch = '/user/search';
  static const String userRequests = '/user/requests';
  static const String userAiChat = '/user/ai-chat';
  static const String userBooking = '/user/booking';
  static const String userPayment = '/user/payment';
  static const String userCases = '/user/cases';
  static const String userSettings = '/user/settings';

  // مسارات المحامي
  static const String lawyerDashboard = '/lawyer/dashboard';
  static const String lawyerProfile = '/lawyer/profile';
  static const String lawyerAiChat = '/lawyer/ai-chat';
  static const String lawyerCases = '/lawyer/cases';

  // مسار المسؤول
  static const String adminDashboard = '/admin/dashboard';
}

class MuhamahApp extends StatelessWidget {
  const MuhamahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'محاميك',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // دعم اللغة العربية والاتجاه من اليمين لليسار
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', 'SA'),
      ],
      locale: const Locale('ar', 'SA'),
      initialRoute: AppRoutes.onboarding,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.onboarding:
            return _route(const OnboardingScreen());
          case AppRoutes.login:
            return _route(const LoginScreen());
          case AppRoutes.forgotPassword:
            return _route(const ForgotPasswordScreen());
          case AppRoutes.signup:
            return _route(const SignUpScreen());
          case AppRoutes.lawyerSignup:
            return _route(const LawyerSignUpScreen());

          // شاشات المستخدم
          case AppRoutes.userDashboard:
            return _route(const UserDashboardScreen());
          case AppRoutes.userSearch:
            return _route(const SearchLawyersScreen());
          case AppRoutes.userRequests:
            return _route(const UserRequestsScreen());
          case AppRoutes.userAiChat:
            return _route(const AIChatScreen(userType: 'user'));
          case AppRoutes.userBooking:
            final lawyer = settings.arguments is Lawyer
                ? settings.arguments as Lawyer
                : null;
            return _route(BookingScreen(lawyer: lawyer));
          case AppRoutes.userPayment:
            return _route(PaymentScreen(details: settings.arguments));
          case AppRoutes.userCases:
            return _route(const CaseManagementScreen(userType: 'user'));
          case AppRoutes.userSettings:
            return _route(const UserSettingsScreen());

          // شاشات المحامي
          case AppRoutes.lawyerDashboard:
            return _route(const LawyerDashboardScreen());
          case AppRoutes.lawyerProfile:
            return _route(const LawyerProfileScreen());
          case AppRoutes.lawyerAiChat:
            return _route(const AIChatScreen(userType: 'lawyer'));
          case AppRoutes.lawyerCases:
            return _route(const CaseManagementScreen(userType: 'lawyer'));

          // شاشات الإدارة
          case AppRoutes.adminDashboard:
            return _route(const AdminDashboardScreen());

          default:
            return _route(const LoginScreen());
        }
      },
    );
  }

  MaterialPageRoute _route(Widget child) {
    return MaterialPageRoute(builder: (_) => child);
  }
}
