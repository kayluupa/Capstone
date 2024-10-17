import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theming/theme_notifier.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = true;

  @override
  void initState() {
    super.initState();
    _loadUserDarkModeSetting();
  }

  Future<void> _loadUserDarkModeSetting() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      setState(() {
        _isDarkMode = userDoc['dark mode'] ?? true;
      });
    }
  }

  Future<void> _updateUserDarkModeSetting(bool value) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'dark mode': value});
    }
  }

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
              Navigator.pushNamed(context, '/notifScreen');
            },
          ),
          ListTile(
            title: const Text('Help'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pushNamed(context, '/helpScreen');
            },
          ),
          ListTile(
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pushNamed(context, '/privacyScreen');
            },
          ),
          ListTile(
            title: const Text('Terms & Conditions'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pushNamed(context, '/tandcScreen');
            },
          ),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: _isDarkMode,
            onChanged: (bool value) {
              setState(() {
                _isDarkMode = value;
              });
              _updateUserDarkModeSetting(value);
              Provider.of<ThemeNotifier>(context, listen: false)
                  .toggleTheme(value);
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
