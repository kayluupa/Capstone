import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '/routing/routes.dart';

class Meeting {
  final String title;
  final String description;
  final String lat;
  final String lng;
  // Add other properties of a meeting here

  Meeting(
      {required this.title,
      required this.description,
      required this.lat,
      required this.lng});

  // Factory method to convert Firestore data to Dart object
  factory Meeting.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Meeting(
      title: data?['title'],
      description: data?['description'],
      lat: data?['lat'],
      lng: data?['lng'],
      // Initialize other properties here
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
      // Query Firestore to fetch meetings for the specified day
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

      // Convert Firestore data to Dart objects
      meetings =
          snapshot.docs.map((doc) => Meeting.fromFirestore(doc)).toList();

      setState(() {});
    } catch (e) {
      // Show an error message to the user
      showErrorMessage(e.toString());
    }
  }

  void showErrorMessage(String message) async {
    if (!mounted) return; // Check if the widget is still mounted
    final currentContext = context;
    await AwesomeDialog(
      context: currentContext,
      dialogType: DialogType.info,
      animType: AnimType.rightSlide,
      title: 'Meeting creation error',
      desc: message,
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Meetings on ${widget.day.toString()}'),
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
                  }, // Pass the day
                );
                // After returning from the createMeeting screen, fetch meetings again
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
              title: Text(meetings[index].title),
              subtitle: Text(meetings[index].description),
              trailing: IconButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    Routes.mapScreen,
                    arguments: {
                      'latitude': meetings[index].lat,
                      'longitude': meetings[index].lng,
                      'title': meetings[index].title,
                      'description': meetings[index].description,
                    },
                  );
                },
                icon: const Icon(Icons.map),
              ));
        },
      ),
    );
  }
}
