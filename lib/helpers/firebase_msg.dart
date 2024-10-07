// helpers/firebase_msg.dart
import 'dart:convert';
import 'package:capstone/routing/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:googleapis/servicecontrol/v1.dart' as servicecontrol;
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
      "type": "service_account",
      "project_id": "algorithm-avengers-3008d",
      "private_key_id": "c9d41cf10f3c2ee30750120fbf7089abe8b296ed",
      "private_key":
          "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC98eNXEmTnxH0g\nW5TE/mWUeEqHzzZklbwyc6IyE8AZVfSBIZrjtU85EW+JP1V4/PU7QpbsRRx4rVqZ\nfGtHk9bIq6f3zN5xFdLnniXioXAbwTSuuC4Ktxc0peYrQ1Tz2uIXhShp4uP39Mpa\nYXkxW/TbcKaKihzUUqZNti+mM6en3cgDPDUYvj04Ng5vMlcQHGDKHauNAxCigrmI\nvA1aLtg4bvHuMV/HrKtZ7CJyjsmE1ZAW0g02eJiFKh+AhCbc6WOZ+KDcoqgfYv4R\nnZZ9DDuwdUQG+eIALNkcBCzBdNXBtOBMwcTCUk783unYig+wk6B76Nz97i2MxwEu\nx2PbqK65AgMBAAECggEAELj9jLppWNWoiyiU70eoa3WwYMbiS+EPlG+FbZw7Mt/U\nQBQp00ywoLPDb+q8By6va8a1NoWad+4R27vOTsXEyJ5YPOL0CIe6guVzrMFizIa/\nhncKUquDkaveGPFQxuFT5hc1PiaZbx3wPMcic4aG3FT4Ie/+kXDaBF3QUcpwGGwG\ndmniu89cVLVs4B/eT49XYBl37XsmGVITZM8pgLfLASuS0KhSkYGMhD5JzuqOzWfx\nq1LR3s+HkSYSy79+9gH8VdKbfsemjFY7ABgAUkjyQFAHjD2NpIEl3IkkwJdydYTg\nCX8ffL+Nk8ANgMX35rqtSW2hN6RJjhJvw4/pf9QcQwKBgQD92dGl5Vw7Su0z3XXI\nNzG7AB8mPL8+IZ66OIJGBwHIHT/uWjkQsN4cUjWfjxaVmm3GdXRXAsNy4OjsB84G\nsBUle4YzYBENZfzUt7NycomyZ+yIPt5WRHHyZTt5xZ7TD8R0X/2OZQV6AsGQ8QsI\n8atlozns8ePGKkRnoJAjOGffSwKBgQC/jZApp33V0kKUS2EQsgzdu7MbiIz15XHM\nLRkWVCV7FKw7AaaSX9rPlL13rSdFoLSZ7fROJs7i5VKS6Lyhl08VmLyv0L6YMDiK\n/gqwYZ+U1HQBNs93UjdAHb3HcSrkm3G1oIEc4V6BfcIZZfDcfZXnLVt5RHKlkuMf\nsmuXDMOziwKBgQDxUQjQmSpFn2PBA009iOK4r1PtSKBQ0ysOQjvtkCmsb8nfr1tC\nN7Dd4XTieubwTv7+Q5fWQ2VDpvUltAGyL9/aYwPfgPqU7xgbq4pmSOYHeG3N014P\nSj+8O2n/x9LFN9789meW3wgGxen2/H4OAZd7JmEhk42BS5r9nBCJusxb4wKBgH/q\nFL78Lje/NN66h5MSkyzuzugwA5GhKqDh7MLQZkcOwwSUUZuljwTXmr50Tqlca73u\n/RnDKJyz7rRT3sM5u4H8gOQXTW9rpBaNFq46QsqsJNs6sshHisWyFq08kRwgAYr8\nJ7wVc3qddCRpwrI62wOJcnBEmRqgQDNGfjpcN8OJAoGAPTZjuauiqxaLJ/3ZLB0E\nKnN6aGvbaI6cwuWaukXcUwF2WOJD7Sfu7xHztMy1QWXiYvX/MFMnpAu8M9Jd+uhm\n9WIftAk0xS1LXMhLx/Gucg0EuwvYoMT2pvhdkEOc2HoPU/1QZbNbam3qj2GrjK51\nXgkoztwOCvMfEjJEX6NFvuk=\n-----END PRIVATE KEY-----\n",
      "client_email":
          "algorithm-avengers@algorithm-avengers-3008d.iam.gserviceaccount.com",
      "client_id": "116017968903328768538",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url":
          "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url":
          "https://www.googleapis.com/robot/v1/metadata/x509/algorithm-avengers%40algorithm-avengers-3008d.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com"
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
            'https://fcm.googleapis.com/v1/projects/algorithm-avengers-3008d/messages:send'),
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
