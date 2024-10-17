import 'package:capstone/helpers/firebase_msg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'theming/theme_notifier.dart';
import 'routing/app_router.dart';
import 'routing/routes.dart';
import 'firebase_options.dart';

late String initialRoute;
final navigatorKey = GlobalKey<NavigatorState>();

ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primarySwatch: Colors.blue,
  useMaterial3: true,
);

ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: Colors.blue,
  useMaterial3: true,
);

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseAuth.instance.authStateChanges().listen(
    (user) {
      if (user == null || !user.emailVerified) {
        initialRoute = Routes.loginScreen;
      } else {
        initialRoute = Routes.homeScreen;
      }
    },
  );

  DateTime today = DateTime.now();
  await ScreenUtil.ensureScreenSize();
  await PushNotifs().initNotifs();

  // Fetch the user's dark mode setting before running the app
  bool isDarkMode = await _getUserDarkModeSetting();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(isDarkMode),
      child: MyApp(router: AppRouter(), today: today),
    ),
  );
}

Future<bool> _getUserDarkModeSetting() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return userDoc['dark mode'] ?? true;
  }
  return true;
}

class MyApp extends StatelessWidget {
  final AppRouter router;
  final DateTime today;

  const MyApp({super.key, required this.router, required this.today});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return Consumer<ThemeNotifier>(
          builder: (context, themeNotifier, child) {
            return MaterialApp(
              title: 'Meet Me Halfway App',
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: themeNotifier.currentTheme,
              onGenerateRoute: (settings) => router.generateRoute(settings),
              debugShowCheckedModeBanner: false,
              initialRoute: initialRoute,
              navigatorKey: navigatorKey,
            );
          },
        );
      },
    );
  }
}
