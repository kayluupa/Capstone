import 'package:flutter/material.dart';

class NotifScreen extends StatelessWidget {
  const NotifScreen({super.key});

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
              value: true, 
              onChanged: (bool value) {
                // toggle logic here
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Email Notifications'),
              value: true, 
              onChanged: (bool value) {
                // toggle logic here
              },
            ),
          ],
        ),
      ),
    );
  }
}