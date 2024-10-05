import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';

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
  final double lat;
  final double lng;
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
      lat: data['lat'] ?? 0.0,
      lng: data['lng'] ?? 0.0,
      name: '',
    );
  }
}

class Place {
  final String placeId;
  final String description;

  Place({required this.placeId, required this.description});
}

double radians(double degrees) {
  return degrees * (pi / 180.0);
}

double degrees(double radians) {
  return radians * 180 / pi;
}

LatLng _calculateMidpoint(LatLng point1, LatLng point2) {
  double lat1 = radians(point1.latitude);
  double lng1 = radians(point1.longitude);
  double lat2 = radians(point2.latitude);
  double lng2 = radians(point2.longitude);

  double dLng = lng2 - lng1;
  double x = cos(lat2) * cos(dLng);
  double y = cos(lat2) * sin(dLng);
  double mLat = atan2(
      sin(lat1) + sin(lat2), sqrt((cos(lat1) + x) * (cos(lat1) + x) + y * y));
  double mLng = lng1 + atan2(y, cos(lat1) + x);

  return LatLng(degrees(mLat), degrees(mLng));
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
  double _latitude = 0.0;
  double _longitude = 0.0;

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

      Set<String> userIds = {};
      for (var request in requests) {
        userIds.add(request.fromUserId);
        userIds.add(request.toUserId);
      }

      if (userIds.isNotEmpty) {
        FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: userIds.toList())
            .get()
            .then((QuerySnapshot<Map<String, dynamic>> snapshot) {
          Map<String, String> userNames = {};
          for (var doc in snapshot.docs) {
            userNames[doc.id] = doc.data()['name'] ?? 'No Name';
          }

          setState(() {
            for (var request in requests) {
              request.name = userNames[request.fromUserId] ?? 'No Name';
            }
            meetingRequests = requests;
          });
        }).catchError((error) {
          showErrorMessage('Error fetching user names: $error');
        });
      }
    } catch (e) {
      showErrorMessage('Error fetching meeting requests: $e');
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
      DocumentSnapshot<Map<String, dynamic>> fromRequestDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(request.fromUserId)
              .collection('requests')
              .doc(request.fromRequestId)
              .get();

      double fromLat = fromRequestDoc.data()?['lat'] ?? 0.0;
      double fromLng = fromRequestDoc.data()?['lng'] ?? 0.0;

      LatLng midpoint = _calculateMidpoint(
          LatLng(fromLat, fromLng), LatLng(_latitude, _longitude));

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
        'lat': midpoint.latitude,
        'lng': midpoint.longitude,
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
          _latitude = lat;
          _longitude = lng;
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
                    searchResults.clear();
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
                        searchResults.clear();
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
