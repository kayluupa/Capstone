import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          ListTile(
            title: const Text('Account'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pushNamed(context, '/accountScreen');  
            },
          ),
          ListTile(
            title: const Text('Notifications'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
            },
          ),
          ListTile(
            title: const Text('About Us'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
            },
          ),
          ListTile(
            title: const Text('Help'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
            },
          ),
          ListTile(
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
            },
          ),
          ListTile(
            title: const Text('Terms & Conditions'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
            },
          ),
          const SizedBox(height: 20.0),
          const Text('App Versions', textAlign: TextAlign.center),
          const SizedBox(height: 5.0),
          const Text('v0.0.1', textAlign: TextAlign.center),
          const SizedBox(height: 20.0),
        ],
      ),
    );
  }
}
