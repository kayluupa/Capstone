import 'package:flutter/material.dart';

import '../screens/create_password/ui/create_password.dart';
import '../screens/forget/ui/forget_screen.dart';
import '../screens/account/ui/account_screen.dart';
import '../screens/login/ui/login_screen.dart';
import '../screens/signup/ui/sign_up_sceen.dart';
import '../screens/home/ui/home_screen.dart';
import '../screens/map/ui/map_screen.dart';
import '../screens/meeting/ui/meeting_screen.dart';
import '../screens/meeting/ui/create_meeting.dart';
import '../screens/settings/ui/settings_screen.dart';
import 'routes.dart';

class AppRouter {
  Route? generateRoute(RouteSettings settings) {
    final arguments = settings.arguments;
    final Map<String, dynamic>? args =
        arguments is Map<String, dynamic> ? arguments : null;
    final DateTime? day = args?['day'] as DateTime?;
    final Function()? refreshMeetingsList =
        args?['refreshMeetingsList'] as Function()?;
    final String? latitude = args?['latitude'];
    final String? longitude = args?['longitude'];
    final String? title = args?['title'];
    final String? description = args?['description'];

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
          builder: (_) => MapScreen(
              latitude: latitude ?? "0.0",
              longitude: longitude ?? "0.0",
              title: title ?? "",
              description: description ?? ""),
        );
      case Routes.meetingScreen:
        return MaterialPageRoute(
          builder: (_) => MeetingScreen(day: day ?? DateTime.now()),
        );
      case Routes.createMeeting:
        return MaterialPageRoute(
          builder: (_) => CreateMeeting(
            day: day ?? DateTime.now(),
            refreshMeetingsList: refreshMeetingsList!,
          ),
        );
      case Routes.settingsScreen:
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
        );
    }
    return null;
  }
}
