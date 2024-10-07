import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../../helpers/firebase_msg.dart' as firebaseMsg;

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

  Future<void> createMeeting(VoidCallback popCallback) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

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
        'date': widget.day.toUtc().add(const Duration(hours: 5)),
        'time': selectedTime != null
            ? '${selectedTime!.hour}:${selectedTime!.minute}'
            : null,
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

    widget.refreshMeetingsList();
    popCallback();
  }

  void sendNotification() async {
    final pushNotifs = firebaseMsg.PushNotifs();

    final token = await FirebaseFirestore.instance
        .collection('users')
        .doc(selectedUserId)
        .collection('tokens')
        .doc('t1')
        .get()
        .then((doc) => doc['token']);

    final fromUserName = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get()
        .then((doc) => doc['name']);

    String date = DateFormat('MM/dd/yy')
        .format(widget.day.toUtc().add(const Duration(hours: 5)));

    String time = selectedTime != null
        ? '${selectedTime!.hour}:${selectedTime!.minute}'
        : 'TBD';

    pushNotifs.sendPushMessage(
        token,
        'Meeting Request from $fromUserName',
        'Meeting on $date - $time',
        Timestamp.fromDate(widget.day.toUtc().add(const Duration(hours: 5))),
        'requests_screen');
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
                            ? '${selectedTime!.hour}:${selectedTime!.minute}'
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
                      sendNotification();
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                      await createMeeting(() {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      });
                    },
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
                      color: Colors.white,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ListView.builder(
                      itemCount: userResults.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(userResults[index].email),
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
                      color: Colors.white,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ListView.builder(
                      itemCount: searchResults.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(searchResults[index].description),
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
    String apiKey = "AIzaSyDizaB7QZXvI6NY2ppGrbFemKAeZNcGSvc";
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
    String apiKey = 'AIzaSyDizaB7QZXvI6NY2ppGrbFemKAeZNcGSvc';
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
