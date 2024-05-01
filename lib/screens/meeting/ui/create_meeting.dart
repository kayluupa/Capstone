import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreateMeeting extends StatefulWidget {
  final DateTime day;
  final void Function() refreshMeetingsList;

  const CreateMeeting(
      {super.key, required this.day, required this.refreshMeetingsList});

  @override
  CreateMeetingState createState() => CreateMeetingState();
}

class Place {
  final String placeId;
  final String description;

  Place({required this.placeId, required this.description});
}

class CreateMeetingState extends State<CreateMeeting> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;

  List<Place> searchResults = [];
  String _latitude = "";
  String _longitude = "";

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _locationController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> createMeeting(VoidCallback popCallback) async {
    // Get user ID
    final userId = FirebaseAuth.instance.currentUser!.uid;

    // Create a new meeting document in Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('meetings')
        .add({
      'title': _titleController.text,
      'description': _descriptionController.text,
      // Add other meeting details as needed
      'date': widget.day.toUtc().add(const Duration(hours: 5)),
      'lat': _latitude,
      'lng': _longitude,
      'location': _locationController.text,
    });

    widget.refreshMeetingsList();

    // Call the callback function to pop the navigator
    popCallback();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Meeting'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
              ),
              maxLines: null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              onChanged: (value) {
                if (value.isNotEmpty) {
                  searchPlaces(value);
                  _locationController.text;
                }
              },
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(hintText: "Enter Location"),
            ),
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
                        searchResults.clear(); // Clear the search results
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                // Show a loading indicator
                showDialog(
                  context: context,
                  barrierDismissible:
                      false, // Prevent dismissing the dialog by tapping outside
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                // Create the meeting
                await createMeeting(() {
                  // Pop the dialog
                  Navigator.pop(context);

                  // Pop the screen
                  Navigator.pop(context);
                });
              },
              child: const Text('Create Meeting'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> searchPlaces(String query) async {
    String apiKey = "AIzaSyBtOyOc0k0pQwnUgjIf_K4sGdPApdI-WUY";
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
    String apiKey = 'AIzaSyBtOyOc0k0pQwnUgjIf_K4sGdPApdI-WUY';
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
}
