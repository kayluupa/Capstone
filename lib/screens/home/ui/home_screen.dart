import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/no_internet.dart';
import '/routing/routes.dart';

class Meeting {
  final Timestamp date;
  final String fromUserId;
  final String fromRequestId;
  final String toUserId;
  final String toRequestId;
  final String time;
  final double lat;
  final double lng;
  String name;

  Meeting({
    required this.fromUserId,
    required this.fromRequestId,
    required this.toUserId,
    required this.toRequestId,
    required this.date,
    required this.time,
    required this.lat,
    required this.lng,
    required this.name,
  });

  factory Meeting.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Meeting(
      fromUserId: data['fromUserId'] ?? '',
      fromRequestId: data['fromRequestId'] ?? '',
      toUserId: data['toUserId'] ?? '',
      toRequestId: data['toRequestId'] ?? '',
      date: data['date'] ?? Timestamp.now(),
      time: data['time'] ?? 'No Time',
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

  @override
  void initState() {
    super.initState();
    fetchCurrentUserAndMeetings();
  }

  void _navigateToMeetingScreen(DateTime day) async {
    final shouldRefresh = await Navigator.pushNamed(
        context, Routes.meetingScreen,
        arguments: {'day': day});

    if (shouldRefresh == true) {
      fetchUpcomingMeetings(); // Refresh the upcoming meetings
    }
  }

  void _navigateToRequestsScreen() async {
    final shouldRefresh =
        await Navigator.pushNamed(context, Routes.requestsScreen);

    if (shouldRefresh == true) {
      fetchUpcomingMeetings();
    }
  }

  void fetchCurrentUserAndMeetings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
      fetchUpcomingMeetings();
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
        title: const Text(
          'Meet Me Halfway',
          textAlign: TextAlign.center,
        ),
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
                color: Color.fromARGB(255, 124, 33, 243),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Get Connected!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/girl.png',
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 10),
                      Image.asset(
                        'assets/guy.png',
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                    ],
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
                Navigator.pop(context);
                _navigateToRequestsScreen();
              },
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Map'),
              onTap: () {
                Navigator.pushNamed(context, Routes.mapScreen);
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
                          mainAxisAlignment: MainAxisAlignment
                              .spaceBetween, // Align items horizontally
                          children: [
                            Expanded(
                              // This makes the title and subtitle take up available space
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
                                  const SizedBox(
                                      height:
                                          4.0), // Reduced height for better compactness
                                  Text(
                                    DateFormat('yyyy-MM-dd – kk:mm')
                                        .format(meeting.date.toDate()),
                                    style: const TextStyle(fontSize: 16.0),
                                  ),
                                ],
                              ),
                            ),
                            // Buttons aligned in a row
                            Row(
                              mainAxisSize: MainAxisSize
                                  .min, // Minimize the size of the row
                              children: [
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
                                IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.red),
                                  onPressed: () => deleteMeeting(meeting),
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
