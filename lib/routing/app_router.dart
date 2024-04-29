import 'package:flutter/material.dart';

import '../screens/create_password/ui/create_password.dart';
import '../screens/forget/ui/forget_screen.dart';
import '../screens/account/ui/account_screen.dart';
import '../screens/login/ui/login_screen.dart';
import '../screens/signup/ui/sign_up_sceen.dart';
import '../screens/home/ui/home_screen.dart';
import '../screens/map/ui/map_screen.dart';
import '../screens/meeting/ui/meeting_screen.dart';
import 'routes.dart';

class AppRouter {
  Route? generateRoute(RouteSettings settings, DateTime day) {
    switch (settings.name) {
      case Routes.forgetScreen:
        return MaterialPageRoute(
          builder: (_) => const ForgetScreen(),
        );
      case Routes.accountScreen:
        return MaterialPageRoute(
          builder: (_) => const AccountScreen(),
        );
      case Routes.homeScreen:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );
      case Routes.createPassword:
        final arguments = settings.arguments;
        if (arguments is List) {
          return MaterialPageRoute(
            builder: (_) => CreatePassword(
              googleUser: arguments[0],
              credential: arguments[1],
            ),
          );
        }
        return null;
      case Routes.signupScreen:
        return MaterialPageRoute(
          builder: (_) => const SignUpScreen(),
        );
      case Routes.loginScreen:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );
      case Routes.mapScreen:
        return MaterialPageRoute(
          builder: (_) => const MapScreen(),
        );
      case Routes.meetingScreen:
        return MaterialPageRoute(
          builder: (_) => MeetingScreen(day: day),
        );
    }
    return null;
  }
}
