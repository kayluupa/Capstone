import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
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
      fromUserId: data['fromUserId'] ?? 'No User',
      fromRequestId: data['fromRequestId'] ?? 'No User',
      toUserId: data['toUserId'] ?? 'No User',
      toRequestId: data['toRequestId'] ?? 'No User',
      date: data['date'] ?? Timestamp.now(),
      time: data['time'] ?? 'No Time',
      lat: data['lat'] ?? 0.0,
      lng: data['lng'] ?? 0.0,
      name: data['name'] ?? 'No Name',
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

      setState(() {
        meetings.remove(meeting);
      });
    } catch (e) {
      showErrorMessage(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('EEEE, MMMM d, yyyy').format(widget.day)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
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
                  foregroundColor: Color(0xFF227CFF),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: meetings.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child: Card(
                    elevation: 4.0,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 16.0),
                      title: Text(
                        meetings[index].name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            'Date: ${DateFormat('MMMM d, yyyy').format(meetings[index].date.toDate().toLocal())}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Time: ${DateFormat('hh:mm a').format(meetings[index].date.toDate().toLocal())}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () {
                              AwesomeDialog(
                                context: context,
                                dialogType: DialogType.question,
                                animType: AnimType.bottomSlide,
                                title: 'Cancel Meeting',
                                desc:
                                    'Are you sure you want to cancel this meeting?',
                                btnOkOnPress: () {
                                  deleteMeeting(meetings[index]);
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
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
