import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'routing/app_router.dart';
import 'routing/routes.dart';

// import the configuration file you generated using Firebase CLI
import 'firebase_options.dart';

late String initialRoute;

void main() async {
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
  DateTime today = DateTime.now(); // Define today here
  await ScreenUtil.ensureScreenSize();
  runApp(MyApp(router: AppRouter(), today: today)); // Pass today to MyApp
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
        return MaterialApp(
          title: 'Meet Me Halfway App',
          theme: ThemeData(
            useMaterial3: true,
          ),
          onGenerateRoute: (settings) => router.generateRoute(settings, today),
          debugShowCheckedModeBanner: false,
          initialRoute: initialRoute,
        );
      },
    );
  }
}

