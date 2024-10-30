import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotifScreen extends StatefulWidget {
  const NotifScreen({super.key});

  @override
  NotifScreenState createState() => NotifScreenState();
}

class NotifScreenState extends State<NotifScreen> {
  bool _pushNotification = true;
  bool _emailNotification = true;
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _fetchNotificationSettings();
  }

  Future<void> _fetchNotificationSettings() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      setState(() {
        _pushNotification = userDoc['push notification'] ?? true;
        _emailNotification = userDoc['email notification'] ?? true;
      });
    }
  }

  Future<void> _updateNotificationSettings(String field, bool value) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      field: value,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Enable Push Notifications'),
              value: _pushNotification,
              activeColor: Color(0xFF227CFF),
              onChanged: (bool value) {
                setState(() {
                  _pushNotification = value;
                });
                _updateNotificationSettings('push notification', value);
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Email Notifications'),
              value: _emailNotification,
              activeColor: Color(0xFF227CFF),
              onChanged: (bool value) {
                setState(() {
                  _emailNotification = value;
                });
                _updateNotificationSettings('email notification', value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
