import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      showErrorMessage('Failed to fetch meetings. Please try again later.');
    }
  }

  void showErrorMessage(String message) {
    final GlobalKey<State> key = GlobalKey<State>();
    final context = key.currentContext;
    if (context != null) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Meetings on ${widget.day.toString()}'),
        ),
        body: ListView.builder(
          itemCount: meetings.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(meetings[index].title),
              subtitle: Text(meetings[index].description),
            );
          },
        ));
  }
}

class Meeting {
  final String title;
  final String description;
  // Add other properties of a meeting here

  Meeting({required this.title, required this.description});

  // Factory method to convert Firestore data to Dart object
  factory Meeting.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Meeting(
      title: data?['title'],
      description: data?['description'],
      // Initialize other properties here
    );
  }
}
