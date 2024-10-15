// helpers/firebase_msg.dart
import 'dart:convert';
import 'package:capstone/routing/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
// import 'package:googleapis/servicecontrol/v1.dart' as servicecontrol;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../main.dart';

class PushNotifs {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initNotifs() async {
    await _fcm.requestPermission();

    String? token = await _fcm.getToken();
    if (token != null) {
      await _saveTokenToDatabase(token);
    }

    // Handle token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen(_saveTokenToDatabase);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received a message while in the foreground!');
      print('Message data: ${message.data}');
      _handleMessage(message);
    });

    // Handle background and terminated state messages
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessage(message);
    });

    // Handle the initial message when the app is opened via a notification
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    User? user = _auth.currentUser;
    if (user != null) {
      var tokensRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tokens')
          .doc('t1');

      await tokensRef.set({
        'token': token,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  void _handleMessage(RemoteMessage message) {
    if (message.data['screen'] == 'meeting_screen') {
      navigatorKey.currentState?.pushNamed(Routes.meetingScreen,
          arguments: {'day': DateTime.parse(message.data['date'])});
    } else if (message.data['screen'] == 'requests_screen') {
      navigatorKey.currentState?.pushNamed(Routes.requestsScreen);
    }
  }

  // Method to get access token for service account
  static Future<String?> getAccessToken() async {
    final serviceAccountJson = {
      "type": dotenv.env['SERVICE_ACCOUNT_TYPE'],
      "project_id": dotenv.env['PROJECT_ID'],
      "private_key_id": dotenv.env['PRIVATE_KEY_ID'],
      "private_key": dotenv.env['PRIVATE_KEY'],
      "client_email": dotenv.env['CLIENT_EMAIL'],
      "client_id": dotenv.env['CLIENT_ID'],
      "auth_uri": dotenv.env['AUTH_URI'],
      "token_uri": dotenv.env['TOKEN_URI'],
      "auth_provider_x509_cert_url": dotenv.env['AUTH_PROVIDER_X509_CERT_URL'],
      "client_x509_cert_url": dotenv.env['CLIENT_X509_CERT_URL'],
      "universe_domain": dotenv.env['UNIVERSE_DOMAIN']
    };

    List<String> scopes = [
      'https://www.googleapis.com/auth/userinfo.email',
      'https://www.googleapis.com/auth/firebase.database',
      'https://www.googleapis.com/auth/firebase.messaging'
    ];

    http.Client client = await auth.clientViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(serviceAccountJson), scopes);

    auth.AccessCredentials credentials =
        await auth.obtainAccessCredentialsViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
      client,
    );

    client.close();

    return credentials.accessToken.data;
  }

  void sendPushMessage(String token, String title, String body, Timestamp date,
      String screen) async {
    final String? serverAccessKey = await getAccessToken();
    final http.Response response = await http.post(
        Uri.parse(
            'https://fcm.googleapis.com/v1/projects/${dotenv.env['PROJECT_ID']}/messages:send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $serverAccessKey',
        },
        body: jsonEncode(<String, dynamic>{
          'message': {
            'token': token,
            'notification': {
              'title': title,
              'body': body,
            },
            'data': {'screen': screen, 'date': date.toDate().toIso8601String()},
          },
        }));

    if (response.statusCode == 200) {
      print('MESSAGE SENT');
    } else {
      print(token);
      print('Message failed with status: ${response.statusCode}');
      print('Message failed with body: ${response.body}');
    }
  }
}
