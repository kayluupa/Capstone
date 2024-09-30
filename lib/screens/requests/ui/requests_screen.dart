import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class User {
  final String id;
  final String email;

  User({required this.id, required this.email});

  factory User.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return User(
      id: doc.id,
      email: data['email'] ?? 'No Email',
    );
  }
}

class MeetingRequest {
  final Timestamp date;
  final String fromUserId;
  final String fromRequestId;
  final String toUserId;
  final String toRequestId;
  final String time;
  final String lat;
  final String lng;
  String userEmail;

  MeetingRequest({
    required this.fromUserId,
    required this.fromRequestId,
    required this.toUserId,
    required this.toRequestId,
    required this.date,
    required this.time,
    required this.lat,
    required this.lng,
    required this.userEmail,
  });

  factory MeetingRequest.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return MeetingRequest(
      fromUserId: data['fromUserId'] ?? '',
      fromRequestId: data['fromRequestId'] ?? '',
      toUserId: data['toUserId'] ?? '',
      toRequestId: data['toRequestId'] ?? '',
      date: data['date'] ?? Timestamp.now(),
      time: data['time'] ?? 'No Time',
      lat: data['lat'] ?? '0.0',
      lng: data['lng'] ?? '0.0',
      userEmail: '',
    );
  }
}

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  RequestsScreenState createState() => RequestsScreenState();
}

class RequestsScreenState extends State<RequestsScreen> {
  late List<MeetingRequest> meetingRequests = [];
  late String userId;
  late TextEditingController _locationController;
  List<Place> searchResults = [];
  String _latitude = "";
  String _longitude = "";

  @override
  void initState() {
    super.initState();
    fetchCurrentUser();
    _locationController = TextEditingController();
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  void fetchCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
      fetchAllRequests();
    }
  }

  void fetchAllRequests() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('requests')
              .get();

      List<MeetingRequest> requests = snapshot.docs
          .map((doc) => MeetingRequest.fromFirestore(doc))
          .where((request) => request.fromUserId != userId)
          .toList();

      for (var request in requests) {
        DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
            .instance
            .collection('users')
            .doc(request.fromUserId)
            .get();
        String email = userDoc.data()?['email'] ?? 'No Email';
        request.userEmail = email;
      }

      meetingRequests = requests;

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

  void acceptRequest(MeetingRequest request) async {
    _locationController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Location'),
          content: SizedBox(
            height: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _locationController,
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      searchPlaces(value);
                    }
                  },
                  decoration: const InputDecoration(hintText: 'Location'),
                ),
                const SizedBox(height: 10),
                if (searchResults.isNotEmpty)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 5.0,
                            spreadRadius: 2.0,
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        itemCount: searchResults.length,
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
          actions: [
            TextButton(
              onPressed: () async {
                final newLocation = _locationController.text;

                if (newLocation.isNotEmpty) {
                  final navigator = Navigator.of(context);
                  final initFromRef = FirebaseFirestore.instance
                      .collection('users')
                      .doc(request.fromUserId)
                      .collection('meetings')
                      .doc();

                  final initToRef = FirebaseFirestore.instance
                      .collection('users')
                      .doc(request.toUserId)
                      .collection('meetings')
                      .doc();

                  final meetingData = {
                    'fromUserId': request.fromUserId,
                    'fromRequestId': initFromRef.id,
                    'toUserId': request.toUserId,
                    'toRequestId': initToRef.id,
                    'email': null,
                    'date': request.date,
                    'time': request.time,
                    'lat': _latitude,
                    'lng': _longitude,
                  };

                  await initFromRef.set(meetingData);
                  await initToRef.set(meetingData);

                  try {
                    DocumentSnapshot<Map<String, dynamic>> userDoc =
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(request.fromUserId)
                            .get();
                    String email = userDoc.data()?['email'] ?? 'No Email';

                    if (userDoc.exists) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(request.toUserId)
                          .collection('requests')
                          .doc(initToRef.id)
                          .update({'email': email});
                    }

                    userDoc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(request.toUserId)
                        .get();

                    if (userDoc.exists) {
                      email = userDoc.data()?['email'] ?? 'No Email';
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(request.fromUserId)
                          .collection('requests')
                          .doc(initFromRef.id)
                          .update({'email': null});
                    }
                  } catch (e) {
                    showErrorMessage(e.toString());
                  }

                  deleteRequest(request);

                  navigator.pop();
                  fetchAllRequests();
                } else {
                  showErrorMessage('Please enter a location.');
                }
              },
              child: const Text('Submit'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void deleteRequest(MeetingRequest request) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(request.fromUserId)
          .collection('requests')
          .doc(request.fromRequestId)
          .delete();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(request.toUserId)
          .collection('requests')
          .doc(request.toRequestId)
          .delete();

      setState(() {
        meetingRequests
            .removeWhere((req) => req.fromRequestId == request.fromRequestId);
      });
    } catch (e) {
      showErrorMessage(e.toString());
    }
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
          _latitude = lat.toString();
          _longitude = lng.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meeting Requests'),
      ),
      body: ListView.builder(
        itemCount: meetingRequests.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(meetingRequests[index].userEmail),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('MMMM d, y')
                    .format(meetingRequests[index].date.toDate())),
                Text(meetingRequests[index].time),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => acceptRequest(meetingRequests[index]),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => deleteRequest(meetingRequests[index]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class Place {
  final String placeId;
  final String description;

  Place({required this.placeId, required this.description});
}
