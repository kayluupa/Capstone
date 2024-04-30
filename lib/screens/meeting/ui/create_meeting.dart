import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateMeeting extends StatefulWidget {
  final DateTime day;
  final void Function() refreshMeetingsList;

  const CreateMeeting(
      {super.key, required this.day, required this.refreshMeetingsList});

  @override
  CreateMeetingState createState() => CreateMeetingState();
}

class CreateMeetingState extends State<CreateMeeting> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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
}
