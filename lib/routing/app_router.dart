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
import '../screens/requests/ui/requests_screen.dart';
import '../screens/settings/ui/notif_screen.dart';
import '../screens/settings/ui/help_screen.dart';
import '../screens/settings/ui/privacy_screen.dart';
import '../screens/settings/ui/tandc_screen.dart';
import 'routes.dart';

class AppRouter {
  Route? generateRoute(RouteSettings settings) {
    final arguments = settings.arguments;
    final Map<String, dynamic>? args =
        arguments is Map<String, dynamic> ? arguments : null;
    final DateTime? day = args?['day'] as DateTime?;
    final Function()? refreshMeetingsList =
        args?['refreshMeetingsList'] as Function()?;
    final double? latitude = args?['latitude'];
    final double? longitude = args?['longitude'];
    final String? name = args?['name'];

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
              latitude: latitude ?? 0.0,
              longitude: longitude ?? 0.0,
              name: name ?? ""),
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
      case Routes.requestsScreen:
        return MaterialPageRoute(
          builder: (_) => const RequestsScreen(),
        );
      case Routes.notifScreen:
        return MaterialPageRoute(
          builder: (_) => const NotifScreen(),
        );
      case Routes.helpScreen:
        return MaterialPageRoute(
          builder: (_) => const HelpScreen(),
        );
      case Routes.privacyScreen:
        return MaterialPageRoute(
          builder: (_) => const PrivacyScreen(),
        );
      case Routes.tandcScreen:
        return MaterialPageRoute(
          builder: (_) => const TandCScreen(),
        );
    }
    return null;
  }
}
