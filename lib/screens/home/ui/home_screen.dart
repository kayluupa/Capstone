import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../theming/theme_notifier.dart';
import '../../../core/widgets/no_internet.dart';
import '/routing/routes.dart';

class Meeting {
  final String fromUserId;
  final String fromRequestId;
  final String toUserId;
  final String toRequestId;
  final Timestamp date;
  final double lat;
  final double lng;
  String name;

  Meeting({
    required this.fromUserId,
    required this.fromRequestId,
    required this.toUserId,
    required this.toRequestId,
    required this.date,
    required this.lat,
    required this.lng,
    required this.name,
  });

  factory Meeting.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Meeting(
      fromUserId: data['fromUserId'] ?? 'No User',
      fromRequestId: data['fromRequestId'] ?? 'No User',
      toUserId: data['toUserId'] ?? 'No User',
      toRequestId: data['toRequestId'] ?? 'No User',
      date: data['date'] ?? Timestamp.now(),
      lat: data['lat'] ?? 0.0,
      lng: data['lng'] ?? 0.0,
      name: data['name'] ?? 'No Name',
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime today = DateTime.now();
  late String userId;
  List<Meeting> upcomingMeetings = [];
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    fetchCurrentUserAndMeetings();
  }

  void _navigateToMeetingScreen(DateTime day) async {
    await Navigator.pushNamed(context, Routes.meetingScreen,
        arguments: {'day': day});

    fetchUpcomingMeetings();
  }

  void _navigateToRequestsScreen() async {
    await Navigator.pushNamed(context, Routes.requestsScreen);

    fetchUpcomingMeetings();
  }

  void fetchCurrentUserAndMeetings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
      isDarkMode = await _getUserDarkModeSetting(userId);
      if (mounted) {
        fetchUpcomingMeetings();
        Provider.of<ThemeNotifier>(context, listen: false)
            .toggleTheme(isDarkMode);
      }
    }
  }

  Future<bool> _getUserDarkModeSetting(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      return userDoc['dark mode'];
    } catch (e) {
      return false;
    }
  }

  void fetchUpcomingMeetings() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('meetings')
              .where('date',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
              .orderBy('date', descending: false)
              .limit(3)
              .get();

      upcomingMeetings =
          snapshot.docs.map((doc) => Meeting.fromFirestore(doc)).toList();
      setState(() {});
    } catch (e) {
      showErrorMessage(e.toString());
    }
  }

  void showErrorMessage(String message) async {
    await AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      animType: AnimType.rightSlide,
      title: 'Error',
      desc: message.isNotEmpty ? message : 'An unknown error occurred.',
    ).show();
  }

  void deleteMeeting(Meeting meeting) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(meeting.fromUserId)
          .collection('meetings')
          .doc(meeting.fromRequestId)
          .delete();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(meeting.toUserId)
          .collection('meetings')
          .doc(meeting.toRequestId)
          .delete();

      fetchUpcomingMeetings();
    } catch (e) {
      showErrorMessage(e.toString());
    }
  }

  void _onDaySelected(DateTime day, DateTime focusedDay) {
    setState(() {
      today = day;
    });
    _navigateToMeetingScreen(day);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //title: const Text(
        //  'Meet Me Halfway',
        //  textAlign: TextAlign.center,
        //),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF227CFF), //blue color for button match
              ),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: const Text(
                      'Meet Me Halfway',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight, 
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0, right: 7.0),
                      child: Image.asset(
                        'assets/mmhwlogo.png', 
                        height: 80, 
                        width: 80,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Meeting Requests'),
              onTap: () {
                Navigator.pop(context, true);
                _navigateToRequestsScreen();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
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
          List<ConnectivityResult> connectivity,
          Widget child,
        ) {
          final bool connected =
              connectivity.contains(ConnectivityResult.mobile) ||
                  connectivity.contains(ConnectivityResult.wifi);

          return connected ? _homePage(context) : const BuildNoInternet();
        },
        child: _homePage(context),
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
                selectedDayPredicate: (day) => isSameDay(day, today),
                focusedDay: today,
                firstDay: DateTime.utc(2024, 1, 1),
                lastDay: DateTime.utc(2024, 12, 31),
                onDaySelected: _onDaySelected,
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Color(0xFF227CFF), 
                    shape: BoxShape.circle,    
                  ),
                  todayTextStyle: const TextStyle(
                    color: Colors.white,       
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  "To start a request to meet-up just click on your desired date!",
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
              if (upcomingMeetings.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: Text(
                    "Upcoming Meetings:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: upcomingMeetings.length,
                  itemBuilder: (context, index) {
                    final meeting = upcomingMeetings[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    meeting.name,
                                    style: const TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    '${DateFormat('MMMM d, yyyy').format(meeting.date.toDate().toLocal())} - ${DateFormat('hh:mm a').format(meeting.date.toDate().toLocal())}',
                                    style: const TextStyle(fontSize: 16.0),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.red),
                                  onPressed: () {
                                    AwesomeDialog(
                                      context: context,
                                      dialogType: DialogType.question,
                                      animType: AnimType.bottomSlide,
                                      title: 'Cancel Meeting',
                                      desc:
                                          'Are you sure you want to cancel this meeting?',
                                      btnOkOnPress: () {
                                        deleteMeeting(meeting);
                                        AwesomeDialog(
                                          context: context,
                                          dialogType: DialogType.info,
                                          animType: AnimType.rightSlide,
                                          title: 'Meeting Cancelled',
                                        ).show();
                                      },
                                      btnCancelOnPress: () {},
                                    ).show();
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.map),
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      Routes.mapScreen,
                                      arguments: {
                                        'latitude': meeting.lat,
                                        'longitude': meeting.lng,
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )
              ],
            ],
          ),
        ),
      ),
    );
  }
}
