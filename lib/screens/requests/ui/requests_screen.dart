import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class User {
  final String id;
  final String name;

  User({required this.id, required this.name});

  factory User.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return User(
      id: doc.id,
      name: data['name'] ?? 'No Name',
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
  String name;

  MeetingRequest({
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
      name: '',
    );
  }
}

class Place {
  final String placeId;
  final String description;

  Place({required this.placeId, required this.description});
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
          .toList();

      for (var request in requests) {
        String targetUserId = request.fromUserId == userId
            ? request.toUserId
            : request.fromUserId;
        DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
            .instance
            .collection('users')
            .doc(targetUserId)
            .get();
        String name = userDoc.data()?['name'] ?? 'No Name';
        request.name = name;
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
    final newLocation = _locationController.text;

    if (newLocation.isNotEmpty) {
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
        'name': null,
        'date': request.date,
        'time': request.time,
        'lat': _latitude,
        'lng': _longitude,
      };

      await initFromRef.set(meetingData);
      await initToRef.set(meetingData);

      try {
        DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
            .instance
            .collection('users')
            .doc(request.toUserId)
            .get();
        String name = userDoc.data()?['name'] ?? 'No Name';

        if (userDoc.exists) {
          await initFromRef.update({'name': name});
        }

        userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(request.fromUserId)
            .get();
        name = userDoc.data()?['name'] ?? 'No Name';

        if (userDoc.exists) {
          await initToRef.update({'name': name});
        }
      } catch (e) {
        showErrorMessage(e.toString());
      }

      deleteRequest(request);
      fetchAllRequests();
    } else {
      showErrorMessage('Please enter a location.');
    }
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _locationController,
              onChanged: (value) {
                if (value.isNotEmpty) {
                  searchPlaces(value);
                } else {
                  setState(() {
                    searchResults
                        .clear();
                  });
                }
              },
              decoration: const InputDecoration(
                hintText: 'Enter Location',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          if (searchResults.isNotEmpty)
            Expanded(
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
                        searchResults
                            .clear();
                      });
                    },
                  );
                },
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: meetingRequests.length,
              itemBuilder: (context, index) {
                final request = meetingRequests[index];
                final isCreatedByCurrentUser = request.fromUserId == userId;

                return ListTile(
                  title: Text(request.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat('MMMM d, y')
                          .format(request.date.toDate())),
                      Text(request.time),
                    ],
                  ),
                  trailing: isCreatedByCurrentUser
                      ? IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => deleteRequest(request),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon:
                                  const Icon(Icons.check, color: Colors.green),
                              onPressed: () => acceptRequest(request),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => deleteRequest(request),
                            ),
                          ],
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
