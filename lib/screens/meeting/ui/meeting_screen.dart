import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '/routing/routes.dart';

class Meeting {
  final String name;
  final String time;
  final String lat;
  final String lng;

  Meeting({
    required this.name,
    required this.time,
    required this.lat,
    required this.lng,
  });

  factory Meeting.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Meeting(
      name: data['name'] ?? 'No Name',
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
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity, 
              child: ElevatedButton.icon(
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
                label: const Text("Add Meeting"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: meetings.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(meetings[index].name),
                  subtitle: Text(meetings[index].time),
                  trailing: IconButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        Routes.mapScreen,
                        arguments: {
                          'latitude': meetings[index].lat,
                          'longitude': meetings[index].lng,
                        },
                      );
                    },
                    icon: const Icon(Icons.map),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
