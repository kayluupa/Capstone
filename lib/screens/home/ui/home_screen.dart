import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/no_internet.dart';
import '../../../theming/colors.dart';
import '../../meeting/ui/meeting_screen.dart';
import '/routing/routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime today = DateTime.now();
  void _onDaySelected(DateTime day, DateTime focusedDay) {
    setState(() {
      today = day;
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MeetingScreen(day: day)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meet Me Halfway',
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () async {
              try {
                Navigator.pushNamed(context, Routes.accountScreen);
              } catch (e) {
                await AwesomeDialog(
                  context: context,
                  dialogType: DialogType.info,
                  animType: AnimType.rightSlide,
                  title: 'Account profile error',
                  desc: e.toString(),
                ).show();
              }
            },
          ),
        ],
      ),
      body: OfflineBuilder(
        connectivityBuilder: (
          BuildContext context,
          ConnectivityResult connectivity,
          Widget child,
        ) {
          final bool connected = connectivity != ConnectivityResult.none;
          return connected ? _homePage(context) : const BuildNoInternet();
        },
        child: const Center(
          child: CircularProgressIndicator(
            color: ColorsManager.mainBlue,
          ),
        ),
      ),
    );
  }

  Widget _homePage(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 15.w),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TableCalendar(
                locale: "en_US",
                headerStyle: const HeaderStyle(
                    formatButtonVisible: false, titleCentered: true),
                //avaibleGestures: AvailableGestures.all,
                selectedDayPredicate: (day) => isSameDay(day, today),
                focusedDay: today,
                firstDay: DateTime.utc(2024, 1, 1),
                lastDay: DateTime.utc(2024, 12, 31),
                onDaySelected: _onDaySelected,
              ),
              TextButton(
                style: TextButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 30)),
                onPressed: () async {
                  try {
                    Navigator.pushNamed(context, Routes.mapScreen);
                  } catch (e) {
                    await AwesomeDialog(
                      context: context,
                      dialogType: DialogType.info,
                      animType: AnimType.rightSlide,
                      title: 'Map error',
                      desc: e.toString(),
                    ).show();
                  }
                },
                child: const Text('Map'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
