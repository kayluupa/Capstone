import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '/routing/routes.dart';

class Meeting {
  final String userEmail;
  final String time;
  final String lat;
  final String lng;

  Meeting({
    required this.userEmail,
    required this.time,
    required this.lat,
    required this.lng,
  });

  factory Meeting.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Meeting(
      userEmail: data['user'] ?? 'No Email',
      time: data['time'] ?? 'No Time',
      lat: data['lat'] ?? '0.0',
      lng: data['lng'] ?? '0.0',
    );
  }
}

class MeetingScreen extends StatefulWidget {
  final DateTime day;

  const MeetingScreen({super.key, required this.day});

  @override
  MeetingScreenState createState() => MeetingScreenState();
}

class MeetingScreenState extends State<MeetingScreen> {
  late List<Meeting> meetings = [];
  late String userId;

  @override
  void initState() {
    super.initState();
    fetchCurrentUser();
  }

  void fetchCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
      fetchMeetingsForDay();
    }
  }

  void fetchMeetingsForDay() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('meetings')
              .where(
                'date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(
                    widget.day.year, widget.day.month, widget.day.day)),
                isLessThan: Timestamp.fromDate(DateTime(
                    widget.day.year, widget.day.month, widget.day.day + 1)),
              )
              .get();

      meetings =
          snapshot.docs.map((doc) => Meeting.fromFirestore(doc)).toList();

      setState(() {});
    } catch (e) {
      showErrorMessage(e.toString());
    }
  }

  void showErrorMessage(String message) async {
    if (!mounted) return;
    final currentContext = context;
    await AwesomeDialog(
      context: currentContext,
      dialogType: DialogType.info,
      animType: AnimType.rightSlide,
      title: 'Error',
      desc: message.isNotEmpty ? message : 'An unknown error occurred.',
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('EEEE, MMMM d, yyyy').format(widget.day)),
        actions: [
          IconButton(
            onPressed: () async {
              try {
                await Navigator.pushNamed(
                  context,
                  Routes.createMeeting,
                  arguments: {
                    'day': widget.day,
                    'refreshMeetingsList': fetchMeetingsForDay,
                  },
                );
                fetchMeetingsForDay();
              } catch (e) {
                showErrorMessage(e.toString());
              }
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: meetings.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(meetings[index].userEmail),
            subtitle: Text(meetings[index].time),
            trailing: IconButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  Routes.mapScreen,
                  arguments: {
                    'latitude': meetings[index].lat,
                    'longitude': meetings[index].lng,
                    'title': meetings[index].userEmail,
                    'description': meetings[index].time,
                  },
                );
              },
              icon: const Icon(Icons.map),
            ),
          );
        },
      ),
    );
  }
}
