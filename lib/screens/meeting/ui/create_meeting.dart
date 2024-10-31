import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:convert';
import '../../../helpers/firebase_msg.dart' as firebase_msg;

class CreateMeeting extends StatefulWidget {
  final DateTime day;
  final void Function() refreshMeetingsList;

  const CreateMeeting(
      {super.key, required this.day, required this.refreshMeetingsList});

  @override
  CreateMeetingState createState() => CreateMeetingState();
}

class User {
  final String userId;
  final String email;

  User({required this.userId, required this.email});
}

class Place {
  final String placeId;
  final String description;

  Place({required this.placeId, required this.description});
}

class CreateMeetingState extends State<CreateMeeting> {
  late TextEditingController _userController;
  late TextEditingController _locationController;

  List<User> userResults = [];
  List<Place> searchResults = [];
  double _latitude = 0.0;
  double _longitude = 0.0;
  TimeOfDay? selectedTime;
  String? selectedUserId;

  @override
  void initState() {
    super.initState();
    _userController = TextEditingController();
    _locationController = TextEditingController();
  }

  @override
  void dispose() {
    _userController.dispose();
    _locationController.dispose();
    super.dispose();
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

  Future<void> createMeeting(VoidCallback popCallback) async {
    DateTime localDate = widget.day;
    DateTime utcDate = DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
      selectedTime?.hour ?? localDate.hour,
      selectedTime?.minute ?? localDate.minute,
    ).toUtc();
    DateTime convertedDate =
        tz.TZDateTime.from(utcDate, tz.getLocation('America/Chicago'));
    String date = DateFormat('MM/dd/yy').format(convertedDate);
    String time = DateFormat('hh:mm a').format(convertedDate);
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final selectedUserDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(selectedUserId)
        .get();

    if (selectedUserId != null) {
      final initRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('requests')
          .doc();

      final selRef = FirebaseFirestore.instance
          .collection('users')
          .doc(selectedUserId)
          .collection('requests')
          .doc();

      final requestData = {
        'fromUserId': currentUserId,
        'fromRequestId': initRef.id,
        'toUserId': selectedUserId,
        'toRequestId': selRef.id,
        'date': utcDate,
        'lat': null,
        'lng': null,
        'location': null,
      };

      await initRef.set(requestData);
      await selRef.set(requestData);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('requests')
          .doc(initRef.id)
          .update({
        'lat': _latitude,
        'lng': _longitude,
      });
    }

    final fromUserName = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get()
        .then((doc) => doc['name']);

    if (selectedUserDoc.exists) {
      if (selectedUserDoc['push notification'] == true) {
        sendNotification(fromUserName, utcDate, date, time);
      }
      if (selectedUserDoc['email notification'] == true) {
        sendEmail(fromUserName, selectedUserDoc['email'], date, time);
      }
    }

    widget.refreshMeetingsList();
    popCallback();
  }

  void sendNotification(
      String fromUserName, DateTime date, String day, String time) async {
    final pushNotifs = firebase_msg.PushNotifs();

    final token = await FirebaseFirestore.instance
        .collection('users')
        .doc(selectedUserId)
        .collection('tokens')
        .doc('t1')
        .get()
        .then((doc) => doc['token']);

    pushNotifs.sendPushMessage(
        token,
        'Meeting Request from $fromUserName',
        'Meeting on $day - $time Central Time',
        Timestamp.fromDate(date),
        'requests_screen');
  }

  void sendEmail(
      String fromUserName, String toUserEmail, String day, String time) async {
    final String username = dotenv.env['GROUP_EMAIL'] ?? '';
    final String password = dotenv.env['GROUP_PASSWORD'] ?? '';

    final smtpServer = gmail(username, password);

    final message = Message()
      ..from = Address(username, 'Meet Me Halfway')
      ..recipients.add(toUserEmail)
      ..subject = 'New Request'
      ..text =
          'Meeting request from $fromUserName for $day - $time Central Time';

    try {
      await send(message, smtpServer);
    } catch (e) {
      showErrorMessage('Email not sent.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Meeting'),
      ),
      body: GestureDetector(
        onTap: () {
          setState(() {
            userResults.clear();
            searchResults.clear();
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Stack(
            children: [
              Container(
                color: Colors.transparent,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _userController,
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        searchUsersByEmail(value);
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Search User by Email',
                    ),
                  ),
                  const SizedBox(height: 40),
                  GestureDetector(
                    onTap: () async {
                      TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedTime = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Select Time',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        selectedTime != null
                            ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                            : 'Select a time',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _locationController,
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        searchPlaces(value);
                      }
                    },
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      hintText: "Enter Location",
                      labelText: 'Location',
                    ),
                  ),
                  const SizedBox(height: 50),
                  ElevatedButton(
                    onPressed: () async {
                      final currentUserEmail =
                          FirebaseAuth.instance.currentUser!.email;

                      if (_userController.text.isEmpty ||
                          _locationController.text.isEmpty ||
                          selectedTime == null) {
                        showErrorMessage('Please fill in all fields.');
                        return;
                      }

                      if (_userController.text == currentUserEmail) {
                        showErrorMessage(
                            'You cannot create a meeting with yourself.');
                        return;
                      }

                      if (selectedUserId == null) {
                        showErrorMessage(
                            'Please select a valid user from the list.');
                        return;
                      }

                      try {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                        await createMeeting(() {
                          Navigator.pop(context);

                          AwesomeDialog(
                            context: context,
                            dialogType: DialogType.info,
                            animType: AnimType.rightSlide,
                            title: 'Meeting Request Sent',
                            btnOkText: 'Close',
                            btnOkOnPress: () {
                              Navigator.pop(context);
                            },
                          ).show();
                        });
                      } catch (e) {
                        showErrorMessage(
                            'Failed to create the meeting. Please try again.');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Color(0xFF227CFF),
                    ),
                    child: const Text('Create Meeting'),
                  ),
                ],
              ),
              if (userResults.isNotEmpty)
                Positioned(
                  top: 70,
                  left: 16,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color.fromARGB(255, 48, 48, 48)
                          : Colors.white,
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color.fromARGB(255, 158, 158, 158)
                            : const Color.fromARGB(255, 158, 158, 158),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ListView.builder(
                      itemCount: userResults.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(
                            userResults[index].email,
                            style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              _userController.text = userResults[index].email;
                              selectedUserId = userResults[index].userId;
                              userResults.clear();
                            });
                          },
                        );
                      },
                    ),
                  ),
                ),
              if (searchResults.isNotEmpty)
                Positioned(
                  top: 255,
                  left: 16,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[850]
                          : Colors.white,
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey
                            : Colors.grey,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ListView.builder(
                      itemCount: searchResults.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(
                            searchResults[index].description,
                            style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white // White text for dark mode
                                  : Colors.black, // Black text for light mode
                            ),
                          ),
                          onTap: () {
                            selectPlace(searchResults[index].placeId);
                            _locationController.text =
                                searchResults[index].description;
                            setState(() {
                              searchResults.clear();
                            });
                          },
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> searchUsersByEmail(String query) async {
    final users = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isGreaterThanOrEqualTo: query)
        .limit(1)
        .get();

    setState(() {
      userResults = users.docs
          .map((doc) => User(userId: doc.id, email: doc['email']))
          .toList();
    });
  }

  Future<void> searchPlaces(String query) async {
    String apiKey = dotenv.env['API_KEY'] ?? '';
    String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&types=geocode&key=$apiKey';
    var response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      if (data['status'] == 'OK') {
        setState(() {
          searchResults = (data['predictions'] as List)
              .map((place) => Place(
                    placeId: place['place_id'],
                    description: place['description'],
                  ))
              .toList();
        });
      }
    }
  }

  Future<void> selectPlace(String placeId) async {
    String apiKey = dotenv.env['API_KEY'] ?? '';
    String url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry&key=$apiKey';
    var response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      if (data['status'] == 'OK') {
        var location = data['result']['geometry']['location'];
        double lat = location['lat'];
        double lng = location['lng'];
        setState(() {
          _latitude = lat;
          _longitude = lng;
        });
      }
    }
  }
}
