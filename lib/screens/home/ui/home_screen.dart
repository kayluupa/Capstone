// import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/material.dart';
import '../../../core/widgets/no_internet.dart';
import '../../../theming/colors.dart';
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
    Navigator.pushNamed(context, Routes.meetingScreen, arguments: {'day': day});
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
            icon: const Icon(Icons.notifications),
            onPressed: () {
            },
          ),
        ],
      ),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Get Connected!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.map),
              title: Text('Map'),
              onTap: () {
                Navigator.pushNamed(context, Routes.mapScreen);
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'), 
              onTap: () {
                Navigator.pushNamed(context, Routes.settingsScreen);  
              },
            ),
          ],
        ),
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
            ],
          ),
        ),
      ),
    );
  }
}
